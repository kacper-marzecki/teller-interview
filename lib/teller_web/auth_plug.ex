defmodule TellerWeb.AuthPlug do
  def init(options), do: options

  def call(%Plug.Conn{} = conn, _opts) do
    authorization = Plug.Conn.get_req_header(conn, "authorization")

    case authorization do
      ["Bearer " <> encoded] ->
        case Base.decode64(encoded) do
          {:ok, raw_auth_string} ->
            with {:ok, token} <- Teller.Token.parse(raw_auth_string) do
              Plug.Conn.assign(conn, :token, token)
            else
              err -> TellerWeb.FallbackController.call(conn, err) |> Plug.Conn.halt()
            end
        end

      _ ->
        TellerWeb.FallbackController.call(conn, {:error, :missing_token}) |> Plug.Conn.halt()
    end
  end
end
