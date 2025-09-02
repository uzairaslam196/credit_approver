defmodule CreditApprover.CreditSummary do
  @moduledoc """
  Struct for representing a complete credit assessment summary.
  """

  @derive Jason.Encoder
  defstruct [
    :recipient_email,
    :basic_answers,
    :financial_answers,
    :credit_amount,
    :approved,
    :generated_at
  ]

  @type t :: %__MODULE__{
          recipient_email: String.t(),
          basic_answers: [CreditApprover.Answer.t()],
          financial_answers: [CreditApprover.Answer.t()],
          credit_amount: non_neg_integer(),
          approved: boolean(),
          generated_at: DateTime.t()
        }

  @doc """
  Creates a new CreditSummary struct.

  ## Examples

      iex> CreditApprover.CreditSummary.new("user@example.com", [], [], 0, false)
      %CreditApprover.CreditSummary{
        recipient_email: "user@example.com",
        basic_answers: [],
        financial_answers: [],
        credit_amount: 0,
        approved: false,
        generated_at: %DateTime{}
      }

  """
  @spec new(String.t(), [map()], [map()], non_neg_integer(), boolean()) :: t()
  def new(recipient_email, basic_answers, financial_answers, credit_amount, approved) do
    %__MODULE__{
      recipient_email: recipient_email,
      basic_answers: Enum.map(basic_answers, &CreditApprover.Answer.from_map/1),
      financial_answers: Enum.map(financial_answers, &CreditApprover.Answer.from_map/1),
      credit_amount: credit_amount,
      approved: approved,
      generated_at: DateTime.utc_now()
    }
  end
end
