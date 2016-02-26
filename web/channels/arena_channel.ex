defmodule Gyro.ArenaChannel do
  use Gyro.Web, :channel
  alias Gyro.Spinner

  @timer 5000

  @doc """
  The main method for socket to join the arena. We currentl only have just
  the lobby as the only room in the channel.
  """
  def join("arenas:lobby", payload, socket) do
    if authorized?(payload) do
      :timer.send_interval(@timer, :spin)
      Spinner.start(socket)
    else
      {:error, %{reason: "unauthorized"}}
    end
  end

  @doc """
  Event handler for the infinite spinning loop. Currently it calls Spinner
  GenServer to get the state of the spinner to report back to user
  """
  def handle_info(:spin, socket) do
    payload = Spinner.introspect(socket)
    socket = assign(socket, :spinner, payload)
    push socket, "introspect", payload
    {:noreply, socket}
  end

  # Channels can be used in a request/response fashion
  # by sending replies to requests from the client
  def handle_in("ping", payload, socket) do
    {:reply, {:ok, payload}, socket}
  end

  @doc """
  Event handler for spinners to send public message to every one in the room.
  """
  def handle_in("shout", payload, socket) do
    broadcast socket, "shout", payload
    {:noreply, socket}
  end

  @doc """
  Event handler for spinners to change their name. Currently we're just
  responding with the name that the spinner gave as confirmation but we
  should broadcast the message to the chatroom that a spinner has changed
  their name.
  """
  def handle_in("intro", %{ "name" => name } = payload, socket) do
    Spinner.update(socket, :name, name)
    {:reply, {:ok, payload}, assign(socket, :spinner, name)}
  end

  @doc """
  Event handler for spinner to private message each other, mainly for
  trash-talking. The room should then broadcase a notification message
  to let everyone know which spinner is trash-talking which spinner.
  """
  def handle_in("taunt", payload, socket) do
    broadcast socket, "taunt", %{"message" => "Someone's been taunted."}
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
