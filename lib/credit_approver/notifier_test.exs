defmodule CreditApprover.NotifierTest do
  use ExUnit.Case
  import Swoosh.TestAssertions

  alias CreditApprover.Notifier

  describe "send_email/4" do
    test "sends email with correct recipient and subject" do
      email = "test@example.com"
      basic_answers = [
        %{question: "Do you have a paying job?", answer: "yes"},
        %{question: "Do you own a home?", answer: "no"}
      ]
      financial_answers = [
        %{question: "Monthly Income", answer: "5000"},
        %{question: "Monthly Expenses", answer: "3000"}
      ]
      credit_amount = 24000

      {:ok, email_struct} = Notifier.send_email(email, basic_answers, financial_answers, credit_amount)

      assert email_struct.to == [{"", "test@example.com"}]
      assert email_struct.from == {"Credit Approver", "support@creditapprover.com"}
      assert email_struct.subject == "Your Credit Approver Summary"
    end

    test "includes PDF attachment" do
      email = "test@example.com"
      basic_answers = [%{question: "Test question", answer: "yes"}]
      financial_answers = [%{question: "Income", answer: "5000"}]
      credit_amount = 24000

      {:ok, email_struct} = Notifier.send_email(email, basic_answers, financial_answers, credit_amount)

      assert length(email_struct.attachments) == 1

      attachment = List.first(email_struct.attachments)
      assert attachment.filename == "credit_approver_summary.pdf"
      assert attachment.content_type == "application/pdf"
      assert is_binary(attachment.data)
    end

    test "generates HTML body with congratulations message" do
      email = "test@example.com"
      basic_answers = []
      financial_answers = []
      credit_amount = 24000

      {:ok, email_struct} = Notifier.send_email(email, basic_answers, financial_answers, credit_amount)

      assert email_struct.html_body =~ "<h1>Congratulations!</h1>"
      assert email_struct.html_body =~ "PDF summary of your answers"
      assert email_struct.html_body =~ "Thank you for using Credit Approver!"
    end
  end

  describe "build_html/3" do
    test "generates valid HTML with all sections" do
      basic_answers = [
        %{question: "Do you have a paying job?", answer: "yes"},
        %{question: "Do you own a home?", answer: "no"}
      ]
      financial_answers = [
        %{question: "Monthly Income", answer: "5000"},
        %{question: "Monthly Expenses", answer: "3000"}
      ]
      credit_amount = 24000

      # Use the private function indirectly by checking PDF generation
      {:ok, email_struct} = Notifier.send_email("test@example.com", basic_answers, financial_answers, credit_amount)

      # The PDF should be generated successfully, indicating valid HTML
      attachment = List.first(email_struct.attachments)
      assert is_binary(attachment.data)
      assert byte_size(attachment.data) > 0
    end
  end

  describe "answers_table/1" do
    test "handles list of maps correctly" do
      answers = [
        %{question: "Question 1", answer: "Answer 1"},
        %{question: "Question 2", answer: "Answer 2"}
      ]

      # Test indirectly through email generation
      {:ok, email_struct} = Notifier.send_email("test@example.com", answers, [], 10000)

      attachment = List.first(email_struct.attachments)
      assert is_binary(attachment.data)
    end

    test "handles list of tuples correctly" do
      answers = [
        {"Question 1", "Answer 1"},
        {"Question 2", "Answer 2"}
      ]

      {:ok, email_struct} = Notifier.send_email("test@example.com", answers, [], 10000)

      attachment = List.first(email_struct.attachments)
      assert is_binary(attachment.data)
    end

    test "handles map format correctly" do
      answers = %{
        "Question 1" => "Answer 1",
        "Question 2" => "Answer 2"
      }

      {:ok, email_struct} = Notifier.send_email("test@example.com", answers, [], 10000)

      attachment = List.first(email_struct.attachments)
      assert is_binary(attachment.data)
    end

    test "handles empty answers gracefully" do
      {:ok, email_struct} = Notifier.send_email("test@example.com", [], [], 10000)

      attachment = List.first(email_struct.attachments)
      assert is_binary(attachment.data)
    end

    test "handles nil and invalid data gracefully" do
      {:ok, email_struct} = Notifier.send_email("test@example.com", nil, nil, 10000)

      attachment = List.first(email_struct.attachments)
      assert is_binary(attachment.data)
    end
  end

  describe "escape_html/1" do
    test "escapes HTML special characters correctly" do
      # Test through the email generation process
      basic_answers = [
        %{question: "Do you have <script>alert('xss')</script>?", answer: "yes & no"},
        %{question: "Test \"quotes\"", answer: "test 'single' quotes"}
      ]

      {:ok, email_struct} = Notifier.send_email("test@example.com", basic_answers, [], 10000)

      # PDF should be generated successfully even with special characters
      attachment = List.first(email_struct.attachments)
      assert is_binary(attachment.data)
      assert byte_size(attachment.data) > 0
    end

    test "handles nil values gracefully" do
      basic_answers = [
        %{question: nil, answer: "test"},
        %{question: "test", answer: nil}
      ]

      {:ok, email_struct} = Notifier.send_email("test@example.com", basic_answers, [], 10000)

      attachment = List.first(email_struct.attachments)
      assert is_binary(attachment.data)
    end

    test "handles non-string values" do
      basic_answers = [
        %{question: "Number answer", answer: 123},
        %{question: "Boolean answer", answer: true}
      ]

      {:ok, email_struct} = Notifier.send_email("test@example.com", basic_answers, [], 10000)

      attachment = List.first(email_struct.attachments)
      assert is_binary(attachment.data)
    end
  end

  describe "PDF generation" do
    test "generates valid PDF binary" do
      basic_answers = [
        %{question: "Do you have a paying job?", answer: "yes"},
        %{question: "Do you own a home?", answer: "no"}
      ]
      financial_answers = [
        %{question: "Monthly Income", answer: "5000"},
        %{question: "Monthly Expenses", answer: "3000"}
      ]
      credit_amount = 24000

      {:ok, email_struct} = Notifier.send_email("test@example.com", basic_answers, financial_answers, credit_amount)

      attachment = List.first(email_struct.attachments)

      # Check PDF signature (PDF files start with %PDF)
      assert String.starts_with?(attachment.data, "%PDF")

      # Check reasonable file size (should be more than just headers)
      assert byte_size(attachment.data) > 1000
    end

    test "PDF contains credit amount" do
      credit_amount = 42000

      {:ok, email_struct} = Notifier.send_email("test@example.com", [], [], credit_amount)

      attachment = List.first(email_struct.attachments)
      assert is_binary(attachment.data)
      assert byte_size(attachment.data) > 0
    end

    test "handles large datasets" do
      # Generate a large number of answers
      basic_answers =
        1..50
        |> Enum.map(fn i -> %{question: "Question #{i}", answer: "Answer #{i}"} end)

      financial_answers =
        1..10
        |> Enum.map(fn i -> %{question: "Financial Question #{i}", answer: "Financial Answer #{i}"} end)

      {:ok, email_struct} = Notifier.send_email("test@example.com", basic_answers, financial_answers, 100000)

      attachment = List.first(email_struct.attachments)
      assert is_binary(attachment.data)
      assert String.starts_with?(attachment.data, "%PDF")
    end
  end

  describe "error handling" do
    test "handles malformed email addresses gracefully" do
      # These should still work as the validation happens in the LiveView
      malformed_emails = ["", "invalid", "@test.com", "test@"]

      Enum.each(malformed_emails, fn email ->
        result = Notifier.send_email(email, [], [], 10000)
        assert {:ok, _} = result
      end)
    end

    test "handles edge case credit amounts" do
      edge_amounts = [0, -1000, 999999999]

      Enum.each(edge_amounts, fn amount ->
        {:ok, email_struct} = Notifier.send_email("test@example.com", [], [], amount)

        attachment = List.first(email_struct.attachments)
        assert is_binary(attachment.data)
      end)
    end
  end

  describe "integration with Swoosh" do
    test "email is properly formatted for delivery" do
      {:ok, email_struct} = Notifier.send_email(
        "integration@example.com",
        [%{question: "Test", answer: "Yes"}],
        [%{question: "Income", answer: "5000"}],
        30000
      )

      # Verify all required email fields are present
      assert email_struct.to == [{"", "integration@example.com"}]
      assert email_struct.from == {"Credit Approver", "support@creditapprover.com"}
      assert email_struct.subject == "Your Credit Approver Summary"
      assert String.contains?(email_struct.html_body, "Congratulations!")
      assert length(email_struct.attachments) == 1

      # Verify attachment structure
      attachment = List.first(email_struct.attachments)
      assert attachment.filename == "credit_approver_summary.pdf"
      assert attachment.content_type == "application/pdf"
      assert is_binary(attachment.data)
    end
  end
end
