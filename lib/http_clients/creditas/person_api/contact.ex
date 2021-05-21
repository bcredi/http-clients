defmodule HttpClients.Creditas.PersonApi.Contact do
  @moduledoc false

  @type t :: %__MODULE__{
          channel: String.t(),
          code: String.t(),
          type: String.t()
        }

  @derive Jason.Encoder
  @enforce_keys ~w(channel code type)a
  defstruct ~w(channel code type)a
end
