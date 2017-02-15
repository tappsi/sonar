use Mix.Config

config :sonar,
  pubsub: [name: Sonar.PubSub,
           adapter: Phoenix.PubSub.PG2,
           opts: [pool_size: 1]],
  echo: [log_level: :debug,
         broadcast_period: 25,
         max_silent_periods: 3]

config :gen_rpc,
  tcp_server_port: 9998,
  tcp_client_port: 9998,
  default_client_driver: :tcp
