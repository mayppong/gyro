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
    GenServer.call(@pid, {:enlist, spinner_pid})
  end

  @doc """
  Remove a spinner from the spinner roster
  """
  def delist(spinner_pid) do
    GenServer.call(@pid, {:delist, spinner_pid})
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
  Add the given spinner id to the spinner roster Agent.
  """
  def handle_call({:enlist, spinner_pid}, _from, state = %{spinner_roster: spinner_roster}) do
    spinner_roster
    |> Agent.update(fn(state) ->
      Map.put(state, :erlang.pid_to_list(spinner_pid), spinner_pid)
    end)

    {:reply, state, state}
  end

  @doc """
  Remove the given spinner id from the spinner roster Agent.
  """
  def handle_call({:delist, spinner_pid}, _from, state = %{spinner_roster: spinner_roster}) do
    spinner_roster
    |> Agent.update(fn(state) ->
      Map.delete(state, :erlang.pid_to_list(spinner_pid))
    end)

    {:reply, state, state}
  end

end
