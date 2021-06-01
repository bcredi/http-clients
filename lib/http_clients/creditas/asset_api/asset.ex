defmodule HttpClients.Creditas.AssetApi.Asset do
  @moduledoc false
  alias HttpClients.Creditas.AssetApi.{Owner, Value}

  @type t :: %__MODULE__{
          id: binary(),
          version: integer(),
          type: String.t(),
          owners: List.t(Owner.t()),
          value: Value.t()
        }

  @derive Jason.Encoder
  @enforce_keys ~w(type owners value)a
  defstruct ~w(id version type owners value)a
end
