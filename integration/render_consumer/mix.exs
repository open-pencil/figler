defmodule FiglerRenderConsumer.MixProject do
  use Mix.Project

  def project do
    [app: :figler_render_consumer, version: "0.1.0", elixir: "~> 1.19", deps: deps()]
  end

  def application, do: [extra_applications: [:logger]]

  defp deps do
    [
      {:figler, path: System.fetch_env!("FIGLER_PACKAGE_PATH")},
      {:skia, "~> 0.3.7"}
    ]
  end
end
