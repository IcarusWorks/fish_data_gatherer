defmodule FishDataGatherer.Mixfile do
  use Mix.Project

  def project do
    [app: :fish_data_gatherer,
     version: "0.0.1",
     elixir: "~> 1.2",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     elixirc_paths: elixirc_paths(Mix.env),
     deps: deps]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    [applications: [:logger, :httpoison, :hound]]
  end

  # Dependencies can be Hex packages:
  #
  #   {:mydep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:mydep, git: "https://github.com/elixir-lang/mydep.git", tag: "0.1.0"}
  #
  # Type "mix help deps" for more examples and options
  defp deps do
    [
      {:httpoison, "~> 0.8.2"},
      {:floki, "~> 0.8.0"},
      {:hound, "~> 1.0.0"}
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/test_helpers"]
  defp elixirc_paths(_), do: ["lib"]
end
