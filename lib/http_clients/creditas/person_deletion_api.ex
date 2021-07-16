defmodule HttpClients.Creditas.PersonDeletionApi do
  @moduledoc false

  alias HttpClients.Creditas.PersonDeletionApi.PersonDeletion

  @spec get(Tesla.Client.t(), String.t()) :: {:error, any} | {:ok, PersonDeletion.t()}
  def get(client, person_deletion_id) do
    case Tesla.get(client, "/person-deletions/#{person_deletion_id}") do
      {:ok, %Tesla.Env{status: 200, body: body}} -> {:ok, build_person_deletion(body)}
      {:ok, %Tesla.Env{status: 404}} -> {:error, :not_found}
      {:ok, %Tesla.Env{} = response} -> {:error, response}
      {:error, reason} -> {:error, reason}
    end
  end

  defp build_person_deletion(attrs) do
    %PersonDeletion{
      id: attrs["id"],
      person_id: attrs["person"]["id"],
      person_cpf: attrs["person"]["mainDocument"]["code"]
    }
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
