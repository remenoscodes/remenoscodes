defmodule OtelBootstrap.MixProject do
  use Mix.Project

  def project do
    [app: :otel_bootstrap, version: "0.1.0", elixir: "~> 1.18", deps: deps()]
  end

  def application, do: [extra_applications: []]

  defp deps do
    [{:opentelemetry, "~> 1.7"}]
  end
end
