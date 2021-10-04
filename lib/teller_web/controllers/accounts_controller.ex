defmodule TellerWeb.AccountsController do
  use TellerWeb, :controller

  def list_accounts(%Plug.Conn{assigns: %{token: token}} = conn, _params) do
    with {:ok, accounts} <- Teller.Accounts.list_accounts(token) do
      Phoenix.Controller.json(conn, accounts)
    end
  end

  def show_account(%Plug.Conn{assigns: %{token: token}} = conn, %{"account_id" => account_id}) do
    with {:ok, account} <- Teller.Accounts.show_account(account_id, token) do
      Phoenix.Controller.json(conn, account)
    end
  end

  def show_account_details(%Plug.Conn{assigns: %{token: token}} = conn, %{
        "account_id" => account_id
      }) do
    with {:ok, details} <- Teller.Accounts.show_account_details(account_id, token) do
      Phoenix.Controller.json(conn, details)
    end
  end

  def show_account_balances(%Plug.Conn{assigns: %{token: token}} = conn, %{
        "account_id" => account_id
      }) do
    with {:ok, balances} <- Teller.Accounts.show_account_balances(account_id, token) do
      Phoenix.Controller.json(conn, balances)
    end
  end

  def show_transactions(
        %Plug.Conn{assigns: %{token: token}} = conn,
        %{
          "account_id" => account_id
        } = params
      ) do
    count =
      params["count"]
      |> int_param()

    from_id = params["from_id"]

    with {:ok, transactions} <-
           Teller.Accounts.show_transactions(account_id, count, from_id, token) do
      Phoenix.Controller.json(conn, transactions)
    end
  end

  def show_transaction(%Plug.Conn{assigns: %{token: token}} = conn, %{
        "account_id" => account_id,
        "transaction_id" => transaction_id
      }) do
    with {:ok, transaction} <- Teller.Accounts.show_transaction(account_id, transaction_id, token) do
      Phoenix.Controller.json(conn, transaction)
    end
  end

  def int_param(nil), do: nil

  def int_param(str) do
    case Integer.parse(str) do
      :error -> nil
      {int, _} -> int
    end
  end
end
