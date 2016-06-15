defmodule Gyro.Arena do
  use GenServer

  alias Gyro.Arena
  alias Gyro.Spinner
  alias Gyro.Scoreboard

  @derive {Poison.Encoder, except: [:members]}
  defstruct members: %{},
    score: 0, spm: 0, scoreboard: %Scoreboard{}

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
    GenServer.start_link(__MODULE__, state, name: @pid)
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
  Add the given spinner id to member list in the state
  """
  def handle_cast({:enlist, spinner_pid}, state = %{members: members}) do
    Process.monitor(spinner_pid)
    state = %{state | members: Map.put(members, spinner_pid, spinner_pid)}
    {:noreply, state}
  end

  @doc """
  Remove the given spinner id from the member list in the state
  """
  def handle_cast({:delist, spinner_pid}, state = %{members: members}) do
    state = %{state | members: Map.delete(members, spinner_pid)}
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
  def handle_info(:spin, state = %{members: members, scoreboard: scoreboard}) do
    scoreboard = members
    |> inspect_members
    |> Scoreboard.build

    state = %{state | scoreboard: scoreboard}
    Process.send_after(self, :spin, @timer)
    {:noreply, state}
  end

  # A private method for getting the latest state of processes in a given
  # list.
  defp inspect_members(members) do
    spinners = members
    |> Stream.map(fn({_, pid}) ->
      Task.async(fn -> Spinner.introspect(pid) end)
    end)
    |> Stream.map(&(Task.await(&1)))
    |> Enum.filter(&(!is_nil(&1)))
  end

end
