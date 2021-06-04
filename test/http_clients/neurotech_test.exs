defmodule HttpClients.NeurotechTest do
  use ExUnit.Case
  import Tesla.Mock

  import HttpClients.Fixtures.Neurotech
  alias HttpClients.Neurotech
  alias HttpClients.Neurotech.Score

  @transaction_id 123

  describe "check_identity/2" do
    test "returns true when identity was approved" do
      response_body = check_identity_response(:approved)
      mock(fn %{url: "/submit", method: :post} -> json(response_body) end)
      person = %Neurotech.Person{birthdate: Date.utc_today()}

      assert {:ok, true} =
               Neurotech.check_identity(client(), credentials(), person, @transaction_id)
    end

    test "returns false when identity was disapproved" do
      response_body = check_identity_response(:disapproved)
      mock(fn %{url: "/submit", method: :post} -> json(response_body) end)

      person = %Neurotech.Person{birthdate: Date.utc_today()}

      assert {:ok, false} =
               Neurotech.check_identity(client(), credentials(), person, @transaction_id)
    end

    test "returns false when identity was pending" do
      response_body = check_identity_response(:pending)
      mock(fn %{url: "/submit", method: :post} -> json(response_body) end)
      person = %Neurotech.Person{birthdate: Date.utc_today()}

      assert {:ok, false} =
               Neurotech.check_identity(client(), credentials(), person, @transaction_id)
    end

    test "returns error when the request fails" do
      mock(fn %{url: "/submit", method: :post} ->
        json(%{"errors" => "some reason"}, status: 404)
      end)

      person = %Neurotech.Person{birthdate: Date.utc_today()}

      assert {:error, reason} =
               Neurotech.check_identity(client(), credentials(), person, @transaction_id)

      assert %Tesla.Env{body: %{"errors" => "some reason"}, status: 404} = reason
    end
  end

  describe "compute_bacen_score/2" do
    @person %Neurotech.Person{cpf: "65661563051"}

    test "returns error when the request fails" do
      response_body = %{"errors" => "some reason"}

      mock(fn %{url: "/submit", method: :post} ->
        json(response_body, status: 500)
      end)

      assert {:error, %Tesla.Env{body: ^response_body, status: 500}} =
               Neurotech.compute_bacen_score(client(), credentials(), @person, @transaction_id)
    end

    test "returns error when Neurotech fails" do
      response_body = %{"StatusCode" => "0300"}
      mock(fn %{url: "/submit", method: :post} -> json(response_body) end)

      assert {:error, %Tesla.Env{body: ^response_body, status: 200}} =
               Neurotech.compute_bacen_score(client(), credentials(), @person, @transaction_id)
    end

    test "returns empty score when neurotech calculated score isn't a integer" do
      expected_analysis = %Score{
        score: nil,
        positive_analysis: "- Sem registro de vencidos no histórico.\r\n",
        negative_analysis: "- LIMITE DE CRÉDITO abaixo de R$1.000,00 no histórico.\r\n"
      }

      response_body = bacen_response(:empty_calc_score)
      mock(fn %{url: "/submit", method: :post} -> json(response_body) end)

      assert Neurotech.compute_bacen_score(client(), credentials(), @person, @transaction_id) ==
               {:ok, expected_analysis}
    end

    test "computes score" do
      expected_analysis = %Score{
        score: 444,
        positive_analysis: "- Sem registro de vencidos no histórico.\r\n",
        negative_analysis: "- LIMITE DE CRÉDITO abaixo de R$1.000,00 no histórico.\r\n"
      }

      response_body = bacen_response(:success)
      mock(fn %{url: "/submit", method: :post} -> json(response_body) end)

      assert Neurotech.compute_bacen_score(client(), credentials(), @person, @transaction_id) ==
               {:ok, expected_analysis}
    end

    test "computes score with some empty analysis" do
      expected_analysis = %Score{
        score: 444,
        positive_analysis: "- Sem registro de vencidos no histórico.\r\n",
        negative_analysis: nil
      }

      response_body = bacen_response(:empty_negative_analysis)
      mock(fn %{url: "/submit", method: :post} -> json(response_body) end)

      assert Neurotech.compute_bacen_score(client(), credentials(), @person, @transaction_id) ==
               {:ok, expected_analysis}
    end

    test "computes score with base_date option" do
      opts = [base_date: ~D[2017-10-01]]

      expected_analysis = %Score{
        score: 444,
        positive_analysis: "- Sem registro de vencidos no histórico.\r\n",
        negative_analysis: "- LIMITE DE CRÉDITO abaixo de R$1.000,00 no histórico.\r\n"
      }

      response_body = bacen_response(:success)

      mock(fn %{url: "/submit", method: :post, body: body} ->
        assert String.match?(body, ~r/PROP_BACEN_DATA_BASE/)
        assert String.match?(body, ~r/01\/10\/2017/)
        json(response_body)
      end)

      assert Neurotech.compute_bacen_score(
               client(),
               credentials(),
               @person,
               @transaction_id,
               opts
             ) == {:ok, expected_analysis}
    end

    test "computes score with bacen_source option" do
      opts = [bacen_source: "SOME_BACEN_SOURCE"]

      expected_analysis = %Score{
        score: 444,
        positive_analysis: "- Sem registro de vencidos no histórico.\r\n",
        negative_analysis: "- LIMITE DE CRÉDITO abaixo de R$1.000,00 no histórico.\r\n"
      }

      response_body = bacen_response(:success)

      mock(fn %{url: "/submit", method: :post, body: body} ->
        assert String.match?(body, ~r/PROP_BACEN_FONTE/)
        assert String.match?(body, ~r/SOME_BACEN_SOURCE/)
        json(response_body)
      end)

      assert Neurotech.compute_bacen_score(
               client(),
               credentials(),
               @person,
               @transaction_id,
               opts
             ) == {:ok, expected_analysis}
    end
  end

  describe "client/1" do
    test "should return configured client" do
      assert %Tesla.Client{} = Neurotech.client("http://some.url")
    end
  end

  defp client, do: Tesla.client([Tesla.Middleware.JSON])
  defp credentials, do: %Neurotech.Credentials{}
end
