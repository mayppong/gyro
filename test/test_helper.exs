ExUnit.start

Mix.Task.run "ecto.create", ~w(-r Gyro.Repo --quiet)
Mix.Task.run "ecto.migrate", ~w(-r Gyro.Repo --quiet)
Ecto.Adapters.SQL.begin_test_transaction(Gyro.Repo)

