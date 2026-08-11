# OpenTelemetry BEAM zero-code loading proof

This spike tests the minimal prerequisite for Erlang/Elixir support in the OpenTelemetry Operator: a vanilla OTP Release, built without any OpenTelemetry dependency, must be able to load an independently compiled OpenTelemetry SDK from an external BEAM library path and emit a real span.

The target release and the OTel bundle are compiled separately. At runtime, `ERL_LIBS` exposes the external OTP applications and `ERL_AFLAGS=-s otel_bootstrap_entry run` boots the externally supplied instrumentation code.

The proof uses the SDK's synchronous stdout exporter to remove Collector/network variables from phase 0. It fails unless the target release contains no `opentelemetry*` applications and the log contains both the target startup marker and a span named `external-zero-code-proof`.

Success marker:

```
PROOF_SUCCEEDED: vanilla OTP Release loaded external OpenTelemetry SDK and emitted a span
```
