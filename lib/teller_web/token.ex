defmodule Teller.Token do
  defstruct [:seed]

  def parse(raw_auth_string) do
    case raw_auth_string do
      "test_" <> raw_token_with_colon ->
        token_string = String.replace_suffix(raw_token_with_colon, ":", "")

        seed =
          :crypto.hash(:sha, token_string)
          |> Base.encode16()
          |> Integer.parse(16)
          |> then(fn {int, _} -> Integer.mod(int, 100) end)

        {:ok, %{seed: seed}}

      _ ->
        {:error, :invalid_token}
    end
  end
end
