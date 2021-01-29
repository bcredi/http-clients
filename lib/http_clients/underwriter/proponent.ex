defmodule HttpClients.Underwriter.Proponent do
  @moduledoc false
  @derive Jason.Encoder

  @type t :: %__MODULE__{
          id: binary(),
          birthdate: String.t(),
          email: String.t(),
          cpf: String.t(),
          name: String.t(),
          mobile_phone_number: String.t(),
          proposal_id: binary(),
          added_by_proponent: String.t()
        }

  defstruct ~w(id birthdate email cpf name mobile_phone_number proposal_id added_by_proponent)a
end
