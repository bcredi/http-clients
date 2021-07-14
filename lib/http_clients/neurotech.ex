defmodule HttpClients.Neurotech do
  @moduledoc """
  Client for neurotech calls
  """
  alias HttpClients.Neurotech.{Credentials, Person, Request, Score}

  @spec check_identity(Tesla.Client.t(), Credentials.t(), Person.t(), integer()) ::
          {:ok, boolean()} | {:error, any()}
  def check_identity(
        %Tesla.Client{} = client,
        %Credentials{} = credentials,
        %Person{} = person,
        transaction_id
      )
      when is_integer(transaction_id) do
    inputs = %{
      "PROP_POLITICA" => "VALIDACAO_IDENTIDADE",
      "PROP_VALIDACAO_IDENTIDADE_CPF" => person.cpf,
      "PROP_VALIDACAO_IDENTIDADE_DATA_NASCIMENTO" =>
        Calendar.strftime(person.birthdate, "%d/%m/%Y"),
      "PROP_VALIDACAO_IDENTIDADE_NOME" => person.name
    }

    request = %Request{
      inputs: inputs,
      transaction_id: transaction_id,
      credentials: credentials
    }

    case Request.submit(client, request) do
      {:ok, %Tesla.Env{status: 200, body: %{"StatusCode" => "0100"}} = response} ->
        check_identity_response(response.body["Result"]["Result"])

      {:ok, %Tesla.Env{} = response} ->
        {:error, response}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp check_identity_response(status) do
    case status do
      "APROVADO" -> {:ok, true}
      "REPROVADO" -> {:ok, false}
      "PENDENTE" -> {:ok, false}
      _failed -> {:error, :failed}
    end
  end

  @spec compute_bacen_score(Tesla.Client.t(), Credentials.t(), Person.t(), integer(), Keyword.t()) ::
          {:ok, Score.t()} | {:error, any()}
  def compute_bacen_score(
        %Tesla.Client{} = client,
        %Credentials{} = credentials,
        %Person{} = person,
        transaction_id,
        opts \\ []
      )
      when is_integer(transaction_id) and is_list(opts) do
    bacen_source = Keyword.get(opts, :bacen_source)
    base_date = Keyword.get(opts, :base_date)

    inputs =
      %{
        "PROP_POLITICA" => "BACEN_SCR",
        "PROP_BACEN_CPFCNPJ" => person.cpf
      }
      |> put_bacen_source(bacen_source)
      |> put_base_date(base_date)

    request = %Request{
      inputs: inputs,
      transaction_id: transaction_id,
      credentials: credentials
    }

    case Request.submit(client, request) do
      {:ok, %Tesla.Env{status: 200, body: %{"StatusCode" => "0100"}} = response} ->
        {:ok, parse_bacen_analysis(response.body)}

      {:ok, %Tesla.Env{} = response} ->
        {:error, response}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp put_bacen_source(inputs, bacen_source) do
    cond do
      is_nil(bacen_source) -> inputs
      is_binary(bacen_source) -> Map.put(inputs, "PROP_BACEN_FONTE", bacen_source)
    end
  end

  defp put_base_date(inputs, base_date) do
    cond do
      is_nil(base_date) ->
        inputs

      %Date{} = base_date ->
        base_date = Calendar.strftime(base_date, "%d/%m/%Y")
        Map.put(inputs, "PROP_BACEN_DATA_BASE", base_date)
    end
  end

  defp parse_bacen_analysis(bacen_analysis) do
    %Score{
      score: get_score(bacen_analysis),
      positive_analysis: get_value(bacen_analysis, "CALC_BACEN_PONTOS_POSITIVOS"),
      negative_analysis: get_value(bacen_analysis, "CALC_BACEN_PONTOS_NEGATIVOS")
    }
  end

  defp get_score(bacen_analysis) do
    score = get_value(bacen_analysis, "CALC_BCREDISCORE_SCORE")

    if is_binary(score), do: String.to_integer(score), else: nil
  end

  defp get_value(bacen_analysis, key) do
    bacen_analysis["Result"]["Outputs"]
    |> Enum.find(%{}, &(&1["Key"] == key))
    |> Map.get("Value")
    |> case do
      "" -> nil
      value -> value
    end
  end

  @spec client(String.t()) :: Tesla.Client.t()
  def client(base_url) do
    middlewares = [
      {Tesla.Middleware.BaseUrl, base_url},
      Tesla.Middleware.JSON,
      {Tesla.Middleware.Retry, delay: 1_000, max_retries: 3},
      {Tesla.Middleware.Timeout, timeout: 120_000},
      {Tesla.Middleware.Logger, filter_headers: ["Authorization"]}
    ]

    Tesla.client(middlewares)
  end
end
