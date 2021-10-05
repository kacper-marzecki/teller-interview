defmodule Teller.Transactions do
  @transaction_amounts [
    -6250,
    -4286,
    -4047,
    -4954,
    -2425,
    -9129,
    -571,
    -1653,
    -3928,
    -6480,
    -1740,
    -7563,
    -3407,
    -3221,
    -4072,
    -9391,
    -6872,
    -5491,
    -7402,
    -887
  ]
  @transaction_amounts_size length(@transaction_amounts)
  @transaction_amounts_sum Enum.sum(@transaction_amounts)
  @transactions_per_day [4, 3, 2, 4, 5, 4, 1, 2, 3, 4, 5, 2, 2, 3, 3, 5, 3, 2, 5, 2]

  @transactions_per_day_sum Enum.sum(@transactions_per_day)
  @transactions_per_day_size length(@transactions_per_day)

  @merchants [
    "Uber",
    "Uber Eats",
    "Lyft",
    "Five Guys",
    "In-N-Out Burger",
    "Chick-Fil-A",
    "AMC",
    "Apple",
    "Amazon",
    "Walmart",
    "Target",
    "Hotel Tonight",
    "Misson Ceviche",
    "Caltrain",
    "Wingstop",
    "Slim Chickens",
    "CVS",
    "Duane Reade",
    "Walgreens",
    "McDonald's",
    "Burger King",
    "KFC",
    "Popeye's",
    "Shake Shack",
    "Lowe's",
    "Costco",
    "Kroger",
    "iTunes",
    "Spotify",
    "Best Buy",
    "TJ Maxx",
    "Aldi",
    "Macy's",
    "H.E. Butt",
    "Dollar Tree",
    "Verizon Wireless",
    "Sprint PCS",
    "T-Mobile",
    "Starbucks",
    "7-Eleven",
    "AT&T Wireless",
    "Rite Aid",
    "Nordstrom",
    "Ross",
    "Gap",
    "Bed, Bath & Beyond",
    "J.C. Penney",
    "Subway",
    "O'Reilly",
    "Wendy's",
    "Petsmart",
    "Dick's Sporting Goods",
    "Sears",
    "Staples",
    "Domino's Pizza",
    "Papa John's",
    "IKEA",
    "Office Depot",
    "Foot Locker",
    "Lids",
    "GameStop",
    "Sephora",
    "Panera",
    "Williams-Sonoma",
    "Saks Fifth Avenue",
    "Chipotle Mexican Grill",
    "Neiman Marcus",
    "Jack In The Box",
    "Sonic",
    "Shell"
  ]
  # Date from which we generate transactions, 90 days in the past
  @tx_origin_date Date.new!(2021, 07, 1)
  @app_url Application.compile_env!(:teller, :app_url)
  @time_service Application.get_env(:teller, :time_service, Teller.TimeImpl)

  alias Teller.Utils

  def generate_transactions(%{seed: seed}) do
    offset = Integer.mod(seed, 10)
    starting_balance = 10_000_000

    now = @time_service.utc_today()

    visible_date_start = Date.add(now, -90)
    origin_visible_diff = Date.diff(visible_date_start, @tx_origin_date)

    {transaction_count_up_to_visible, day_offset} =
      if origin_visible_diff > 0 do
        {batches, days} = Utils.floor_and_mod(origin_visible_diff, @transactions_per_day_size)

        transaction_count_up_to_visible =
          @transactions_per_day_sum * batches +
            (Utils.get_stream_from(@transactions_per_day, offset)
             |> Enum.take(days)
             |> Enum.sum())

        {transaction_count_up_to_visible, days + offset}
      else
        {0, offset}
      end

    {transaction_batches_up_to_visible, loose_transactions_up_to_visible} =
      Utils.floor_and_mod(transaction_count_up_to_visible, @transaction_amounts_size)

    transaction_sum_up_to_visible =
      transaction_batches_up_to_visible * @transaction_amounts_sum +
        (Utils.get_stream_from(@transaction_amounts, offset)
         |> Enum.take(loose_transactions_up_to_visible)
         |> Enum.sum())

    #  visible_transaction_amount_stream
    vta_stream =
      Utils.get_stream_from(@transaction_amounts, offset + loose_transactions_up_to_visible)

    #  transactions_per_day_stream
    tpd_stream = Utils.get_stream_from(@transactions_per_day, day_offset)

    visible_dates =
      Stream.iterate(visible_date_start, fn date -> Date.add(date, 1) end)
      # 90 days back + today
      |> Enum.take(91)

    generate_visible_transactions(
      visible_dates,
      vta_stream,
      tpd_stream,
      starting_balance + transaction_sum_up_to_visible,
      seed
    )
  end

  def generate_visible_transactions(visible_dates, vta_stream, tpd_stream, balance_to_date, seed) do
    %{transactions: reverse_transactions} =
      Enum.reduce(
        visible_dates,
        %{
          vta_stream: vta_stream,
          tpd_stream: tpd_stream,
          transactions: [],
          balance: balance_to_date
        },
        fn date, acc ->
          {[transactions_per_day], tpd_stream} = Utils.take_from_stream(acc.tpd_stream, 1)

          {transaction_amounts, vta_stream} =
            Utils.take_from_stream(acc.vta_stream, transactions_per_day)

          {balance, reverse_new_transactions, _} =
            Enum.reduce(transaction_amounts, {acc.balance, [], 0}, fn amount,
                                                                      {balance, transactions,
                                                                       day_transaction_count} ->
              transaction =
                construct_transaction(date, amount, balance, day_transaction_count, seed)

              {transaction.running_balance, [transaction | transactions],
               day_transaction_count + 1}
            end)

          %{
            vta_stream: vta_stream,
            tpd_stream: tpd_stream,
            transactions: reverse_new_transactions ++ acc.transactions,
            balance: balance
          }
        end
      )

    Enum.reverse(reverse_transactions)
  end

  def construct_transaction(date, amount, balance, no_in_day, seed) do
    tx_id = "txn_#{seed}d#{date}n#{no_in_day}"
    organization = Utils.get_at(@merchants, seed + no_in_day)
    counterparty_name = organization |> String.upcase() |> String.replace(" ", "-")

    %{
      account_id: "acc_#{seed}",
      amount: amount,
      date: Date.to_string(date),
      description: organization,
      details: %{
        category: "dining",
        counterparty: %{
          name: counterparty_name,
          type: "organization"
        },
        processing_status: "complete"
      },
      id: tx_id,
      links: %{
        account: "#{@app_url}/accounts/#{"acc_#{seed}"}",
        self: "#{@app_url}/accounts/#{"acc_#{seed}"}/transactions/#{tx_id}"
      },
      running_balance: balance + amount,
      status: "posted",
      type: "card_payment"
    }
  end
end
