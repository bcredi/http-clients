defmodule HttpClients.Underwriter.CreditAnalysis do
  @moduledoc false

  @type t :: %__MODULE__{
          warranty_value_status: String.t(),
          warranty_region_status: String.t(),
          warranty_type_status: String.t(),
          pre_qualified: boolean()
        }

  @derive Jason.Encoder
  defstruct ~w(warranty_value_status warranty_region_status warranty_type_status pre_qualified)a
end
