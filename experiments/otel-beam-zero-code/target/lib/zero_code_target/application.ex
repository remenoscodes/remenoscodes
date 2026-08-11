defmodule ZeroCodeTarget.Application do
  use Application

  @impl true
  def start(_type, _args) do
    IO.puts("TARGET_RELEASE_STARTED")
    Supervisor.start_link([], strategy: :one_for_one, name: ZeroCodeTarget.Supervisor)
  end
end
