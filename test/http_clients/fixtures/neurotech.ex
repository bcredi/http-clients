defmodule HttpClients.Fixtures.Neurotech do
  @moduledoc false
  def check_identity_response(_case)

  def check_identity_response(:approved) do
    %{
      "Result" => %{
        "Result" => "APROVADO"
      },
      "StatusCode" => "0100"
    }
  end

  def check_identity_response(:disapproved) do
    %{
      "Result" => %{
        "Result" => "REPROVADO"
      },
      "StatusCode" => "0100"
    }
  end

  def check_identity_response(:pending) do
    %{
      "Result" => %{
        "Result" => "PENDING"
      },
      "StatusCode" => "0100"
    }
  end

  def bacen_response(_case)

  def bacen_response(:success) do
    %{
      "StatusCode" => "0100",
      "Result" => %{
        "Outputs" => [
          %{
            "Key" => "CALC_BACEN_PONTOS_NEGATIVOS",
            "Value" => "- LIMITE DE CRÉDITO abaixo de R$1.000,00 no histórico.\r\n"
          },
          %{
            "Key" => "CALC_BACEN_PONTOS_POSITIVOS",
            "Value" => "- Sem registro de vencidos no histórico.\r\n"
          },
          %{
            "Key" => "CALC_BCREDISCORE_SCORE",
            "Value" => "444"
          }
        ]
      }
    }
  end

  def bacen_response(:empty_negative_analysis) do
    %{
      "StatusCode" => "0100",
      "Result" => %{
        "Outputs" => [
          %{
            "Key" => "CALC_BACEN_PONTOS_NEGATIVOS",
            "Value" => ""
          },
          %{
            "Key" => "CALC_BACEN_PONTOS_POSITIVOS",
            "Value" => "- Sem registro de vencidos no histórico.\r\n"
          },
          %{
            "Key" => "CALC_BCREDISCORE_SCORE",
            "Value" => "444"
          }
        ]
      }
    }
  end

  def bacen_response(:empty_calc_score) do
    %{
      "StatusCode" => "0100",
      "Result" => %{
        "Outputs" => [
          %{
            "Key" => "CALC_BACEN_PONTOS_NEGATIVOS",
            "Value" => "- LIMITE DE CRÉDITO abaixo de R$1.000,00 no histórico.\r\n"
          },
          %{
            "Key" => "CALC_BACEN_PONTOS_POSITIVOS",
            "Value" => "- Sem registro de vencidos no histórico.\r\n"
          },
          %{
            "Key" => "CALC_BCREDISCORE_SCORE",
            "Value" => ""
          }
        ]
      }
    }
  end
end
