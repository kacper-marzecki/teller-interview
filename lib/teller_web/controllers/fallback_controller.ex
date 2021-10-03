defmodule Teller.FallbackController do
  use TellerWeb, :controller
  require Logger

  def call(conn, {:error, :validation_failure}) do
    conn
    |> put_status(:unprocessable_entity)
    |> Phoenix.Controller.json(%{
      error: %{
        code: "422",
        message: "A request was made with an invalid request body."
      }
    })
  end

  def call(conn, {:error, :missing_token}) do
    conn
    |> put_status(:unauthorized)
    |> Phoenix.Controller.json(%{
      error: %{
        code: "401",
        message: "A request was made without an access token where one was required. "
      }
    })
  end

  def call(conn, {:error, :invalid_token}) do
    conn
    |> put_status(:forbidden)
    |> Phoenix.Controller.json(%{
      error: %{
        code: "403",
        message: "A request was made with an invalid or revoked access token."
      }
    })
  end

  def call(conn, {:error, :not_found}) do
    conn
    |> put_status(:forbidden)
    |> Phoenix.Controller.json(%{
      error: %{
        code: "404",
        message: "Requested resource not found."
      }
    })
  end

  def call(conn, {:error, %Ecto.Changeset{} = changeset}) do
    conn
    |> put_status(:unprocessable_entity)
    |> Phoenix.Controller.json(%{errors: error_strings(changeset)})
  end

  def call(conn, {:error, :not_found}) do
    conn
    |> put_status(:not_found)
    |> Plug.Conn.send_resp(:not_found, [])
  end

  def call(conn, {:error, {:not_found, target}}) do
    conn
    |> put_status(:not_found)
    |> Phoenix.Controller.json(%{errors: ["not found: " <> to_string(target)]})
  end

  def call(conn, err) do
    Logger.error(err)
    Plug.Conn.send_resp(conn, :internal_server_error, "")
  end

  def error_strings(%Ecto.Changeset{} = changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Enum.reduce(opts, msg, fn {key, value}, acc ->
        String.replace(acc, "%{#{key}}", _to_string(value))
      end)
    end)
    |> Enum.map(fn {k, v} ->
      joined_errors = Enum.join(v, "; ")
      "#{joined_errors}: #{k}"
    end)
  end

  defp _to_string(val) when is_list(val) do
    Enum.join(val, ",")
  end

  defp _to_string(val), do: to_string(val)
end
