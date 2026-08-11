-module(otel_bootstrap_entry).
-export([run/0]).

run() ->
    'Elixir.OtelBootstrap':run().
