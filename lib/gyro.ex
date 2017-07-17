defmodule Gyro do
  use Application

  # See http://elixir-lang.org/docs/stable/elixir/Application.html
  # for more information on OTP Applications
  @doc """
  Start the arena GenServer by first starts 2 Agents: one for tracking active
  spinners, and another for tracking active squads in the system. One both
  Agents are started successfully, we then start the Arena GenServer.
  If either of the Agents fails to start, it returns the error from that
  Agent and not starts the arena GenServer.
  """
  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    children = [
      # Start the endpoint when the application starts
      supervisor(Gyro.Endpoint, []),
      # Start the Ecto repository
      supervisor(Gyro.Repo, []),
      # Here you could define other workers and supervisors as children
      # worker(Gyro.Worker, [arg1, arg2, arg3]),
      worker(Gyro.Arena, [:spinners], [id: :spinners]),
      worker(Gyro.Arena, [:squads], [id: :squads]),
      supervisor(Gyro.Squad.Supervisor, []),
    ]

    # See http://elixir-lang.org/docs/stable/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Gyro.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    Gyro.Endpoint.config_change(changed, removed)
    :ok
  end
end
