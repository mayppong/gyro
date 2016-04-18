defmodule Gyro.Arena do
  use GenServer

  alias Gyro.Arena
  alias Gyro.Spinner
  alias Gyro.Squad

  defstruct legendary_spinners: [], legendary_squads: [],
    heroic_spinners: [], heroic_squads: [],
    loudest_squads: []

  @name :arena
  @timer 1000

  @doc """
  Shortcut method for starting
  """
  def start do
    case start_link(%Arena{}) do
      {:ok, pid} ->
        # :timer.send_interval(@timer, pid, :spin)
        {:ok, pid}
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Start a GenServer. A permutation without param input is needed for the
  Application Supervisor children.
  """
  def start_link, do: start_link(%Arena{})
  def start_link(state) do
    GenServer.start_link(__MODULE__, state, name: {:global, @name})
  end

end
