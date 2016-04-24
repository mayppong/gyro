defmodule Gyro.SquadSocketTest do
  use Gyro.ChannelCase

  alias Gyro.Squad
  alias Gyro.ArenaChannel
  alias Gyro.UserSocket

  setup do
    socket = socket("user_id", %{})
    {:ok, socket} = UserSocket.connect(nil, socket)
    {:ok, _, socket} = socket
      |> subscribe_and_join(ArenaChannel, "arenas:lobby")

    {:ok, socket: socket}
  end

  test "start a squad" do
    {status, _} = Squad.start("TIM")
    assert :ok == status
  end

  test "enlist a member", %{socket: socket} do
    {:ok, socket} = Squad.enlist(socket, "TIM")
    socket = Squad.introspect(socket)
    [{member_pid, _}] = socket.assigns.squad.members

    assert member_pid == socket.assigns[:spinner_pid]
  end

  test "delist a member", %{socket: socket} do
    {:ok, socket} = Squad.enlist(socket, "TIM")
    %{ assigns: %{squad_pid: squad_pid, squad: squad} } = Squad.delist(socket)

    assert nil == squad_pid
    assert nil == squad
  end

  end
end
