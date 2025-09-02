defmodule CreditApprover.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      CreditApproverWeb.Telemetry,
      {DNSCluster, query: Application.get_env(:credit_approver, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: CreditApprover.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: CreditApprover.Finch},
      {ChromicPDF, chromic_pdf_opts()},
      # Start a worker by calling: CreditApprover.Worker.start_link(arg)
      # {CreditApprover.Worker, arg},
      # Start to serve requests, typically the last entry
      CreditApproverWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: CreditApprover.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    CreditApproverWeb.Endpoint.config_change(changed, removed)
    :ok
  end

  defp chromic_pdf_opts do
    [
      session_pool: [
        size: 3,
        timeout: 30_000
      ],
      on_demand_session_pool: [
        size: 2,
        timeout: 30_000
      ]
    ]
  end
end
