import Config

# Configure your database
#
# The MIX_TEST_PARTITION environment variable can be used
# to provide built-in test partitioning in CI environment.
# Run `mix help test` for more information.
config :liveview_upload, LU.Repo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  database: "liveview_upload_test#{System.get_env("MIX_TEST_PARTITION")}",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: 10

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :liveview_upload, LUWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "vkj770jYzuA6oJDdvEkFsa194i4eIw4E6DSz1WAxIa6rJq2TISyMTrVl0oHzKaB7",
  server: false

# In test we don't send emails.
config :liveview_upload, LU.Mailer, adapter: Swoosh.Adapters.Test

# Disable swoosh api client as it is only required for production adapters.
config :swoosh, :api_client, false

# Print only warnings and errors during test
config :logger, level: :warning

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime
