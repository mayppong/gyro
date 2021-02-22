defmodule Gyro.Spinner do
  use Gyro.Arena.Spinnable

  alias __MODULE__
  alias Gyro.Arena

  @derive {Jason.Encoder, except: [:id, :squad_pid]}
  defstruct id: nil, name: nil, spm: 1, score: 0, squad_pid: nil, created_at: DateTime.utc_now()

  @timer 1000

  @doc """
  The main method for starting a new spinner GenServer.
  """
  def enlist() do
    case start_link() do
      {:ok, spinner_pid} ->
        Arena.enlist(:spinners, spinner_pid)
        {:ok, spinner_pid}

      {:error, _} ->
        {:error, %{reason: "Unable to start spinner process"}}
    end
  end

  @doc """
  Stop the spinner GenServer with a given reason
  """
  def delist(spinner_pid, reason \\ :normal) do
    GenServer.stop(spinner_pid, reason)
  end

  @doc """
  Start a new GenServer for the current spinner. The server is registered
  as an unnamed since we don't worry about duplicating name in this case,
  unlike with squads where we want to allow only a team of the same name.
  """
  def start_link(state \\ %Spinner{}) do
    GenServer.start_link(__MODULE__, state)
  end

  @doc """
  Once the GenServer is started successfully, the init function is invoked.
  For now, we just need to tell it to start spinning.
  """
  def init(state) do
    state = Map.put(state, :id, self())
    :timer.send_interval(@timer, self(), :spin)
    {:ok, state}
  end

  @doc """
  Handle `spinning` which is where we update the current state of a spinner
  at a set interval.
  """
  def handle_info(:spin, state) do
    state =
      state
      |> update_score

    {:noreply, state}
  end

  # Calculate score by converting spin per minute to seconds and convert spin
  # interval from miliseconds to seconds, then combine them together.
  defp update_score(state = %{score: score, spm: spm}) do
    score = score + spm * (@timer / 1000) / 60
    Map.put(state, :score, score)
  end
end
