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

    test "returns error when request is not accepted" do
      error_body = %{
        "code" => "INPUT_VALIDATION_ERROR",
        "message" => "Some fields are not valid.",
        "details" => [
          %{"target" => "participantId", "message" => "Field has invalid format."}
        ]
      }

      mock_global(fn %{url: @expected_url, method: :get} ->
        %Tesla.Env{status: 400, body: error_body}
      end)

      assert PersonDeletionApi.get(@client, @person_deletion_id) ==
               {:error, %Tesla.Env{body: error_body, status: 400}}
    end

    test "returns error when person deletion don't exist" do
      error_body = %{
        "code" => "NOT_FOUND",
        "message" => "Person Deletion with id: Person Deletion Not Found was not found"
      }

      mock_global(fn %{url: @expected_url, method: :get} ->
        %Tesla.Env{status: 404, body: error_body}
      end)

      assert PersonDeletionApi.get(@client, @person_deletion_id) == {:error, :not_found}
    end

    test "returns person deletion" do
      response = %{
        "id" => UUID.uuid4(),
        "person" => %{
          "id" => UUID.uuid4(),
          "mainDocument" => %{
            "type" => "CPF",
            "code" => "62393275819"
          }
        }
      }

      expected_person_deletion = %PersonDeletionApi.PersonDeletion{
        id: response["id"],
        person_id: response["person"]["id"],
        person_cpf: response["person"]["mainDocument"]["code"]
      }

      mock_global(fn %{url: @expected_url, method: :get} ->
        %Tesla.Env{status: 200, body: response}
      end)

      assert PersonDeletionApi.get(@client, @person_deletion_id) ==
               {:ok, expected_person_deletion}
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
