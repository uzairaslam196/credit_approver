defmodule CreditApprover.Utils do
  @moduledoc """
  Utility functions for the Credit Approver application.
  """

  @doc """
  Formats an integer amount as a currency string with commas.

  ## Examples

      iex> CreditApprover.Utils.format_currency(1000)
      "1,000"

      iex> CreditApprover.Utils.format_currency(24000)
      "24,000"

      iex> CreditApprover.Utils.format_currency(1000000)
      "1,000,000"

  """
  @spec format_currency(integer()) :: String.t()
  def format_currency(amount) when is_integer(amount) do
    amount
    |> Integer.to_string()
    |> String.reverse()
    |> String.replace(~r/(\d{3})(?=\d)/, "\\1,")
    |> String.reverse()
  end
end
