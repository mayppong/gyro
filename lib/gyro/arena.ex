defmodule Gyro.Arena do
  use GenServer

  alias __MODULE__
  alias Gyro.Arena.Spinnable
  alias Gyro.Scoreboard

  @derive {Poison.Encoder, except: [:members]}
  defstruct members: %{},
    score: 0, spm: 0, size: 0,
    scoreboard: %Scoreboard{}

  @spinners_pid {:global, :spinners}
  @squads_pid {:global, :squads}
  @timer 1000

  @doc """
  Add a new spinner to the spinner roster
  """
  def enlist(:spinners, spinnable_pid) do
    GenServer.cast(@spinners_pid, {:enlist, spinnable_pid})
  end
  def enlist(:squads, spinnable_pid) do
    GenServer.cast(@squads_pid, {:enlist, spinnable_pid})
  end

  @doc """
  Remove a spinner from the spinner roster
  """
  def delist(:spinners, spinnable_pid) do
    GenServer.cast(@spinners_pid, {:delist, spinnable_pid})
  end
  def delist(:squads, spinnable_pid) do
    GenServer.cast(@squads_pid, {:delist, spinnable_pid})
  end

  @doc """
  Get the current state of the Arena
  """
  def introspect(:spinners) do
    GenServer.call(@spinners_pid, :introspect)
  end
  def introspect(:squads) do
    GenServer.call(@squads_pid, :introspect)
  end

  @doc """
  Start the arena GenServer by first starts 2 Agents: one for tracking active
  spinners, and another for tracking active squads in the system. One both
  Agents are started successfully, we then start the Arena GenServer.
  If either of the Agents fails to start, it returns the error from that
  Agent and not starts the arena GenServer.
  """
  def start_link(name, state \\ %Arena{})
  def start_link(:spinners, state) do
    GenServer.start_link(__MODULE__, state, name: @spinners_pid)
  end
  def start_link(:squads, state) do
    GenServer.start_link(__MODULE__, state, name: @squads_pid)
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
  def handle_cast({:enlist, spinner_pid}, state = %{members: members, size: size}) do
    Process.monitor(spinner_pid)
    state = %{state | members: Map.put(members, spinner_pid, spinner_pid), size: size + 1}
    {:noreply, state}
  end

  @doc """
  Remove the given spinner id from the member list in the state
  """
  def handle_cast({:delist, spinner_pid}, state = %{members: members, size: size}) do
    state = %{state | members: Map.delete(members, spinner_pid), size: size - 1}
    {:noreply, state}
  end


  @doc """
  Handle the `:DOWN` message from the Spinnables' processes we monitor on
  enlist.
  If the Spinnable's process is downed, we delist them from the Arna's roster.
  """
  def handle_info({:DOWN, _, :process, spinner_pid, _}, state) do
    handle_cast({:delist, spinner_pid}, state)
  end

  @doc """
  Handle the spinning which is where we update the state of the Arena at an
  interval.
  """
  def handle_info(:spin, state = %{members: pids, scoreboard: scoreboard}) do
    members = pids
    |> inspect_members

    scoreboard = Scoreboard.build(scoreboard, members)

    state = %{state | scoreboard: scoreboard, score: scoreboard.score, spm: scoreboard.spm}
    Process.send_after(self, :spin, @timer)
    {:noreply, state}
  end

  # A private method for getting the latest state of processes in a given
  # list.
  defp inspect_members(members) do
    members
    |> Stream.map(fn({_, pid}) ->
      Task.async(fn -> Spinnable.introspect(pid) end)
    end)
    |> Stream.map(&(Task.await(&1)))
    |> Enum.filter(&(!is_nil(&1)))
  end

end
