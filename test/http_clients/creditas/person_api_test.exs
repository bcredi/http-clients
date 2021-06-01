defmodule HttpClients.Creditas.PersonApiTest do
  use ExUnit.Case

  import Tesla.Mock

  alias HttpClients.Creditas.PersonApi
  alias HttpClients.Creditas.PersonApi.{Address, Contact, MainDocument, Person}

  @base_url "https://api.creditas.io/persons"
  @bearer_token "some_jwt_token"
  @client PersonApi.client(@base_url, @bearer_token)
  @person_id UUID.uuid4()
  @cpf "45658265002"

  @response_body %{
    "id" => @person_id,
    "fullName" => "Fulano Sicrano",
    "birthDate" => "10-10-1990",
    "version" => 1,
    "mainDocument" => %{
      "type" => "CPF",
      "code" => @cpf
    },
    "contacts" => [
      %{
        "channel" => "PHONE",
        "code" => "55998788454",
        "type" => "PERSONAL"
      },
      %{
        "channel" => "PHONE",
        "code" => "55998788888",
        "type" => "PERSONAL"
      }
    ],
    "addresses" => [
      %{
        "type" => "HOME",
        "country" => "BR"
      },
      %{
        "type" => "BILLING",
        "country" => "BR",
        "street" => "Av de bill",
        "number" => "2020",
        "zipCode" => "81810111",
        "neighborhood" => "Centro",
        "complement" => "apto 123"
      }
    ]
  }

  @person %Person{
    id: @person_id,
    fullName: "Fulano Sicrano",
    birthDate: "10-10-1990",
    version: 1,
    mainDocument: %MainDocument{
      type: "CPF",
      code: @cpf
    },
    contacts: [
      %Contact{
        channel: "PHONE",
        code: "55998788454",
        type: "PERSONAL"
      },
      %Contact{
        channel: "PHONE",
        code: "55998788888",
        type: "PERSONAL"
      }
    ],
    addresses: [
      %Address{
        country: "BR",
        type: "HOME"
      },
      %Address{
        complement: "apto 123",
        country: "BR",
        neighborhood: "Centro",
        number: "2020",
        street: "Av de bill",
        type: "BILLING",
        zipCode: "81810111"
      }
    ]
  }

  describe "client/2" do
    @decode_content_types [
      decode_content_types: ["application/vnd.creditas.v1+json"]
    ]
    @headers [
      {"Authorization", "Bearer #{@bearer_token}"},
      {"X-Tenant-Id", "creditasbr"},
      {"Accept", "application/vnd.creditas.v1+json"}
    ]

    test "returns a tesla client" do
      expected_configs = [
        {Tesla.Middleware.BaseUrl, :call, [@base_url]},
        {Tesla.Middleware.JSON, :call, [@decode_content_types]},
        {Tesla.Middleware.Retry, :call, [[delay: 1000, max_retries: 3]]},
        {Tesla.Middleware.Timeout, :call, [[timeout: 120_000]]},
        {Tesla.Middleware.Logger, :call, [[]]},
        {Tesla.Middleware.Headers, :call, [@headers]}
      ]

      assert %Tesla.Client{pre: ^expected_configs} = PersonApi.client(@base_url, @bearer_token)
    end
  end

  describe "get_by_cpf/2" do
    @query ["mainDocument.code": @cpf]
    @get_response_body %{"items" => [@response_body]}

    test "returns person" do
      mock_global(fn %{url: "#{@base_url}/persons", method: :get, query: @query} ->
        %Tesla.Env{status: 200, body: @get_response_body}
      end)

      assert PersonApi.get_by_cpf(@client, @cpf) == {:ok, @person}
    end

    test "returns person without addresses" do
      response_body = %{"items" => [Map.delete(@response_body, "addresses")]}

      mock_global(fn %{url: "#{@base_url}/persons", method: :get, query: @query} ->
        %Tesla.Env{status: 200, body: response_body}
      end)

      expected_person = @person |> Map.put(:addresses, [])
      assert PersonApi.get_by_cpf(@client, @cpf) == {:ok, expected_person}
    end

    test "returns person without contacts" do
      response_body = %{"items" => [Map.delete(@response_body, "contacts")]}

      mock_global(fn %{url: "#{@base_url}/persons", method: :get, query: @query} ->
        %Tesla.Env{status: 200, body: response_body}
      end)

      expected_person = @person |> Map.put(:contacts, [])
      assert PersonApi.get_by_cpf(@client, @cpf) == {:ok, expected_person}
    end

    test "returns error when request fails" do
      mock_global(fn %{url: "#{@base_url}/persons", method: :get, query: @query} ->
        %Tesla.Env{status: 400}
      end)

      assert PersonApi.get_by_cpf(@client, @cpf) == {:error, %Tesla.Env{status: 400}}
    end

    test "returns error when couldn't call Creditas API" do
      mock_global(fn %{url: "#{@base_url}/persons", method: :get, query: @query} ->
        {:error, :timeout}
      end)

      assert PersonApi.get_by_cpf(@client, @cpf) == {:error, :timeout}
    end
  end

  describe "create/2" do
    @create_person_attrs %{
      "fullName" => "Joãozinho Junior",
      "mainDocument" => %{
        "type" => "CPF",
        "code" => "344.189.910-50"
      }
    }

    test "returns a person" do
      mock_global(fn %{url: "#{@base_url}/persons", method: :post} ->
        %Tesla.Env{status: 201, body: @response_body}
      end)

      assert PersonApi.create(@client, @create_person_attrs) == {:ok, @person}
    end

    test "returns error when request fails" do
      mock_global(fn %{url: "#{@base_url}/persons", method: :post} -> %Tesla.Env{status: 400} end)

      assert PersonApi.create(@client, @create_person_attrs) ==
               {:error, %Tesla.Env{status: 400}}
    end

    test "returns error when couldn't call Creditas API" do
      mock_global(fn %{url: "#{@base_url}/persons", method: :post} -> {:error, :timeout} end)
      assert PersonApi.create(@client, @create_person_attrs) == {:error, :timeout}
    end
  end

  describe "update/3" do
    @current_version 1
    @query [currentVersion: @current_version]
    @attrs %{
      "fullName" => "Sicrano Fulano",
      "birthDate" => "10-10-1999"
    }
    @encoded_attrs Jason.encode!(@attrs)

    @update_headers [
      {"content-type", "application/merge-patch+json"},
      {"content-type", "application/json"},
      {"Authorization", "Bearer some_jwt_token"},
      {"X-Tenant-Id", "creditasbr"},
      {"Accept", "application/vnd.creditas.v1+json"}
    ]

    test "updates a person" do
      expected_response =
        @response_body
        |> Map.put("fullName", @attrs["fullName"])
        |> Map.put("birthDate", @attrs["birthDate"])

      expected_person =
        @person
        |> Map.put(:fullName, @attrs["fullName"])
        |> Map.put(:birthDate, @attrs["birthDate"])

      mock_global(fn %{
                       method: :patch,
                       url: "#{@base_url}/persons/#{@person_id}",
                       body: @encoded_attrs,
                       query: @query,
                       headers: @update_headers
                     } ->
        %Tesla.Env{status: 200, body: expected_response}
      end)

      assert PersonApi.update(@client, @person, @attrs) == {:ok, expected_person}
    end

    test "returns error when request fails" do
      mock_global(fn %{
                       method: :patch,
                       url: "#{@base_url}/persons/#{@person_id}",
                       body: @encoded_attrs,
                       query: @query,
                       headers: @update_headers
                     } ->
        %Tesla.Env{status: 400}
      end)

      assert PersonApi.update(@client, @person, @attrs) ==
               {:error, %Tesla.Env{status: 400}}
    end

    test "returns error when couldn't call Creditas API" do
      mock_global(fn %{
                       method: :patch,
                       url: "#{@base_url}/persons/#{@person_id}",
                       body: @encoded_attrs,
                       query: @query,
                       headers: @update_headers
                     } ->
        {:error, :timeout}
      end)

      assert PersonApi.update(@client, @person, @attrs) == {:error, :timeout}
    end
  end
end
