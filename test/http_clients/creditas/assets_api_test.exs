defmodule HttpClients.Creditas.AssetsApiTest do
  use ExUnit.Case

  alias HttpClients.Creditas.AssetsApi

  @base_url "https://api.creditas.io/v0/assets"
  @bearer_token "some_jwt_token"

  describe "client/2" do
    @headers [
      {"Authorization", "Bearer #{@bearer_token}"}
    ]

    test "returns a tesla client" do
      expected_configs = [
        {Tesla.Middleware.BaseUrl, :call, [@base_url]},
        {Tesla.Middleware.JSON, :call, [[]]},
        {Tesla.Middleware.Retry, :call, [[delay: 1000, max_retries: 3]]},
        {Tesla.Middleware.Timeout, :call, [[timeout: 120_000]]},
        {Tesla.Middleware.Logger, :call, [[]]},
        {Tesla.Middleware.Headers, :call, [@headers]}
      ]

      assert %Tesla.Client{pre: expected_configs} == AssetsApi.client(@base_url, @bearer_token)
    end
  end
end
