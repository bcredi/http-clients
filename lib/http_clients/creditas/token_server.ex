defmodule HttpClients.Creditas.TokenServer do
  use Agent
  require Logger

  alias HttpClients.Creditas.Token

  defguardp is_token_server(server) when is_pid(server) or is_atom(server)

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
  @spec request_new_token([{:credentials, map} | {:url, binary}, ...]) ::
          {:error, any} | {:ok, Token.t()}
  def request_new_token(url: url, credentials: credentials)
      when is_binary(url) and is_map(credentials) do
    case Tesla.post(creditas_client(), url, credentials) do
          {:ok, %Tesla.Env{status: 201, body: token}} -> {:ok, build_token(token)}
          {:ok, %Tesla.Env{} = response} -> {:error, response}
          {:error, reason} -> {:error, reason}
        end
    end

  defp creditas_client do
    middleware = [
      Tesla.Middleware.JSON,
      {Tesla.Middleware.Retry, delay: 1_000, max_retries: 3},
      {Tesla.Middleware.Timeout, timeout: 15_000}
    ]

    Tesla.client(middleware)
  end

  defp build_token(%{} = payload) do
    now = DateTime.utc_now()
    expires_at = DateTime.add(now, payload["expires_in"], :second)

    %Token{
      access_token: payload["access_token"],
      expires_at: expires_at
    }
  end

  @doc "Gets a token from the given TokenServer"
  @spec get_token(atom() | pid()) :: map()
  def get_token(server) when is_token_server(server) do
    Agent.get(server, & &1[:token])
  end

  @doc "Gets a refreshed token from the given TokenServer"
  @spec get_refreshed_token(atom() | pid(), integer()) :: map()
  def get_refreshed_token(server, seconds_before_refresh)
      when is_token_server(server) and seconds_before_refresh >= 0 do
    token = Agent.get(server, & &1[:token])

    if update_token?(token, seconds_before_refresh) do
      with :ok <- update_token(server), do: Agent.get(server, & &1[:token])
    else
      token
    end
  end

  defp update_token?(%Token{expires_at: expires_at}, seconds_before_refresh) do
    now = DateTime.utc_now()
    diff_seconds = DateTime.diff(expires_at, now)
    0 > diff_seconds or diff_seconds <= seconds_before_refresh
  end

  @doc "Set a new token for the given TokenServer"
  @spec set_token(atom() | pid(), Token.t()) :: :ok
  def set_token(server, %Token{} = new_token) when is_token_server(server) do
    Logger.info("Setting new Creditas token for #{inspect(server)}")
    Agent.update(server, &Map.put(&1, :token, new_token))
  end

  @doc "Request an authenticated token to Creditas and set it to the given TokenServer"
  @spec update_token(atom() | pid()) :: :ok | no_return()
  def update_token(server) when is_token_server(server) do
    Logger.info("Updating Creditas token for #{inspect(server)}")
    config = Agent.get(server, & &1[:config])
    with {:ok, token} <- request_new_token(config), do: set_token(server, token)
  end
end
