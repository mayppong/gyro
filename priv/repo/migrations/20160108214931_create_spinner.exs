defmodule Gyro.Repo.Migrations.CreateSpinner do
  use Ecto.Migration

  def change do
    create table(:spinners) do
      add :pid, :string
      add :name, :string
      add :team, :string
      add :score, :float
      add :disconnected_at, :datetime

      timestamps
    end

  end
end
