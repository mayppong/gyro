defmodule Gyro.ArenaTest do
  use ExUnit.Case, async: true
  use Gyro.ChannelCase

  alias Gyro.UserSocket
  alias Gyro.Arena

  setup do
    socket = socket("user_id", %{})
    {:ok, socket} = UserSocket.connect(nil, socket)

    {:ok, socket: socket, spinner_pid: socket.assigns[:spinner_pid]}
  end

  test "adding a new spinner", %{spinner_pid: spinner_pid} do
    %{spinner_roster: spinner_roster} = Arena.enlist(spinner_pid)
    listed_pid = Agent.get(spinner_roster, fn(state) ->
      state
      |> Map.get(:erlang.pid_to_list(spinner_pid))
    end)

    assert spinner_pid == listed_pid
  end

  test "removing a spinner", %{spinner_pid: spinner_pid} do
    Arena.enlist(spinner_pid)
    %{spinner_roster: spinner_roster} = Arena.delist(spinner_pid)
    listed_pid = Agent.get(spinner_roster, fn(state) ->
      state
      |> Map.get(:erlang.pid_to_list(spinner_pid))
    end)

    assert listed_pid == nil
  end

  test "inspecting the arena", %{spinner_pid: spinner_pid} do
    Arena.enlist(spinner_pid)
    state = Arena.introspect()

    assert is_pid(state.spinner_roster)
    assert is_pid(state.squad_roster)
  end

end
