defmodule Peerage.Via.Ec2.Mixfile do
  use Mix.Project

  def project do
    [
      app: :peerage_ec2,
      version: "1.2.0",
      elixir: "~> 1.5",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      name: "Peerage EC2",
      package: package(),
      description: description(),
      source_url: "https://github.com/BoweryFarming/peerage_ec2",
      homepage_url: "https://github.com/BoweryFarming/peerage_ec2",
      docs: [main: "readme", extras: ["README.md"]],
      elixirc_paths: elixirc_paths(Mix.env())
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    # Easy Elixir clusters, pluggable discovery
    [
      {:peerage, "~> 1.0"},
      # ExDoc is a documentation generation tool for Elixir
      {:ex_doc, "~> 0.18.1", only: :dev},
      # A mocking library for the Elixir language
      {:mock, "~> 0.2.0", only: :test}
    ]
  end

  def package do
    [
      files: ["lib", "mix.exs", "README*"],
      maintainers: ["Kevin Sheurs", "Dylan Fareed", "Henry Sztul"],
      licenses: ["MIT"],
      links: %{
        "GitHub" => "https://github.com/BoweryFarming/peerage_ec2",
        "Docs" => "https://hexdocs.pm/peerage_ec2/readme.html"
      }
    ]
  end

  def description do
    """
    A Peerage provider for easy clustering on AWS EC2 and Elastic Beanstalk
    """
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]
end
