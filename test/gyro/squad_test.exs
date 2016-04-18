defmodule Gyro.SquadTest do
  use ExUnit.Case, async: true

  alias Gyro.Spinner
  alias Gyro.Squad

  @squad %Squad{name: "TIM"}

  setup do
    {:ok, squad_pid} = Squad.start_link(@squad, @squad.name)

    {:ok, squad_pid: squad_pid}
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

    state = GenServer.call(squad_pid, {:enlist, spinner_pid})
    [{member_pid, _}] = state.members

    assert spinner_pid == member_pid
  end

  test "delist a spinner from a squad", %{squad_pid: squad_pid} do
    {:ok, spinner_pid} = Spinner.start_link(%Spinner{})
    GenServer.call(squad_pid, {:enlist, spinner_pid})

    state = GenServer.call(squad_pid, {:delist, spinner_pid})

    assert [] == state.members
  end
end
