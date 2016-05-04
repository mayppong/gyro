defmodule Gyro.SpinnerTest do
  use ExUnit.Case, async: true

  alias Gyro.Arena
  alias Gyro.Spinner

  setup do
    {:ok, spinner_pid} = Spinner.start_link()

    {:ok, spinner_pid: spinner_pid}
  end

  test "enlist a new spinner" do
    {:ok, pid} = Spinner.enlist()
    assert is_pid(pid)
  end

  test "enlist a spinner add them to arena" do
    {:ok, pid} = Spinner.enlist()
    %{spinner_roster: spinner_roster} = Arena.introspect()
    found_pid = Agent.get(spinner_roster, fn(state) ->
      Map.get(state, :erlang.pid_to_list(pid))
    end)

    assert pid == found_pid
  end

  @tag :skip
  test "delist a spinner" do
    {:ok, pid} = Spinner.enlist()
    :ok = Spinner.delist(pid)

    assert GenServer.whereis(pid) == nil
  end

end
