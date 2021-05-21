defmodule HttpClients.Creditas.PersonApi.Person do
  @moduledoc false

  alias HttpClients.Creditas.PersonApi.{Address, Contact, MainDocument}

  @type t :: %__MODULE__{
          fullName: String.t(),
          birthDate: Date.t(),
          contacts: List.t(Contact.t()),
          addresses: List.t(Address.t()),
          mainDocument: MainDocument.t()
        }

  @enforce_keys ~w(fullName birthDate mainDocument)a
  @derive Jason.Encoder
  defstruct ~w(fullName birthDate contacts addresses mainDocument)a
end
