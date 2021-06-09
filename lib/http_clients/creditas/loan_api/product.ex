defmodule HttpClients.Creditas.LoanApi.Product do
  @moduledoc false

  @type t :: %__MODULE__{
          type: String.t(),
          subtype: String.t()
        }

  @derive Jason.Encoder
  defstruct ~w(type subtype)a
end
