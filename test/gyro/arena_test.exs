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
    [listed_pid] = Agent.get(spinner_roster, fn(state) -> state end)

    assert spinner_pid == listed_pid
  end

end
