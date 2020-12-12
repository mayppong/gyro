defmodule Gyro.Mixfile do
  use Mix.Project

  def project do
    [app: :gyro,
     version: "0.1.0",
     elixir: "~> 1.9",
     elixirc_paths: elixirc_paths(Mix.env),
     compilers: [:phoenix, :gettext] ++ Mix.compilers,
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     aliases: aliases(),
     deps: deps()]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {Gyro, []},
      extra_applications: [:logger, :runtime_tools]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_),     do: ["lib"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [{:phoenix, "~> 1.5"},
     {:phoenix_pubsub, "~> 2.0"},
     {:phoenix_html, "~> 2.14"},
     {:phoenix_live_reload, "~> 1.3", only: :dev},
     {:gettext, "~> 0.16"},
     {:jason, "~> 1.0"},
     {:plug_cowboy, "~> 2.0"},
     {:libcluster, "~> 3.2"},
     {:distillery, "~> 2.1"}]
  end

  # Aliases are shortcut or tasks specific to the current project.
  # For example, to create, migrate and run the seeds file at once:
  #
  #     $ mix setup
  #
  # See the documentation for `Mix` for more info on aliases.
  defp aliases do
    [
      setup: ["deps.get", "cmd npm install --prefix assets"],
      test: "test"
    ]
  end
end
