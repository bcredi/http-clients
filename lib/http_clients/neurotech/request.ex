defmodule HttpClients.Neurotech.Request do
  @moduledoc false

  @type t :: %__MODULE__{
          credentials: HttpClients.Neurotech.Credentials.t(),
          transaction_id: integer(),
          inputs: map()
        }

  defstruct [:credentials, :transaction_id, :inputs]

  defp build_body(%__MODULE__{} = request) do
    %{
      "Properties" => [%{"Key" => "USUARIO", "Value" => "BCREDI"}],
      "Authentication" => %{
        "Login" => request.credentials.login,
        "Password" => request.credentials.password,
        "Properties" => [%{"Key" => "FILIAL_ID", "Value" => "0"}]
      },
      "Submit" => %{
        "Id" => request.transaction_id,
        "Inputs" => build_inputs(request.inputs),
        "Policy" => "BCREDI",
        "ResultingVariable" => "FLX_PRINCIPAL"
      }
    }
  end

  def submit(%Tesla.Client{} = client, %__MODULE__{} = request) do
    client_opts = [
      adapter: [
        ssl_options: [verify: :verify_none],
        recv_timeout: 600_000
      ]
    ]

    request = build_body(request)

    Tesla.post(client, "/submit", request, client_opts)
  end

  defp build_inputs(%{} = inputs) when inputs != %{},
    do: Enum.map(inputs, &build_input/1)

  defp build_input({input_name, input_value}), do: %{"Name" => input_name, "Value" => input_value}
end
