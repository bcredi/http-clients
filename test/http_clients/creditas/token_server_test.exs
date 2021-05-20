defmodule HttpClients.Creditas.TokenServerTest do
  use ExUnit.Case
  import Tesla.Mock

  alias HttpClients.Creditas.TokenServer

  @creditas_url "https://test.com/api/internal_clients/tokens"

  @config [
    url: @creditas_url,
    credentials: %{
      username: "bcredi-chp",
      password: "password123",
      grant_type: "password"
    }
  ]

  @token %{
    "access_token" =>
      "eyJhbGciOiJIUzI1NiJ9.eyJ1c2VyX2lkIjoiY2IzZTQ4NzAtMDIyMC00YTMwLTkxYjctYThmY2RhMzRkYjNkIiwidXNlcl90eXBlIjoiYXBpLWNsaWVudCIsInRva2VuX3R5cGUiOiJhY2Nlc3NfdG9rZW4iLCJzZXNzaW9uX2lkIjoiNmRhOWU1NDEtZDIwYi00NjZlLTlhNGQtYmY1OTJjYWZmNzdiIiwiZXhwIjoxNjIxNTIyMzc1LCJpYXQiOjE2MjE1MTUxNzUsImlzcyI6ImJhbmtmYWNpbF9jb3JlIn0.xutmWQjk7Q_o0E2IxtImbcjiOmemuLlhwqnUc8k1nfc",
    "token_type" => "bearer",
    "refresh_token" => "ref-token",
    "expires_in" => 7200
  }

  setup do
    mock_global(fn %{method: :post, url: @creditas_url} -> json(@token, status: 201) end)

    opts = [name: TokenServer, config: @config]
    {:ok, pid: start_supervised!({TokenServer, opts})}
  end

  describe "start_link/1" do
    setup do
      stop_supervised(TokenServer)
      :ok
    end

    test "raises error when there's no config" do
      assert_raise RuntimeError, ~r/key :config not found in: \[]/, fn ->
        start_supervised!({TokenServer, []})
      end
    end

    test "starts the server with a valid token" do
      name = MyCreditasTokenServer
      pid = start_supervised!({TokenServer, config: @config, name: name})

      Agent.get(pid, fn state ->
        assert state[:token] == @token
        assert state[:config] == @config
      end)

      Agent.get(name, fn state ->
        assert state[:token] == @token
        assert state[:config] == @config
      end)
    end
  end

  describe "request_new_token/1" do
    test "returns error without url" do
      config = Keyword.delete(@config, :url)
      assert TokenServer.request_new_token(config) == {:error, ":url is missing!"}
    end

    test "returns error without credentials" do
      config = Keyword.delete(@config, :credentials)
      assert TokenServer.request_new_token(config) == {:error, ":credentials is missing!"}
    end

    test "fails to request a new token" do
      mock_global(fn %{method: :post, url: @creditas_url} -> {:error, :timeout} end)
      assert TokenServer.request_new_token(@config) == {:error, :timeout}
    end

    test "returns error with invalid credentials" do
      error_response = %{"error" => "Invalid Credentials"}

      mock_global(fn %{method: :post, url: @creditas_url} -> json(error_response, status: 401) end)

      assert {:error, %Tesla.Env{status: 401, body: ^error_response}} =
               TokenServer.request_new_token(@config)
    end

    test "requests a new token" do
      assert TokenServer.request_new_token(@config) == {:ok, @token}
    end
  end
end
