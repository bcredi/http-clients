defmodule HttpClients.Creditas.LoanApi.Participant do
  @moduledoc false

  @type t :: %__MODULE__{
          id: String.t(),
          authId: String.t(),
          creditScore: CreditScore.t(),
          roles: List.t(String.t())
        }

  @derive Jason.Encoder
  @enforce_keys ~w(id authId creditScore roles)a
  defstruct ~w(id authId creditScore roles)a
end
