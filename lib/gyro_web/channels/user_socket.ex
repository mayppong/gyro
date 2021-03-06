defmodule GyroWeb.UserSocket do
  use Phoenix.Socket

  alias Gyro.Spinner

  ## Channels
  # channel "rooms:*", Gyro.RoomChannel
  channel("arenas:lobby", GyroWeb.ArenaChannel)
  channel("arenas:squads:*", GyroWeb.SquadChannel)

  # Socket params are passed from the client and can
  # be used to verify and authenticate a user. After
  # verification, you can put default assigns into
  # the socket that will be set for all channels, ie
  #
  #     {:ok, assign(socket, :user_id, verified_user_id)}
  #
  # To deny connection, return `:error`.
  #
  # See `Phoenix.Token` documentation for examples in
  # performing token verification on connect.
  def connect(_params, socket) do
    socket =
      socket
      |> assign(:connected, DateTime.utc_now())

    # For the SquadChannel to work, it needs to know the spinner pid. Since we
    # currently can't share socket data in assigns between channels, I had to
    # move the `Spinner.start/1` to the connection level. Data assigns to
    # socket at this level will be available to every channels.
    # {:ok, socket}
    {:ok, spinner_pid} = Spinner.enlist()
    {:ok, assign(socket, :spinner_pid, spinner_pid)}
  end

  # Socket id's are topics that allow you to identify all sockets for a given user:
  #
  #     def id(socket), do: "users_socket:#{socket.assigns.user_id}"
  #
  # Would allow you to broadcast a "disconnect" event and terminate
  # all active sockets and channels for a given user:
  #
  #     Gyro.Endpoint.broadcast("users_socket:#{user.id}", "disconnect", %{})
  #
  # Returning `nil` makes this socket anonymous.
  def id(_socket), do: nil
end
