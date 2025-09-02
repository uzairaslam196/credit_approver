defmodule CreditApprover.CreditSummaryTest do
  use ExUnit.Case, async: true

  alias CreditApprover.{CreditSummary, Answer}

  describe "new/5" do
    test "creates a credit summary with all fields" do
      basic_answers = [
        %{question: "Do you have a job?", answer: "yes"},
        %{question: "Do you own a home?", answer: "no"}
      ]

      financial_answers = [
        %{question: "Monthly income?", answer: "5000"},
        %{question: "Monthly expenses?", answer: "2000"}
      ]

      summary = CreditSummary.new(
        "test@example.com",
        basic_answers,
        financial_answers,
        36000,
        true
      )

      assert %CreditSummary{} = summary
      assert summary.recipient_email == "test@example.com"
      assert length(summary.basic_answers) == 2
      assert length(summary.financial_answers) == 2
      assert summary.credit_amount == 36000
      assert summary.approved == true
      assert %DateTime{} = summary.generated_at
    end

    test "converts maps to Answer structs" do
      basic_answers = [%{question: "Test question?", answer: "yes"}]

      summary = CreditSummary.new(
        "test@example.com",
        basic_answers,
        [],
        0,
        false
      )

      [answer] = summary.basic_answers
      assert %Answer{} = answer
      assert answer.question == "Test question?"
      assert answer.answer == "yes"
    end

    test "handles empty answer lists" do
      summary = CreditSummary.new(
        "test@example.com",
        [],
        [],
        0,
        false
      )

      assert summary.basic_answers == []
      assert summary.financial_answers == []
    end

    test "sets generated_at to current UTC time" do
      before = DateTime.utc_now()

      summary = CreditSummary.new("test@example.com", [], [], 0, false)

      after_time = DateTime.utc_now()

      assert DateTime.compare(summary.generated_at, before) in [:gt, :eq]
      assert DateTime.compare(summary.generated_at, after_time) in [:lt, :eq]
    end
  end

  describe "Jason encoding" do
    test "can be encoded to JSON" do
      summary = CreditSummary.new(
        "test@example.com",
        [%{question: "Test?", answer: "yes"}],
        [],
        1000,
        true
      )

      assert {:ok, json} = Jason.encode(summary)
      assert is_binary(json)
      assert String.contains?(json, "test@example.com")
      assert String.contains?(json, "Test?")
    end
  end
end
