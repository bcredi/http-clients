defmodule HttpClients.SalesforceTokenServerTest do
  use ExUnit.Case
  import Tesla.Mock

  alias HttpClients.SalesforceTokenServer

  @salesforce_url "https://login.salesforce.com"

  @config [
    url: @salesforce_url,
    client_id: "some client_id",
    client_secret: "some client_secret",
    username: "fulano@creditas.com",
    password: "somepassword123",
    grant_type: "password"
  ]

  @token_response %{
    "access_token" => "access_token_foo",
    "instance_url" => "https://example.com",
    "id" => "https://example.com/id/fakeid",
    "token_type" => "Bearer",
    "issued_at" => "1505149885697",
    "signature" => "+HM1VVxVzTAkwHLmcEiRrFoQDEiZm8H0QfALenayXg0="
  }

  @token %ExForce.OAuthResponse{
    access_token: @token_response["access_token"],
    id: @token_response["id"],
    instance_url: @token_response["instance_url"],
    signature: @token_response["signature"],
    token_type: @token_response["token_type"],
    refresh_token: nil,
    scope: nil,
    issued_at:
      @token_response["issued_at"] |> String.to_integer() |> DateTime.from_unix!(:millisecond)
  }

  setup do
    mock_global(fn %{method: :post, url: "#{@salesforce_url}/services/oauth2/token"} ->
      json(@token_response)
    end)

    opts = [name: SalesforceTokenServer, config: @config]
    {:ok, pid: start_supervised!({SalesforceTokenServer, opts})}
  end

  describe "start_link/1" do
    setup do
      stop_supervised(SalesforceTokenServer)
      :ok
    end

    test "raises error when there's no config" do
      assert_raise RuntimeError, ~r/key :config not found in: \[]/, fn ->
        start_supervised!({SalesforceTokenServer, []})
      end
    end

    test "raises error when there's no url on config" do
      assert_raise RuntimeError, ~r/key :url not found in: \[]/, fn ->
        start_supervised!({SalesforceTokenServer, config: []})
      end
    end

    test "starts the server with a valid token" do
      pid = start_supervised!({SalesforceTokenServer, config: @config})

      Agent.get(pid, fn state ->
        assert state[:token] == @token
        assert state[:config] == @config
      end)
    end
  end

  describe "get_token/1" do
    test "returns a token", %{pid: pid} do
      assert SalesforceTokenServer.get_token(pid) == @token
      assert SalesforceTokenServer.get_token(SalesforceTokenServer) == @token
    end
  end

  describe "update_token/1" do
    test "updates a token", %{pid: pid} do
      token_response = Map.put(@token_response, "token_type", "some token_type")
      expected_token = Map.put(@token, :token_type, "some token_type")

      mock_global(fn %{method: :post, url: "#{@salesforce_url}/services/oauth2/token"} ->
        json(token_response)
      end)

      :ok = SalesforceTokenServer.update_token(pid)
      assert SalesforceTokenServer.get_token(pid) == expected_token
      assert SalesforceTokenServer.get_token(SalesforceTokenServer) == expected_token
    end
  end

  describe "request_new_token/1" do
    test "raises error without url" do
      {_, config} = Keyword.pop!(@config, :url)

      assert_raise KeyError, ~r/key :url not found in/, fn ->
        SalesforceTokenServer.request_new_token(config)
      end
    end

    test "requests a new token" do
      assert SalesforceTokenServer.request_new_token(@config) == {:ok, @token}
    end
  end

  describe "set_token/2" do
    test "stores a token", %{pid: pid} do
      token = %ExForce.OAuthResponse{}
      :ok = SalesforceTokenServer.set_token(pid, token)
      assert SalesforceTokenServer.get_token(pid) == token
      assert SalesforceTokenServer.get_token(SalesforceTokenServer) == token
    end
  end
end
