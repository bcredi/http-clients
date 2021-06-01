defmodule HttpClients.Creditas.AssetApi.Value do
  @moduledoc false

  @type t :: %__MODULE__{
          amount: Money.t()
        }

  @derive Jason.Encoder
  @enforce_keys ~w(amount)a
  defstruct ~w(amount)a
end
