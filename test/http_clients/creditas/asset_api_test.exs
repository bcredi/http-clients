defmodule HttpClients.Creditas.AssetApiTest do
  use ExUnit.Case

  import Tesla.Mock

  alias HttpClients.Creditas.AssetApi
  alias HttpClients.Creditas.AssetApi.Asset

  @base_url "https://api.creditas.io/v0/assets"
  @bearer_token "some_jwt_token"

  describe "create_person/2" do
    @client AssetApi.client(@base_url, @bearer_token)
    @response_body %{"id" => "AST-E9264AE3-3785-4D05-A8CB-2E7B26029C2F", "version" => 1}

    @create_asset_attrs %{
      "type" => "REAL_ESTATE",
      "value" => %{
        "amount" => %{
          "currency" => "BRL",
          "amount" => "33827.00"
        }
      },
      "owners" => [
        %{
          "person" => %{
            "id" => "PER-EA178DDC-FDC6-4CF8-AD3F-B02A80567F1F",
            "version" => 12
          }
        }
      ]
    }

    test "returns an asset" do
      mock_global(fn %{url: "#{@base_url}/assets", method: :post} ->
        %Tesla.Env{status: 201, body: @response_body}
      end)

      expected_asset = %Asset{id: @response_body["id"], version: @response_body["version"]}
      assert AssetApi.create_asset(@client, @create_asset_attrs) == {:ok, expected_asset}
    end

    test "returns error when request fails" do
      mock_global(fn %{url: "#{@base_url}/assets", method: :post} -> %Tesla.Env{status: 400} end)

      assert AssetApi.create_asset(@client, @create_asset_attrs) ==
               {:error, %Tesla.Env{status: 400}}
    end

    test "returns error when couldn't call Creditas API" do
      mock_global(fn %{url: "#{@base_url}/assets", method: :post} -> {:error, :timeout} end)
      assert AssetApi.create_asset(@client, @create_asset_attrs) == {:error, :timeout}
    end
  end

  describe "client/2" do
    @headers [
      {"Authorization", "Bearer #{@bearer_token}"}
    ]

    test "returns a tesla client" do
      expected_configs = [
        {Tesla.Middleware.BaseUrl, :call, [@base_url]},
        {Tesla.Middleware.Headers, :call, [@headers]},
        {Tesla.Middleware.JSON, :call, [[]]},
        {Tesla.Middleware.Logger, :call, [[]]},
        {Tesla.Middleware.Retry, :call, [[delay: 1000, max_retries: 3]]},
        {Tesla.Middleware.Timeout, :call, [[timeout: 120_000]]}
      ]

      assert %Tesla.Client{pre: expected_configs} == AssetApi.client(@base_url, @bearer_token)
    end
  end
end
