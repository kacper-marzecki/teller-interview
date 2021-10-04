defmodule Teller.Time do
  @callback utc_today() :: Date.t()
end

defmodule Teller.TimeImpl do
  @behaviour Teller.Time

  @impl Teller.Time
  def utc_today(), do: Date.utc_today()
end
