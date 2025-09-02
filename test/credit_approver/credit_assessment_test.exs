defmodule CreditApprover.CreditAssessmentTest do
  use ExUnit.Case, async: true

  alias CreditApprover.CreditAssessment.{Answer, CreditSummary}

  describe "Answer.new/2" do
    test "creates an Answer struct with question and answer" do
      answer = Answer.new("Do you have a job?", "yes")

      assert %Answer{} = answer
      assert answer.question == "Do you have a job?"
      assert answer.answer == "yes"
    end

    test "converts non-strings to strings" do
      answer = Answer.new(:question, 42)

      assert answer.question == "question"
      assert answer.answer == "42"
    end
  end

  describe "Answer.from_map/1" do
    test "creates Answer from map with atom keys" do
      map = %{question: "Test question?", answer: "yes"}
      answer = Answer.from_map(map)

      assert %Answer{} = answer
      assert answer.question == "Test question?"
      assert answer.answer == "yes"
    end

    test "creates Answer from map with string keys" do
      map = %{"question" => "Test question?", "answer" => "no"}
      answer = Answer.from_map(map)

      assert %Answer{} = answer
      assert answer.question == "Test question?"
      assert answer.answer == "no"
    end

    test "creates Answer from tuple" do
      tuple = {"Test question?", "maybe"}
      answer = Answer.from_map(tuple)

      assert %Answer{} = answer
      assert answer.question == "Test question?"
      assert answer.answer == "maybe"
    end

    test "raises ArgumentError for invalid input" do
      assert_raise ArgumentError, ~r/Cannot create Answer from/, fn ->
        Answer.from_map("invalid")
      end

      assert_raise ArgumentError, ~r/Cannot create Answer from/, fn ->
        Answer.from_map(%{invalid: "data"})
      end
    end
  end

  describe "Answer.Jason encoding" do
    test "can be encoded to JSON" do
      answer = Answer.new("Test question?", "yes")

      assert {:ok, json} = Jason.encode(answer)
      assert is_binary(json)
      assert String.contains?(json, "Test question?")
      assert String.contains?(json, "yes")
    end
  end

  describe "CreditSummary.new/5" do
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

  describe "CreditSummary.Jason encoding" do
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
