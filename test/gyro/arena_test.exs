defmodule Gyro.ArenaTest do
  use ExUnit.Case, async: true
  use Gyro.ChannelCase

  alias Gyro.UserSocket
  alias Gyro.Arena
  alias Gyro.Spinner

  setup do
    socket = socket("user_id", %{})
    {:ok, socket} = UserSocket.connect(nil, socket)

    {:ok, socket: socket, spinner_pid: socket.assigns[:spinner_pid]}
  end

  test "adding a new spinner" do
    {:ok, spinner_pid} = Spinner.start_link()

    Arena.enlist(spinner_pid)
    %{members: members} = Arena.introspect()
    listed_pid = Map.get(members, spinner_pid)

    assert spinner_pid == listed_pid
  end

  test "removing a spinner", %{spinner_pid: spinner_pid} do
    Arena.delist(spinner_pid)
    %{members: members} = Arena.introspect()
    listed_pid = Map.get(members, spinner_pid)

    assert listed_pid == nil
  end

  test "inspecting the arena" do
    state = Arena.introspect()

    assert Map.has_key?(state, :members)
  end

end
