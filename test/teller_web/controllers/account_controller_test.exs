defmodule TellerWeb.AccountControllerTest do
  use TellerWeb.ConnCase
  @auth_token Base.encode64("test_1234:")
  import Mox

  setup :verify_on_exit!

  test "doesnt allow unauthenticated access", %{conn: conn} do
    test_unauthorized = fn path ->
      resp =
        conn
        |> get(path)
        |> json_response(401)

      assert %{
               "error" => %{
                 "code" => "401",
                 "message" =>
                   "A request was made without an access token where one was required. "
               }
             } == resp
    end

    [
      "/accounts",
      "/accounts/acc_123",
      "accounts/acc_123/details",
      "accounts/acc_123/balances",
      "accounts/acc_123/transactions",
      "accounts/acc_123/transactions/txn_123"
    ]
    |> Enum.each(test_unauthorized)
  end

  test "returns accounts", %{conn: conn} do
    resp =
      conn
      |> with_token()
      |> get("/accounts")
      |> json_response(200)

    assert resp == [
             %{
               "currency" => "USD",
               "enrollment_id" => "enr_12",
               "id" => "acc_12",
               "institution" => %{"id" => "wells_fargo", "name" => "Wells Fargo"},
               "last_four" => "7092",
               "links" => %{
                 "balances" => "https://public_url.com/accounts/acc_12/balances",
                 "details" => "https://public_url.com/accounts/acc_12/details",
                 "self" => "https://public_url.com/accounts/acc_12",
                 "transactions" => "https://public_url.com/accounts/acc_12/transactions"
               },
               "name" => "Bill Clinton",
               "subtype" => "checking",
               "type" => "depository"
             }
           ]
  end

  test "returns account", %{conn: conn} do
    account = get_account(conn)

    assert conn
           |> with_token()
           |> get("/accounts/#{account["id"]}")
           |> json_response(200) == account
  end

  test "returns 404 for non-existing resources", %{conn: conn} do
    stub_time_service()
    account_id = get_account_id(conn)

    non_existing_account_id = account_id <> "1"

    test_not_found = fn path ->
      assert conn
             |> with_token()
             |> get(path)
             |> json_response(404) == %{
               "error" => %{"code" => "404", "message" => "Requested resource not found."}
             }
    end

    [
      "/accounts/#{non_existing_account_id}",
      "accounts/#{non_existing_account_id}/details",
      "accounts/#{non_existing_account_id}/balances",
      "accounts/#{non_existing_account_id}/transactions",
      "accounts/#{non_existing_account_id}/transactions/txn_123"
    ]
    |> Enum.each(test_not_found)
  end

  test "returns account details", %{conn: conn} do
    account = get_account(conn)

    resp =
      conn
      |> with_token()
      |> get("accounts/#{account["id"]}/details")
      |> json_response(200)

    assert resp == %{
             "account_id" => "acc_12",
             "account_number" => "418061387092",
             "links" => %{
               "account" => "https://public_url.com/accounts/acc_12",
               "self" => "https://public_url.com/accounts/acc_12/details"
             },
             "routing_numbers" => %{"ach" => "61387092"}
           }

    assert resp["account_number"] |> Teller.Utils.last_n_letters(4) == account["last_four"]
  end

  test "returns account balances", %{conn: conn} do
    stub_time_service()
    account_id = get_account_id(conn)
    balances = get_account_balances(conn, %{account_id: account_id})

    assert balances == %{
             "account_id" => account_id,
             "available" => "857068.6",
             "ledger" => "857291.0",
             "links" => %{
               "account" => "https://public_url.com/accounts/acc_12",
               "self" => "https://public_url.com/accounts/acc_12/balances"
             }
           }
  end

  test "returns transactions", %{conn: conn} do
    stub_time_service()
    account = get_account(conn)

    transactions =
      conn
      |> with_token()
      |> get("accounts/#{account["id"]}/transactions")
      |> json_response(200)

    # Schema check
    assert Enum.at(transactions, 0) == %{
             "account_id" => "acc_12",
             "amount" => "-740.2",
             "date" => "2021-07-06",
             "description" => "Misson Ceviche",
             "details" => %{
               "category" => "dining",
               "counterparty" => %{"name" => "MISSON-CEVICHE", "type" => "organization"},
               "processing_status" => "complete"
             },
             "id" => "txn_12d2021-07-06n0",
             "links" => %{
               "account" => "https://public_url.com/accounts/acc_12",
               "self" => "https://public_url.com/accounts/acc_12/transactions/txn_12d2021-07-06n0"
             },
             "running_balance" => "991765.4",
             "status" => "posted",
             "type" => "card_payment"
           }

    test_transactions_add_up(transactions)
  end

  def test_transactions_add_up(transactions) do
    Enum.reverse(transactions)
    |> Enum.reduce(fn tx, next_tx ->
      IO.inspect(next_tx, label: "NEXT")
      IO.inspect(tx, label: "PREV")
      next_balance = next_tx["running_balance"] |> parse_float_string_to_int()
      transaction_amount = next_tx["amount"] |> parse_float_string_to_int()
      previous_balance = tx["running_balance"] |> parse_float_string_to_int()
      IO.inspect(next_balance, label: "next_balance")
      IO.inspect(transaction_amount, label: "transaction_amount")
      IO.inspect(previous_balance, label: "previous_balance")

      assert previous_balance + transaction_amount == next_balance
      tx
    end)
  end

  test "paginates transactions", %{conn: conn} do
    stub_time_service()
    account_id = get_account_id(conn)

    all_transactions =
      conn
      |> with_token()
      |> get("accounts/#{account_id}/transactions")
      |> json_response(200)

    count = 4
    from_id = Enum.at(all_transactions, 10)["id"]
    expected_transactions = Enum.slice(all_transactions, 9..12)

    paginated =
      conn
      |> with_token()
      |> get("accounts/#{account_id}/transactions?count=#{count}&from_id=#{from_id}")
      |> json_response(200)

    assert paginated == expected_transactions
  end

  test "transactions add up to account balance", %{conn: conn} do
    stub_time_service()
    account_id = get_account_id(conn)

    transactions =
      conn
      |> with_token()
      |> get("accounts/#{account_id}/transactions")
      |> json_response(200)

    balances = get_account_balances(conn, %{account_id: account_id})

    assert List.last(transactions)["running_balance"] == balances["available"]
  end

  test "adds new transactions as time passes", %{conn: conn} do
    stub_time_service(Date.new!(2021, 10, 04))

    account_id = get_account_id(conn)

    prev_day_transactions =
      conn
      |> with_token()
      |> get("accounts/#{account_id}/transactions")
      |> json_response(200)

    stub_time_service(Date.new!(2021, 10, 05))

    all_transactions_next_day =
      conn
      |> with_token()
      |> get("accounts/#{account_id}/transactions")
      |> json_response(200)

    {old_transactions, new_transactions} =
      Enum.split_while(all_transactions_next_day, fn tx -> tx["date"] != "2021-10-05" end)

    assert !Enum.empty?(new_transactions)
    Enum.each(old_transactions, fn it -> assert it in prev_day_transactions end)
    assert List.last(old_transactions) == List.last(prev_day_transactions)
    test_transactions_add_up(prev_day_transactions ++ new_transactions)
  end

  defp get_account_balances(conn, params \\ %{}) do
    account_id = Map.get(params, :account_id, get_account_id(conn))

    conn
    |> with_token()
    |> get("accounts/#{account_id}/balances")
    |> json_response(200)
  end

  defp with_token(%Plug.Conn{} = conn) do
    conn
    |> Plug.Conn.put_req_header("authorization", "Bearer #{@auth_token}")
  end

  defp get_account(conn) do
    [account] =
      conn
      |> with_token()
      |> get("/accounts")
      |> json_response(200)

    account
  end

  defp get_account_id(conn) do
    get_account(conn)["id"]
  end

  defp stub_time_service(date \\ Date.new!(2021, 10, 04)) do
    Teller.TimeMock
    |> stub(:utc_today, fn -> date end)
  end

  # Converts a float string to integer no of cents
  def parse_float_string_to_int(str) do
    [int_str, fraction_str] = String.split(str, ".")
    {int, _} = Integer.parse(int_str)

    fraction =
      case String.length(fraction_str) do
        1 ->
          {it, _} = Integer.parse(fraction_str)
          it * 10

        2 ->
          {it, _} = Integer.parse(fraction_str)
          it

        _ ->
          0
      end

    int * 100 +
      if int >= 0 do
        fraction
      else
        -fraction
      end
  end
end
