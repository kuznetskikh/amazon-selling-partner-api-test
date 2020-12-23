defmodule AmazonSellingPartnerApi.MixProject do
  use Mix.Project

  def project do
    [
      app: :amazon_selling_partner_api,
      version: "0.1.0",
      elixir: "~> 1.10",
      start_permanent: Mix.env() == :prod,
      deps: deps()
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
    [
      {:httpoison, "~> 1.7"},
      {:aws_auth, "~> 0.7.2"},
      {:jason, "~> 1.2"},
      {:oauth2, "~> 2.0"}
    ]
  end
end
