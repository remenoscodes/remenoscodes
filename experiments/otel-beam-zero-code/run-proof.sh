#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD="$ROOT/.proof-build"
TARGET_RELEASE="$BUILD/target-release"
OTEL_ROOT="$BUILD/otel-auto"
LOG="$BUILD/release.log"

rm -rf "$BUILD"
mkdir -p "$BUILD" "$OTEL_ROOT/lib"

echo '=== 1. Build target OTP Release WITHOUT OpenTelemetry ==='
pushd "$ROOT/target" >/dev/null
MIX_ENV=prod mix compile
MIX_ENV=prod mix release --path "$TARGET_RELEASE"
popd >/dev/null

if find "$TARGET_RELEASE/lib" -maxdepth 1 -type d -name 'opentelemetry*' | grep -q .; then
  echo 'FAIL: target release unexpectedly contains OpenTelemetry'
  find "$TARGET_RELEASE/lib" -maxdepth 1 -type d -name 'opentelemetry*' -print
  exit 1
fi

echo 'PASS: target release contains no opentelemetry* application'

echo '=== 2. Build OpenTelemetry bundle independently ==='
pushd "$ROOT/bundle" >/dev/null
MIX_ENV=prod mix deps.get
MIX_ENV=prod mix compile
cp -R _build/prod/lib/. "$OTEL_ROOT/lib/"
popd >/dev/null

for app in opentelemetry opentelemetry_api otel_bootstrap; do
  if ! find "$OTEL_ROOT/lib" -maxdepth 1 -type d -name "${app}-*" | grep -q .; then
    echo "FAIL: external bundle is missing $app"
    exit 1
  fi
done

echo 'PASS: OTel SDK/API/bootstrap exist only in the external bundle'

echo '=== 3. Start vanilla release with external BEAM library root ==='
set +e
ERL_LIBS="$OTEL_ROOT/lib" \
ERL_AFLAGS="-s otel_bootstrap_entry run" \
timeout 8s "$TARGET_RELEASE/bin/zero_code_target" start >"$LOG" 2>&1
status=$?
set -e

cat "$LOG"

if [[ "$status" != "0" && "$status" != "124" ]]; then
  echo "FAIL: release exited unexpectedly with status $status"
  exit "$status"
fi

echo '=== 4. Validate the externally injected SDK actually produced a span ==='
grep -q 'OTEL_EXTERNAL_BOOTSTRAP_LOADED' "$LOG"
grep -q 'OTEL_SDK_STARTED=' "$LOG"
grep -q 'OTEL_EXTERNAL_SPAN_EMITTED' "$LOG"
grep -q '\*SPANS FOR DEBUG\*' "$LOG"
grep -q 'external-zero-code-proof' "$LOG"
grep -q 'TARGET_RELEASE_STARTED' "$LOG"

echo 'PROOF_SUCCEEDED: vanilla OTP Release loaded external OpenTelemetry SDK and emitted a span'
