defmodule Gyro.SquadTest do
  use ExUnit.Case, async: true
  use Gyro.ChannelCase

  alias Phoenix.Socket
  alias Gyro.ArenaChannel
  alias Gyro.UserSocket

  alias Gyro.Spinner
  alias Gyro.Squad

  @squad %Squad{name: "TIM"}

  setup do
    socket = socket("user_id", %{})
    {:ok, socket} = UserSocket.connect(nil, socket)
    {:ok, _, socket} = socket
      |> subscribe_and_join(ArenaChannel, "arenas:lobby")

    {:ok, squad_pid} = Squad.start_link(@squad, @squad.name)

    {:ok, socket: socket, squad_pid: squad_pid}
  end

  test "introspect a squad", %{squad_pid: squad_pid} do
    state = GenServer.call(squad_pid, :introspect)

    assert @squad == state
  end

  test "update state of a squad", %{squad_pid: squad_pid} do
    state = GenServer.call(squad_pid, {:update, :score, 100})

    assert %Squad{@squad | score: 100} == state
  end

  test "enlist a spinner to a squad", %{squad_pid: squad_pid} do
    {:ok, spinner_pid} = Spinner.start_link(%Spinner{})

    %{members: [{member_pid, _} | _]} = GenServer.call(squad_pid, {:enlist, spinner_pid})

    assert spinner_pid == member_pid
    assert is_member?(spinner_pid, squad_pid)
  end

  test "delist a spinner from a squad", %{squad_pid: squad_pid} do
    {:ok, spinner_pid} = Spinner.start_link(%Spinner{})
    GenServer.call(squad_pid, {:enlist, spinner_pid})

    %{members: members} = GenServer.call(squad_pid, {:delist, spinner_pid})
    assert [] == members
    refute is_member?(spinner_pid, squad_pid)
  end

  test "form a squad" do
    {status, _} = Squad.form("TIM")
    assert :ok == status
  end

  test "enlist a member", %{socket: socket} do
    {:ok, socket} = Squad.enlist(socket, "TIM")
    assert is_member?(socket, {:global, "TIM"})
  end

  test "delist a member", %{socket: socket} do
    {:ok, socket} = Squad.enlist(socket, "TIM")
    %{ assigns: %{squad_pid: squad_pid, squad: squad} } = Squad.delist(socket)

    assert nil == squad_pid
    assert nil == squad
  end

  test "enlist a member who's already in another squad", %{socket: socket} do
    {:ok, socket} = Squad.enlist(socket, "TIM")
    {:ok, socket} = Squad.enlist(socket, "MAY")

    assert is_member?(socket, {:global, "MAY"})
    refute is_member?(socket, {:global, "TIM"})
  end


  defp is_member?(%Socket{assigns: %{spinner_pid: spinner_pid}}, squad_id), do: is_member?(spinner_pid, squad_id)
  defp is_member?(spinner_pid, squad_id) when is_pid(spinner_pid) do
    %{members: members} = GenServer.call(squad_id, :introspect)
    nil != members
      |> Enum.find(fn({member_pid, _}) ->
        member_pid == spinner_pid
      end)
  end
end
