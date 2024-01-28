defmodule LU.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      LUWeb.Telemetry,
      LU.Repo,
      {DNSCluster, query: Application.get_env(:liveview_upload, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: LU.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: LU.Finch},
      {Task.Supervisor, name: Flamel.Task},
      # Start a worker by calling: LU.Worker.start_link(arg)
      # {LU.Worker, arg},
      # Start to serve requests, typically the last entry
      LUWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: LU.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    LUWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
