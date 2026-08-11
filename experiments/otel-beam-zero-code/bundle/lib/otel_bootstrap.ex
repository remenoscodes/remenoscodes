defmodule OtelBootstrap do
  require OpenTelemetry.Tracer

  def run do
    IO.puts("OTEL_EXTERNAL_BOOTSTRAP_LOADED")
    _ = Application.load(:otel_bootstrap)

    Application.put_env(:opentelemetry, :span_processor, :simple)
    Application.put_env(:opentelemetry, :traces_exporter, {:otel_exporter_stdout, %{}})

    case Application.ensure_all_started(:opentelemetry) do
      {:ok, started} ->
        IO.puts("OTEL_SDK_STARTED=#{inspect(started)}")

        OpenTelemetry.Tracer.with_span "external-zero-code-proof", %{
          attributes: %{
            "proof.mode" => "external-beam-code-path",
            "proof.target_has_otel_dependency" => false
          }
        } do
          OpenTelemetry.Tracer.set_attribute("proof.result", "span-created")
        end

        IO.puts("OTEL_EXTERNAL_SPAN_EMITTED")
        :ok

      {:error, reason} ->
        IO.puts("OTEL_SDK_START_FAILED=#{inspect(reason)}")
        :error
    end
  end
end
