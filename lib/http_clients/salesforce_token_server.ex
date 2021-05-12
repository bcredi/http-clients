defmodule HttpClients.SalesforceTokenServer do
  @moduledoc """
  An agent that stores a valid Salesforce API token.

  First setup it on your `application.ex`, e.g.:

  ```elixir
  config = [
    url: "https://login.salesforce.com",
    client_id: "some client_id",
    client_secret: "some client_secret",
    username: "fulano@creditas.com",
    password: "somepassword123",
    grant_type: "password"
  ]
  children = [{HttpClients.SalesforceTokenServer, name: MyApp.SalesforceTokenServer, config: config}]
  Supervisor.start_link(children, name: MyApp.Supervisor)
  ```

  Then you can retrieve the token:

  ```elixir
  HttpClients.SalesforceTokenServer.get_token(MyApp.SalesforceTokenServer)
  ```

  Also you can update the token when needed:

  ```elixir
  HttpClients.SalesforceTokenServer.update_token(MyApp.SalesforceTokenServer)
  ```

  Or you can get a new token and set it by yourself:

  ```elixir
  config = [
    url: "https://login.salesforce.com",
    client_id: "some client_id",
    client_secret: "some client_secret",
    username: "fulano@creditas.com",
    password: "somepassword123",
    grant_type: "password"
  ]
  {:ok, token} = HttpClients.SalesforceTokenServer.request_new_token(config)
  HttpClients.SalesforceTokenServer.set_token(MyApp.SalesforceTokenServer, token)
  ```
  """
  use Agent
  require Logger

  defguard is_server(server) when is_pid(server) or is_atom(server)

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

  @doc "Request an authenticated token to Salesforce"
  @spec request_new_token(keyword()) ::
          {:ok, ExForce.OAuthResponse.t()} | {:error, any()} | no_return()
  def request_new_token(config) when is_list(config) do
    {url, payload} = Keyword.pop!(config, :url)
    ExForce.OAuth.get_token(url, payload)
  end

  @doc "Gets a token from the given TokenServer"
  @spec get_token(pid()) :: ExForce.OAuthResponse.t()
  def get_token(server) when is_server(server) do
    Agent.get(server, & &1[:token])
  end

  @doc "Request an authenticated token to Salesforce and set it to the given TokenServer"
  @spec update_token(pid()) :: :ok | no_return()
  def update_token(server) when is_server(server) do
    Logger.info("Updating the salesforce token")
    config = Agent.get(server, & &1[:config])
    {:ok, token} = request_new_token(config)
    set_token(server, token)
  end

  @doc "Set a new token for the given TokenServer"
  @spec set_token(pid(), ExForce.OAuthResponse.t()) :: :ok
  def set_token(server, %ExForce.OAuthResponse{} = new_token) when is_server(server) do
    Logger.info("Setting new token for #{inspect(server)}")
    Agent.update(server, &Map.put(&1, :token, new_token))
  end
end
