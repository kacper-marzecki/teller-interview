import Config

config :teller, TellerWeb.Endpoint,
  url: [scheme: "https", host: "teller-interview.herokuapp.com", port: 443],
  force_ssl: [rewrite_on: [:x_forwarded_proto]],
  cache_static_manifest: "priv/static/cache_manifest.json"

config :logger, level: :info

config :teller, :app_url, "https://teller-interview.herokuapp.com"
