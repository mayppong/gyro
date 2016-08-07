defmodule Gyro.ScoreboardTest do
  use ExUnit.Case, async: true

  alias Gyro.Spinner
  alias Gyro.Scoreboard

  setup do
    {:ok, spinner_pid} = Spinner.enlist()
    spinner = Spinner.introspect(spinner_pid)

    {:ok, pid} = Spinner.enlist()
    another = Spinner.introspect(pid)

    spinners = 1..5
    |> Enum.map(fn(_) -> Spinner.enlist() end)
    |> Enum.map(fn({:ok, pid}) ->
      Spinner.introspect(pid)
    end)

    {:ok, spinner: spinner, another: another, spinners: spinners}
  end

  test "calculate total", %{spinner: spinner, another: another} do
    {score, spm} = Scoreboard.total([spinner, another])

    assert spinner.score + another.score == score
    assert spinner.spm + another.spm == spm
  end

  test "building a list of latest", %{spinner: spinner, another: another} do
    latest = Scoreboard.latest([another, spinner])
    order = Enum.map(latest, &(&1.created_at))

    assert order == [spinner.created_at, another.created_at]
  end

  test "building a list of heroics", %{spinner: spinner, another: another} do
    heroics = Scoreboard.heroics([another, spinner])
    order = Enum.map(heroics, &(&1.score))

    assert order == [spinner.score, another.score]
  end

  test "building a list of legendaries", %{spinner: spinner, another: another} do
    legendaries = Scoreboard.legendaries([another, spinner], [])

    assert legendaries == [spinner, another]
  end

  test "building scoreboard", %{spinner: spinner, another: another} do
    scoreboard = Scoreboard.build([another, spinner])

    assert Map.has_key?(scoreboard, :score)
    assert Map.has_key?(scoreboard, :spm)
    assert Map.has_key?(scoreboard, :latest)
    assert Map.has_key?(scoreboard, :heroics)
    assert Map.has_key?(scoreboard, :legendaries)
  end
end
