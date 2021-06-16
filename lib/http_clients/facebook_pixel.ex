defmodule HttpClients.FacebookPixel do
  @moduledoc """
  Client for CustomerManagement app
  """

  @spec send_event(%Tesla.Client{}, String.t(), String.t(), map()) ::
          {:error, any} | {:ok, Tesla.Env.t()}
  def send_event(client, access_token, pixel_id, payload) do
    case Tesla.post(client, "/#{pixel_id}/events?access_token=#{access_token}", payload) do
      {:ok, %Tesla.Env{status: 200} = response} ->
        {:ok, response}
        # {:ok, %Tesla.Env{} = response} -> {:error, response}
        # {:error, reason} -> {:error, reason}
    end
  end

  @spec client(String.t()) :: Tesla.Client.t()
  def client(base_url) do
    middleware = [
      {Tesla.Middleware.BaseUrl, base_url},
      Tesla.Middleware.JSON,
      {Tesla.Middleware.Retry, delay: 1_000, max_retries: 3},
      {Tesla.Middleware.Timeout, timeout: 15_000},
      Tesla.Middleware.Logger
    ]

    Tesla.client(middleware)
  end
end
