defmodule HttpClients.Creditas.LoanApiTest do
  use ExUnit.Case

  import Tesla.Mock

  alias HttpClients.Creditas.LoanApi

  @base_url "https://api.creditas.io"
  @bearer_token "some_jwt_token"

  describe "get_by_key/2" do
    @client LoanApi.client(@base_url, @bearer_token)
    @query ["key.code": "some_code", "key.type": "CREDIT_CERTIFICATE"]
    @response_body %{
      "key" => %{
        "type" => "CREDIT_CERTIFICATE",
        "code" => "TESTE_BCREDI_HOME_PRE_2_LOAN1696"
      },
      "id" => "LOA-52AB4FD7-A166-4DA3-9B3B-F94C94A5A622",
      "status" => "ACTIVE",
      "creditor" => "FIDC_TEMPUS_HOME",
      "originator" => "CREDITAS",
      "underwriter" => "CHP",
      "currency" => "BRL",
      "financedAmount" => 10768.23,
      "installmentsCount" => 24,
      "installmentFrequency" => "MONTHLY",
      "installmentFixedAmount" => 642.67,
      "firstInstallmentDueDate" => "2020-04-19",
      "lastInstallmentDueDate" => "2022-03-19",
      "amortizationMethod" => "PRICE",
      "contract" => %{
        "number" => "7127054",
        "issuedAt" => "2017-08-01",
        "signedAt" => "2017-08-01"
      },
      "collaterals" => [
        %{
          "id" => "AST-39FC89D8-DEF8-45F9-B029-DEA368D7551A"
        }
      ],
      "participants" => [
        %{
          "id" => "PER-335C78F1-90EC-4AA7-BBFA-999820149A7F",
          "authId" => "a9a1fa8e-1d46-4452-b2a9-d57041ef493d",
          "creditScore" => %{
            "provider" => "SERASA",
            "value" => "999.9"
          },
          "roles" => [
            "PRINCIPAL_PRIMARIO"
          ]
        }
      ],
      "product" => %{
        "type" => "HOME",
        "subtype" => "BCREDI_HOME_REFINANCING"
      },
      "fees" => [
        %{
          "type" => "OPENING",
          "payer" => "CLIENT",
          "value" => 50.0
        },
        %{
          "type" => "REGISTRY",
          "payer" => "CLIENT",
          "value" => 50.0
        },
        %{
          "type" => "TAG",
          "payer" => "CLIENT",
          "value" => 50.0
        }
      ],
      "taxes" => [
        %{
          "type" => "IOF",
          "value" => 286.16
        },
        %{
          "type" => "TAC",
          "value" => 600.0
        }
      ],
      "interestRates" => [
        %{
          "context" => "AMORTIZATION_PLAN",
          "frequency" => "MONTHLY",
          "base" => 360,
          "value" => 0.0284
        },
        %{
          "context" => "REGULAR_CHARGES",
          "frequency" => "MONTHLY",
          "base" => 365,
          "value" => 0.028036
        }
      ],
      "indexation" => %{
        "type" => "FIXED"
      },
      "disbursements" => [],
      "insurances" => [
        %{
          "type" => "MIP"
        },
        %{
          "type" => "DFI"
        }
      ]
    }
    @get_response_body %{"items" => [@response_body]}
    @loan %LoanApi.Loan{
      key: %LoanApi.Key{
        type: "CREDIT_CERTIFICATE",
        code: "TESTE_BCREDI_HOME_PRE_2_LOAN1696"
      },
      id: "LOA-52AB4FD7-A166-4DA3-9B3B-F94C94A5A622",
      status: "ACTIVE",
      creditor: "FIDC_TEMPUS_HOME",
      originator: "CREDITAS",
      underwriter: "CHP",
      currency: "BRL",
      financedAmount: 10768.23,
      installmentsCount: 24,
      installmentFrequency: "MONTHLY",
      installmentFixedAmount: 642.67,
      firstInstallmentDueDate: "2020-04-19",
      lastInstallmentDueDate: "2022-03-19",
      amortizationMethod: "PRICE",
      contract: %LoanApi.Contract{
        number: "7127054",
        issuedAt: "2017-08-01",
        signedAt: "2017-08-01"
      },
      collaterals: [
        %LoanApi.Collateral{
          id: "AST-39FC89D8-DEF8-45F9-B029-DEA368D7551A"
        }
      ],
      participants: [
        %LoanApi.Participant{
          id: "PER-335C78F1-90EC-4AA7-BBFA-999820149A7F",
          authId: "a9a1fa8e-1d46-4452-b2a9-d57041ef493d",
          creditScore: %LoanApi.CreditScore{
            provider: "SERASA",
            value: "999.9"
          },
          roles: [
            "PRINCIPAL_PRIMARIO"
          ]
        }
      ],
      product: %LoanApi.Product{
        type: "HOME",
        subtype: "BCREDI_HOME_REFINANCING"
      },
      fees: [
        %LoanApi.Fee{
          type: "OPENING",
          payer: "CLIENT",
          value: 50.0
        },
        %LoanApi.Fee{
          type: "REGISTRY",
          payer: "CLIENT",
          value: 50.0
        },
        %LoanApi.Fee{
          type: "TAG",
          payer: "CLIENT",
          value: 50.0
        }
      ],
      taxes: [
        %LoanApi.Tax{
          type: "IOF",
          value: 286.16
        },
        %LoanApi.Tax{
          type: "TAC",
          value: 600.0
        }
      ],
      interestRates: [
        %LoanApi.InterestRate{
          context: "AMORTIZATION_PLAN",
          frequency: "MONTHLY",
          base: 360,
          value: 0.0284
        },
        %LoanApi.InterestRate{
          context: "REGULAR_CHARGES",
          frequency: "MONTHLY",
          base: 365,
          value: 0.028036
        }
      ],
      indexation: %LoanApi.Indexation{
        type: "FIXED"
      },
      insurances: [
        %LoanApi.Insurance{
          type: "MIP"
        },
        %LoanApi.Insurance{
          type: "DFI"
        }
      ]
    }

    test "returns error when loan api times out" do
      loan_key = %LoanApi.Key{type: "CREDIT_CERTIFICATE", code: "some_code"}

      mock_global(fn %{url: "#{@base_url}/loans", method: :get, query: @query} ->
        {:error, :timeout}
      end)

      assert {:error, :timeout} = LoanApi.get_by_key(@client, loan_key)
    end

    test "returns error when request is not accepted" do
      loan_key = %LoanApi.Key{type: "CREDIT_CERTIFICATE", code: "some_code"}

      error_body = %{
        "code" => "INPUT_VALIDATION_ERROR",
        "message" => "Some fields are not valid.",
        "details" => [
          %{"target" => "participantId", "message" => "Field has invalid format."}
        ]
      }

      mock_global(fn %{url: "#{@base_url}/loans", method: :get, query: @query} ->
        %Tesla.Env{status: 400, body: error_body}
      end)

      assert {:error,
              %Tesla.Env{
                body: ^error_body,
                status: 400
              }} = LoanApi.get_by_key(@client, loan_key)
    end

    test "returns nil when loan is not found" do
      loan_key = %LoanApi.Key{type: "CREDIT_CERTIFICATE", code: "some_code"}

      mock_global(fn %{url: "#{@base_url}/loans", method: :get, query: @query} ->
        %Tesla.Env{status: 200, body: %{"items" => []}}
      end)

      assert {:ok, nil} = LoanApi.get_by_key(@client, loan_key)
    end

    test "returns loan" do
      loan_key = %LoanApi.Key{type: "CREDIT_CERTIFICATE", code: "some_code"}

      mock_global(fn %{url: "#{@base_url}/loans", method: :get, query: @query} ->
        %Tesla.Env{status: 200, body: @get_response_body}
      end)

      assert {:ok, @loan} = LoanApi.get_by_key(@client, loan_key)
    end
  end

  describe "client/2" do
    @headers [
      {"Authorization", "Bearer #{@bearer_token}"},
      {"X-Tenant-Id", "creditasbr"},
      {"Accept", "application/vnd.creditas.v2+json"}
    ]

    test "returns a tesla client" do
      expected_configs = [
        {Tesla.Middleware.BaseUrl, :call, [@base_url]},
        {Tesla.Middleware.Headers, :call, [@headers]},
        {Tesla.Middleware.JSON, :call, [[]]},
        {Tesla.Middleware.Logger, :call, [[]]},
        {Tesla.Middleware.Retry, :call, [[delay: 1000, max_retries: 3]]},
        {Tesla.Middleware.Timeout, :call, [[timeout: 120_000]]}
      ]

      assert %Tesla.Client{pre: expected_configs} == LoanApi.client(@base_url, @bearer_token)
    end
  end
end
