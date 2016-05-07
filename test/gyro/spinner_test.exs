defmodule Gyro.SpinnerTest do
  use ExUnit.Case, async: true

  alias Gyro.Arena
  alias Gyro.Spinner

  setup do
    {:ok, spinner_pid} = Spinner.start_link()

    {:ok, spinner_pid: spinner_pid}
  end

  test "handle `:introspect` message call" do
  end

  test "enlist a new spinner" do
    {:ok, pid} = Spinner.enlist()
    assert is_pid(pid)
  end

  test "enlist a spinner add them to arena" do
    {:ok, spinner_pid} = Spinner.enlist()
    %{spinner_roster: spinner_roster} = Arena.introspect()
    found_pid = Agent.get(spinner_roster, fn(state) ->
      Map.get(state, :erlang.pid_to_list(spinner_pid))
    end)

    assert spinner_pid == found_pid
  end

  test "checking if spinner exists", %{spinner_pid: spinner_pid} do
    assert Spinner.exists?(spinner_pid)
  end

  @tag :skip
  test "delist a spinner", %{spinner_pid: spinner_pid} do
    Spinner.delist(spinner_pid)
    refute Spinner.exists?(spinner_pid)
  end

  test "introspecting a spinner", %{spinner_pid: spinner_pid} do
    state = Spinner.introspect(spinner_pid)

    refute is_nil(state.score)
    assert state.spm == 1
  end

  test "introspecting a dead spinner", %{spinner_pid: spinner_pid} do
    Spinner.delist(spinner_pid)
    state = Spinner.introspect(spinner_pid)

    assert nil == state
  end

  test "update spinner state", %{spinner_pid: spinner_pid} do
    Spinner.update(spinner_pid, :name, "MAY")
    %{name: name} = Spinner.introspect(spinner_pid)

    assert name == "MAY"
  end

  @tag :skip
  test "delist a spinner", %{spinner_pid: spinner_pid} do
    :ok = Spinner.delist(spinner_pid)

    assert GenServer.whereis(spinner_pid) == nil
  end

end
