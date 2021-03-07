defmodule GyroWeb.SquadChannel do
  @moduledoc """
  A web socket channel for handling the team game event which runs under
  the Squad context.
  """
  use GyroWeb, :channel
  alias Phoenix.Socket
  alias Gyro.Arena
  alias Gyro.Squad
  alias Gyro.Spinner

  @timer 5000

  @doc """
  The main method for socket to join a squad. The namespace shows dependence
  on client being part of the arena channel already.
  The name of the squad is defined by the user which is then by Squad GenServer
  to look up with.
  """
  def join("arenas:squads:", _, _), do: {:error, %{reason: "invalid name"}}

  def join(
        "arenas:squads:" <> name,
        payload,
        socket = %Socket{assigns: %{spinner_pid: spinner_pid}}
      ) do
    if authorized?(payload) do
      {:ok, squad_pid} =
        name
        |> String.slice(0, 3)
        |> Squad.enlist(spinner_pid)

      send(self(), :init)
      {:ok, assign(socket, :squad_pid, squad_pid)}
    else
      {:error, %{reason: "unauthorized"}}
    end
  end

  @doc """
  Terminate method is called when a user leaves the channel. In this case,
  we would want remove the user from the squad when they leave the channel.
  """
  def terminate(_, %Socket{assigns: %{spinner_pid: spinner_pid, squad_pid: squad_pid}}) do
    Squad.delist(squad_pid, spinner_pid)
  end

  def handle_info(:init, socket) do
    send(self(), :spin)
    {:noreply, socket}
  end

  @doc """
  Event handler for the infinite spinning loop. Currently it calls Squad
  GenServer to get the state of the squad to report back to client
  """
  def handle_info(:spin, socket = %Socket{assigns: %{squad_pid: squad_pid}}) do
    squad = Squad.introspect(squad_pid)
    arena = Arena.introspect(:squads)

    socket = assign(socket, :squad, squad)

    push(socket, "introspect", %{"arena" => arena, "squad" => squad})
    Process.send_after(self(), :spin, @timer)
    {:noreply, socket}
  end

  # Channels can be used in a request/response fashion
  # by sending replies to requests from the client
  def handle_in("ping", payload, socket) do
    {:reply, {:ok, payload}, socket}
  end

  # It is also common to receive messages from the client and
  # broadcast to everyone in the current topic (squads:lobby).
  def handle_in(
        "shout",
        %{"message" => message},
        socket = %Socket{assigns: %{spinner_pid: spinner_pid}}
      ) do
    spinner = Spinner.introspect(spinner_pid)

    payload = %{
      "message" => message,
      "from" => spinner.name,
      "squad" => socket.assigns.squad.name
    }

    broadcast(socket, "shout", payload)
    {:noreply, socket}
  end

  # This is invoked every time a notification is being broadcast
  # to the client. The default implementation is just to push it
  # downstream but one could filter or change the event.
  def handle_out(event, payload, socket) do
    push(socket, event, payload)
    {:noreply, socket}
  end

  # Add authorization logic here as required.
  defp authorized?(_payload) do
    true
  end
end
