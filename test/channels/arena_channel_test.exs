defmodule Gyro.ArenaChannelTest do
  use Gyro.ChannelCase

  alias Gyro.ArenaChannel
  alias Gyro.UserSocket

  setup do
    socket = socket("user_id", %{some: :assign})
    {:ok, socket} = UserSocket.connect(nil, socket)
    {:ok, _, socket} = socket
      |> subscribe_and_join(ArenaChannel, "arenas:lobby")

    {:ok, socket: socket}
  end

  test "ping replies with status ok", %{socket: socket} do
    ref = push socket, "ping", %{"hello" => "there"}
    assert_reply ref, :ok, %{"hello" => "there"}
  end

  test "shout broadcasts to arenas:lobby", %{socket: socket} do
    push socket, "shout", %{"message" => "hello"}
    assert_broadcast "shout", %{"message" => "hello", "from" => nil}
  end

  test "broadcasts are pushed to the client", %{socket: socket} do
    broadcast_from! socket, "broadcast", %{"some" => "data"}
    assert_push "broadcast", %{"some" => "data"}
  end

  test "changing name through intro event", %{socket: socket} do
    ref = push socket, "intro", %{"name" => "MAY"}
    assert_reply ref, :ok, %{"name" => "MAY"}
  end

  test "taunting other spinners broadcast to non-target censored message", %{socket: socket} do
    push socket, "taunt", %{"message" => "rude words"}
    assert_broadcast "taunt", %{"message" => "Someone's been taunted."}
  end
end
