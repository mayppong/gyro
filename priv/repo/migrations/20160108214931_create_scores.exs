defmodule Gyro.Repo.Migrations.CreateScores do
  use Ecto.Migration

  def change do
    create table(:scores) do
      add :pid, :string
      add :name, :string
      add :team, :string
      add :score, :float
      add :disconnected_at, :datetime

      timestamps
    end

  end
end
