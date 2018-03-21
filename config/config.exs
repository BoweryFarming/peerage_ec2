# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
use Mix.Config

config :peerage, via: Peerage.Via.Ec2

config :peerage_ec2,
  aws_access_key_id: "example",
  aws_secret_access_key: "key",
  tags: [{:cluster, "cluster"}, {:service, "service"}],
  timeout: 1000
