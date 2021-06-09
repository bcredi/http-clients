defmodule HttpClients.Creditas.LoanApi.Contract do
  @moduledoc false

  @type t :: %__MODULE__{
          number: String.t(),
          issuedAt: Date.t(),
          signedAt: Date.t(),
          protocoledAt: Date.t()
        }

  @derive Jason.Encoder
  @enforce_keys ~w(number issuedAt signedAt)a
  defstruct ~w(number issuedAt signedAt protocoledAt)a
end
