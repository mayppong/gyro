defmodule Gyro.Arena do
  use GenServer

  alias Gyro.Arena
  alias Gyro.Spinner
  alias Gyro.Squad

  defstruct spinner_roster: nil, squad_roster: nil,
    legendary_spinners: [], legendary_squads: [],
    heroic_spinners: [], heroic_squads: [],
    loudest_squads: []

  @name :arena
  @pid {:global, @name}
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
      GenServer.start_link(__MODULE__, state, name: {:global, @name})
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
    |> Enum.map(fn({_, pid}) ->
      Task.async(fn -> Spinner.introspect(pid) end)
    end)
    |> Enum.map(&(Task.await(&1)))
    |> Enum.reduce([], fn(spinner, acc) ->
      case spinner do
        nil -> acc
        state -> [state | acc]
      end
    end)

    state
    |> update_heroic_spinners(spinners)
    |> update_legendary_spinners
  end

  # This method is used for updating the heroic_spinners during the spin. It
  # collects the spinner data by iterating through the spinner roster and ask
  # for the current spinner state, then sort them by score before taking the
  # top 10 players.
  defp update_heroic_spinners(state, spinners) do
    heroics = spinners
    |> Enum.sort(&(&1.score >= &2.score))
    |> Enum.take(10)
    |> minify

    Map.put(state, :heroic_spinners, heroics)
  end

  # This method updates the legendary spinner list based on the new heroic
  # spinners. Unlike heroic, legendary spinners are an all-time score, so we
  # need to compare the score against existing legendary as well, even if the
  # spinner has left the system.
  defp update_legendary_spinners(state = %{heroic_spinners: heroes, legendary_spinners: legends}) do
    legends = legends
    |> Enum.concat(heroes)
    |> Enum.sort(&(&1.score >= &2.score))
    |> Enum.take(10)

    Map.put(state, :legendary_spinners, legends)
  end

  # Private method for cleaning up spinner state before we add them to the
  # list. There are some data in each spinner where we might not care for.
  # This is a good place where we can clean them up and store just the data
  # we need.
  # TODO: once we can JSONify this, we won't need this method any more
  defp minify(spinners) do
    spinners
    |> Enum.map(fn(spinner) ->
      spinner
      |> Map.delete(:connected_at)
    end)
  end

end
