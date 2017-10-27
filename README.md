# Peerage AWS EC2 and Elastic Beanstalk Provider

![Peerage](https://github.com/mrluc/peerage) helps your nodes find each other.

It supports DNS-based discovery, which means you can use it out of the box with Kubernetes (and probably also Weave, discoverd, Swarm, or other anything else with dns-based service discovery).

It also supports UDP-based discovery, so that nodes on the same network (like docker containers on the same host) can find each other.

This library adds support for API-based discovery for nodes running in an AWS VPC on EC2 or Elastic Beanstalk.

## Installation

Add `peerage` and `peerage_ec2` to your list of dependencies in mix.exs, and start its application:

```elixir
    def application do
      [applications: [:peerage]]
    end

    def deps do
      [
      	{:peerage, "~> 1.0.2"},
      	{:peerage_ec2, "~> 0.1.0"},
      ]
    end
```

Note that the latest hex version may be higher than what is listed here. You can find the latest version on [hex](https://hex.pm/packages/peerage). You should match the version or alternatively you can use a looser version constraint like `"~> 1.0"`.

## Usage

See ![Peerage](https://github.com/mrluc/peerage) for setup instructions specific to that library. To configure the `Peerage.Via.Ec2` provider:

```elixir
   config :peerage, via: Peerage.Via.Ec2
```

`Peerage.Via.Ec2` uses a polling mechanism, so a GenServer is not necessary.
