defmodule Gyro.Spinner do
  use GenServer

  alias Gyro.Spinner
  alias Phoenix.Socket

  defstruct name: nil, spm: 1, score: 0,
    connected_at: :calendar.universal_time()

  @timer 1000

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

  def introspect(socket) do
    state = socket.assigns[:spinner_pid]
    |> GenServer.call(:introspect)
    Socket.assign(socket, :spinner, state)
  end

  def update(socket, key, value) do
    state = socket.assigns[:spinner_pid]
    |> GenServer.call({:update, key, value})
    Socket.assign(socket, :spinner, state)
  end

  def stop(socket, reason) do
    socket.assigns[:spinner_pid]
    |> GenServer.stop(reason)

    socket
    |> Socket.assign(:spinner, nil)
    |> Socket.assign(:spinner_pid, nil)
  end

  def start_link(state) do
    GenServer.start_link(__MODULE__, state)
  end

  def handle_call(:introspect, _from, state) do
    {:reply, state, state}
  end

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
