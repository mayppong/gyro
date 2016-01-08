defmodule Gyro.SpinnerTest do
  use Gyro.ModelCase

  alias Gyro.Spinner

  @valid_attrs %{disconnected_at: "2010-04-17 14:00:00", name: "some content", pid: "some content", score: "120.5", team: "some content"}
  @invalid_attrs %{}

  test "changeset with valid attributes" do
    changeset = Spinner.changeset(%Spinner{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    changeset = Spinner.changeset(%Spinner{}, @invalid_attrs)
    refute changeset.valid?
  end
end
