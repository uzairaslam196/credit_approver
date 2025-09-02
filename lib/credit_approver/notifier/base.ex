defmodule CreditApprover.Notifier.Base do
  @moduledoc """
  Base notifier module with shared email delivery functionality.

  This module provides common email delivery functions that can be
  used by specific email type modules.
  """

  import Swoosh.Email
  alias CreditApprover.Mailer

  @doc """
  Delivers an email with comprehensive logging.

  ## Parameters

    * `email` - The Swoosh.Email struct to deliver
    * `recipient_email` - The recipient's email address for logging
    * `email_type` - Type of email being sent (e.g., "credit_assessment", "welcome")

  ## Returns

    * `{:ok, %Swoosh.Email{}}` - Successfully delivered email
    * `{:error, reason}` - Error during delivery

  ## Examples

      iex> email = new() |> to("user@example.com") |> subject("Test")
      iex> CreditApprover.Notifier.Base.deliver_with_logging(email, "user@example.com", "test")
      {:ok, %Swoosh.Email{}}

  """
  @spec deliver_with_logging(Swoosh.Email.t(), String.t(), String.t()) :: {:ok, Swoosh.Email.t()} | {:error, any()}
  def deliver_with_logging(email, recipient_email, email_type \\ "email") do
    require Logger

    Logger.debug("Attempting to deliver #{email_type} to #{recipient_email}")

    with {:ok, metadata} <- Mailer.deliver(email) do
      Logger.debug("#{String.capitalize(email_type)} delivery successful to #{recipient_email}, metadata: #{inspect(metadata)}")
      {:ok, email}
    else
      {:error, reason} ->
        Logger.error("#{String.capitalize(email_type)} delivery failed to #{recipient_email}: #{inspect(reason)}")
        {:error, "#{String.capitalize(email_type)} delivery failed: #{inspect(reason)}"}
    end
  rescue
    exception ->
      require Logger
      Logger.error("#{String.capitalize(email_type)} delivery exception for #{recipient_email}: #{inspect(exception)}")
      {:error, "#{String.capitalize(email_type)} delivery exception: #{inspect(exception)}"}
  end

  @doc """
  Builds a basic email structure with common headers.

  ## Parameters

    * `to_email` - Recipient's email address
    * `subject` - Email subject line
    * `from_name` - Sender's display name (optional, defaults to "Credit Approver")
    * `from_email` - Sender's email address (optional, defaults to "support@creditapprover.com")

  ## Returns

    * `%Swoosh.Email{}` - Base email struct ready for customization

  ## Examples

      iex> CreditApprover.Notifier.Base.build_base_email("user@example.com", "Test Subject")
      %Swoosh.Email{to: [{"", "user@example.com"}], subject: "Test Subject", ...}

  """
  @spec build_base_email(String.t(), String.t(), String.t(), String.t()) :: Swoosh.Email.t()
  def build_base_email(to_email, subject, from_name \\ "Credit Approver", from_email \\ "support@creditapprover.com") do
    new()
    |> to(to_email)
    |> from({from_name, from_email})
    |> subject(subject)
  end

  @doc """
  Adds a PDF attachment to an email.

  ## Parameters

    * `email` - The Swoosh.Email struct
    * `pdf_binary` - The PDF content as binary
    * `filename` - The attachment filename

  ## Returns

    * `%Swoosh.Email{}` - Email with PDF attachment

  """
  @spec add_pdf_attachment(Swoosh.Email.t(), binary(), String.t()) :: Swoosh.Email.t()
  def add_pdf_attachment(email, pdf_binary, filename) do
    email
    |> attachment(
      Swoosh.Attachment.new({:data, pdf_binary},
        filename: filename,
        content_type: "application/pdf"
      )
    )
  end

  @doc """
  Validates an email address format.

  ## Parameters

    * `email` - Email address to validate

  ## Returns

    * `{:ok, email}` - Valid email
    * `{:error, reason}` - Invalid email

  ## Examples

      iex> CreditApprover.Notifier.Base.validate_email("user@example.com")
      {:ok, "user@example.com"}

      iex> CreditApprover.Notifier.Base.validate_email("invalid-email")
      {:error, "Invalid email format"}

  """
  @spec validate_email(String.t()) :: {:ok, String.t()} | {:error, String.t()}
  def validate_email(email) when is_binary(email) do
    if Regex.match?(~r/^[^@\s]+@[^@\s]+\.[^@\s]+$/, email) do
      {:ok, email}
    else
      {:error, "Invalid email format"}
    end
  end

  def validate_email(_email) do
    {:error, "Email must be a string"}
  end

  @doc """
  Logs the start of an email sending process.

  ## Parameters

    * `email_type` - Type of email being sent
    * `recipient_email` - Recipient's email address
    * `context` - Additional context (optional)

  """
  @spec log_email_start(String.t(), String.t(), map()) :: :ok
  def log_email_start(email_type, recipient_email, context \\ %{}) do
    require Logger

    context_str = if map_size(context) > 0 do
      " with context: #{inspect(context)}"
    else
      ""
    end

    Logger.info("Attempting to send #{email_type} email to #{recipient_email}#{context_str}")
  end

  @doc """
  Logs the successful completion of an email sending process.

  ## Parameters

    * `email_type` - Type of email that was sent
    * `recipient_email` - Recipient's email address

  """
  @spec log_email_success(String.t(), String.t()) :: :ok
  def log_email_success(email_type, recipient_email) do
    require Logger
    Logger.info("Successfully sent #{email_type} email to #{recipient_email}")
  end

  @doc """
  Logs an email sending failure.

  ## Parameters

    * `email_type` - Type of email that failed
    * `recipient_email` - Recipient's email address
    * `reason` - Failure reason

  """
  @spec log_email_failure(String.t(), String.t(), any()) :: :ok
  def log_email_failure(email_type, recipient_email, reason) do
    require Logger
    Logger.error("Failed to send #{email_type} email to #{recipient_email}: #{inspect(reason)}")
  end
end
