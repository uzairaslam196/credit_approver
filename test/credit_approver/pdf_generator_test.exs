defmodule CreditApprover.PDFGeneratorTest do
  use ExUnit.Case, async: true

  alias CreditApprover.{PDFGenerator}
  alias CreditApprover.CreditAssessment.CreditSummary

  @moduletag capture_log: true

  # Check if Chrome is available before running PDF tests
  setup_all do
    chrome_path = Application.get_env(:chromic_pdf, :executable_path)

    chrome_available =
      chrome_path && File.exists?(chrome_path)

    unless chrome_available do
      IO.puts("""

      🚨 SKIPPING PDF tests: Chrome/Chromium not found at #{inspect(chrome_path)}
      To run PDF tests, install Chrome/Chromium:

      macOS: brew install --cask chromium
      Linux: apt-get install chromium-browser
      """)
    end

    %{chrome_available: chrome_available}
  end

  # Skip PDF tests if Chrome is not available
  setup context do
    unless context.chrome_available do
      {:skip, "Chrome/Chromium browser not available for PDF generation"}
    else
      :ok
    end
  end

  describe "generate/2 - core functionality" do
    test "generates PDF for approved and rejected summaries (memory method default)" do
      # Test approved case
      approved_summary = build_approved_summary()
      assert {:ok, pdf_binary} = PDFGenerator.generate(approved_summary)
      assert is_binary(pdf_binary)
      assert byte_size(pdf_binary) > 0
      assert String.starts_with?(pdf_binary, "%PDF-")

      # Test rejected case in same test to reduce Chrome startups
      rejected_summary = build_rejected_summary()
      assert {:ok, pdf_binary} = PDFGenerator.generate(rejected_summary)
      assert is_binary(pdf_binary)
      assert byte_size(pdf_binary) > 0
      assert String.starts_with?(pdf_binary, "%PDF-")
    end

    test "explicitly uses memory method when specified" do
      credit_summary = build_approved_summary()

      assert {:ok, pdf_binary} = PDFGenerator.generate(credit_summary, method: :memory)
      assert is_binary(pdf_binary)
      assert byte_size(pdf_binary) > 0
      assert String.starts_with?(pdf_binary, "%PDF-")
    end
  end

    describe "generate/2 - file method" do
    test "generates PDF using file method and handles options" do
      credit_summary = build_approved_summary()
      custom_path = System.tmp_dir!()

      # Test basic file method
      assert {:ok, pdf_binary} = PDFGenerator.generate(credit_summary, method: :file)
      assert is_binary(pdf_binary)
      assert byte_size(pdf_binary) > 0
      assert String.starts_with?(pdf_binary, "%PDF-")

      # Test custom output path in same test
      assert {:ok, pdf_binary} = PDFGenerator.generate(credit_summary, method: :file, output_path: custom_path)
      assert is_binary(pdf_binary)
      assert byte_size(pdf_binary) > 0
    end

    test "creates unique filenames for concurrent file generation" do
      credit_summary = build_approved_summary()

      # Reduce concurrency from 5 to 3 to speed up test
      tasks = for _i <- 1..3 do
        Task.async(fn ->
          PDFGenerator.generate(credit_summary, method: :file)
        end)
      end

      results = Task.await_many(tasks, 5_000)

      # All should succeed
      for result <- results do
        assert {:ok, pdf_binary} = result
        assert is_binary(pdf_binary)
        assert byte_size(pdf_binary) > 0
        assert String.starts_with?(pdf_binary, "%PDF-")
      end
    end
  end

  describe "generate/2 - method comparison" do
    test "both methods produce similar PDF output" do
      credit_summary = build_approved_summary()

      {:ok, memory_pdf} = PDFGenerator.generate(credit_summary, method: :memory)
      {:ok, file_pdf} = PDFGenerator.generate(credit_summary, method: :file)

      # Both should be valid PDFs
      assert String.starts_with?(memory_pdf, "%PDF-")
      assert String.starts_with?(file_pdf, "%PDF-")

      # Both should have reasonable sizes
      assert byte_size(memory_pdf) > 1000
      assert byte_size(file_pdf) > 1000

      # PDFs should be similar in size (within 10% variance)
      size_diff = abs(byte_size(memory_pdf) - byte_size(file_pdf))
      max_allowed_diff = max(byte_size(memory_pdf), byte_size(file_pdf)) * 0.1
      assert size_diff <= max_allowed_diff
    end
  end

  describe "generate/2 - error handling" do
    test "handles edge cases and errors" do
      # Test empty answers for both methods
      empty_summary = CreditSummary.new("test@example.com", [], [], 0, false)

      assert {:ok, pdf_binary} = PDFGenerator.generate(empty_summary, method: :memory)
      assert is_binary(pdf_binary)
      assert byte_size(pdf_binary) > 0

      assert {:ok, pdf_binary} = PDFGenerator.generate(empty_summary, method: :file)
      assert is_binary(pdf_binary)
      assert byte_size(pdf_binary) > 0

      # Test file method error handling
      credit_summary = build_approved_summary()
      invalid_path = "/invalid/path/that/does/not/exist"

      assert {:error, reason} = PDFGenerator.generate(credit_summary, method: :file, output_path: invalid_path)
      assert is_binary(reason)
      assert String.contains?(reason, "PDF generation failed")

      # Test malformed data
      malformed_summary = %CreditSummary{
        recipient_email: "test@example.com",
        basic_answers: [%{question: nil, answer: nil}],
        financial_answers: [],
        credit_amount: 0,
        approved: false,
        generated_at: DateTime.utc_now()
      }

      assert {:ok, pdf_binary} = PDFGenerator.generate(malformed_summary, method: :memory)
      assert is_binary(pdf_binary)
      assert byte_size(pdf_binary) > 0
    end
  end

  describe "backward compatibility and options" do
    test "handles legacy options and method differences" do
      credit_summary = build_approved_summary()
      custom_filename = "custom_credit_report.pdf"
      custom_path = System.tmp_dir!()

      # Test legacy filename option with file method
      assert {:ok, _pdf_binary} = PDFGenerator.generate(credit_summary, method: :file, filename: custom_filename)

      # Test legacy output_path option with file method
      assert {:ok, _pdf_binary} = PDFGenerator.generate(credit_summary, method: :file, output_path: custom_path)

      # Test that options are ignored with memory method
      assert {:ok, pdf_binary} = PDFGenerator.generate(credit_summary,
        method: :memory,
        filename: "ignored.pdf",
        output_path: "/ignored/path"
      )
      assert is_binary(pdf_binary)
      assert byte_size(pdf_binary) > 0
    end
  end

  describe "generate!/2" do
    test "works with both methods and handles errors" do
      credit_summary = build_approved_summary()

      # Test memory method (default)
      pdf_binary = PDFGenerator.generate!(credit_summary)
      assert is_binary(pdf_binary)
      assert byte_size(pdf_binary) > 0
      assert String.starts_with?(pdf_binary, "%PDF-")

      # Test explicit memory method
      pdf_binary = PDFGenerator.generate!(credit_summary, method: :memory)
      assert is_binary(pdf_binary)
      assert byte_size(pdf_binary) > 0
      assert String.starts_with?(pdf_binary, "%PDF-")

      # Test file method
      pdf_binary = PDFGenerator.generate!(credit_summary, method: :file)
      assert is_binary(pdf_binary)
      assert byte_size(pdf_binary) > 0
      assert String.starts_with?(pdf_binary, "%PDF-")

      # Test error handling
      invalid_path = "/invalid/path/that/does/not/exist"
      assert_raise RuntimeError, ~r/PDF generation failed/, fn ->
        PDFGenerator.generate!(credit_summary, method: :file, output_path: invalid_path)
      end
    end
  end

  describe "PDF content validation and edge cases" do
    test "validates PDF structure and handles special content" do
      credit_summary = build_approved_summary()

      {:ok, pdf_binary} = PDFGenerator.generate(credit_summary)

      # Basic PDF structure validation
      assert String.starts_with?(pdf_binary, "%PDF-")
      assert String.contains?(pdf_binary, "%%EOF")
      assert byte_size(pdf_binary) > 1000  # Reasonable size for our content

      # Test special characters in answers
      special_answers = [
        %{question: "Do you have a job with <special> characters & symbols?", answer: "Yes & No"},
        %{question: "Income range: $50,000 - $75,000", answer: "\"Approximately\" $60,000"}
      ]

      special_summary = CreditSummary.new("test@example.com", special_answers, [], 25000, true)
      assert {:ok, pdf_binary} = PDFGenerator.generate(special_summary)
      assert is_binary(pdf_binary)
      assert byte_size(pdf_binary) > 0

      # Test unicode characters
      unicode_answers = [
        %{question: "Ñame with áccents", answer: "José García"},
        %{question: "Currency symbol", answer: "€1,000"}
      ]

      unicode_summary = CreditSummary.new("test@example.com", unicode_answers, [], 15000, true)
      assert {:ok, pdf_binary} = PDFGenerator.generate(unicode_summary)
      assert is_binary(pdf_binary)
      assert byte_size(pdf_binary) > 0

      # Test large credit amounts
      large_amount_summary = CreditSummary.new(
        "test@example.com",
        build_basic_answers(),
        build_financial_answers(),
        1_000_000,  # $1,000,000
        true
      )

      assert {:ok, pdf_binary} = PDFGenerator.generate(large_amount_summary)
      assert is_binary(pdf_binary)
      assert byte_size(pdf_binary) > 0
    end
  end

  # Helper functions
  defp build_approved_summary do
    CreditSummary.new(
      "approved@example.com",
      build_basic_answers(),
      build_financial_answers(),
      24000,
      true
    )
  end

  defp build_rejected_summary do
    CreditSummary.new(
      "rejected@example.com",
      build_basic_answers(),
      [],
      0,
      false
    )
  end

  defp build_basic_answers do
    [
      %{question: "Do you have a paying job?", answer: "yes"},
      %{question: "Did you consistently had a paying job for past 12?", answer: "yes"},
      %{question: "Do you own a home?", answer: "yes"},
      %{question: "Do you own a car?", answer: "yes"},
      %{question: "Do you have any additional source of income?", answer: "yes"}
    ]
  end

  defp build_financial_answers do
    [
      %{question: "What is their total monthly income from all income source (in USD)", answer: "1000"},
      %{question: "What are their total monthly expenses (in USD)", answer: "500"}
    ]
  end


end
