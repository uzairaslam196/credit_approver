defmodule CreditApprover.Answer do
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

      iex> CreditApprover.Answer.new("Do you have a job?", "yes")
      %CreditApprover.Answer{question: "Do you have a job?", answer: "yes"}

  """
  @spec new(String.t(), String.t()) :: t()
  def new(question, answer) do
    %__MODULE__{
      question: to_string(question),
      answer: to_string(answer)
    }
  end

  @doc """
  Creates an Answer struct from a map.

  ## Examples

      iex> CreditApprover.Answer.from_map(%{question: "Test?", answer: "yes"})
      %CreditApprover.Answer{question: "Test?", answer: "yes"}

      iex> CreditApprover.Answer.from_map({"Test?", "yes"})
      %CreditApprover.Answer{question: "Test?", answer: "yes"}

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
