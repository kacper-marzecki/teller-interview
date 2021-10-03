defmodule Teller.Accounts do
  @account_names [
    "My Checking",
    "Jimmy Carter",
    "Ronald Reagan",
    "George H. W. Bush",
    "Bill Clinton",
    "George W. Bush",
    "Barack Obama",
    "Donald Trump"
  ]
  @institutions ["Chase", "Bank of America", "Wells Fargo", "Citibank", "Capital One"]

  @app_url Application.compile_env!(:teller, :app_url)
  # Date from which we generate transactions

  alias Teller.Transactions
  alias Teller.Utils

  def show_transactions(account_id, count, from_id, %{seed: seed}) do
    if is_valid_account(account_id, seed) do
      Transactions.generate_transactions(%{seed: seed})
      |> Enum.map(&prepare_transaction_for_presentation/1)
      |> take_from_transaction_id(from_id)
      |> limit_to_count(count)
    else
      {:error, :not_found}
    end
  end

  def prepare_transaction_for_presentation(tx) do
    %{
      tx
      | amount: Float.to_string(tx.amount / 10),
        running_balance: Float.to_string(tx.running_balance / 10)
    }
  end

  def limit_to_count(transactions, count) do
    if count do
      Enum.take(transactions, count)
    else
      transactions
    end
  end

  def take_from_transaction_id(transactions, from_id) do
    if from_id do
      target_index = Enum.find_index(transactions, fn tx -> tx.id == from_id end)
      first_index_in_batch = Enum.max([target_index - 1, 0])
      Enum.slice(transactions, first_index_in_batch..length(transactions))
    else
      transactions
    end
  end

  def show_transaction(account_id, transaction_id, %{seed: seed}) do
    Transactions.generate_transactions(%{seed: seed})
    |> Enum.map(&prepare_transaction_for_presentation/1)
    |> Enum.find()

    # TODO
    if is_valid_account(account_id, seed) do
    else
      {:error, :not_found}
    end
  end

  def list_accounts(%{seed: seed}) do
    [show_account("acc_#{seed}", %{seed: seed})]
  end

  def show_account(account_id, %{seed: seed}) do
    institution_name = Utils.get_at(@institutions, seed)
    account_name = Utils.get_at(@account_names, seed)

    if is_valid_account(account_id, seed) do
      %{
        currency: "USD",
        enrollment_id: "enr_#{seed}",
        id: account_id,
        institution: %{
          id: institution_id(institution_name),
          name: institution_name
        },
        last_four: generate_account_id(seed) |> Teller.Utils.last_n_letters(4),
        links: %{
          balances: "#{@app_url}/accounts/#{account_id}/balances",
          details: "#{@app_url}/accounts/#{account_id}/details",
          self: "#{@app_url}/accounts/#{account_id}",
          transactions: "#{@app_url}/accounts/#{account_id}/transactions"
        },
        name: account_name,
        subtype: "checking",
        type: "depository"
      }
    else
      {:error, :not_found}
    end
  end

  def show_account_details(account_id, %{seed: seed}) do
    if is_valid_account(account_id, seed) do
      %{
        account_id: account_id,
        account_number: generate_account_id(seed),
        links: %{
          account: "#{@app_url}/accounts/#{account_id}",
          self: "#{@app_url}/accounts/#{account_id}/details"
        },
        routing_numbers: %{
          ach: generate_routing_number(seed)
        }
      }
    else
      {:error, :not_found}
    end
  end

  def show_account_balances(account_id, %{seed: seed}) do
    if is_valid_account(account_id, seed) do
      {available, ledger} = current_available_and_ledger(seed)

      %{
        account_id: account_id,
        available: available,
        ledger: ledger,
        links: %{
          account: "#{@app_url}/accounts/#{account_id}",
          self: "#{@app_url}/accounts/#{account_id}/balances"
        }
      }
    else
      {:error, :not_found}
    end
  end

  def current_available_and_ledger(seed) do
    today = Utils.today_date()
    yesterday = Date.add(today, -1)
    today_str = Date.to_string(today)
    yesterday_str = Date.to_string(yesterday)

    txs =
      Transactions.generate_transactions(%{seed: seed})
      |> Enum.filter(fn tx -> tx.date in [today_str, yesterday_str] end)

    find_min_balance = fn transactions, date ->
      transactions
      |> Enum.filter(fn tx -> tx.date == date end)
      |> Enum.map(fn tx -> tx.running_balance end)
      |> Enum.min()
      |> then(fn balance -> Float.to_string(balance / 10) end)
    end

    {find_min_balance.(txs, today_str), find_min_balance.(txs, yesterday_str)}
  end

  def institution_id(institution_name) do
    institution_name
    |> String.replace(" ", "_")
    |> String.downcase()
  end

  def generate_account_id(seed) do
    Teller.Utils.generate_int(seed, 1_000_000_000_000)
    |> Integer.to_string()
  end

  def generate_routing_number(seed) do
    Teller.Utils.generate_int(seed, 1_000_000_000)
    |> Integer.to_string()
  end

  def is_valid_account(account_id, seed), do: account_id == "acc_#{seed}"
end
