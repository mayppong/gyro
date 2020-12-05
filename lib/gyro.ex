defmodule Gyro do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

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
    children = [
      # Start the PubSub system
      {Phoenix.PubSub, [name: Gyro.PubSub]},
      # Start the endpoint (http/https) when the application starts
      GyroWeb.Endpoint,
      # Here you could define other workers and supervisors as children
      %{start: {Gyro.Arena, :start_link, [:spinners]}, id: :spinners},
      %{start: {Gyro.Arena, :start_link, [:squads]}, id: :squads},
      Gyro.Squad.DynamicSupervisor
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Gyro.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    GyroWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
