defmodule HttpClients.Underwriter do
  @moduledoc """
  Client for Underwriter calls
  """
  alias HttpClients.Underwriter.Proponent

  @spec create_proponent(Tesla.Client.t(), Proponent.t()) :: {:error, any} | {:ok, Tesla.Env.t()}
  def create_proponent(%Tesla.Client{} = client, %Proponent{} = attrs) do
    case Tesla.post(client, "/v1/proponents", attrs) do
      {:ok, %Tesla.Env{status: 200} = response} -> {:ok, response}
      {:ok, %Tesla.Env{} = response} -> {:error, response}
      {:error, reason} -> {:error, reason}
    end
  end

  @spec client(String.t(), String.t(), String.t()) :: Tesla.Client.t()
  def client(base_url, client_id, client_secret) do
    headers = authorization_headers(client_id, client_secret)

    middleware = [
      {Tesla.Middleware.BaseUrl, base_url},
      Tesla.Middleware.JSON,
      {Tesla.Middleware.Headers, headers},
      {Tesla.Middleware.Retry, delay: 1_000, max_retries: 3},
      {Tesla.Middleware.Timeout, timeout: 15_000},
      Tesla.Middleware.Logger,
      Goodies.Tesla.Middleware.RequestIdForwarder
    ]

    Tesla.client(middleware)
  end

  defp authorization_headers(client_id, client_secret) do
    [
      {"X-Ambassador-Client-ID", client_id},
      {"X-Ambassador-Client-Secret", client_secret}
    ]
  end
end
