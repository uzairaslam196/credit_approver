defmodule CreditApproverWeb.CreditCalculatorTest do
  use CreditApproverWeb.ConnCase

  import Phoenix.LiveViewTest
  import Swoosh.TestAssertions

  alias CreditApproverWeb.CreditCalculator

  # Questions with their point values for reference
  @questionnaire [
    %{question: "Do you have a paying job?", points: 4},
    %{question: "Did you consistently had a paying job for past 12?", points: 2},
    %{question: "Do you own a home?", points: 2},
    %{question: "Do you own a car?", points: 1},
    %{question: "Do you have any additional source of income?", points: 2}
  ]

  describe "mount/3" do
    test "initializes with correct default state", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/credit_calculator")

      assert has_element?(view, "[data-phx-main]")

      # Check initial state
      assert view.assigns.earned_points == 0
      assert view.assigns.answers == %{}
      assert view.assigns.financial_answers == %{}
      assert view.assigns.current_step == 0
      assert view.assigns.allot_credit_amount == 0
      assert view.assigns.email_valid == false
      assert view.assigns.email_message == ""
      assert view.assigns.show_mailbox == false
      assert view.assigns.current_question == Enum.at(@questionnaire, 0)
    end

    test "displays first question on mount", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/credit_calculator")

      assert html =~ "Question 1"
      assert html =~ "of 5"
      assert html =~ "Do you have a paying job?"
    end
  end

  describe "questionnaire navigation" do
    test "progresses through all questions with 'yes' answers", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/credit_calculator")

      # Answer all questions with "yes"
      Enum.with_index(@questionnaire, fn {question, _points}, index ->
        # Check current question is displayed
        assert render(view) =~ "Question #{index + 1}"
        assert render(view) =~ question.question

        # Answer "yes" to current question
        view
        |> form("form", %{"answer" => "yes", "step" => "#{index}"})
        |> render_submit()

        # Check earned points calculation
        expected_points =
          @questionnaire
          |> Enum.take(index + 1)
          |> Enum.sum(& &1.points)

        assert view.assigns.earned_points == expected_points
        assert view.assigns.answers[index] == "yes"

        if index < length(@questionnaire) - 1 do
          # Should show next question
          next_question = Enum.at(@questionnaire, index + 1)
          assert render(view) =~ next_question.question
        end
      end)

      # After all questions answered with "yes", should show financial form
      assert view.assigns.earned_points == 11  # Sum of all points: 4+2+2+1+2
      assert render(view) =~ "What is your total monthly income"
      assert render(view) =~ "What are your total monthly expenses"
    end

    test "progresses through all questions with 'no' answers", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/credit_calculator")

      # Answer all questions with "no"
      Enum.with_index(@questionnaire, fn {question, _points}, index ->
        assert render(view) =~ question.question

        view
        |> form("form", %{"answer" => "no", "step" => "#{index}"})
        |> render_submit()

        assert view.assigns.earned_points == 0  # No points for "no" answers
        assert view.assigns.answers[index] == "no"
      end)

      # After all questions answered with "no", should show thank you message
      assert view.assigns.earned_points == 0
      assert render(view) =~ "Thank you for completing the questionnaire!"
      assert render(view) =~ "Earned Points: 0"
    end

    test "navigation works correctly with previous button", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/credit_calculator")

      # Answer first question
      view
      |> form("form", %{"answer" => "yes", "step" => "0"})
      |> render_submit()

      # Should be on question 2
      assert render(view) =~ "Question 2"
      assert render(view) =~ @questionnaire |> Enum.at(1) |> Map.get(:question)

      # Click previous button
      view
      |> element("button[phx-click='prev_step']")
      |> render_click(%{"step" => "1"})

      # Should be back on question 1
      assert render(view) =~ "Question 1"
      assert render(view) =~ @questionnaire |> Enum.at(0) |> Map.get(:question)

      # Previous answer should be preserved
      assert view.assigns.answers[0] == "yes"
    end

    test "previous button is disabled on first question", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/credit_calculator")

      assert has_element?(view, "button[phx-click='prev_step'][disabled]")
    end
  end

  describe "point calculation logic" do
    test "calculates points correctly for mixed answers", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/credit_calculator")

      # Answer pattern: yes, no, yes, no, yes
      # Expected points: 4 + 0 + 2 + 0 + 2 = 8
      answers = ["yes", "no", "yes", "no", "yes"]

      Enum.with_index(answers, fn answer, index ->
        view
        |> form("form", %{"answer" => answer, "step" => "#{index}"})
        |> render_submit()
      end)

      assert view.assigns.earned_points == 8
      assert %{0 => "yes", 1 => "no", 2 => "yes", 3 => "no", 4 => "yes"} = view.assigns.answers
    end

    test "points calculation updates when changing previous answers", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/credit_calculator")

      # Answer first question "yes" (4 points)
      view
      |> form("form", %{"answer" => "yes", "step" => "0"})
      |> render_submit()

      assert view.assigns.earned_points == 4

      # Go to second question and answer "yes" (2 points)
      view
      |> form("form", %{"answer" => "yes", "step" => "1"})
      |> render_submit()

      assert view.assigns.earned_points == 6

      # Go back to first question
      view
      |> element("button[phx-click='prev_step']")
      |> render_click(%{"step" => "1"})

      # Change first answer to "no"
      view
      |> form("form", %{"answer" => "no", "step" => "0"})
      |> render_submit()

      # Points should be recalculated: 0 + 2 = 2
      assert view.assigns.earned_points == 2
    end
  end

  describe "credit approval threshold" do
    test "shows financial form when points >= 6", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/credit_calculator")

      # Answer to get exactly 6 points: job (4) + consistent job (2) = 6
      view
      |> form("form", %{"answer" => "yes", "step" => "0"})  # job: +4
      |> render_submit()

      view
      |> form("form", %{"answer" => "yes", "step" => "1"})  # consistent job: +2
      |> render_submit()

      view
      |> form("form", %{"answer" => "no", "step" => "2"})   # home: +0
      |> render_submit()

      view
      |> form("form", %{"answer" => "no", "step" => "3"})   # car: +0
      |> render_submit()

      view
      |> form("form", %{"answer" => "no", "step" => "4"})   # additional income: +0
      |> render_submit()

      assert view.assigns.earned_points == 6
      assert render(view) =~ "What is your total monthly income"
      assert render(view) =~ "What are your total monthly expenses"
      assert render(view) =~ "Submit Financials"
    end

    test "shows thank you message when points < 6", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/credit_calculator")

      # Answer to get 5 points: job (4) + car (1) = 5
      view
      |> form("form", %{"answer" => "yes", "step" => "0"})  # job: +4
      |> render_submit()

      view
      |> form("form", %{"answer" => "no", "step" => "1"})   # consistent job: +0
      |> render_submit()

      view
      |> form("form", %{"answer" => "no", "step" => "2"})   # home: +0
      |> render_submit()

      view
      |> form("form", %{"answer" => "yes", "step" => "3"})  # car: +1
      |> render_submit()

      view
      |> form("form", %{"answer" => "no", "step" => "4"})   # additional income: +0
      |> render_submit()

      assert view.assigns.earned_points == 5
      assert render(view) =~ "Thank you for completing the questionnaire!"
      assert render(view) =~ "Earned Points: 5"
      refute render(view) =~ "What is your total monthly income"
    end
  end

  describe "financial questions flow" do
    setup %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/credit_calculator")

      # Answer questions to reach 6+ points
      view
      |> form("form", %{"answer" => "yes", "step" => "0"})  # job: +4
      |> render_submit()

      view
      |> form("form", %{"answer" => "yes", "step" => "1"})  # consistent job: +2
      |> render_submit()

      view
      |> form("form", %{"answer" => "no", "step" => "2"})   # home: +0
      |> render_submit()

      view
      |> form("form", %{"answer" => "no", "step" => "3"})   # car: +0
      |> render_submit()

      view
      |> form("form", %{"answer" => "no", "step" => "4"})   # additional income: +0
      |> render_submit()

      %{view: view}
    end

    test "submits financial information and calculates credit amount", %{view: view} do
      monthly_income = "5000"
      monthly_expenses = "3000"
      expected_credit = (5000 - 3000) * 12  # 24000

      view
      |> form("form", %{"monthly_income" => monthly_income, "monthly_expenses" => monthly_expenses})
      |> render_submit()

      assert view.assigns.allot_credit_amount == expected_credit
      assert %{"monthly_income" => ^monthly_income, "monthly_expenses" => ^monthly_expenses} = view.assigns.financial_answers

      # Should show congratulations page
      assert render(view) =~ "Congratulations!"
      assert render(view) =~ "You have been approved for credit up to"
      assert render(view) =~ "$#{expected_credit}"
      assert render(view) =~ "Enter your email address"
    end

    test "handles financial calculation with different amounts", %{view: view} do
      test_cases = [
        {6000, 2000, 48000},    # Good income ratio
        {4000, 3500, 6000},     # Lower surplus
        {3000, 2000, 12000},    # Moderate case
        {10000, 5000, 60000}    # High income case
      ]

      Enum.each(test_cases, fn {income, expenses, expected} ->
        # Reset the state
        send(view.pid, {:reset_credit_amount})

        view
        |> form("form", %{"monthly_income" => "#{income}", "monthly_expenses" => "#{expenses}"})
        |> render_submit()

        assert view.assigns.allot_credit_amount == expected
      end)
    end

    test "handles zero or negative credit calculation", %{view: view} do
      # Expenses equal to income
      view
      |> form("form", %{"monthly_income" => "3000", "monthly_expenses" => "3000"})
      |> render_submit()

      assert view.assigns.allot_credit_amount == 0

      # Reset and test expenses higher than income
      send(view.pid, {:reset_credit_amount})

      view
      |> form("form", %{"monthly_income" => "2000", "monthly_expenses" => "3000"})
      |> render_submit()

      assert view.assigns.allot_credit_amount == -12000
    end
  end

  describe "email functionality" do
    setup %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/credit_calculator")

      # Complete questionnaire and financials to reach approval state
      view
      |> form("form", %{"answer" => "yes", "step" => "0"})
      |> render_submit()

      view
      |> form("form", %{"answer" => "yes", "step" => "1"})
      |> render_submit()

      view
      |> form("form", %{"answer" => "yes", "step" => "2"})
      |> render_submit()

      view
      |> form("form", %{"answer" => "no", "step" => "3"})
      |> render_submit()

      view
      |> form("form", %{"answer" => "no", "step" => "4"})
      |> render_submit()

      view
      |> form("form", %{"monthly_income" => "5000", "monthly_expenses" => "3000"})
      |> render_submit()

      %{view: view}
    end

    test "validates email format correctly", %{view: view} do
      # Test invalid emails
      invalid_emails = ["", "invalid", "test@", "@test.com", "test.com", "test@test"]

      Enum.each(invalid_emails, fn email ->
        view
        |> form("form", %{"email" => email})
        |> render_change()

        assert view.assigns.email_valid == false
        assert view.assigns.email_message != "Email looks good!"
      end)

      # Test valid email
      view
      |> form("form", %{"email" => "test@example.com"})
      |> render_change()

      assert view.assigns.email_valid == true
      assert view.assigns.email_message == "Email looks good!"
    end

    test "sends email with correct information", %{view: view} do
      email = "test@example.com"

      view
      |> form("form", %{"email" => email})
      |> render_submit()

      # Check that email was attempted to be sent
      assert view.assigns.show_mailbox == true
      assert has_element?(view, "a[href='/dev/mailbox']")

      # Verify flash message
      assert render(view) =~ "Email has been sent please check!"
    end

    test "email contains all questionnaire answers", %{view: view} do
      # This test verifies the data structure passed to the notifier
      expected_basic_answers = [
        %{question: "Do you have a paying job?", answer: "yes"},
        %{question: "Did you consistently had a paying job for past 12?", answer: "yes"},
        %{question: "Do you own a home?", answer: "yes"},
        %{question: "Do you own a car?", answer: "no"},
        %{question: "Do you have any additional source of income?", answer: "no"}
      ]

      expected_financial_answers = [
        %{question: "What is your total monthly income from all income sources (in USD)?", answer: "5000"},
        %{question: "What are your total monthly expenses (in USD)?", answer: "3000"}
      ]

      email = "test@example.com"

      # Mock the Notifier to capture the arguments
      original_notifier = Application.get_env(:credit_approver, :notifier, CreditApprover.Notifier)

      test_pid = self()
      mock_notifier = fn email, basic, financial, amount ->
        send(test_pid, {:email_sent, email, basic, financial, amount})
        {:ok, %{}}
      end

      Application.put_env(:credit_approver, :notifier, mock_notifier)

      view
      |> form("form", %{"email" => email})
      |> render_submit()

      # Restore original notifier
      Application.put_env(:credit_approver, :notifier, original_notifier)

      # Verify the email content
      assert_received {:email_sent, ^email, basic_answers, financial_answers, 24000}

      assert Enum.all?(expected_basic_answers, fn expected ->
        Enum.any?(basic_answers, fn actual ->
          actual.question == expected.question && actual.answer == expected.answer
        end)
      end)

      assert Enum.all?(expected_financial_answers, fn expected ->
        Enum.any?(financial_answers, fn actual ->
          actual.question == expected.question && actual.answer == expected.answer
        end)
      end)
    end
  end

  describe "edge cases and error handling" do
    test "handles invalid step values in next_step", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/credit_calculator")

      # Test with invalid step
      view
      |> form("form", %{"answer" => "yes", "step" => "invalid"})
      |> render_submit()

      # Should treat invalid step as 0
      assert view.assigns.current_step == 1
    end

    test "handles invalid step values in prev_step", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/credit_calculator")

      # Go to second question first
      view
      |> form("form", %{"answer" => "yes", "step" => "0"})
      |> render_submit()

      # Test with invalid step in prev_step
      view
      |> element("button[phx-click='prev_step']")
      |> render_click(%{"step" => "invalid"})

      # Should handle gracefully
      assert view.assigns.current_step >= 0
    end

    test "handles missing financial data gracefully", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/credit_calculator")

      # Reach financial stage
      Enum.with_index(@questionnaire, fn _question, index ->
        view
        |> form("form", %{"answer" => "yes", "step" => "#{index}"})
        |> render_submit()
      end)

      # Try to submit empty financial form
      assert_raise Phoenix.LiveViewTest.StaleViewError, fn ->
        view
        |> form("form", %{})
        |> render_submit()
      end
    end

    test "parse_int function handles different input types correctly", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/credit_calculator")

      # Test string input
      view
      |> form("form", %{"answer" => "yes", "step" => "1"})
      |> render_submit()

      assert view.assigns.current_step == 2

      # The parse_int function is private, but we can test its behavior indirectly
      # through the step handling
    end

    test "prevents going beyond questionnaire bounds", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/credit_calculator")

      # Answer all questions
      Enum.with_index(@questionnaire, fn _question, index ->
        view
        |> form("form", %{"answer" => "yes", "step" => "#{index}"})
        |> render_submit()
      end)

      # Try to go to another step (should be on financial form now)
      assert render(view) =~ "What is your total monthly income"
      assert view.assigns.current_question == nil
    end

    test "handles boundary credit calculations", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/credit_calculator")

      # Get to financial stage
      Enum.with_index(@questionnaire, fn _question, index ->
        view
        |> form("form", %{"answer" => "yes", "step" => "#{index}"})
        |> render_submit()
      end)

      # Test minimum values
      view
      |> form("form", %{"monthly_income" => "0", "monthly_expenses" => "0"})
      |> render_submit()

      assert view.assigns.allot_credit_amount == 0

      # Test maximum reasonable values
      send(view.pid, {:reset_credit_amount})

      view
      |> form("form", %{"monthly_income" => "100000", "monthly_expenses" => "50000"})
      |> render_submit()

      assert view.assigns.allot_credit_amount == 600000  # (100000 - 50000) * 12
    end
  end

  describe "complete user journey scenarios" do
    test "successful high-earner journey", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/credit_calculator")

      # Answer all questions positively (11 points total)
      Enum.with_index(@questionnaire, fn _question, index ->
        view
        |> form("form", %{"answer" => "yes", "step" => "#{index}"})
        |> render_submit()
      end)

      assert view.assigns.earned_points == 11

      # Submit high income
      view
      |> form("form", %{"monthly_income" => "8000", "monthly_expenses" => "4000"})
      |> render_submit()

      assert view.assigns.allot_credit_amount == 48000

      # Submit email
      view
      |> form("form", %{"email" => "highearner@example.com"})
      |> render_submit()

      assert render(view) =~ "Email has been sent please check!"
      assert view.assigns.show_mailbox == true
    end

    test "unsuccessful low-score journey", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/credit_calculator")

      # Answer questions to get low score (only car = 1 point)
      view
      |> form("form", %{"answer" => "no", "step" => "0"})   # job: 0
      |> render_submit()

      view
      |> form("form", %{"answer" => "no", "step" => "1"})   # consistent job: 0
      |> render_submit()

      view
      |> form("form", %{"answer" => "no", "step" => "2"})   # home: 0
      |> render_submit()

      view
      |> form("form", %{"answer" => "yes", "step" => "3"})  # car: 1
      |> render_submit()

      view
      |> form("form", %{"answer" => "no", "step" => "4"})   # additional income: 0
      |> render_submit()

      assert view.assigns.earned_points == 1
      assert render(view) =~ "Thank you for completing the questionnaire!"
      assert render(view) =~ "Earned Points: 1"
      refute render(view) =~ "What is your total monthly income"
    end

    test "marginal case - exactly 6 points", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/credit_calculator")

      # Get exactly 6 points: job (4) + consistent job (2)
      view
      |> form("form", %{"answer" => "yes", "step" => "0"})  # job: 4
      |> render_submit()

      view
      |> form("form", %{"answer" => "yes", "step" => "1"})  # consistent job: 2
      |> render_submit()

      view
      |> form("form", %{"answer" => "no", "step" => "2"})   # home: 0
      |> render_submit()

      view
      |> form("form", %{"answer" => "no", "step" => "3"})   # car: 0
      |> render_submit()

      view
      |> form("form", %{"answer" => "no", "step" => "4"})   # additional income: 0
      |> render_submit()

      assert view.assigns.earned_points == 6
      assert render(view) =~ "What is your total monthly income"

      # Submit marginal financials
      view
      |> form("form", %{"monthly_income" => "2500", "monthly_expenses" => "2000"})
      |> render_submit()

      assert view.assigns.allot_credit_amount == 6000  # (2500 - 2000) * 12
      assert render(view) =~ "Congratulations!"
    end
  end

  # Helper function to handle reset messages (would need to be implemented in the LiveView)
  def handle_info({:reset_credit_amount}, socket) do
    {:noreply, assign(socket, allot_credit_amount: 0)}
  end
end
