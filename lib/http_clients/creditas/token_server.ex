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
  # get token and refresh it if is expired or at most 30 seconds before expiring
  HttpClients.Creditas.TokenServer.get_token(MyApp.CreditasTokenServer)

  # get token and refresh it if is expired or at most 120 seconds before expiring
  HttpClients.Creditas.TokenServer.get_token(MyApp.CreditasTokenServer, 120)

  # get a new refreshed token
  HttpClients.Creditas.TokenServer.get_new_token(MyApp.CreditasTokenServer)
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

  defp request_new_token(url: url, credentials: credentials)
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

  @doc "Gets a new token from the given TokenServer"
  @spec get_new_token(atom() | pid()) :: {:error, any} | {:ok, Token.t()}
  def get_new_token(server) when is_token_server(server) do
    config = Agent.get(server, & &1[:config])

    with {:ok, token} <- request_new_token(config),
         :ok <- Agent.update(server, &Map.put(&1, :token, token)) do
      Logger.info("Creditas token updated for #{inspect(server)}")
      {:ok, token}
    end
  end

  @doc "Gets a token from the given TokenServer"
  @spec get_token(atom() | pid(), integer()) :: map()
  def get_token(server, seconds_before_refresh \\ 30)
      when is_token_server(server) and seconds_before_refresh >= 0 do
    token = Agent.get(server, & &1[:token])

    if expired?(token, seconds_before_refresh) do
      with {:ok, token} <- get_new_token(server), do: token
    else
      token
    end
  end

  defp expired?(%Token{expires_at: expires_at}, seconds_before_refresh) do
    now = DateTime.utc_now()
    seconds_until_expiration = DateTime.diff(expires_at, now)
    0 > seconds_until_expiration or seconds_until_expiration <= seconds_before_refresh
  end
end
