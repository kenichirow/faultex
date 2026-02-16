defmodule Faultex.MixProject do
  use Mix.Project

  def project do
    [
      app: :faultex,
      version: "0.0.2",
      elixir: "~> 1.10",
      deps: deps(),
      package: package(),
      dialyzer: [
        plt_local_path: "priv/plts",
        plt_core_path: "priv/plts"
      ]
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp package do
    [
      description: "Fault injection library in Elixir",
      maintainers: ["kenichirow"],
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/kenichirow/faultex"}
    ]
  end

  defp deps do
    [
      {:plug, "~> 1.11"},
      {:httpoison, "~> 1.8"},
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false},
      {:dialyxir, "~> 1.4", only: :dev, runtime: false}
    ]
  end
end
