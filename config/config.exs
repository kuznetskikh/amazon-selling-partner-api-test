# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

config :amazon_selling_partner_api,
  api_site: "https://sellingpartnerapi-na.amazon.com",
  access_token_site: "https://api.amazon.com",
  client_id: System.get_env("APP_CLIENT_ID"),
  client_secret: System.get_env("APP_CLIENT_SECRET"),
  access_key_id: System.get_env("IAM_ACCESS_KEY_ID"),
  secret_access_key: System.get_env("IAM_SECRET_ACCESS_KEY"),
  refresh_token: System.get_env("APP_LONG_LIVED_REFRESH_TOKEN")

config :ex_aws,
  region: "us-east-1"

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
