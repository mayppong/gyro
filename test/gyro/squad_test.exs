defmodule Gyro.SquadTest do
  use ExUnit.Case, async: true

  alias Gyro.Spinner
  alias Gyro.Squad

  @pid {:global, "TIM"}
  @squad %Squad{id: @pid, name: "TIM"}

  setup do
    {:ok, spinner_pid} = Spinner.start_link()
    {:ok, squad_pid} = Squad.start_link(@pid, @squad)

    {:ok, spinner_pid: spinner_pid, squad_pid: squad_pid}
  end

  test "introspect a squad", %{squad_pid: squad_pid} do
    state = GenServer.call(squad_pid, :introspect)

    assert @squad == state
  end

  test "update state of a squad", %{squad_pid: squad_pid} do
    GenServer.cast(squad_pid, {:update, :score, 100})
    %{score: score} = GenServer.call(squad_pid, :introspect)

    assert 100 == score
  end

  test "enlist a spinner to a squad", %{squad_pid: squad_pid, spinner_pid: spinner_pid} do
    GenServer.cast(squad_pid, {:enlist, spinner_pid})
    %{members: members} = GenServer.call(squad_pid, :introspect)

    assert Map.has_key?(members, spinner_pid)
    assert is_member?(spinner_pid, squad_pid)
  end

  test "delist a spinner from a squad", %{squad_pid: squad_pid, spinner_pid: spinner_pid} do
    GenServer.cast(squad_pid, {:enlist, spinner_pid})
    GenServer.cast(squad_pid, {:delist, spinner_pid})

    %{members: members} = GenServer.call(squad_pid, :introspect)
    assert %{} == members
    refute is_member?(spinner_pid, squad_pid)
  end

  test "form a squad spawn process links to application supervisor" do
    {status, _} = Squad.form("TIM")

    assert :ok == status

    #squad_pid = GenServer.whereis(squad_pid)
    #has_squad = Supervisor.which_children(Gyro.Supervisor)
    #  |> Enum.any?(fn({_, child_pid, _, _}) ->
    #    child_pid == squad_pid
    #  end)
    #assert has_squad
  end

  test "enlist a member", %{squad_pid: squad_pid, spinner_pid: spinner_pid} do
    Squad.enlist(@squad.name, spinner_pid)
    assert is_member?(spinner_pid, squad_pid)

    %{squad_pid: result} = Spinner.introspect(spinner_pid)
    assert @pid == result
  end

  test "delist a spinner from squad stored in its state", %{squad_pid: squad_pid, spinner_pid: spinner_pid} do
    Squad.enlist(squad_pid, spinner_pid)
    Squad.delist(spinner_pid)

    refute is_member?(spinner_pid, squad_pid)
  end

  test "delist a member", %{squad_pid: squad_pid, spinner_pid: spinner_pid} do
    Squad.enlist(@squad.name, spinner_pid)
    Squad.delist(squad_pid, spinner_pid)

    refute is_member?(spinner_pid, squad_pid)

    %{squad_pid: result} = Spinner.introspect(spinner_pid)
    assert nil == result
  end

  @tag :skip
  test "enlist a member who's already in another squad", %{squad_pid: squad_pid, spinner_pid: spinner_pid} do
    Squad.enlist(@squad.name, spinner_pid)
    Squad.enlist({:global, "MAY"}, spinner_pid)

    assert is_member?(spinner_pid, {:global, "MAY"})
    refute is_member?(spinner_pid, squad_pid)
  end

  test "checking if squad still exists", %{squad_pid: squad_pid} do
    assert Squad.exists?(squad_pid)
    assert Squad.exists?(@squad.name)
  end


  defp is_member?(spinner_pid, squad_id) when is_pid(spinner_pid) do
    %{members: members} = GenServer.call(squad_id, :introspect)

    Map.has_key?(members, spinner_pid)
  end
end
