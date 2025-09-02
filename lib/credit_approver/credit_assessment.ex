defmodule CreditApprover.CreditAssessment do
  @moduledoc """
  Data structures for credit assessment workflow.

  This module contains the core data structures used throughout
  the credit assessment process:

  - `Answer` - Question-answer pairs from questionnaires
  - `CreditSummary` - Complete assessment results and metadata
  """

  defmodule Answer do
    @moduledoc """
    Struct for representing a question-answer pair in the credit assessment.
    """

    @derive Jason.Encoder
    defstruct [:question, :answer]

    @type t :: %__MODULE__{
            question: String.t(),
            answer: String.t()
          }

    @doc """
    Creates a new Answer struct.

    ## Examples

        iex> CreditApprover.CreditAssessment.Answer.new("Do you have a job?", "yes")
        %CreditApprover.CreditAssessment.Answer{question: "Do you have a job?", answer: "yes"}

    """
    @spec new(String.t(), String.t()) :: t()
    def new(question, answer) do
      %__MODULE__{
        question: to_string(question),
        answer: to_string(answer)
      }
    end

    @doc """
    Creates an Answer struct from a map or tuple.

    ## Examples

        iex> CreditApprover.CreditAssessment.Answer.from_map(%{question: "Test?", answer: "yes"})
        %CreditApprover.CreditAssessment.Answer{question: "Test?", answer: "yes"}

        iex> CreditApprover.CreditAssessment.Answer.from_map({"Test?", "yes"})
        %CreditApprover.CreditAssessment.Answer{question: "Test?", answer: "yes"}

    """
    @spec from_map(map() | {String.t(), String.t()}) :: t()
    def from_map(%{question: question, answer: answer}) do
      new(question, answer)
    end

    def from_map({question, answer}) do
      new(question, answer)
    end

    def from_map(%{"question" => question, "answer" => answer}) do
      new(question, answer)
    end

    def from_map(other) do
      raise ArgumentError, "Cannot create Answer from: #{inspect(other)}"
    end
  end

  defmodule CreditSummary do
    @moduledoc """
    Struct for representing a complete credit assessment summary.

    Contains all the information needed to generate reports and
    send assessment results to users.
    """

    alias CreditApprover.CreditAssessment.Answer

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
            basic_answers: [Answer.t()],
            financial_answers: [Answer.t()],
            credit_amount: non_neg_integer(),
            approved: boolean(),
            generated_at: DateTime.t()
          }

    @doc """
    Creates a new CreditSummary struct.

    ## Examples

        iex> CreditApprover.CreditAssessment.CreditSummary.new("user@example.com", [], [], 0, false)
        %CreditApprover.CreditAssessment.CreditSummary{
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
        basic_answers: Enum.map(basic_answers, &Answer.from_map/1),
        financial_answers: Enum.map(financial_answers, &Answer.from_map/1),
        credit_amount: credit_amount,
        approved: approved,
        generated_at: DateTime.utc_now()
      }
    end

    @doc """
    Checks if the credit assessment was approved.

    ## Examples

        iex> summary = CreditApprover.CreditAssessment.CreditSummary.new("user@example.com", [], [], 25000, true)
        iex> CreditApprover.CreditAssessment.CreditSummary.approved?(summary)
        true

    """
    @spec approved?(t()) :: boolean()
    def approved?(%__MODULE__{approved: approved}), do: approved

    @doc """
    Gets the formatted credit amount as a string.

    ## Examples

        iex> summary = CreditApprover.CreditAssessment.CreditSummary.new("user@example.com", [], [], 25000, true)
        iex> CreditApprover.CreditAssessment.CreditSummary.formatted_amount(summary)
        "$25,000"

    """
    @spec formatted_amount(t()) :: String.t()
    def formatted_amount(%__MODULE__{credit_amount: amount}) do
      CreditApprover.Utils.format_currency(amount)
    end
  end
end
