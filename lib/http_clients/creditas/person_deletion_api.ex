defmodule HttpClients.Creditas.PersonDeletionApi do
  @moduledoc false

  alias HttpClients.Creditas.PersonDeletionApi.Acknowledgment

  @spec acknowledgments(Tesla.Client.t(), Acknowledgment.t()) :: {:error, any} | {:ok }
  def acknowledgments(client, ack) do
    case Tesla.post(client, "/#{ack.person_deletion_id}/acknowledgments", build_ack_payload(ack)) do
      {:ok, %Tesla.Env{ status: 200 } } -> { :ok }
      {:ok, %Tesla.Env{} = response} -> {:error, response}
      {:error, reason} -> {:error, reason}
    end
  end

  @spec build_ack_payload(Acknowledgment.t()) :: map()
  defp build_ack_payload(ack) do
    %{
      systemName: ack.system_name,
      status: ack.status,
      notConfirmedReason: ack.not_confirmed_reason
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
