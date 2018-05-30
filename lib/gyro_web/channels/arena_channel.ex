defmodule GyroWeb.ArenaChannel do
  use Gyro.Web, :channel

  alias Phoenix.Socket
  alias Gyro.Arena
  alias Gyro.Spinner

  @timer 5000

  @doc """
  The main method for socket to join the arena. We currently only have just
  the lobby as the only room in the channel.
  """
  def join("arenas:lobby", payload, socket) do
    if authorized?(payload) do
      send(self(), :init)
      {:ok, socket}
    else
      {:error, %{reason: "unauthorized"}}
    end
  end

  @doc """
  Terminate method is called when a user leaves the channel. In this case,
  we would want stop the GenServer when the user leave `arena` channel.
  """
  def terminate(_, %Socket{assigns: %{spinner_pid: spinner_pid}}) do
    Spinner.delist(spinner_pid)
  end

  @doc """
  Set spinner up with their initial data on their first join.
  """
  def handle_info(:init, socket) do
    send(self(), :spin)
    {:noreply, socket}
  end

  @doc """
  Event handler for the infinite spinning loop. Currently it calls Spinner
  GenServer to get the state of the spinner to report back to client
  """
  def handle_info(:spin, socket = %Socket{assigns: %{spinner_pid: spinner_pid}}) do
    spinner = Spinner.introspect(spinner_pid)
    socket = assign(socket, :spinner, spinner)

    arena = Arena.introspect(:spinners)

    push socket, "introspect", %{"arena" => arena, "spinner" => spinner}
    Process.send_after(self(), :spin, @timer)
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
  def handle_in("shout", %{"message" => message}, socket = %Socket{assigns: %{spinner: spinner}}) do
    payload = %{"message" => message, "from" => spinner.name}
    broadcast socket, "shout", payload
    {:noreply, socket}
  end

  @doc """
  Event handler for spinners to change their name. Currently we're just
  responding with the name that the spinner gave as confirmation.
  """
  def handle_in("intro", payload = %{"name" => name}, socket = %Socket{assigns: %{spinner_pid: spinner_pid, spinner: spinner}}) do
    name = name
    |> String.slice(0, 3)

    Spinner.update(spinner_pid, :name, name)
    socket = assign(socket, :spinner, %{spinner | name: name})

    broadcast socket, "shout", %{"message" => "Introducing #{name}", "from" => "ADMIN"}
    {:reply, {:ok, payload}, socket}
  end

  @doc """
  Event handler for spinner to private message each other, mainly for
  trash-talking. The room should then broadcase a notification message
  to let everyone know which spinner is trash-talking which spinner.
  """
  def handle_in("taunt", _, socket) do
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
