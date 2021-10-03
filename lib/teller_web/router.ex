defmodule TellerWeb.Router do
  use TellerWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, {TellerWeb.LayoutView, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
    plug Teller.AuthPlug
  end

  scope "/accounts" do
    pipe_through :api
    get "/", TellerWeb.AccountsController, :list_accounts

    scope "/:account_id" do
      get "/", TellerWeb.AccountsController, :show_account
      get "/details", TellerWeb.AccountsController, :show_account_details
      get "/balances", TellerWeb.AccountsController, :show_account_balances

      scope "/transactions" do
        get "/", TellerWeb.AccountsController, :show_transactions
        get "/:transaction_id", TellerWeb.AccountsController, :show_transaction
      end
    end
  end

  scope "/dashboard" do
    pipe_through :browser
  end
end
