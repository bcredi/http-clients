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
      "PROP_VALIDACAO_IDENTIDADE_DATA_NASCIMENTO" => format_date(person.birthdate),
      "PROP_VALIDACAO_IDENTIDADE_NOME" => person.name
    }

    request = %Request{
      inputs: inputs,
      transaction_id: transaction_id,
      credentials: credentials
    }

    case Request.submit(client, request) do
      {:ok, %Tesla.Env{status: 200, body: %{"StatusCode" => "0100"}} = response} ->
        {:ok, approved?(response.body["Result"]["Result"])}

      {:ok, %Tesla.Env{} = response} ->
        {:error, response}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp format_date(%Date{} = date) do
    month = if date.month < 10, do: "0#{date.month}", else: date.month
    "#{date.day}/#{month}/#{date.year}"
  end

  defp approved?(status), do: status == "APROVADO"

  @spec compute_bacen_score(Tesla.Client.t(), Credentials.t(), Person.t(), integer()) ::
          {:ok, map()} | {:error, any()}
  def compute_bacen_score(
        %Tesla.Client{} = client,
        %Credentials{} = credentials,
        %Person{} = person,
        transaction_id
      )
      when is_integer(transaction_id) do
    inputs = %{
      "PROP_POLITICA" => "BACEN_SCR",
      "PROP_BACEN_CPFCNPJ" => person.cpf
    }

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

  defp parse_bacen_analysis(bacen_analysis) do
    %Score{
      score: get_value(bacen_analysis, "CALC_BCREDISCORE_SCORE") |> String.to_integer(),
      positive_analysis: get_value(bacen_analysis, "CALC_BACEN_PONTOS_POSITIVOS"),
      negative_analysis: bacen_analysis |> get_value("CALC_BACEN_PONTOS_NEGATIVOS")
    }
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
      Tesla.Middleware.Logger
    ]

    Tesla.client(middlewares)
  end
end
