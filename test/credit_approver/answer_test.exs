defmodule CreditApprover.AnswerTest do
  use ExUnit.Case, async: true

  alias CreditApprover.Answer

  describe "new/2" do
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

  describe "from_map/1" do
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

  describe "Jason encoding" do
    test "can be encoded to JSON" do
      answer = Answer.new("Test question?", "yes")

      assert {:ok, json} = Jason.encode(answer)
      assert is_binary(json)
      assert String.contains?(json, "Test question?")
      assert String.contains?(json, "yes")
    end
  end
end
