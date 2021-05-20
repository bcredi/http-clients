defmodule HttpClients.Creditas.PersonApiTest do
  use ExUnit.Case

  alias HttpClients.Creditas.PersonApi

  describe "client/2" do
    @base_url "https://api.creditas.io/persons"
    @bearer_token "some_jwt_token"
    @headers [
      {"Authorization", "Bearer #{@bearer_token}"},
      {"X-Tenant-Id", "creditasbr"},
      {"Accept", "application/vnd.creditas.v1+json"}
    ]

    test "returns a tesla client" do
      expected_configs = [
        {Tesla.Middleware.BaseUrl, :call, [@base_url]},
        {Tesla.Middleware.Headers, :call, [@headers]},
        {Tesla.Middleware.JSON, :call, [[]]},
        {Tesla.Middleware.Retry, :call, [[delay: 1000, max_retries: 3]]},
        {Tesla.Middleware.Timeout, :call, [[timeout: 120_000]]},
        {Tesla.Middleware.Logger, :call, [[]]},
        {Goodies.Tesla.Middleware.RequestIdForwarder, :call, [[]]}
      ]

      client = PersonApi.client(@base_url, @bearer_token)
      assert %Tesla.Client{} = client
      assert client.pre == expected_configs
    end
  end
end
