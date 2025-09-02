defmodule CreditApprover.Notifier do
  @moduledoc """
  Main notification interface for Credit Approver.

  This module serves as the primary interface for sending different types
  of notifications. It delegates to specific email modules while maintaining
  backward compatibility.

  ## Features

    * Centralized notification interface
    * Delegates to specialized email modules
    * Maintains backward compatibility
    * Provides generic notification utilities

  ## Example

      iex> CreditApprover.Notifier.send_credit_assessment_email(
      ...>   "user@example.com",
      ...>   [%{question: "Do you have a paying job?", answer: "yes"}],
      ...>   [%{question: "Monthly Income", answer: "$5000"}],
      ...>   36000
      ...> )
      {:ok, %Swoosh.Email{...}}

  """

  alias CreditApprover.Notifier.CreditAssessmentEmail

  @doc """
  Sends a credit assessment email with PDF summary.

  Delegates to the specialized CreditAssessmentEmail module.

  ## Parameters

    * `email` - The recipient's email address (string)
    * `basic_question_answers` - List or map of basic questionnaire answers
    * `financial_question_answers` - List or map of financial answers
    * `allot_credit_amount` - The approved credit amount (integer)

  ## Returns

    * `{:ok, %Swoosh.Email{}}` - Successfully sent email
    * `{:error, reason}` - Error during email sending

  ## Example

      iex> CreditApprover.Notifier.send_credit_assessment_email(
      ...>   "user@example.com",
      ...>   [%{question: "Do you have a paying job?", answer: "yes"}],
      ...>   [%{question: "Monthly Income", answer: "$5000"}],
      ...>   36000
      ...> )
      {:ok, %Swoosh.Email{...}}

  """
  @spec send_credit_assessment_email(String.t(), list(), list(), non_neg_integer()) ::
    {:ok, Swoosh.Email.t()} | {:error, any()}
  def send_credit_assessment_email(email, basic_question_answers, financial_question_answers, allot_credit_amount) do
    CreditAssessmentEmail.send(email, basic_question_answers, financial_question_answers, allot_credit_amount)
  end
end
