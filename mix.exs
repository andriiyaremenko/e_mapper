defmodule EMapper.MixProject do
  use Mix.Project

  def project do
    [
      app: :e_mapper,
      version: "0.1.0",
      elixir: "~> 1.9",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      consolidate_protocols: Mix.env() != :test,

      # Docs
    name: "EMapper",
    source_url: "https://github.com/yarrem/e_mapper",
    #homepage_url: "http://YOUR_PROJECT_HOMEPAGE",
    docs: [
      main: "EMapper", # The main page in the docs
      # logo: "path/to/logo.png",
      extras: ["README.md"]
    ]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {EMapper.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ex_doc, "~> 0.21", only: :dev, runtime: false},
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
    ]
  end
end
