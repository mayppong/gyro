ExUnit.start
ExUnit.configure exclude: :skip

Ecto.Adapters.SQL.Sandbox.mode(Gyro.Repo, :manual)
