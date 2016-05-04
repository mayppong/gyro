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
    :timer.send_interval(@timer, self, :spin)
    {:ok, state}
  end

  @doc """
  Add the given spinner id to the spinner roster Agent.
  """
  def handle_call({:enlist, spinner_pid}, _from, state = %{spinner_roster: spinner_roster}) do
    spinner_roster
    |> Agent.update(fn(spinners) ->
      Map.put(spinners, :erlang.pid_to_list(spinner_pid), spinner_pid)
    end)

    {:reply, state, state}
  end

  @doc """
  Remove the given spinner id from the spinner roster Agent.
  """
  def handle_call({:delist, spinner_pid}, _from, state = %{spinner_roster: spinner_roster}) do
    spinner_roster
    |> Agent.update(fn(spinners) ->
      Map.delete(spinners, :erlang.pid_to_list(spinner_pid))
    end)

    {:reply, state, state}
  end

  @doc """
  Handle the introspect call to get the current state of the Arena.
  """
  def handle_call(:introspect, _from, state) do
    {:reply, state, state}
  end

  @doc """
  Handle the spinning which is where we update the state of the Arena at an
  interval.
  """
  def handle_info(:spin, state) do
    state = state
    |> update_heroic_spinners

    {:noreply, state}
  end

  # This is a generic function for updating a map of spinners
  defp update_spinners(spinners) do
    spinners
    |> Enum.map(fn({_, spinner_pid}) ->
      case Spinner.exists?(spinner_pid) do
        nil -> %{score: 0, spm: 0}
        _ -> Spinner.introspect(spinner_pid) |> Map.delete(:connected_at)
      end
    end)
  end

  # This method is used for updating the heroic_spinners during the spin. It
  # collects the spinner data by iterating through the spinner roster and ask
  # for the current spinner state, then sort them by score before taking the
  # top 10 players.
  # TODO: Currently, we have to remove the connected_at value from the
  # spinner bacause we can't output it into a JSON format.
  defp update_heroic_spinners(state = %{spinner_roster: spinner_roster}) do
    top10 = Agent.get(spinner_roster, fn(spinners) ->
      spinners
      |> update_spinners
      |> Enum.sort(fn(one, two) ->
        one.score >= two.score
      end)
      |> Enum.take(10)
    end)

    Map.put(state, :heroic_spinners, top10)
  end
end
