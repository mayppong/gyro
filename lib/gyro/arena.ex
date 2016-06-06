defmodule Gyro.Arena do
  use GenServer

  alias Gyro.Arena
  alias Gyro.Spinner
  alias Gyro.Scoreboard

  defstruct spinner_roster: nil, squad_roster: nil,
    scoreboard: %Scoreboard{}

  @pid {:global, __MODULE__}
  @timer 1000

  @doc """
  Add a new spinner to the spinner roster
  """
  def enlist(spinner_pid) do
    GenServer.cast(@pid, {:enlist, spinner_pid})
  end

  @doc """
  Remove a spinner from the spinner roster
  """
  def delist(spinner_pid) do
    GenServer.cast(@pid, {:delist, spinner_pid})
  end

  @doc """
  Get the current state of the Arena
  """
  def introspect() do
    GenServer.call(@pid, :introspect)
  end

  @doc """
  Start the arena GenServer by first starts 2 Agents: one for tracking active
  spinners, and another for tracking active squads in the system. One both
  Agents are started successfully, we then start the Arena GenServer.
  If either of the Agents fails to start, it returns the error from that
  Agent and not starts the arena GenServer.
  """
  def start_link(state \\ %Arena{}) do
    with {:ok, spinner_roster} <- Agent.start_link((fn() -> %{} end)),
    {:ok, squad_roster} <- Agent.start_link((fn() -> %{} end))
    do
      state = %{state | spinner_roster: spinner_roster, squad_roster: squad_roster}
      GenServer.start_link(__MODULE__, state, name: @pid)
    end
  end

  @doc """
  Once the GenServer is started successfully, the init function is invoked.
  For now, we just need to tell it to start spinning.
  """
  def init(state) do
    send(self, :spin)
    {:ok, state}
  end

  @doc """
  Handle the introspect call to get the current state of the Arena.
  """
  def handle_call(:introspect, _from, state) do
    {:reply, state, state}
  end

  @doc """
  Add the given spinner id to the spinner roster Agent.
  """
  def handle_cast({:enlist, spinner_pid}, state = %{spinner_roster: spinner_roster}) do
    Process.monitor(spinner_pid)
    spinner_roster
    |> Agent.update(fn(spinners) ->
      Map.put(spinners, spinner_pid, spinner_pid)
    end)

    {:noreply, state}
  end

  @doc """
  Remove the given spinner id from the spinner roster Agent.
  """
  def handle_cast({:delist, spinner_pid}, state = %{spinner_roster: spinner_roster}) do
    spinner_roster
    |> Agent.update(fn(spinners) ->
      Map.delete(spinners, spinner_pid)
    end)

    {:noreply, state}
  end


  @doc """
  Handle the `:DOWN` message from the Spinners' process we monitor on enlist.
  If the Spinner process is downed, we delist them from the Arna's roster.
  """
  def handle_info({:DOWN, _, :process, spinner_pid, _}, state) do
    handle_cast({:delist, spinner_pid}, state)
  end

  @doc """
  Handle the spinning which is where we update the state of the Arena at an
  interval.
  """
  def handle_info(:spin, state) do
    state = state
    |> update_spinners

    Process.send_after(self, :spin, @timer)
    {:noreply, state}
  end

  # This is a generic function for updating spinner-related stats
  # To update spinner state,  new process is spun up for each member to
  # introspect the state asynchronously. Once we have all members data, we can
  # continue on with the calculations.
  defp update_spinners(state = %{spinner_roster: spinner_roster}) do
    spinners = spinner_roster
    |> Agent.get(&(&1))
    |> Stream.map(fn({_, pid}) ->
      Task.async(fn -> Spinner.introspect(pid) end)
    end)
    |> Stream.map(&(Task.await(&1)))
    |> Enum.filter(&(!is_nil(&1)))

    scoreboard = Scoreboard.build(state.scoreboard, spinners)
    Map.put(state, :scoreboard, scoreboard)
  end

end
