defmodule Gyro.ArenaTest do
  use Gyro.ChannelCase

  alias Gyro.UserSocket
  alias Gyro.Arena

  setup do
    socket = socket("user_id", %{})
    {:ok, socket} = UserSocket.connect(nil, socket)
    {:ok, socket: socket, spinner_pid: socket.assigns[:spinner_pid]}
  end

  describe "GenServer callback implementations" do
    test "handle enlist", %{spinner_pid: spinner_pid} do
      {:noreply, state} = Arena.handle_cast({:enlist, spinner_pid}, %Arena{})
      assert state.size == 1
    end

    test "handle delist", %{spinner_pid: spinner_pid} do
      {:noreply, enlisted_state} = Arena.handle_cast({:enlist, spinner_pid}, %Arena{})
      {:noreply, delisted_state} = Arena.handle_cast({:delist, spinner_pid}, enlisted_state)
      assert delisted_state.size == 0
    end

    test "handle info" do
      {:reply, state, _} = Arena.handle_call(:introspect, nil, %Arena{})
      assert state == %Arena{}
    end

    test "handle process down", %{spinner_pid: spinner_pid} do
      {:noreply, enlisted_state} = Arena.handle_cast({:enlist, spinner_pid}, %Arena{})
      {:noreply, delisted_state} = Arena.handle_info({:DOWN, nil, :process, spinner_pid, nil}, enlisted_state)
      assert delisted_state.size == 0
    end
  end

  describe "public API" do
    test "adding a new spinner", %{spinner_pid: spinner_pid} do
      Arena.enlist(:spinners, spinner_pid)
      %{members: members} = Arena.introspect(:spinners)
      listed_pid = Map.get(members, spinner_pid)

      assert spinner_pid == listed_pid
    end

    test "removing a spinner", %{spinner_pid: spinner_pid} do
      Arena.delist(:spinners, spinner_pid)
      %{members: members} = Arena.introspect(:spinners)
      listed_pid = Map.get(members, spinner_pid)

      assert listed_pid == nil
    end

    test "inspecting the arena" do
      state = Arena.introspect(:spinners)
      assert Map.has_key?(state, :members)
    end
  end

end
