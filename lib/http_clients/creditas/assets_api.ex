defmodule HttpClients.Creditas.AssetsApi do
  @moduledoc false

  @spec client(String.t(), String.t()) :: Tesla.Client.t()
  def client(base_url, bearer_token) do
    middlewares = [
      {Tesla.Middleware.BaseUrl, base_url},
      Tesla.Middleware.JSON,
      {Tesla.Middleware.Retry, delay: 1_000, max_retries: 3},
      {Tesla.Middleware.Timeout, timeout: 120_000},
      Tesla.Middleware.Logger,
      {Tesla.Middleware.Headers, [{"Authorization", "Bearer #{bearer_token}"}]}
    ]

    Tesla.client(middlewares)
  end
end
