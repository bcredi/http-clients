defmodule HttpClients.ScrAuthorizer do
  @moduledoc """
  Client for SCR Authorizer calls
  """
  alias HttpClients.ScrAuthorizer.ProponentAuthorization

  @spec create_proponent_authorization(Tesla.Client.t(), ProponentAuthorization.t()) ::
          {:error, any} | {:ok, Proponent.t()}
  def create_proponent_authorization(
        %Tesla.Client{} = client,
        %ProponentAuthorization{} = authorization
      ) do
    case Tesla.post(client, "/v1/proponent-authorizations", authorization) do
      {:ok, %Tesla.Env{status: 201} = response} ->
        {:ok, build_proponent_authorization(response.body["data"])}

      {:ok, %Tesla.Env{} = response} ->
        {:error, response}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp build_proponent_authorization(authorization) do
    %ProponentAuthorization{
      id: authorization["id"],
      proponent_id: authorization["proponent_id"],
      user_agent: authorization["user_agent"],
      ip: authorization["ip"]
    }
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
