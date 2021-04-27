defmodule HttpClients.Underwriter.Proposal do
  @moduledoc false

  @type t :: %__MODULE__{
          id: binary(),
          sales_stage: String.t(),
          lost_reason: String.t()
        }

  @derive Jason.Encoder
  defstruct ~w(id sales_stage lost_reason)a
end
