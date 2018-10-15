defmodule Storage.Account do
  defstruct [:id, :name]

  @type t :: %__MODULE__{
          id: pos_integer,
          name: String.t()
        }
end
