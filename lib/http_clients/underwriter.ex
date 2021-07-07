defmodule HttpClients.Underwriter do
  @moduledoc """
  Client for Underwriter calls
  """
  alias HttpClients.Underwriter.{Partner, Proponent, Proposal}

  @spec get_proponent(Tesla.Client.t(), String.t()) :: {:error, any} | {:ok, Tesla.Env.t()}
  def get_proponent(%Tesla.Client{} = client, proponent_id) do
    case Tesla.get(client, "/v1/proponents/#{proponent_id}") do
      {:ok, %Tesla.Env{status: 200} = response} -> {:ok, response}
      {:ok, %Tesla.Env{} = response} -> {:error, response}
      {:error, reason} -> {:error, reason}
    end
  end

  @spec get_main_proponent(Tesla.Client.t(), String.t()) :: {:error, any} | {:ok, Tesla.Env.t()}
  def get_main_proponent(%Tesla.Client{} = client, proponent_id) do
    case Tesla.get(client, "/v1/main-proponents/#{proponent_id}") do
      {:ok, %Tesla.Env{status: 200} = response} -> {:ok, response}
      {:ok, %Tesla.Env{} = response} -> {:error, response}
      {:error, reason} -> {:error, reason}
    end
  end

  @spec get_proposal(Tesla.Client.t(), String.t()) :: {:error, any} | {:ok, Tesla.Env.t()}
  def get_proposal(%Tesla.Client{} = client, proposal_id) do
    case Tesla.get(client, "/v1/proposals/#{proposal_id}") do
      {:ok, %Tesla.Env{status: 200, body: body}} -> {:ok, build_proposal(body["data"])}
      {:ok, %Tesla.Env{} = response} -> {:error, response}
      {:error, reason} -> {:error, reason}
    end
  end

  @spec create_proponent(Tesla.Client.t(), Proponent.t()) :: {:error, any} | {:ok, Proponent.t()}
  def create_proponent(%Tesla.Client{} = client, %Proponent{} = proponent) do
    case Tesla.post(client, "/v1/proponents", proponent) do
      {:ok, %Tesla.Env{status: 201} = response} -> {:ok, build_proponent(response.body["data"])}
      {:ok, %Tesla.Env{} = response} -> {:error, response}
      {:error, reason} -> {:error, reason}
    end
  end

  @spec update_proponent(Tesla.Client.t(), Proponent.t()) :: {:error, any} | {:ok, Proponent.t()}
  def update_proponent(%Tesla.Client{} = client, %Proponent{} = proponent) do
    case Tesla.patch(client, "/v1/proponents/#{proponent.id}", proponent) do
      {:ok, %Tesla.Env{status: 200} = response} -> {:ok, build_proponent(response.body["data"])}
      {:ok, %Tesla.Env{} = response} -> {:error, response}
      {:error, reason} -> {:error, reason}
    end
  end

  @spec remove_proponent(Tesla.Client.t(), Proponent.t()) :: {:error, any} | :ok
  def remove_proponent(%Tesla.Client{} = client, %Proponent{} = proponent) do
    case Tesla.delete(client, "/v1/proponents/#{proponent.id}") do
      {:ok, %Tesla.Env{status: 204}} -> :ok
      {:ok, %Tesla.Env{} = response} -> {:error, response}
      {:error, reason} -> {:error, reason}
    end
  end

  defp build_proponent(proponent) do
    %Proponent{
      id: proponent["id"],
      birthdate: proponent["birthdate"],
      email: proponent["email"],
      cpf: proponent["cpf"],
      name: proponent["name"],
      proposal_id: proponent["proposal_id"],
      added_by_proponent: proponent["added_by_proponent"]
    }
  end

  @spec update_proposal(Tesla.Client.t(), Proposal.t()) :: {:error, any} | {:ok, Proposal.t()}
  def update_proposal(%Tesla.Client{} = client, %Proposal{} = proposal) do
    case Tesla.put(client, "/v1/proposals/#{proposal.id}", proposal) do
      {:ok, %Tesla.Env{status: 200} = response} ->
        {:ok, build_updated_proposal(response.body["data"])}

      {:ok, %Tesla.Env{} = response} ->
        {:error, response}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp build_updated_proposal(updated_proposal) do
    %Proposal{
      id: updated_proposal["id"],
      sales_stage: updated_proposal["sales_stage"],
      lost_reason: updated_proposal["lost_reason"]
    }
  end

  defp build_proposal(proposal) do
    main_proponent = proposal["main_proponent"]
    partner = proposal["partner"]
    credit_analysis = proposal["credit_analysis"]
    proposal_simulation = proposal["proposal_simulation"]

    main_proponent = %Proponent{
      id_validation_status: main_proponent["id_validation_status"],
      bacen_score: main_proponent["bacen_score"],
      name: main_proponent["name"],
      email: main_proponent["email"],
      mobile_phone_number: main_proponent["mobile_phone_number"],
      birthdate: Date.from_iso8601!(main_proponent["birthdate"]),
      cpf: main_proponent["cpf"]
    }

    partner = %Partner{type: partner["partner_type"], slug: partner["slug"]}

    %Proposal{
      id: proposal["id"],
      sales_stage: proposal["sales_stage"],
      financing_type: proposal_simulation["financing_type"],
      loan_requested_amount: proposal_simulation["loan_requested_amount"],
      lost_reason: proposal["lost_reason"],
      status: proposal["status"],
      lead_score: proposal["blearning_lead_score"],
      main_proponent: main_proponent,
      partner: partner,
      warranty_region_status: credit_analysis["warranty_region_status"],
      warranty_type_status: credit_analysis["warranty_type_status"],
      warranty_value_status: credit_analysis["warranty_value_status"],
      pre_qualified: credit_analysis["pre_qualified"]
    }
  end

  @spec client(String.t(), String.t(), String.t()) :: Tesla.Client.t()
  def client(base_url, client_id, client_secret) do
    headers = authorization_headers(client_id, client_secret)

    middleware = [
      {Tesla.Middleware.BaseUrl, base_url},
      Tesla.Middleware.JSON,
      {Tesla.Middleware.Headers, headers},
      {Tesla.Middleware.Retry, delay: 1_000, max_retries: 3},
      {Tesla.Middleware.Timeout, timeout: 15_000},
      {Tesla.Middleware.Logger, filter_headers: ["Authorization"]},
      Goodies.Tesla.Middleware.RequestIdForwarder
    ]

    Tesla.client(middleware)
  end

  defp authorization_headers(client_id, client_secret) do
    [
      {"X-Ambassador-Client-ID", client_id},
      {"X-Ambassador-Client-Secret", client_secret}
    ]
  end
end
