defmodule TellerWeb.RequestCountPlug do
  def init(options), do: options

  def call(%Plug.Conn{} = conn, _opts) do
    Phoenix.PubSub.broadcast!(Teller.PubSub, "requests", {:path_requested, conn.request_path})
    conn
  end
end
