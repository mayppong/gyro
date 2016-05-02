defmodule Gyro.ArenaTest do
  use ExUnit.Case, async: true
  use Gyro.ChannelCase

  alias Gyro.UserSocket
  alias Gyro.Arena

  setup do
    socket = socket("user_id", %{})
    {:ok, socket} = UserSocket.connect(nil, socket)

    {:ok, socket: socket}
  end

  test "adding a new spinner", %{socket: %{assigns: %{spinner_pid: spinner_pid}}} do
    %{spinner_roster: spinner_roster} = Arena.enlist(spinner_pid)
    listed_pid = Agent.get(spinner_roster, fn(state) ->
      state
      |> Map.get(:erlang.pid_to_list(spinner_pid))
    end)

    assert spinner_pid == listed_pid
  end

  test "removing a spinner", %{socket: %{assigns: %{spinner_pid: spinner_pid}}} do
    Arena.enlist(spinner_pid)
    %{spinner_roster: spinner_roster} = Arena.delist(spinner_pid)
    listed_pid = Agent.get(spinner_roster, fn(state) ->
      state
      |> Map.get(:erlang.pid_to_list(spinner_pid))
    end)

    assert listed_pid == nil
  end

end
