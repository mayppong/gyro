defmodule Gyro.Spinner do
  use GenServer

  alias Gyro.Spinner
  alias Phoenix.Socket

  defstruct connected_at: :calendar.universal_time(), score: 0

  def start(socket = %Socket{}) do
    case start_link(%Spinner{}) do
      {:ok, spinner_pid} ->
        socket = Socket.assign(socket, :spinner_pid, spinner_pid)
        Process.send_after(spinner_pid, :spin, 1000)
        {:ok, socket}
      {:error, _} ->
        {:error, %{reason: "Unable to start spinner process"}}
    end
  end

  def introspect(socket) do
    socket.assigns[:spinner_pid]
    |> GenServer.call(:introspect)
  end

  def update(socket, key, value) do
    socket.assigns[:spinner_pid]
    |> GenServer.call({:update, key, value})
  end

  def stop(socket, reason) do
    socket.assigns[:spinner_pid]
    |> GenServer.stop(reason)
  end

  def start_link(state) do
    GenServer.start_link(__MODULE__, state)
  end

  def handle_call(:introspect, _from, state) do
    response = Map.delete(state, :connected_at)
    {:reply, response, state}
  end

  def handle_call({:update, key, value}, _from, state) do
    {:reply, _from, Map.put(state, key, value)}
  end

  def handle_info(:spin, state = %{score: score}) do
    state = Map.put(state, :score, score + 1000)
    Process.send_after(self, :spin, 1000)
    {:noreply, state}
  end
end
