defmodule Teller.Token do
  defstruct [:seed]

  def parse(raw_auth_string) do
    case raw_auth_string do
      "test_" <> raw_token_with_colon ->
        token_string = String.replace_suffix(raw_token_with_colon, ":", "")

        seed = Teller.Utils.generate_int(token_string, 100)
        {:ok, %{seed: seed}}

      _ ->
        {:error, :invalid_token}
    end
  end
end
