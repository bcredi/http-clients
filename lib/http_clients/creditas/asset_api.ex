defmodule HttpClients.Creditas.AssetApi do
  @moduledoc false

  alias HttpClients.Creditas.AssetApi.Asset

  @spec create_asset(Tesla.Client.t(), map()) :: {:error, any} | {:ok, Asset.t()}
  def create_asset(client, attrs) do
    case Tesla.post(client, "/assets", attrs) do
      {:ok, %Tesla.Env{status: 201, body: response_body}} -> {:ok, build_asset(response_body)}
      {:ok, %Tesla.Env{} = response} -> {:error, response}
      {:error, reason} -> {:error, reason}
    end
  end

  defp build_asset(attrs) do
    %Asset{
      id: attrs["id"],
      version: attrs["version"]
    }
  end

  @spec client(String.t(), String.t()) :: Tesla.Client.t()
  def client(base_url, bearer_token) do
    middlewares = [
      {Tesla.Middleware.BaseUrl, base_url},
      {Tesla.Middleware.Headers, [{"Authorization", "Bearer #{bearer_token}"}]},
      Tesla.Middleware.JSON,
      Tesla.Middleware.Logger,
      {Tesla.Middleware.Retry, delay: 1_000, max_retries: 3},
      {Tesla.Middleware.Timeout, timeout: 120_000}
    ]

    Tesla.client(middlewares)
  end
end
