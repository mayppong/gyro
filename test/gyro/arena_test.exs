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
    %{spinner_roster: spinner_roster} = Arena.enlist(spinner_pid)
    listed_pid = Agent.get(spinner_roster, fn(state) ->
      state
      |> Map.get(spinner_pid)
    end)

    assert spinner_pid == listed_pid
  end

  test "removing a spinner", %{spinner_pid: spinner_pid} do
    %{spinner_roster: spinner_roster} = Arena.delist(spinner_pid)
    listed_pid = Agent.get(spinner_roster, fn(state) ->
      state
      |> Map.get(spinner_pid)
    end)

    assert listed_pid == nil
  end

  test "inspecting the arena" do
    state = Arena.introspect()

    assert is_pid(state.spinner_roster)
    assert is_pid(state.squad_roster)
  end

  @tag :skip
  test "arena update spinners" do
    {:ok, spinner_pid} = Spinner.start_link()
    Arena.enlist(spinner_pid)
    %{legendary_spinners: legends, heroic_spinners: heroes} = Arena.introspect()

    assert Enum.count(legends) == 2
    assert Enum.count(heroes) == 2
  end

end
