defmodule HttpClients.Creditas.AssetsApi.Value do
  @moduledoc false
  alias HttpClients.Creditas.AssetsApi.Amount

  @type t :: %__MODULE__{
          amount: Amount.t()
        }

  @derive Jason.Encoder
  @enforce_keys ~w(amount)a
  defstruct ~w(amount)a
end
