# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
import Config

# Configures the endpoint
config :gyro, GyroWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "rds/k0cS4P9e20n5ovNm5zQMTmMo7sPJSFZYcTWA4JhFBxY8yYd/dAg1KF5J0CLd",
  render_errors: [
    accepts: ~w(html json),
    formats: [html: GyroWeb.ErrorHTML, json: GyroWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: Gyro.PubSub

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Configure phoenix generators
config :phoenix, :generators,
  migration: true,
  binary_id: false

config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
