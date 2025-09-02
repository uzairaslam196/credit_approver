defmodule CreditApprover.PDFGenerator do
  @moduledoc """
  Handles PDF generation for credit assessment summaries.

  This module is responsible for generating professional-looking PDFs
  from credit summary data using ChromicPDF.
  """

  alias CreditApprover.{CreditAssessment.CreditSummary, Utils}

  @doc """
  Generates a PDF from a CreditSummary struct.

  ## Parameters

    * `credit_summary` - A `CreditApprover.CreditSummary` struct
    * `opts` - Options keyword list:
      * `:filename` - Custom filename (default: "credit_assessment_summary.pdf")
      * `:output_path` - Custom output path (default: system temp directory)

  ## Returns

    * `{:ok, binary}` - The PDF as binary data
    * `{:error, reason}` - Error tuple if generation fails

  ## Examples

      iex> summary = CreditApprover.CreditSummary.new(...)
      iex> CreditApprover.PDFGenerator.generate(summary)
      {:ok, <<PDF_BINARY>>}

  """
  @spec generate(CreditSummary.t(), keyword()) :: {:ok, binary()} | {:error, any()}
  def generate(%CreditSummary{} = credit_summary, opts \\ []) do
    # Validate Chrome availability before attempting PDF generation
    with :ok <- validate_chrome_browser() do
      # For high-scale applications, prefer memory-based generation
      case Keyword.get(opts, :method, :memory) do
        :memory -> generate_in_memory(credit_summary, opts)
        :file -> generate_with_file(credit_summary, opts)
      end
    else
      {:error, reason} -> {:error, reason}
    end
  end

    # Recommended for production: no file system I/O
  defp generate_in_memory(%CreditSummary{} = credit_summary, _opts) do
    try do
      html = build_html(credit_summary)

      # Generate PDF directly to binary without temp files
      case ChromicPDF.print_to_pdf({:html, html}) do
        {:ok, base64_binary} ->
          # ChromicPDF returns base64 encoded string, decode it to actual binary
          binary = Base.decode64!(base64_binary)
          {:ok, binary}
        {:error, reason} -> {:error, "PDF generation failed: #{inspect(reason)}"}
      end
    rescue
      error ->
        {:error, "PDF generation failed: #{inspect(error)}"}
    end
  end

  # Legacy file-based method with improved safety
  defp generate_with_file(%CreditSummary{} = credit_summary, opts) do
    # Generate unique filename to prevent race conditions
    unique_id = :crypto.strong_rand_bytes(16) |> Base.encode16(case: :lower)
    timestamp = System.system_time(:microsecond)
    filename = "credit_assessment_#{timestamp}_#{unique_id}.pdf"

    output_path = Keyword.get(opts, :output_path, System.tmp_dir!())
    tmpfile = Path.join(output_path, filename)

    try do
      html = build_html(credit_summary)

      case ChromicPDF.print_to_pdf({:html, html}, output: tmpfile) do
        :ok ->
          binary = File.read!(tmpfile)
          File.rm(tmpfile)
          {:ok, binary}

        {:error, reason} ->
          # Cleanup on error
          if File.exists?(tmpfile), do: File.rm(tmpfile)
          {:error, "PDF generation failed: #{inspect(reason)}"}
      end
    rescue
      error ->
        # Ensure cleanup even on exceptions
        if File.exists?(tmpfile), do: File.rm(tmpfile)
        {:error, "PDF generation failed: #{inspect(error)}"}
    end
  end

  @doc """
  Generates a PDF and returns the binary directly.
  Raises an exception if generation fails.

  ## Parameters

    * `credit_summary` - A `CreditApprover.CreditSummary` struct
    * `opts` - Options keyword list (same as `generate/2`)

  ## Returns

    * Binary PDF data

  ## Examples

      iex> summary = CreditApprover.CreditSummary.new(...)
      iex> CreditApprover.PDFGenerator.generate!(summary)
      <<PDF_BINARY>>

  """
  @spec generate!(CreditSummary.t(), keyword()) :: binary()
  def generate!(%CreditSummary{} = credit_summary, opts \\ []) do
    case generate(credit_summary, opts) do
      {:ok, binary} -> binary
      {:error, reason} -> raise "PDF generation failed: #{reason}"
    end
  end

  # Validates that Chrome/Chromium browser is available for PDF generation
  defp validate_chrome_browser do
    chrome_path = Application.get_env(:chromic_pdf, :executable_path)

    cond do
      is_nil(chrome_path) ->
        require Logger
        Logger.error("Chrome/Chromium browser path not configured for PDF generation")
        {:error, "Chrome/Chromium browser not configured. Please install Chrome/Chromium and configure executable_path in config.exs"}

      not File.exists?(chrome_path) ->
        require Logger
        Logger.error("Chrome/Chromium browser not found at: #{chrome_path}")
        {:error, "Chrome/Chromium browser not found at #{chrome_path}. Please install Chrome/Chromium or update the path in config.exs"}

      true ->
        :ok
    end
  end

  @doc false
  defp build_html(%CreditSummary{} = summary) do
    """
    <!DOCTYPE html>
    <html lang="en">
      <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Credit Assessment Summary</title>
        <style>
          #{pdf_styles()}
        </style>
      </head>
      <body>
        <div class="container">
          #{header_section()}
          #{credit_amount_section(summary)}
          #{basic_answers_section(summary.basic_answers)}
          #{financial_answers_section(summary.financial_answers)}
          #{footer_section(summary.generated_at)}
        </div>
      </body>
    </html>
    """
  end

  @doc false
  defp pdf_styles do
    """
    @page {
      size: A4;
      margin: 20mm;
    }

    body {
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Helvetica, Arial, sans-serif;
      background: white;
      color: #1f2937;
      margin: 0;
      padding: 0;
      line-height: 1.6;
    }

    .container {
      max-width: 100%;
      margin: 0;
      background: white;
    }

    .header {
      text-align: center;
      margin-bottom: 30px;
      padding-bottom: 20px;
      border-bottom: 3px solid #3b82f6;
    }

    .header h1 {
      color: #1e40af;
      font-size: 28px;
      margin: 0 0 10px 0;
      font-weight: 700;
    }

    .header .subtitle {
      color: #64748b;
      font-size: 14px;
      margin: 0;
    }

    .credit-section {
      background: linear-gradient(135deg, #ecfdf5 0%, #f0fdf4 100%);
      border: 2px solid #10b981;
      border-radius: 12px;
      padding: 25px;
      text-align: center;
      margin-bottom: 30px;
    }

    .credit-section.rejected {
      background: linear-gradient(135deg, #fef2f2 0%, #fef7f7 100%);
      border-color: #ef4444;
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

    .credit-amount {
      font-size: 36px;
      font-weight: 700;
      color: #10b981;
      margin: 0;
    }

    .credit-amount.rejected {
      color: #ef4444;
      font-size: 24px;
    }

    .section {
      margin-bottom: 30px;
    }

    .section h2 {
      color: #1e293b;
      font-size: 20px;
      font-weight: 600;
      margin: 0 0 15px 0;
      padding-bottom: 8px;
      border-bottom: 2px solid #e2e8f0;
    }

    .answers-grid {
      display: grid;
      gap: 12px;
    }

    .answer-row {
      display: grid;
      grid-template-columns: 1fr auto;
      padding: 12px 16px;
      background: #f8fafc;
      border-radius: 8px;
      border-left: 4px solid #3b82f6;
    }

    .question {
      font-weight: 500;
      color: #374151;
    }

    .answer {
      font-weight: 600;
      color: #1f2937;
      text-align: right;
    }

    .answer.positive {
      color: #059669;
    }

    .answer.negative {
      color: #dc2626;
    }

    .footer {
      margin-top: 40px;
      padding-top: 20px;
      border-top: 1px solid #e5e7eb;
      text-align: center;
      color: #6b7280;
      font-size: 12px;
    }

    .generated-date {
      margin-bottom: 10px;
      font-style: italic;
    }
    """
  end

  @doc false
  defp header_section do
    """
    <div class="header">
      <h1>Credit Assessment Summary</h1>
      <p class="subtitle">Professional Credit Evaluation Report</p>
    </div>
    """
  end

  @doc false
  defp credit_amount_section(%CreditSummary{approved: approved, credit_amount: amount}) do
    if approved do
      """
      <div class="credit-section">
        <div class="status-badge approved">✓ Approved</div>
        <div class="credit-amount">$#{Utils.format_currency(amount)}</div>
        <p style="margin: 10px 0 0 0; color: #059669; font-weight: 500;">
          Congratulations! You have been approved for credit.
        </p>
      </div>
      """
    else
      """
      <div class="credit-section rejected">
        <div class="status-badge rejected">✗ Not Approved</div>
        <div class="credit-amount rejected">Credit Not Approved</div>
        <p style="margin: 10px 0 0 0; color: #dc2626; font-weight: 500;">
          We are currently unable to issue credit at this time.
        </p>
      </div>
      """
    end
  end

  @doc false
  defp basic_answers_section(basic_answers) do
    """
    <div class="section">
      <h2>📋 Assessment Questions</h2>
      <div class="answers-grid">
        #{Enum.map_join(basic_answers, "\n", &answer_row/1)}
      </div>
    </div>
    """
  end

  @doc false
  defp financial_answers_section([]), do: ""

  defp financial_answers_section(financial_answers) do
    """
    <div class="section">
      <h2>💰 Financial Information</h2>
      <div class="answers-grid">
        #{Enum.map_join(financial_answers, "\n", &answer_row/1)}
      </div>
    </div>
    """
  end

  @doc false
  defp answer_row(%{question: question, answer: answer}) do
    answer_class = answer_style_class(answer)
    """
    <div class="answer-row">
      <span class="question">#{escape_html(question)}</span>
      <span class="answer #{answer_class}">#{escape_html(answer)}</span>
    </div>
    """
  end

  @doc false
  defp answer_style_class(answer) do
    cond do
      String.downcase(to_string(answer)) in ["yes", "true"] -> "positive"
      String.downcase(to_string(answer)) in ["no", "false"] -> "negative"
      true -> ""
    end
  end

  @doc false
  defp footer_section(generated_at) do
    formatted_date = Calendar.strftime(generated_at, "%B %d, %Y at %I:%M %p UTC")

    """
    <div class="footer">
      <div class="generated-date">Generated on #{formatted_date}</div>
      <div>Thank you for choosing Credit Approver</div>
    </div>
    """
  end

  @doc false
  defp escape_html(nil), do: ""

  defp escape_html(str) when is_binary(str) do
    str
    |> String.replace("&", "&amp;")
    |> String.replace("<", "&lt;")
    |> String.replace(">", "&gt;")
    |> String.replace("\"", "&quot;")
    |> String.replace("'", "&#39;")
  end

  defp escape_html(other), do: escape_html(to_string(other))
end
