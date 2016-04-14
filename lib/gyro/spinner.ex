defmodule Gyro.Spinner do
  use GenServer

  alias Gyro.Spinner
  alias Phoenix.Socket

  defstruct name: nil, spm: 1, score: 0,
    connected_at: :calendar.universal_time()

  @timer 1000

  @doc """
  The main method for starting a new spinner GenServer for a given socket.
  """
  def start(socket = %Socket{}) do
    case start_link(%Spinner{}) do
      {:ok, spinner_pid} ->
        socket = Socket.assign(socket, :spinner_pid, spinner_pid)
        :timer.send_interval(@timer, spinner_pid, :spin)
        {:ok, socket}
      {:error, _} ->
        {:error, %{reason: "Unable to start spinner process"}}
    end
  end

  @doc """
  Inspect the current state of the spinner assigned to the given socket
  """
  def introspect(socket) do
    state = socket.assigns[:spinner_pid]
    |> GenServer.call(:introspect)
    Socket.assign(socket, :spinner, state)
  end

  @doc """
  Update spinner data for the spinner stored in the socket.
  """
  def update(socket, key, value) do
    state = socket.assigns[:spinner_pid]
    |> GenServer.call({:update, key, value})
    Socket.assign(socket, :spinner, state)
  end

  @doc """
  Stop the squad GenServer assigned to the given socket with a given reason
  """
  def stop(socket, reason \\ :normal) do
    socket.assigns[:spinner_pid]
    |> GenServer.stop(reason)

    socket
    |> Socket.assign(:spinner, nil)
    |> Socket.assign(:spinner_pid, nil)
  end

  @doc """
  Start a new GenServer for the current spinner. The server is registered
  as an unnamed since we don't worry about duplicating name in this case,
  unlike with squads where we want to allow only a team of the same name.
  """
  def start_link(state) do
    GenServer.start_link(__MODULE__, state)
  end

  @doc """
  Handle a call to get the current state stored in the process.
  """
  def handle_call(:introspect, _from, state) do
    {:reply, state, state}
  end

  @doc """
  Handle updating a key in the current state.
  """
  def handle_call({:update, key, value}, _from, state) do
    state = Map.put(state, key, value)
    {:reply, state, state}
  end

  @doc """
  Handle `spinning` which is where we update the current state of a spinner
  at a set interval.
  """
  def handle_info(:spin, state) do
    state = state
    |> update_score
    {:noreply, state}
  end

  # Calculate score by converting spin per minute to seconds and convert spin
  # interval from miliseconds to seconds, then combine them together.
  defp update_score(state = %{score: score, spm: spm}) do
    score = score + (spm * (@timer / 1000) / 60)
    Map.put(state, :score, score)
  end

end
