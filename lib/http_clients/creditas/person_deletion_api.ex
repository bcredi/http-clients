defmodule HttpClients.Creditas.PersonDeletionApi do
  @moduledoc false

  @spec get(Tesla.Client.t(), binary()) :: {:error, any}
  def get(client, person_id) do
    case Tesla.get(client, "/person-deletions/#{person_id}") do
      {:error, reason} -> {:error, reason}
    end
  end

  @spec client(String.t(), String.t(), String.t()) :: Tesla.Client.t()
  def client(base_url, bearer_token, tenant_id \\ "creditasbr") do
    headers = [
      {"Authorization", "Bearer #{bearer_token}"},
      {"X-Tenant-Id", tenant_id},
      {"Accept", "application/vnd.creditas.v1+json"}
    ]

    json_opts = [
      decode_content_types: ["application/vnd.creditas.v1+json"]
    ]

    middlewares = [
      {Tesla.Middleware.BaseUrl, base_url},
      {Tesla.Middleware.Headers, headers},
      {Tesla.Middleware.JSON, json_opts},
      {Tesla.Middleware.Logger, filter_headers: ["Authorization"]},
      {Tesla.Middleware.Retry, delay: 1_000, max_retries: 3},
      {Tesla.Middleware.Timeout, timeout: 120_000}
    ]

    Tesla.client(middlewares)
  end
end
