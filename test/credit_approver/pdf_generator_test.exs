defmodule CreditApprover.PDFGeneratorTest do
  use ExUnit.Case, async: true

  alias CreditApprover.{PDFGenerator, CreditSummary}

  describe "generate/2" do
    test "generates PDF for approved credit summary" do
      credit_summary = build_approved_summary()

      assert {:ok, pdf_binary} = PDFGenerator.generate(credit_summary)
      assert is_binary(pdf_binary)
      assert byte_size(pdf_binary) > 0

      # Check PDF header
      assert String.starts_with?(pdf_binary, "%PDF-")
    end

    test "generates PDF for rejected credit summary" do
      credit_summary = build_rejected_summary()

      assert {:ok, pdf_binary} = PDFGenerator.generate(credit_summary)
      assert is_binary(pdf_binary)
      assert byte_size(pdf_binary) > 0

      # Check PDF header
      assert String.starts_with?(pdf_binary, "%PDF-")
    end

    test "handles empty answers gracefully" do
      credit_summary = CreditSummary.new(
        "test@example.com",
        [],
        [],
        0,
        false
      )

      assert {:ok, pdf_binary} = PDFGenerator.generate(credit_summary)
      assert is_binary(pdf_binary)
      assert byte_size(pdf_binary) > 0
    end

    test "accepts custom filename option" do
      credit_summary = build_approved_summary()
      custom_filename = "custom_credit_report.pdf"

      assert {:ok, _pdf_binary} = PDFGenerator.generate(credit_summary, filename: custom_filename)
    end

    test "accepts custom output path option" do
      credit_summary = build_approved_summary()
      custom_path = System.tmp_dir!()

      assert {:ok, _pdf_binary} = PDFGenerator.generate(credit_summary, output_path: custom_path)
    end

    test "returns error tuple on PDF generation failure" do
      # Create a summary with invalid data that might cause ChromicPDF to fail
      credit_summary = %CreditSummary{
        recipient_email: "test@example.com",
        basic_answers: [],
        financial_answers: [],
        credit_amount: 0,
        approved: false,
        generated_at: DateTime.utc_now()
      }

      # Test with invalid output path to force an error
      invalid_path = "/invalid/path/that/does/not/exist"

      assert {:error, reason} = PDFGenerator.generate(credit_summary, output_path: invalid_path)
      assert is_binary(reason)
      assert String.contains?(reason, "PDF generation failed")
    end
  end

  describe "generate!/2" do
    test "returns PDF binary directly on success" do
      credit_summary = build_approved_summary()

      pdf_binary = PDFGenerator.generate!(credit_summary)
      assert is_binary(pdf_binary)
      assert byte_size(pdf_binary) > 0
      assert String.starts_with?(pdf_binary, "%PDF-")
    end

    test "raises exception on failure" do
      credit_summary = build_approved_summary()
      invalid_path = "/invalid/path/that/does/not/exist"

      assert_raise RuntimeError, ~r/PDF generation failed/, fn ->
        PDFGenerator.generate!(credit_summary, output_path: invalid_path)
      end
    end
  end

  describe "PDF content validation" do
    test "generated PDF contains proper structure for approved case" do
      credit_summary = build_approved_summary()

      {:ok, pdf_binary} = PDFGenerator.generate(credit_summary)

      # Basic PDF structure validation
      assert String.starts_with?(pdf_binary, "%PDF-")
      assert String.contains?(pdf_binary, "%%EOF")

      # Check that the PDF is not empty and has content
      assert byte_size(pdf_binary) > 1000  # Reasonable size for our content
    end

    test "handles special characters in answers" do
      basic_answers = [
        %{question: "Do you have a job with <special> characters & symbols?", answer: "Yes & No"},
        %{question: "Income range: $50,000 - $75,000", answer: "\"Approximately\" $60,000"}
      ]

      credit_summary = CreditSummary.new(
        "test@example.com",
        basic_answers,
        [],
        25000,
        true
      )

      assert {:ok, pdf_binary} = PDFGenerator.generate(credit_summary)
      assert is_binary(pdf_binary)
      assert byte_size(pdf_binary) > 0
    end

    test "handles unicode characters properly" do
      basic_answers = [
        %{question: "Ñame with áccents", answer: "José García"},
        %{question: "Currency symbol", answer: "€1,000"}
      ]

      credit_summary = CreditSummary.new(
        "test@example.com",
        basic_answers,
        [],
        15000,
        true
      )

      assert {:ok, pdf_binary} = PDFGenerator.generate(credit_summary)
      assert is_binary(pdf_binary)
      assert byte_size(pdf_binary) > 0
    end
  end

  describe "PDF generation with different credit amounts" do
    test "formats large credit amounts correctly" do
      credit_summary = CreditSummary.new(
        "test@example.com",
        build_basic_answers(),
        build_financial_answers(),
        1_000_000,  # $1,000,000
        true
      )

      assert {:ok, pdf_binary} = PDFGenerator.generate(credit_summary)
      assert is_binary(pdf_binary)
      assert byte_size(pdf_binary) > 0
    end

    test "handles zero credit amount for rejected cases" do
      credit_summary = CreditSummary.new(
        "test@example.com",
        build_basic_answers(),
        [],
        0,
        false
      )

      assert {:ok, pdf_binary} = PDFGenerator.generate(credit_summary)
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
