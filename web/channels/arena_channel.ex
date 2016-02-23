defmodule Gyro.ArenaChannel do
  use Gyro.Web, :channel

  alias Gyro.Spinner

  def join("arenas:lobby", payload, socket) do
    if authorized?(payload) do
      :timer.send_interval(5000, :spin)
      Spinner.start(socket)
    else
      {:error, %{reason: "unauthorized"}}
    end
  end

  def handle_info(:spin, socket) do
    payload = Spinner.introspect(socket)
    push socket, "introspect", payload
    {:noreply, socket}
  end

  # Channels can be used in a request/response fashion
  # by sending replies to requests from the client
  def handle_in("ping", payload, socket) do
    {:reply, {:ok, payload}, socket}
  end

  # It is also common to receive messages from the client and
  # broadcast to everyone in the current topic (arenas:lobby).
  def handle_in("shout", payload, socket) do
    broadcast socket, "shout", payload
    {:noreply, socket}
  end

  def handle_in("intro", %{ "name" => name } = payload, socket) do
    Spinner.update(socket, :name, name)
    {:reply, {:ok, payload}, assign(socket, :spinner, name)}
  end

  def handle_in("taunt", payload, socket) do
    broadcast socket, "taunt", %{message: "Someone's been taunted."}
    {:noreply, socket}
  end

  # This is invoked every time a notification is being broadcast
  # to the client. The default implementation is just to push it
  # downstream but one could filter or change the event.
  def handle_out(event, payload, socket) do
    push socket, event, payload
    {:noreply, socket}
  end

  # Add authorization logic here as required.
  defp authorized?(_payload) do
    true
  end
end
