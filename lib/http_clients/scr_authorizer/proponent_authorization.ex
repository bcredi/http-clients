defmodule HttpClients.ScrAuthorizer.ProponentAuthorization do
  @moduledoc false

  @type t :: %__MODULE__{
          id: UUID.t(),
          proponent_id: UUID.t(),
          user_agent: String.t(),
          ip: String.t(),
          term_of_use_document: binary()
        }

  @derive Jason.Encoder
  defstruct ~w(id proponent_id user_agent ip term_of_use_document)a
end
