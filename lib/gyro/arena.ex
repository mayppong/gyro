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
  @timer 1000

  @doc """
  Start the arena GenServer by first starts 2 Agents: one for tracking active
  spinners, and another for tracking active squads in the system. One both
  Agents are started successfully, we then start the Arena GenServer.
  If either of the Agents fails to start, it returns the error from that
  Agent and not starts the arena GenServer.
  """
  def start_link(state \\ %Arena{}) do
    with {:ok, spinner_roster} <- Agent.start_link((fn() -> [] end)),
    {:ok, squad_roster} <- Agent.start_link((fn() -> [] end))
    do
      state = %{state | spinner_roster: spinner_roster, squad_roster: squad_roster}
      GenServer.start_link(__MODULE__, state, name: {:global, @name})
    end
  end

end
