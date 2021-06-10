defmodule HttpClients.Creditas.PersonApi do
  @moduledoc false

  alias HttpClients.Creditas.PersonApi.{Address, Contact, MainDocument, Person}

  @spec get_by_cpf(Tesla.Client.t(), String.t()) :: {:error, any} | {:ok, Person.t()}
  def get_by_cpf(client, cpf) do
    query = ["mainDocument.code": cpf]

    case Tesla.get(client, "/persons", query: query) do
      {:ok, %Tesla.Env{status: 200, body: %{"items" => [attrs]}}} -> {:ok, build_person(attrs)}
      {:ok, %Tesla.Env{} = response} -> {:error, response}
      {:error, reason} -> {:error, reason}
    end
  end

  @spec create(Tesla.Client.t(), map()) :: {:error, any} | {:ok, Person.t()}
  def create(client, attrs) do
    case Tesla.post(client, "/persons", attrs) do
      {:ok, %Tesla.Env{status: 201, body: response_body}} -> {:ok, build_person(response_body)}
      {:ok, %Tesla.Env{} = response} -> {:error, response}
      {:error, reason} -> {:error, reason}
    end
  end

  @spec update(Tesla.Client.t(), Person.t(), map()) :: {:ok, Person.t()} | {:error, any()}
  def update(client, %Person{id: person_id, version: current_version}, attrs) do
    query = [currentVersion: current_version]
    # This header is only needed on patch requests
    headers = [{"content-type", "application/merge-patch+json"}]

    case Tesla.patch(client, "/persons/#{person_id}", attrs, query: query, headers: headers) do
      {:ok, %Tesla.Env{status: 200, body: updated_attrs}} -> {:ok, build_person(updated_attrs)}
      {:ok, %Tesla.Env{} = response} -> {:error, response}
      {:error, reason} -> {:error, reason}
    end
  end

  defp build_person(attrs) do
    %Person{
      id: attrs["id"],
      fullName: attrs["fullName"],
      birthDate: attrs["birthDate"],
      version: attrs["version"],
      contacts: build_contacts(attrs["contacts"] || []),
      addresses: build_addresses(attrs["addresses"] || []),
      mainDocument: build_main_document(attrs["mainDocument"])
    }
  end

  defp build_main_document(main_document) do
    %MainDocument{
      type: main_document["type"],
      code: main_document["code"]
    }
  end

  defp build_contacts(contacts) do
    Enum.map(contacts, fn contact ->
      %Contact{
        channel: contact["channel"],
        code: contact["code"],
        type: contact["type"]
      }
    end)
  end

  defp build_addresses(addresses) do
    Enum.map(addresses, fn address ->
      %Address{
        type: address["type"],
        country: address["country"],
        street: address["street"],
        number: address["number"],
        zipCode: address["zipCode"],
        neighborhood: address["neighborhood"],
        complement: address["complement"],
        administrativeAreaLevel1: address["administrativeAreaLevel1"],
        administrativeAreaLevel2: address["administrativeAreaLevel2"]
      }
    end)
  end

  @spec client(String.t(), String.t()) :: Tesla.Client.t()
  def client(base_url, bearer_token) do
    headers = headers(bearer_token)

    json_opts = [
      decode_content_types: ["application/vnd.creditas.v1+json"]
    ]

    middlewares = [
      {Tesla.Middleware.BaseUrl, base_url},
      {Tesla.Middleware.JSON, json_opts},
      {Tesla.Middleware.Retry, delay: 1_000, max_retries: 3},
      {Tesla.Middleware.Timeout, timeout: 120_000},
      {Tesla.Middleware.Logger, filter_headers: ["Authorization"]},
      {Tesla.Middleware.Headers, headers}
    ]

    Tesla.client(middlewares)
  end

  defp headers(bearer_token) do
    [
      {"Authorization", "Bearer #{bearer_token}"},
      {"X-Tenant-Id", "creditasbr"},
      {"Accept", "application/vnd.creditas.v1+json"}
    ]
  end
end
