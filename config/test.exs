import Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :blackjack, BlackjackWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "X9GYDEFOCU0IaG01CLzCKwh8M42b3bYOf1eqNgAGiu4zB5umpGzisAvXKBUI0Rqm",
  server: false

# In test we don't send emails.
config :blackjack, Blackjack.Mailer,
  adapter: Swoosh.Adapters.Test

# Print only warnings and errors during test
config :logger, level: :warn

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime
