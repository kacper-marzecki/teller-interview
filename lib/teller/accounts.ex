defmodule Teller.Accounts do
  @transaction_amounts [10, 20, 30]
  @transaction_amounts_size length(@transaction_amounts)
  @transaction_amounts_sum Enum.sum(@transaction_amounts)
  @transactions_per_day [1]

  @institutions ["Chase", "Bank of America", "Wells Fargo", "Citibank", "Capital One"]

  def get_transactions(%{seed: seed}) do
    now =
      DateTime.utc_now()
      |> DateTime.to_date()

    start_date = Date.new(2021, 07, 1)
    day_difference = Date.diff(now, start_date)
  end

  def get_accounts(%{seed: seed}) do
    institution_name = get_at(@institutions, seed)
    account_id = "acc_#{seed}"

    [
      %{
        currency: "USD",
        enrollment_id: "enr_#{seed}",
        id: account_id,
        institution: %{
          id: institution_id(institution_name),
          name: institution_name
        },
        last_four: (seed * 27) |> Integer.to_string() |> String.slice(0, 4),
        links: %{
          balances: "https://api.teller.io/accounts/#{account_id}/balances",
          details: "https://api.teller.io/accounts/#{account_id}/details",
          self: "https://api.teller.io/accounts/#{account_id}",
          transactions: "https://api.teller.io/accounts/#{account_id}/transactions"
        },
        name: "#{account_id} Checking",
        subtype: "checking",
        type: "depository"
      }
    ]
  end

  def get_at(list, index) do
    get_stream_from(list, index)
    |> Enum.at(0)
  end

  def get_stream_from(list, index) do
    to_drop = Integer.mod(index, length(list))

    Stream.cycle(list)
    |> Stream.drop(to_drop)
  end

  def institution_id(institution_name) do
    institution_name
    |> String.replace(" ", "_")
    |> String.downcase()
  end
end
