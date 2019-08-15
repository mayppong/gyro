defmodule GyroWeb.SquadChannelTest do
  use GyroWeb.ChannelCase

  alias GyroWeb.SquadChannel
  alias GyroWeb.UserSocket

  setup do
    socket = socket(UserSocket, "user_id", %{some: :assign})
    {:ok, socket} = UserSocket.connect(nil, socket)
    {:ok, _, socket} =
      socket
      |> subscribe_and_join(SquadChannel, "arenas:squads:lobby")

    {:ok, socket: socket}
  end

  test "ping replies with status ok", %{socket: socket} do
    ref = push socket, "ping", %{"hello" => "there"}
    assert_reply ref, :ok, %{"hello" => "there"}
  end

  test "shout broadcasts to squads:lobby", %{socket: socket} do
    push socket, "shout", %{"message" => "hello"}
    assert_broadcast "shout", %{"message" => "hello", "from" => nil}
  end

  test "broadcasts are pushed to the client", %{socket: socket} do
    broadcast_from! socket, "broadcast", %{"some" => "data"}
    assert_push "broadcast", %{"some" => "data"}
  end
end
