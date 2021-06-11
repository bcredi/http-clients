defmodule HttpClients.Creditas.LoanApiTest do
  use ExUnit.Case

  import Tesla.Mock

  alias HttpClients.Creditas.LoanApi

  @base_url "https://api.creditas.io"
  @bearer_token "some_jwt_token"
  @json_opts [decode_content_types: ["application/vnd.creditas.v2+json"]]

  @headers [
    {"Authorization", "Bearer #{@bearer_token}"},
    {"X-Tenant-Id", "creditasbr"},
    {"Accept", "application/vnd.creditas.v2+json"}
  ]

  @middlewares [
    {Tesla.Middleware.BaseUrl, @base_url},
    {Tesla.Middleware.Headers, @headers},
    {Tesla.Middleware.JSON, @json_opts},
    {Tesla.Middleware.Logger, filter_headers: ["Authorization"]}
  ]

  @client Tesla.client(@middlewares)

  describe "get_by_key/2" do
    @loan_key %LoanApi.Key{type: "CREDIT_CERTIFICATE", code: "some_code"}
    @query ["key.code": "some_code", "key.type": "CREDIT_CERTIFICATE"]
    @get_response_body %{
      "items" => [
        %{
          "key" => %{
            "type" => "CREDIT_CERTIFICATE",
            "code" => "BCREDI_LOAN_LOAN1696"
          },
          "id" => "LOA-52AB4FD7-A166-4DA3-9B3B-F94C94A5A622",
          "status" => "ACTIVE",
          "creditor" => "CREDITAS_SCD",
          "originator" => "CREDITAS",
          "underwriter" => "CREDITAS_SCD",
          "currency" => "BRL",
          "financedAmount" => 107_512.59,
          "installmentsCount" => 120,
          "installmentFrequency" => "MONTHLY",
          "installmentFixedAmount" => 1_069.76,
          "firstInstallmentDueDate" => "2020-04-19",
          "lastInstallmentDueDate" => "2022-03-19",
          "amortizationMethod" => "PRICE",
          "contract" => %{
            "number" => "7127054",
            "issuedAt" => "2021-04-10",
            "signedAt" => "2021-04-10"
          },
          "collaterals" => [
            %{
              "id" => "AST-5EC45F94-F6A5-4A25-9D80-5EC426667436"
            }
          ],
          "participants" => [
            %{
              "id" => "PER-335C78F1-90EC-4AA7-BBFA-999820149A7F",
              "authId" => "a9a1fa8e-1d46-4452-b2a9-d57041ef493d",
              "creditScore" => %{
                "provider" => "SERASA",
                "value" => "600"
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
              "value" => 0.0085
            },
            %{
              "context" => "REGULAR_CHARGES",
              "frequency" => "MONTHLY",
              "base" => 365,
              "value" => 0.0085
            }
          ],
          "indexation" => %{
            "type" => "FIXED",
            "inflationIndexType" => nil
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
      ]
    }
    @loan %LoanApi.Loan{
      key: %LoanApi.Key{
        type: "CREDIT_CERTIFICATE",
        code: "BCREDI_LOAN_LOAN1696"
      },
      id: "LOA-52AB4FD7-A166-4DA3-9B3B-F94C94A5A622",
      status: "ACTIVE",
      creditor: "CREDITAS_SCD",
      originator: "CREDITAS",
      underwriter: "CREDITAS_SCD",
      currency: "BRL",
      financedAmount: 107_512.59,
      installmentsCount: 120,
      installmentFrequency: "MONTHLY",
      installmentFixedAmount: 1069.76,
      firstInstallmentDueDate: "2020-04-19",
      lastInstallmentDueDate: "2022-03-19",
      amortizationMethod: "PRICE",
      contract: %LoanApi.Contract{
        number: "7127054",
        issuedAt: "2021-04-10",
        signedAt: "2021-04-10"
      },
      collaterals: [
        %LoanApi.Collateral{
          id: "AST-5EC45F94-F6A5-4A25-9D80-5EC426667436"
        }
      ],
      participants: [
        %LoanApi.Participant{
          id: "PER-335C78F1-90EC-4AA7-BBFA-999820149A7F",
          authId: "a9a1fa8e-1d46-4452-b2a9-d57041ef493d",
          creditScore: %LoanApi.CreditScore{
            provider: "SERASA",
            value: "600"
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
          value: 0.0085
        },
        %LoanApi.InterestRate{
          context: "REGULAR_CHARGES",
          frequency: "MONTHLY",
          base: 365,
          value: 0.0085
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

    test "returns error when request times out" do
      mock_global(fn %{url: "#{@base_url}/loans", method: :get, query: @query} ->
        {:error, :timeout}
      end)

      assert {:error, :timeout} = LoanApi.get_by_key(@client, @loan_key)
    end

    test "returns error when request is not accepted" do
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
              }} = LoanApi.get_by_key(@client, @loan_key)
    end

    test "returns nil when loan is not found" do
      mock_global(fn %{url: "#{@base_url}/loans", method: :get, query: @query} ->
        %Tesla.Env{status: 200, body: %{"items" => []}}
      end)

      assert LoanApi.get_by_key(@client, @loan_key) == {:ok, nil}
    end

    test "returns loan" do
      mock_global(fn %{url: "#{@base_url}/loans", method: :get, query: @query} ->
        %Tesla.Env{status: 200, body: @get_response_body}
      end)

      assert LoanApi.get_by_key(@client, @loan_key) == {:ok, @loan}
    end
  end

  describe "create/2" do
    @create_loan_attrs %{
      "key" => %{"type" => "CREDIT_CERTIFICATE", "code" => "BCREDI_LOAN_TESTE_11061543"},
      "contract" => %{
        "number" => "bcredi_tentativa_10",
        "issuedAt" => "2021-04-10",
        "signedAt" => "2021-04-10"
      },
      "collaterals" => [%{"id" => "AST-5EC45F94-F6A5-4A25-9D80-5EC426667436"}],
      "participants" => [
        %{
          "id" => "PER-335C78F1-90EC-4AA7-BBFA-999820149A7F",
          "authId" => "586c73b2-2406-4885-b9b6-f1d208598a87",
          "creditScore" => %{"provider" => "SERASA", "value" => "600"},
          "roles" => ["PRINCIPAL_PRIMARIO"]
        }
      ],
      "creditor" => "CREDITAS_SCD",
      "originator" => "CREDITAS",
      "underwriter" => "CREDITAS_SCD",
      "product" => %{"type" => "HOME", "subtype" => "BCREDI_HOME_REFINANCING"},
      "currency" => "BRL",
      "financedAmount" => 107_512.59,
      "installmentsCount" => 120,
      "installmentFrequency" => "MONTHLY",
      "installmentFixedAmount" => 1069.76,
      "firstInstallmentDueDate" => "2021-07-14",
      "lastInstallmentDueDate" => "2031-06-14",
      "fees" => [],
      "taxes" => [%{"type" => "IOF", "value" => 1249.16}, %{"type" => "TAC", "value" => 0}],
      "interestRates" => [
        %{
          "context" => "AMORTIZATION_PLAN",
          "frequency" => "MONTHLY",
          "base" => 360,
          "value" => 0.0085
        },
        %{
          "context" => "REGULAR_CHARGES",
          "frequency" => "MONTHLY",
          "base" => 360,
          "value" => 0.0085
        }
      ],
      "amortizationMethod" => "PRICE",
      "indexation" => %{"type" => "FIXED"},
      "insurances" => [%{"type" => "MIP"}, %{"type" => "DFI"}]
    }

    @create_loan_response %{
      "id" => "LOA-9CD1A8A3-8A6A-4497-8044-AB6EE62D69F9",
      "key" => %{"type" => "CREDIT_CERTIFICATE", "code" => "BCREDI_LOAN_TESTE_11061542"},
      "status" => "ACTIVE",
      "contract" => %{
        "number" => "bcredi_tentativa_10",
        "issuedAt" => "2021-04-10",
        "signedAt" => "2021-04-10"
      },
      "collaterals" => [%{"id" => "AST-5EC45F94-F6A5-4A25-9D80-5EC426667436"}],
      "participants" => [
        %{
          "id" => "PER-335C78F1-90EC-4AA7-BBFA-999820149A7F",
          "authId" => "586c73b2-2406-4885-b9b6-f1d208598a87",
          "creditScore" => %{"provider" => "SERASA", "value" => "600"},
          "roles" => ["PRINCIPAL_PRIMARIO"]
        }
      ],
      "creditor" => "CREDITAS_SCD",
      "originator" => "CREDITAS",
      "underwriter" => "CREDITAS_SCD",
      "product" => %{"type" => "HOME", "subtype" => "BCREDI_HOME_REFINANCING"},
      "currency" => "BRL",
      "financedAmount" => 107_512.59,
      "installmentsCount" => 120,
      "installmentFrequency" => "MONTHLY",
      "installmentFixedAmount" => 1069.76,
      "firstInstallmentDueDate" => "2021-07-14",
      "lastInstallmentDueDate" => "2031-06-14",
      "fees" => [],
      "taxes" => [%{"type" => "IOF", "value" => 1249.16}, %{"type" => "TAC", "value" => 0.0}],
      "interestRates" => [
        %{
          "context" => "AMORTIZATION_PLAN",
          "frequency" => "MONTHLY",
          "base" => 360,
          "value" => 0.0085
        },
        %{
          "context" => "REGULAR_CHARGES",
          "frequency" => "MONTHLY",
          "base" => 360,
          "value" => 0.0085
        }
      ],
      "amortizationMethod" => "PRICE",
      "indexation" => %{"type" => "FIXED"},
      "disbursements" => [],
      "insurances" => [%{"type" => "MIP"}, %{"type" => "DFI"}],
      "createdAt" => "2021-06-11T19:09:51.846853Z",
      "updatedAt" => "2021-06-11T19:09:52.080832Z"
    }

    @loan %LoanApi.Loan{
      status: "ACTIVE",
      amortizationMethod: "PRICE",
      collaterals: [%LoanApi.Collateral{id: "AST-5EC45F94-F6A5-4A25-9D80-5EC426667436"}],
      contract: %LoanApi.Contract{
        issuedAt: "2021-04-10",
        number: "bcredi_tentativa_10",
        signedAt: "2021-04-10"
      },
      creditor: "CREDITAS_SCD",
      currency: "BRL",
      fees: [],
      financedAmount: 107_512.59,
      firstInstallmentDueDate: "2021-07-14",
      id: "LOA-9CD1A8A3-8A6A-4497-8044-AB6EE62D69F9",
      indexation: %LoanApi.Indexation{inflationIndexType: nil, type: "FIXED"},
      installmentFixedAmount: 1069.76,
      installmentFrequency: "MONTHLY",
      installmentsCount: 120,
      insurances: [%LoanApi.Insurance{type: "MIP"}, %LoanApi.Insurance{type: "DFI"}],
      interestRates: [
        %LoanApi.InterestRate{
          base: 360,
          context: "AMORTIZATION_PLAN",
          frequency: "MONTHLY",
          value: 0.0085
        },
        %LoanApi.InterestRate{
          base: 360,
          context: "REGULAR_CHARGES",
          frequency: "MONTHLY",
          value: 0.0085
        }
      ],
      key: %LoanApi.Key{code: "BCREDI_LOAN_TESTE_11061542", type: "CREDIT_CERTIFICATE"},
      lastInstallmentDueDate: "2031-06-14",
      originator: "CREDITAS",
      participants: [
        %LoanApi.Participant{
          authId: "586c73b2-2406-4885-b9b6-f1d208598a87",
          creditScore: %LoanApi.CreditScore{provider: "SERASA", value: "600"},
          id: "PER-335C78F1-90EC-4AA7-BBFA-999820149A7F",
          roles: ["PRINCIPAL_PRIMARIO"]
        }
      ],
      product: %LoanApi.Product{subtype: "BCREDI_HOME_REFINANCING", type: "HOME"},
      taxes: [
        %LoanApi.Tax{type: "IOF", value: 1249.16},
        %LoanApi.Tax{type: "TAC", value: 0.0}
      ],
      underwriter: "CREDITAS_SCD"
    }

    test "returns error when couldn't call Creditas API" do
      mock_global(fn %{url: "#{@base_url}/loans", method: :post} -> {:error, :timeout} end)
      assert LoanApi.create(@client, @create_loan_attrs) == {:error, :timeout}
    end

    test "returns error when request fails" do
      mock_global(fn %{url: "#{@base_url}/loans", method: :post} -> %Tesla.Env{status: 400} end)

      assert LoanApi.create(@client, @create_loan_attrs) ==
               {:error, %Tesla.Env{status: 400}}
    end

    test "returns loan" do
      mock_global(fn %{url: "#{@base_url}/loans", method: :post} ->
        %Tesla.Env{status: 200, body: @create_loan_response}
      end)

      assert LoanApi.create(@client, @create_loan_attrs) == {:ok, @loan}
    end
  end

  describe "client/2" do
    test "returns a tesla client" do
      decode_content_types = [decode_content_types: ["application/vnd.creditas.v2+json"]]

      expected_configs = [
        {Tesla.Middleware.BaseUrl, :call, [@base_url]},
        {Tesla.Middleware.Headers, :call, [@headers]},
        {Tesla.Middleware.JSON, :call, [decode_content_types]},
        {Tesla.Middleware.Logger, :call, [[filter_headers: ["Authorization"]]]},
        {Tesla.Middleware.Retry, :call, [[delay: 1000, max_retries: 3]]},
        {Tesla.Middleware.Timeout, :call, [[timeout: 120_000]]}
      ]

      assert LoanApi.client(@base_url, @bearer_token) == %Tesla.Client{pre: expected_configs}
    end
  end
end
