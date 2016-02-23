defmodule Gyro.Score do
  use Gyro.Web, :model

  schema "scores" do
    field :pid, :string
    field :name, :string
    field :team, :string
    field :score, :float
    field :disconnected_at, Ecto.DateTime

    timestamps
  end

  @required_fields ~w(pid name)
  @optional_fields ~w(team score disconnected_at)

  @doc """
  Creates a changeset based on the `model` and `params`.

  If no params are provided, an invalid changeset is returned
  with no validation performed.
  """
  def changeset(model, params \\ :empty) do
    model
    |> cast(params, @required_fields, @optional_fields)
  end
end
