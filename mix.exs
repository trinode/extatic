defmodule Extatic.Mixfile do
  use Mix.Project

  def project do
    [app: :extatic,
     version: "0.2.1",
     elixir: "~> 1.3",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     description: description(),
     package: package(),
     deps: deps()]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    [mod: {Extatic, []},
      applications: [:logger]]
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
    [{:plug, "~> 1.0"},
     {:credo, "~> 0.4", only: [:dev, :test]}]
  end

  defp description do
    """
    A library to interface with monitoring services and loggers via plugins, allowing you to switch providers with
    minimal rework your app.
    """
  end

  defp package do
     [
       name: :extatic,
       files: ["lib", "mix.exs", "README*", "LICENSE*"],
       maintainers: ["Anthony Graham"],
       licenses: ["Apache 2.0"],
       links: %{"GitHub" => "https://github.com/trinode/extatic"}
     ]
  end
end
