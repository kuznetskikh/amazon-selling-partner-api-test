defmodule AmazonSellingPartnerApi.MixProject do
  use Mix.Project

  def project do
    [
      app: :amazon_selling_partner_api,
      version: "0.1.0",
      elixir: "~> 1.11",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger, :oauth2]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
      {:httpoison, "~> 1.7"},
      {:ex_aws, "~> 2.1"},
      {:jason, "~> 1.2"},
      {:oauth2, "~> 2.0"}
    ]
  end
end
