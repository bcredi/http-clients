defmodule HttpClients.Creditas.PersonApiTest do
  use ExUnit.Case

  import Tesla.Mock

  alias HttpClients.Creditas.PersonApi
  alias HttpClients.Creditas.PersonApi.{Address, Contact, MainDocument, Person}

  @client %Tesla.Client{}
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
        {Tesla.Middleware.Logger, :call, [[]]}
      ]

      assert %Tesla.Client{pre: ^expected_configs} = PersonApi.client(@base_url, @bearer_token)
    end
  end

  describe "get_person_by_cpf/2" do
    @query "mainDocument.code=#{@cpf}"

    test "returns person" do
      mock(fn %{url: "/persons", method: :get, query: @query} ->
        %Tesla.Env{status: 200, body: @response_body}
      end)

      assert PersonApi.get_person_by_cpf(@client, @cpf) == {:ok, @person}
    end

    test "returns person without addresses" do
      response_body = Map.delete(@response_body, "addresses")

      mock(fn %{url: "/persons", method: :get, query: @query} ->
        %Tesla.Env{status: 200, body: response_body}
      end)

      expected_person = @person |> Map.put(:addresses, [])
      assert PersonApi.get_person_by_cpf(@client, @cpf) == {:ok, expected_person}
    end

    test "returns person without contacts" do
      response_body = Map.delete(@response_body, "contacts")

      mock(fn %{url: "/persons", method: :get, query: @query} ->
        %Tesla.Env{status: 200, body: response_body}
      end)

      expected_person = @person |> Map.put(:contacts, [])
      assert PersonApi.get_person_by_cpf(@client, @cpf) == {:ok, expected_person}
    end

    test "returns error when request fails" do
      mock(fn %{url: "/persons", method: :get, query: @query} -> %Tesla.Env{status: 400} end)
      assert PersonApi.get_person_by_cpf(@client, @cpf) == {:error, %Tesla.Env{status: 400}}
    end

    test "returns error when couldn't call Creditas API" do
      mock(fn %{url: "/persons", method: :get, query: @query} -> {:error, :timeout} end)
      assert PersonApi.get_person_by_cpf(@client, @cpf) == {:error, :timeout}
    end
  end

  describe "create_person/2" do
    @create_person_request Map.drop(@person, [:id, :version])

    test "returns a person" do
      mock(fn %{url: "/persons", method: :post} ->
        %Tesla.Env{status: 201, body: @response_body}
      end)

      assert PersonApi.create_person(@client, @create_person_request) == {:ok, @person}
    end

    test "returns error when request fails" do
      mock(fn %{url: "/persons", method: :post} -> %Tesla.Env{status: 400} end)

      assert PersonApi.create_person(@client, @create_person_request) ==
               {:error, %Tesla.Env{status: 400}}
    end

    test "returns error when couldn't call Creditas API" do
      mock(fn %{url: "/persons", method: :post} -> {:error, :timeout} end)
      assert PersonApi.create_person(@client, @create_person_request) == {:error, :timeout}
    end
  end

  describe "update_person/3" do
    @current_version 1
    @query "currentVersion=#{@current_version}"
    @attrs %{
      "fullName" => "Sicrano Fulano",
      "birthDate" => "10-10-1999"
    }

    test "returns an updated person" do
      expected_response =
        @response_body
        |> Map.put("fullName", "Sicrano Fulano")
        |> Map.put("birthDate", "10-10-1999")

      expected_person =
        @person
        |> Map.put(:fullName, "Sicrano Fulano")
        |> Map.put(:birthDate, "10-10-1999")

      mock(fn %{method: :patch, url: "/persons/#{@person_id}", body: @attrs, query: @query} ->
        %Tesla.Env{status: 200, body: expected_response}
      end)

      assert PersonApi.update_person(@client, @person, @attrs) == {:ok, expected_person}
    end

    test "returns error when request fails" do
      mock(fn %{method: :patch, url: "/persons/#{@person_id}", body: @attrs, query: @query} ->
        %Tesla.Env{status: 400}
      end)

      assert PersonApi.update_person(@client, @person, @attrs) ==
               {:error, %Tesla.Env{status: 400}}
    end

    test "returns error when couldn't call Creditas API" do
      mock(fn %{method: :patch, url: "/persons/#{@person_id}", body: @attrs, query: @query} ->
        {:error, :timeout}
      end)

      assert PersonApi.update_person(@client, @person, @attrs) == {:error, :timeout}
    end
  end
end
