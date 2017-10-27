defmodule Peerage.Via.Ec2.Mixfile do
  use Mix.Project

  def project do
    [
      app: :peerage_ec2,
      version: "0.1.0",
      elixir: "~> 1.5",
      start_permanent: Mix.env == :prod,
      deps: deps(),
      description: description(),
    ]
  end

  def description do
    """
    A Peerage provider for easy clustering on AWS EC2 and Elastic Beanstalk
    """
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ex_aws, "~> 1.1"},
      {:hackney, "~> 1.10"},
      {:peerage, "~> 1.0"},
      {:sweet_xml, "~> 0.6.5"},
    ]
  end
end
