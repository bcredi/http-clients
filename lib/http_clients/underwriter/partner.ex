defmodule HttpClients.Underwriter.Partner do
  @moduledoc false

  @type t :: %__MODULE__{type: String.t(), slug: String.t()}
  @derive Jason.Encoder
  defstruct ~w(type slug)a
end
