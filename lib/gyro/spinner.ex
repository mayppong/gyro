defmodule Gyro.Spinner do
  use GenServer
  alias Phoenix.Socket
  alias Gyro.ArenaChannel

  def start_link(state) do
    GenServer.start_link(__MODULE__, state)
  end

  def handle_cast({:update, key, value} , state) do
    {:noreply, Map.put(state, key, value)}
  end

  def handle_call(:introspect, _from, state = %{socket: socket}) do
    {:reply, Map.delete(state, :socket), state}
  end

  def start(socket = %Socket{}) do
    state = %{
      spinner_pid: self,
      connected_at: :calendar.universal_time(),
      socket: socket
    }
    start_link(state)
  end

  def update(pid, key, value) do
    GenServer.cast(pid, {:update, key, value})
  end

  defp broadcast(event, payload, socket) do
    ArenaChannel.handle_out(event, payload, socket)
  end
end
