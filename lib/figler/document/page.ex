defmodule Figler.Document.Page do
  @moduledoc "Page metadata retained at the `.fig` document boundary."

  @enforce_keys [:guid]
  defstruct [:guid, :name]

  @type t :: %__MODULE__{
          guid: String.t(),
          name: String.t() | nil
        }
end
