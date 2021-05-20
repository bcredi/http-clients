defmodule HttpClients.Creditas.TokenServer do
  @moduledoc """
  An agent that stores a valid Creditas API token.

  First setup it on your `application.ex`, e.g.:

  ```elixir
  config = [
    url: "https://auth-staging.creditas.com.br/api/internal_clients/tokens",
    credentials: %{
      username: "someuser",
      password: "password123",
      grant_type: "password"
    }
  ]
  children = [{HttpClients.Creditas.TokenServer, name: MyApp.CreditasTokenServer, config: config}]
  Supervisor.start_link(children, name: MyApp.Supervisor)
  ```

  Then you can retrieve the token:

  ```elixir
  HttpClients.Creditas.TokenServer.get_token(MyApp.CreditasTokenServer)

  Or you can retrieve the refreshed token if it's expired (or almost):

  ```elixir
  # get token and refresh it if is expired or at most 120 seconds before expiring
  HttpClients.Creditas.TokenServer.get_refreshed_token(MyApp.CreditasTokenServer, 120)
  ```

  Also you can force a token update when needed:

  ```elixir
  HttpClients.Creditas.TokenServer.update_token(MyApp.CreditasTokenServer)
  ```

  Or you can get a new token and set it by yourself:

  ```elixir
  config = [
    url: "https://auth-staging.creditas.com.br/api/internal_clients/tokens",
    credentials: %{
      username: "someuser",
      password: "password123",
      grant_type: "password"
    }
  ]
  {:ok, token} = HttpClients.Creditas.TokenServer.request_new_token(config)
  HttpClients.Creditas.TokenServer.set_token(MyApp.CreditasTokenServer, token)
  ```
  """

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
      with {:ok, token} <- update_token(server), do: token
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

    with {:ok, token} <- request_new_token(config),
         :ok <- set_token(server, token) do
      {:ok, token}
    end
  end
end
