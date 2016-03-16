defmodule Gyro.Spinner do
  use GenServer

  alias Gyro.Spinner
  alias Phoenix.Socket

  defstruct name: nil, connected_at: :calendar.universal_time(), score: 0
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
    Socket.assign(socket, :spinner, Map.delete(state, :connected_at))
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
    response = Map.delete(state, :connected_at)
    {:reply, response, state}
  end

  def handle_call({:update, key, value}, _from, state) do
    state = Map.put(state, key, value)
    {:reply, state, state}
  end

  def handle_info(:spin, state = %{score: score}) do
    state = Map.put(state, :score, score + @timer)
    {:noreply, state}
  end
end
