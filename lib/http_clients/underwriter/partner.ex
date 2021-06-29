defmodule HttpClients.Underwriter.Partner do
  @moduledoc false

  @type t :: %__MODULE__{partner_type: String.t(), slug: String.t()}
  @derive Jason.Encoder
  defstruct ~w(partner_type slug)a
end
