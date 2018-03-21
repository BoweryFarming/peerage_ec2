# Peerage EC2 Provider

![Peerage](https://github.com/mrluc/peerage) helps your nodes find each other.

It supports DNS-based discovery, which means you can use it out of the box with Kubernetes (and probably also Weave, discoverd, Swarm, or other anything else with dns-based service discovery).

It also supports UDP-based discovery, so that nodes on the same network (like docker containers on the same host) can find each other.

This library adds support for API-based discovery of nodes running in an AWS VPC on EC2 or Elastic Beanstalk.

[![CircleCI](https://circleci.com/gh/BoweryFarming/peerage_ec2.svg?style=svg)](https://circleci.com/gh/BoweryFarming/peerage_ec2)

## Installation

Add `peerage_ec2` to your list of dependencies in mix.exs:

```elixir
    def deps do
      [
        {:peerage_ec2, "~> 1.2.0"},
      ]
    end
```

Note that the latest release may be a different version number than the version number noted in this document. You can find the latest release on Hex for [peerage_ec2](https://hex.pm/packages/peerage_ec2). You should match the version or alternatively you can use a looser version constraint like `"~> 1.1"`.

## Usage

See ![Peerage](https://github.com/mrluc/peerage) for setup instructions specific to that library. To configure the `Peerage.Via.Ec2` provider:

```elixir
  config :peerage, via: Peerage.Via.Ec2
  config :peerage_ec2, aws_access_key_id: "...",
                       aws_secret_access_key: "...",
                       tags: [{:cluster, "..."}, {:service, "..."}]
```

`tags` are mappings to tags set on your EC2 instances. If using Elastic Beanstalk, these tags are set within the EB environment configuration. The cluster tag is used to discover all nodes in your cluster ("production", "staging", etc). The service tag is used to name each node/service that is found ("accounts", "payments", etc).

`Peerage.Via.Ec2` uses a polling mechanism, so a GenServer is not necessary.
