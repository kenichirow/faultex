defmodule Injex.MixProject do
  use Mix.Project

  def project do
    [
      app: :faultex,
      version: "0.1.0",
      elixir: "~> 1.10",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:plug, "~> 1.11"},
      {:httpoison, "~> 1.8"},
      {:jason, "~> 1.2"}
    ]
  end
end
