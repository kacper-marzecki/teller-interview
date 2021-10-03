defmodule TellerWeb.AccountsController do
  use TellerWeb, :controller
  action_fallback TellerWeb.FallbackController

  def list_accounts(%Plug.Conn{assigns: %{token: token}} = conn, _params) do
    Phoenix.Controller.json(conn, Teller.Accounts.get_accounts(token))
  end

  def show_account(%Plug.Conn{assigns: %{token: token}} = conn, %{"account_id" => account_id}) do
    IO.puts(token)
    IO.puts(conn)
    IO.puts(account_id)
  end

  def show_account_details(%Plug.Conn{assigns: %{token: token}} = conn, %{
        "account_id" => account_id
      }) do
    IO.puts(token)
    IO.puts(conn)
    IO.puts(account_id)
  end

  def show_account_balances(%Plug.Conn{assigns: %{token: token}} = conn, %{
        "account_id" => account_id
      }) do
    IO.puts(token)
    IO.puts(conn)
    IO.puts(account_id)
  end

  def show_transactions(%Plug.Conn{assigns: %{token: token}} = conn, %{"account_id" => account_id}) do
    IO.puts(token)
    IO.puts(conn)
    IO.puts(account_id)
  end

  def show_transaction(%Plug.Conn{assigns: %{token: token}} = conn, %{
        "account_id" => account_id,
        "transaction_id" => transaction_id
      }) do
    IO.puts(token)
    IO.puts(conn)
    IO.puts(account_id)
    IO.puts(transaction_id)
  end
end
