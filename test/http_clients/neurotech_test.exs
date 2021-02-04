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
    test "returns score when the request succeeds" do
      response_body = bacen_response(:success)
      mock(fn %{url: "/submit", method: :post} -> json(response_body) end)
      person = %Neurotech.Person{cpf: "65661563051"}

      expected_analysis = %Score{
        score: 444,
        positive_analysis: "- Sem registro de vencidos no histórico.\r\n",
        negative_analysis: "- LIMITE DE CRÉDITO abaixo de R$1.000,00 no histórico.\r\n"
      }

      assert {:ok, ^expected_analysis} =
               Neurotech.compute_bacen_score(client(), credentials(), person, @transaction_id)
    end

    test "requests score using base_date option" do
      response_body = bacen_response(:success)

      mock(fn %{url: "/submit", method: :post, body: body} ->
        assert String.match?(body, ~r/PROP_BACEN_DATA_BASE/)
        assert String.match?(body, ~r/01\/10\/2017/)
        json(response_body)
      end)

      person = %Neurotech.Person{cpf: "65661563051"}
      opts = [base_date: ~D[2017-10-01]]

      expected_analysis = %Score{
        score: 444,
        positive_analysis: "- Sem registro de vencidos no histórico.\r\n",
        negative_analysis: "- LIMITE DE CRÉDITO abaixo de R$1.000,00 no histórico.\r\n"
      }

      assert {:ok, ^expected_analysis} =
               Neurotech.compute_bacen_score(
                 client(),
                 credentials(),
                 person,
                 @transaction_id,
                 opts
               )
    end

    test "returns score when the some analysis is empty" do
      response_body = bacen_response(:empty_positive_analysis)
      mock(fn %{url: "/submit", method: :post} -> json(response_body) end)
      person = %Neurotech.Person{cpf: "65661563051"}

      expected_analysis = %Score{
        score: 444,
        positive_analysis: "- Sem registro de vencidos no histórico.\r\n",
        negative_analysis: nil
      }

      assert {:ok, ^expected_analysis} =
               Neurotech.compute_bacen_score(client(), credentials(), person, @transaction_id)
    end

    test "returns failed response when StatusCode != 0100" do
      response_body = %{"StatusCode" => "0300"}
      mock(fn %{url: "/submit", method: :post} -> json(response_body) end)
      person = %Neurotech.Person{cpf: "65661563051"}

      assert {:error, %Tesla.Env{body: %{"StatusCode" => "0300"}, status: 200}} =
               Neurotech.compute_bacen_score(client(), credentials(), person, @transaction_id)
    end

    test "returns error when the request fails" do
      mock(fn %{url: "/submit", method: :post} ->
        json(%{"errors" => "some reason"}, status: 404)
      end)

      person = %Neurotech.Person{cpf: "65661563051"}

      assert {:error, %Tesla.Env{body: %{"errors" => "some reason"}, status: 404}} =
               Neurotech.compute_bacen_score(client(), credentials(), person, @transaction_id)
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
