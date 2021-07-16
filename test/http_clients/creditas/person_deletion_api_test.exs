defmodule HttpClients.Creditas.PersonDeletionApiTest do
  use ExUnit.Case

  import Tesla.Mock

  alias HttpClients.Creditas.PersonDeletionApi
  alias HttpClients.Creditas.PersonDeletionApi.{Acknowledgment}

  describe "client/3" do
    @base_url "https://api.creditas.io"
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

  describe "acknowledgments/2" do

    @base_url "https://api.creditas.io"
    @bearer_token "some_jwt_token"

    test "create an acknowledgment to a deletion person" do

      ack = %Acknowledgment{
        person_deletion_id: "PDR-6346740B-88C1-4F27-B3CD-B482BD5A5AA4",
        system_name: "bcredi"
      }

      %Acknowledgment{person_deletion_id: person_deletion_id} = ack

      url = "#{@base_url}/#{person_deletion_id}/acknowledgments"

      mock_global(fn
        %{method: :post, url: ^url} ->
          %Tesla.Env{status: 200}
      end)

      client = PersonDeletionApi.client(@base_url, @bearer_token)
      assert PersonDeletionApi.acknowledgments(client, ack) == {:ok}
    end

  end
end
