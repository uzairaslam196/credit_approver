defmodule CreditApprover.Notifier.CreditAssessmentEmail do
  @moduledoc """
  Handles credit assessment email generation and sending.

  This module is responsible for:
  - Generating PDF reports from credit summaries
  - Creating HTML and text email content
  - Sending assessment results to users
  """

  alias CreditApprover.PDFGenerator
  alias CreditApprover.CreditAssessment.CreditSummary
  alias CreditApprover.Notifier.Base

  @pdf_filename "credit_assessment_summary.pdf"

  @doc """
  Builds and sends a credit assessment email with PDF attachment.

  ## Parameters

    * `email` - The recipient's email address (string)
    * `basic_question_answers` - List or map of basic questionnaire answers
    * `financial_question_answers` - List or map of financial answers
    * `allot_credit_amount` - The approved credit amount (integer)

  ## Returns

    * `{:ok, %Swoosh.Email{}}` - Successfully sent email
    * `{:error, reason}` - Error during email sending

  ## Examples

      iex> CreditApprover.Notifier.CreditAssessmentEmail.send(
      ...>   "user@example.com",
      ...>   [%{question: "Do you have a paying job?", answer: "yes"}],
      ...>   [%{question: "Monthly Income", answer: "$5000"}],
      ...>   36000
      ...> )
      {:ok, %Swoosh.Email{...}}

  """
  @spec send(String.t(), list(), list(), non_neg_integer()) :: {:ok, Swoosh.Email.t()} | {:error, any()}
  def send(email, basic_question_answers, financial_question_answers, allot_credit_amount) do
    with {:ok, validated_email} <- Base.validate_email(email) do
      Base.log_email_start("credit_assessment", validated_email, %{
        credit_amount: allot_credit_amount,
        approved: allot_credit_amount > 0
      })

      approved = allot_credit_amount > 0

      credit_summary = CreditSummary.new(
        validated_email,
        basic_question_answers,
        financial_question_answers,
        allot_credit_amount,
        approved
      )

      with {:ok, pdf_binary} <- PDFGenerator.generate(credit_summary),
           {:ok, email_struct} <- build_email(credit_summary, pdf_binary),
           {:ok, sent_email} <- Base.deliver_with_logging(email_struct, validated_email, "credit_assessment") do
        Base.log_email_success("credit_assessment", validated_email)
        {:ok, sent_email}
      else
        {:error, reason} = error ->
          Base.log_email_failure("credit_assessment", validated_email, reason)
          error
      end
    else
      {:error, reason} = error ->
        Base.log_email_failure("credit_assessment", email, reason)
        error
    end
  end

  @doc false
  defp build_email(%CreditSummary{} = credit_summary, pdf_binary) do
    try do
      email_body = build_email_html(credit_summary)

      email_struct =
        Base.build_base_email(
          credit_summary.recipient_email,
          "Your Credit Assessment Summary"
        )
        |> Swoosh.Email.html_body(email_body)
        |> Swoosh.Email.text_body(build_text_body(credit_summary))
        |> Base.add_pdf_attachment(pdf_binary, @pdf_filename)

      {:ok, email_struct}
    rescue
      error ->
        {:error, "Failed to build credit assessment email: #{inspect(error)}"}
    end
  end

  @doc false
  defp build_email_html(%CreditSummary{} = credit_summary) do
    status_message = if CreditSummary.approved?(credit_summary), do: "Congratulations!", else: "Assessment Complete"

    """
    <!DOCTYPE html>
    <html lang="en">
      <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Credit Assessment Summary</title>
        <style>
          #{email_styles()}
        </style>
      </head>
      <body>
        <div class="email-container">
          #{email_header(status_message)}
          #{email_credit_section(credit_summary)}
          #{email_summary_section()}
          #{email_footer()}
        </div>
      </body>
    </html>
    """
  end

  @doc false
  defp build_text_body(%CreditSummary{} = credit_summary) do
    status = if CreditSummary.approved?(credit_summary), do: "APPROVED", else: "NOT APPROVED"
    amount_text = if CreditSummary.approved?(credit_summary),
      do: "Credit Amount: #{CreditSummary.formatted_amount(credit_summary)}",
      else: "Credit not approved at this time"

    """
    CREDIT ASSESSMENT SUMMARY

    Status: #{status}
    #{amount_text}

    A detailed PDF summary is attached to this email.

    Thank you for choosing Credit Approver!

    If you have any questions, please contact our support team.
    """
  end

  @doc false
  defp email_styles do
    """
    body {
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Helvetica, Arial, sans-serif;
      line-height: 1.6;
      color: #374151;
      background-color: #f9fafb;
      margin: 0;
      padding: 0;
    }

    .email-container {
      max-width: 600px;
      margin: 0 auto;
      background-color: #ffffff;
      box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);
    }

    .header {
      background: linear-gradient(135deg, #3b82f6 0%, #1e40af 100%);
      color: white;
      padding: 40px 30px;
      text-align: center;
    }

    .header h1 {
      margin: 0;
      font-size: 28px;
      font-weight: 700;
    }

    .header p {
      margin: 10px 0 0 0;
      font-size: 16px;
      opacity: 0.9;
    }

    .content {
      padding: 30px;
    }

    .credit-status {
      text-align: center;
      padding: 25px;
      border-radius: 12px;
      margin-bottom: 30px;
    }

    .credit-status.approved {
      background: linear-gradient(135deg, #ecfdf5 0%, #f0fdf4 100%);
      border: 2px solid #10b981;
    }

    .credit-status.rejected {
      background: linear-gradient(135deg, #fef2f2 0%, #fef7f7 100%);
      border: 2px solid #ef4444;
    }

    .status-badge {
      display: inline-block;
      padding: 8px 16px;
      border-radius: 20px;
      font-size: 12px;
      font-weight: 600;
      text-transform: uppercase;
      letter-spacing: 0.5px;
      margin-bottom: 15px;
    }

    .status-badge.approved {
      background: #10b981;
      color: white;
    }

    .status-badge.rejected {
      background: #ef4444;
      color: white;
    }

    .amount {
      font-size: 32px;
      font-weight: 700;
      margin: 10px 0;
    }

    .amount.approved {
      color: #10b981;
    }

    .amount.rejected {
      color: #ef4444;
      font-size: 20px;
    }

    .summary-section {
      background: #f8fafc;
      border-radius: 8px;
      padding: 25px;
      margin-bottom: 25px;
    }

    .summary-section h2 {
      margin: 0 0 15px 0;
      color: #1e293b;
      font-size: 18px;
      font-weight: 600;
    }

    .footer {
      background: #f1f5f9;
      padding: 30px;
      text-align: center;
      color: #6b7280;
      font-size: 14px;
      border-top: 1px solid #e5e7eb;
    }

    .footer p {
      margin: 5px 0;
    }

    .cta-button {
      display: inline-block;
      background: #3b82f6;
      color: white !important;
      padding: 12px 24px;
      text-decoration: none;
      border-radius: 6px;
      font-weight: 600;
      margin: 15px 0;
    }
    """
  end

  @doc false
  defp email_header(status_message) do
    """
    <div class="header">
      <h1>#{status_message}</h1>
      <p>Your Credit Assessment is Complete</p>
    </div>
    """
  end

  @doc false
  defp email_credit_section(%CreditSummary{} = credit_summary) do
    if CreditSummary.approved?(credit_summary) do
      """
      <div class="content">
        <div class="credit-status approved">
          <div class="status-badge approved">✓ Approved</div>
          <div class="amount approved">#{CreditSummary.formatted_amount(credit_summary)}</div>
          <p style="margin: 0; color: #059669; font-weight: 500;">
            You have been approved for credit up to this amount.
          </p>
        </div>
      </div>
      """
    else
      """
      <div class="content">
        <div class="credit-status rejected">
          <div class="status-badge rejected">✗ Not Approved</div>
          <div class="amount rejected">Credit Not Approved</div>
          <p style="margin: 0; color: #dc2626; font-weight: 500;">
            We are currently unable to issue credit at this time.
          </p>
        </div>
      </div>
      """
    end
  end

  @doc false
  defp email_summary_section do
    """
    <div class="content">
      <div class="summary-section">
        <h2>📄 Detailed Summary</h2>
        <p>A comprehensive PDF summary of your assessment is attached to this email. The document includes:</p>
        <ul style="margin: 10px 0; padding-left: 20px;">
          <li>Your complete questionnaire responses</li>
          <li>Financial information (if applicable)</li>
          <li>Assessment results and credit decision</li>
        </ul>
      </div>
    </div>
    """
  end

  @doc false
  defp email_footer do
    """
    <div class="footer">
      <p><strong>Thank you for choosing Credit Approver!</strong></p>
      <p>If you have any questions about your assessment, please contact our support team.</p>
      <p style="margin-top: 20px; font-size: 12px; color: #9ca3af;">
        This email was sent from an automated system. Please do not reply to this email.
      </p>
    </div>
    """
  end
end
