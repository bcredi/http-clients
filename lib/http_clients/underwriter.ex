defmodule HttpClients.Underwriter do
  @moduledoc """
  Client for Underwriter calls
  """
  alias HttpClients.Underwriter.Proponent

  @spec create_proponent(Tesla.Client.t(), Proponent.t()) :: {:error, any} | {:ok, Proponent.t()}
  def create_proponent(%Tesla.Client{} = client, %Proponent{} = proponent) do
    case Tesla.post(client, "/v1/proponents", proponent) do
      {:ok, %Tesla.Env{status: 201} = response} -> {:ok, build_struct(response.body["data"])}
      {:ok, %Tesla.Env{} = response} -> {:error, response}
      {:error, reason} -> {:error, reason}
    end
  end

  defp build_struct(proponent) do
    %Proponent{
      id: proponent["id"],
      birthdate: proponent["birthdate"],
      email: proponent["email"],
      cpf: proponent["cpf"],
      name: proponent["name"],
      proposal_id: proponent["proposal_id"],
      added_by_proponent: proponent["added_by_proponent"]
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
