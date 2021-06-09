defmodule HttpClients.Creditas.PersonApi.Address do
  @moduledoc false

  @type t :: %__MODULE__{
          type: String.t(),
          country: String.t(),
          street: String.t(),
          number: String.t(),
          zipCode: String.t(),
          neighborhood: String.t(),
          complement: String.t(),
          administrativeAreaLevel1: String.t(),
          administrativeAreaLevel2: String.t()
        }

  @derive Jason.Encoder
  @enforce_keys ~w(type country)a
  defstruct ~w(type country street number zipCode neighborhood complement administrativeAreaLevel1 administrativeAreaLevel2)a
end
