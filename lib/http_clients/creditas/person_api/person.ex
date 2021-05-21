defmodule HttpClients.Creditas.PersonApi.Person do
  @moduledoc false

  alias HttpClients.Creditas.PersonApi.{Address, Contact, MainDocument}

  @type t :: %__MODULE__{
          id: binary(),
          fullName: String.t(),
          birthDate: Date.t(),
          contacts: List.t(Contact.t()),
          addresses: List.t(Address.t()),
          mainDocument: MainDocument.t(),
          version: integer(),
          currentVersion: integer()
        }

  @derive Jason.Encoder
  @enforce_keys ~w(fullName birthDate mainDocument)a
  defstruct ~w(id fullName birthDate contacts addresses mainDocument version currentVersion)a
end
