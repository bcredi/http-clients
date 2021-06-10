defmodule HttpClients.Creditas.LoanApi do
  @moduledoc false

  alias HttpClients.Creditas.LoanApi

  @spec get_by_key(Tesla.Client.t(), Key.t()) :: {:error, any} | {:ok, Loan.t() | nil}
  def get_by_key(client, %LoanApi.Key{} = key) do
    query = ["key.code": key.code, "key.type": key.type]

    case Tesla.get(client, "/loans", query: query) do
      {:ok, %Tesla.Env{status: 200, body: %{"items" => [attrs]}}} -> {:ok, build_loan(attrs)}
      {:ok, %Tesla.Env{status: 200, body: %{"items" => []}}} -> {:ok, nil}
      {:ok, %Tesla.Env{} = response} -> {:error, response}
      {:error, reason} -> {:error, reason}
    end
  end

  defp build_loan(attrs) do
    key = struct_from_map(LoanApi.Key, attrs["key"])
    contract = struct_from_map(LoanApi.Contract, attrs["contract"])
    product = struct_from_map(LoanApi.Product, attrs["product"])
    indexation = struct_from_map(LoanApi.Indexation, attrs["indexation"])

    LoanApi.Loan
    |> struct_from_map(attrs)
    |> Map.put(:key, key)
    |> Map.put(:contract, contract)
    |> Map.put(:product, product)
    |> Map.put(:indexation, indexation)
    |> Map.put(:collaterals, build_collaterals(attrs["collaterals"]))
    |> Map.put(:participants, build_participants(attrs["participants"]))
    |> Map.put(:fees, build_fees(attrs["fees"]))
    |> Map.put(:taxes, build_taxes(attrs["taxes"]))
    |> Map.put(:interestRates, build_interest_rates(attrs["interestRates"]))
    |> Map.put(:insurances, build_insurances(attrs["insurances"]))
  end

  defp build_collaterals(collaterals) do
    Enum.map(collaterals, fn collateral ->
      struct_from_map(LoanApi.Collateral, collateral)
    end)
  end

  defp build_participants(participants) do
    Enum.map(participants, fn participant ->
      credit_score_attrs = participant["creditScore"]
      credit_score = struct_from_map(LoanApi.CreditScore, credit_score_attrs)

      LoanApi.Participant
      |> struct_from_map(participant)
      |> Map.put(:creditScore, credit_score)
    end)
  end

  defp build_fees(fees) do
    Enum.map(fees, fn fee -> struct_from_map(LoanApi.Fee, fee) end)
  end

  defp build_taxes(taxes) do
    Enum.map(taxes, fn tax -> struct_from_map(LoanApi.Tax, tax) end)
  end

  defp build_interest_rates(interest_rates) do
    Enum.map(interest_rates, fn interest_rate ->
      struct_from_map(LoanApi.InterestRate, interest_rate)
    end)
  end

  defp build_insurances(insurances) do
    Enum.map(insurances, fn insurance -> struct_from_map(LoanApi.Insurance, insurance) end)
  end

  defp struct_from_map(struct_module, %{} = map) when is_atom(struct_module) do
    attrs =
      struct_module
      |> struct(%{})
      |> Map.drop([:__struct__])
      |> Map.keys()
      |> Enum.reduce(%{}, fn struct_key, acc ->
        string_key = Atom.to_string(struct_key)
        Map.put(acc, struct_key, map[string_key])
      end)

    struct(struct_module, attrs)
  end

  @spec client(String.t(), String.t()) :: Tesla.Client.t()
  def client(base_url, bearer_token) do
    headers = [
      {"Authorization", "Bearer #{bearer_token}"},
      {"X-Tenant-Id", "creditasbr"},
      {"Accept", "application/vnd.creditas.v2+json"}
    ]

    middlewares = [
      {Tesla.Middleware.BaseUrl, base_url},
      {Tesla.Middleware.Headers, headers},
      Tesla.Middleware.JSON,
      Tesla.Middleware.Logger,
      {Tesla.Middleware.Retry, delay: 1_000, max_retries: 3},
      {Tesla.Middleware.Timeout, timeout: 120_000}
    ]

    Tesla.client(middlewares)
  end
end
