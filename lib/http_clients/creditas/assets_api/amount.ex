defmodule HttpClients.Creditas.AssetsApi.Amount do
  @moduledoc false

  @type t :: %__MODULE__{
          currency: String.t(),
          amount: Money.t()
        }

  @derive Jason.Encoder
  @enforce_keys ~w(currency amount)a
  defstruct ~w(currency amount)a
end
