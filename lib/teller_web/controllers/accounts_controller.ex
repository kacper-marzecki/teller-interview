defmodule TellerWeb.AccountsController do
  use TellerWeb, :controller
  action_fallback TellerWeb.FallbackController
  alias Teller.Accounts

  def list_accounts(%Plug.Conn{assigns: %{token: token}} = conn, _params) do
    Phoenix.Controller.json(conn, Teller.Accounts.list_accounts(token))
  end

  def show_account(%Plug.Conn{assigns: %{token: token}} = conn, %{"account_id" => account_id}) do
    Phoenix.Controller.json(conn, Teller.Accounts.show_account(account_id, token))
  end

  def show_account_details(%Plug.Conn{assigns: %{token: token}} = conn, %{
        "account_id" => account_id
      }) do
    Phoenix.Controller.json(conn, Teller.Accounts.show_account_details(account_id, token))
  end

  def show_account_balances(%Plug.Conn{assigns: %{token: token}} = conn, %{
        "account_id" => account_id
      }) do
    Phoenix.Controller.json(conn, Teller.Accounts.show_account_balances(account_id, token))
  end

  def show_transactions(
        %Plug.Conn{assigns: %{token: token}} = conn,
        %{
          "account_id" => account_id
        } = params
      ) do
    count = params["count"]
    from_id = params["from_id"]

    Phoenix.Controller.json(
      conn,
      Teller.Accounts.show_transactions(account_id, count, from_id, token)
    )
  end

  def show_transaction(%Plug.Conn{assigns: %{token: token}} = conn, %{
        "account_id" => account_id,
        "transaction_id" => transaction_id
      }) do
    Phoenix.Controller.json(
      conn,
      Teller.Accounts.show_transaction(account_id, transaction_id, token)
    )
  end
end
