defmodule AbsintheSecurity.MixProject do
  use Mix.Project

  @version "1.0.0"

  def project do
    [
      app: :absinthe_security,
      version: @version,
      elixir: "~> 1.8",
      elixirc_paths: elixirc_paths(Mix.env()),
      description: "This library provides security utilities to validate a GraphQL query before executing it.",
      source_url: "https://github.com/mirego/absinthe_security",
      homepage_url: "https://github.com/mirego/absinthe_security",
      docs: [
        extras: ["README.md"],
        main: "readme",
        source_ref: "v#{@version}",
        source_url: "https://github.com/mirego/absinthe_security"
      ],
      start_permanent: false,
      package: package(),
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    [
      {:absinthe, "~> 1.7"},
      {:credo_naming, "~> 0.4", only: [:dev, :test], runtime: false},
      {:styler, "~> 0.10", only: [:dev, :test], runtime: false},
      {:ex_doc, ">= 0.0.0", only: [:dev, :test], runtime: false}
    ]
  end

  defp package do
    %{
      maintainers: ["Mirego"],
      licenses: ["BSD-3-Clause"],
      links: %{
        "GitHub" => "https://github.com/mirego/absinthe_security"
      }
    }
  end
end
