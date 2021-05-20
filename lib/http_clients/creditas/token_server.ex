defmodule HttpClients.Creditas.TokenServer do
  use Agent
  require Logger

  @spec start_link(keyword()) :: {:ok, pid()} | {:error, any()} | no_return()
  def start_link(opts) when is_list(opts) do
    {config, opts} = Keyword.pop!(opts, :config)

    Agent.start_link(
      fn ->
        {:ok, token} = request_new_token(config)
        Logger.info("#{__MODULE__} started with pid #{inspect(self())}")
        %{token: token, config: config}
      end,
      opts
    )
  end

  @doc "Request an authenticated token to Creditas"
  @spec request_new_token(keyword()) ::
          {:ok, map()} | {:error, any()} | no_return()
  def request_new_token(config) when is_list(config) do
    cond do
      not is_binary(config[:url]) ->
        {:error, ":url is missing!"}

      not is_map(config[:credentials]) ->
        {:error, ":credentials is missing!"}

      true ->
        case Tesla.post(creditas_client(), config[:url], config[:credentials]) do
          {:ok, %Tesla.Env{status: 201, body: token}} -> {:ok, token}
          {:ok, %Tesla.Env{} = response} -> {:error, response}
          {:error, reason} -> {:error, reason}
        end
    end
  end

  defp creditas_client do
    middleware = [
      Tesla.Middleware.JSON,
      {Tesla.Middleware.Retry, delay: 1_000, max_retries: 3},
      {Tesla.Middleware.Timeout, timeout: 15_000},
      Tesla.Middleware.Logger
    ]

    Tesla.client(middleware)
  end
end
