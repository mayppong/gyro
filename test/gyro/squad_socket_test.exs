defmodule Gyro.SquadSocketTest do
  use Gyro.ChannelCase

  alias Gyro.Squad
  alias Gyro.ArenaChannel
  alias Gyro.UserSocket
  alias Phoenix.Socket

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
    assert is_member(socket, "TIM")
  end

  test "delist a member", %{socket: socket} do
    {:ok, socket} = Squad.enlist(socket, "TIM")
    %{ assigns: %{squad_pid: squad_pid, squad: squad} } = Squad.delist(socket)

    assert nil == squad_pid
    assert nil == squad
  end

  defp is_member(socket = %Socket{assigns: %{spinner_pid: spinner_pid}}, name) do
    %{ members: members } = GenServer.call({:global, name}, :introspect)
    nil != members
      |> Enum.find(fn({member_pid, _}) ->
        member_pid == spinner_pid
      end)
  end
end
