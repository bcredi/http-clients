defmodule HttpClients.Creditas.PersonDeletionApiTest do
  use ExUnit.Case

  import Tesla.Mock

  alias HttpClients.Creditas.PersonDeletionApi

  @base_url "https://api.creditas.io"

  describe "get/2" do
    @middlewares [
      {Tesla.Middleware.BaseUrl, "https://api.creditas.io"},
      {Tesla.Middleware.Headers, [{"Authorization", "Bearer 123"}]},
      {Tesla.Middleware.JSON, decode_content_types: ["some+json"]},
      {Tesla.Middleware.Logger, filter_headers: ["Authorization"]}
    ]

    @client Tesla.client(@middlewares)
    @person_deletion_id "some_id"
    @expected_url "#{@base_url}/person-deletions/#{@person_deletion_id}"

    test "returns error when request times out" do
      mock_global(fn %{url: @expected_url, method: :get} ->
        {:error, :timeout}
      end)

      assert PersonDeletionApi.get(@client, @person_deletion_id) == {:error, :timeout}
    end
  end

  describe "client/3" do
    @bearer_token "some_jwt_token"
    @decode_content_types [decode_content_types: ["application/vnd.creditas.v1+json"]]

    test "builds a tesla client with default tenant" do
      headers = [
        {"Authorization", "Bearer #{@bearer_token}"},
        {"X-Tenant-Id", "creditasbr"},
        {"Accept", "application/vnd.creditas.v1+json"}
      ]

      expected_configs = [
        {Tesla.Middleware.BaseUrl, :call, [@base_url]},
        {Tesla.Middleware.Headers, :call, [headers]},
        {Tesla.Middleware.JSON, :call, [@decode_content_types]},
        {Tesla.Middleware.Logger, :call, [[filter_headers: ["Authorization"]]]},
        {Tesla.Middleware.Retry, :call, [[delay: 1000, max_retries: 3]]},
        {Tesla.Middleware.Timeout, :call, [[timeout: 120_000]]}
      ]

      assert PersonDeletionApi.client(@base_url, @bearer_token) == %Tesla.Client{
               pre: expected_configs
             }
    end

    test "builds a tesla client" do
      tenant_id = "creditasbr"

      headers = [
        {"Authorization", "Bearer #{@bearer_token}"},
        {"X-Tenant-Id", tenant_id},
        {"Accept", "application/vnd.creditas.v1+json"}
      ]

      expected_configs = [
        {Tesla.Middleware.BaseUrl, :call, [@base_url]},
        {Tesla.Middleware.Headers, :call, [headers]},
        {Tesla.Middleware.JSON, :call, [@decode_content_types]},
        {Tesla.Middleware.Logger, :call, [[filter_headers: ["Authorization"]]]},
        {Tesla.Middleware.Retry, :call, [[delay: 1000, max_retries: 3]]},
        {Tesla.Middleware.Timeout, :call, [[timeout: 120_000]]}
      ]

      assert PersonDeletionApi.client(@base_url, @bearer_token, tenant_id) == %Tesla.Client{
               pre: expected_configs
             }
    end
  end
end
