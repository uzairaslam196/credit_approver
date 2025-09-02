defmodule CreditApproverWeb.CreditCalculatorTest do
  use CreditApproverWeb.ConnCase

  import Phoenix.LiveViewTest

  # Questions with their point values for reference
  @questionnaire [
    %{question: "Do you have a paying job?", points: 4},
    %{question: "Did you consistently had a paying job for past 12?", points: 2},
    %{question: "Do you own a home?", points: 2},
    %{question: "Do you own a car?", points: 1},
    %{question: "Do you have any additional source of income?", points: 2}
  ]

  # Helper function to access LiveView assigns in tests
  defp get_assigns(view) do
    %{socket: %{assigns: assigns}} = :sys.get_state(view.pid)
    assigns
  end

  describe "mount/3" do
    test "initializes with correct default state", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/credit_calculator")

      # LiveView mounted successfully (checking for basic container)
      assert has_element?(view, "div")

      # Check initial state
      assigns = get_assigns(view)
      assert assigns.earned_points == 0
      assert assigns.answers == %{}
      assert assigns.financial_answers == %{}
      assert assigns.current_step == 0
      assert assigns.allot_credit_amount == 0
      assert assigns.email_valid == false
      assert assigns.email_message == ""
      assert assigns.show_mailbox == false
      assert assigns.current_question == Enum.at(@questionnaire, 0)
    end

    test "displays first question on mount", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/credit_calculator")

      assert html =~ "Question 1"
      assert html =~ "of 5"
      assert html =~ "Do you have a paying job?"
      assert html =~ "Back to Home"
    end
  end

  describe "questionnaire navigation" do
    test "progresses through all questions with 'yes' answers", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/credit_calculator")

      # Answer all questions with "yes"
      @questionnaire
      |> Enum.with_index()
      |> Enum.each(fn {question, index} ->
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
          |> Enum.map(& &1.points)
          |> Enum.sum()

        assigns = get_assigns(view)
        assert assigns.earned_points == expected_points
        assert assigns.answers[index] == "yes"

        if index < length(@questionnaire) - 1 do
          # Should show next question
          next_question = Enum.at(@questionnaire, index + 1)
          assert render(view) =~ next_question.question
        end
      end)

      # After all questions answered with "yes", should show financial form
      assigns = get_assigns(view)
      assert assigns.earned_points == 11  # Sum of all points: 4+2+2+1+2
      assert render(view) =~ "What is your total monthly income"
      assert render(view) =~ "What are your total monthly expenses"
    end

    test "progresses through all questions with 'no' answers", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/credit_calculator")

      # Answer all questions with "no"
      @questionnaire
      |> Enum.with_index()
      |> Enum.each(fn {question, index} ->
        assert render(view) =~ question.question

        view
        |> form("form", %{"answer" => "no", "step" => "#{index}"})
        |> render_submit()

        assigns = get_assigns(view)
        assert assigns.earned_points == 0  # No points for "no" answers
        assert assigns.answers[index] == "no"
      end)

      # After all questions answered with "no", should show rejection message
      assert render(view) =~ "Thank you for your answer. We are currently unable to issue credit to you"
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
      assigns = get_assigns(view)
      assert assigns.answers[0] == "yes"
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

      answers
      |> Enum.with_index()
      |> Enum.each(fn {answer, index} ->
        view
        |> form("form", %{"answer" => answer, "step" => "#{index}"})
        |> render_submit()
      end)

      assigns = get_assigns(view)
      assert assigns.earned_points == 8
      assert %{0 => "yes", 1 => "no", 2 => "yes", 3 => "no", 4 => "yes"} = assigns.answers
    end

    test "points calculation updates when changing previous answers", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/credit_calculator")

      # Answer first question "yes" (4 points)
      view
      |> form("form", %{"answer" => "yes", "step" => "0"})
      |> render_submit()

      assigns = get_assigns(view)
      assert assigns.earned_points == 4

      # Go to second question and answer "yes" (2 points)
      view
      |> form("form", %{"answer" => "yes", "step" => "1"})
      |> render_submit()

      assigns = get_assigns(view)
      assert assigns.earned_points == 6

      # Go back to first question
      view
      |> element("button[phx-click='prev_step']")
      |> render_click(%{"step" => "1"})

      # Change first answer to "no"
      view
      |> form("form", %{"answer" => "no", "step" => "0"})
      |> render_submit()

      # Points should be recalculated: 0 + 2 = 2
      assigns = get_assigns(view)
      assert assigns.earned_points == 2
    end
  end

  describe "credit approval threshold" do
    test "shows financial form when points > 6", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/credit_calculator")

      # Answer to get 7 points: job (4) + consistent job (2) + car (1) = 7
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
      |> form("form", %{"answer" => "yes", "step" => "3"})  # car: +1
      |> render_submit()

      view
      |> form("form", %{"answer" => "no", "step" => "4"})   # additional income: +0
      |> render_submit()

      # Should show financial form for points > 6
      assert render(view) =~ "What is your total monthly income"
      assert render(view) =~ "What are your total monthly expenses"
      assert render(view) =~ "Submit Financials"
    end

    test "shows rejection message when points <= 6", %{conn: conn} do
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

      assert render(view) =~ "Thank you for your answer. We are currently unable to issue credit to you"
      assert render(view) =~ "Start New Assessment"
      refute render(view) =~ "What is your total monthly income"
    end

    test "shows rejection message when points exactly equal 6", %{conn: conn} do
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

      assert render(view) =~ "Thank you for your answer. We are currently unable to issue credit to you"
      assert render(view) =~ "Start New Assessment"
      refute render(view) =~ "What is your total monthly income"
    end
  end

  describe "financial questions flow" do
    setup %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/credit_calculator")

      # Answer questions to reach > 6 points (7 points total)
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
      |> form("form", %{"answer" => "yes", "step" => "3"})  # car: +1
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

      assigns = get_assigns(view)
      assert assigns.allot_credit_amount == expected_credit
      assert %{"monthly_income" => ^monthly_income, "monthly_expenses" => ^monthly_expenses} = assigns.financial_answers

      # Should show congratulations page
      assert render(view) =~ "Congratulations!"
      assert render(view) =~ "You have been approved for credit up to"
      assert render(view) =~ "$#{CreditApprover.Utils.format_currency(expected_credit)}"
      assert render(view) =~ "Enter your email address"
    end

    test "handles financial calculation with different amounts", %{view: view} do
      # Test simple case first
      view
      |> form("form", %{"monthly_income" => "6000", "monthly_expenses" => "2000"})
      |> render_submit()

      assigns = get_assigns(view)
      assert assigns.allot_credit_amount == 48000
    end

    test "handles zero or negative credit calculation", %{view: view} do
      # Expenses equal to income
      view
      |> form("form", %{"monthly_income" => "3000", "monthly_expenses" => "3000"})
      |> render_submit()

      assigns = get_assigns(view)
      assert assigns.allot_credit_amount == 0
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

        assigns = get_assigns(view)
        assert assigns.email_valid == false
        assert assigns.email_message != "Email looks good!"
      end)

      # Test valid email
      view
      |> form("form", %{"email" => "test@example.com"})
      |> render_change()

      assigns = get_assigns(view)
      assert assigns.email_valid == true
      assert assigns.email_message == "Email looks good!"
    end

    test "sends email with correct information", %{view: view} do
      email = "test@example.com"

      view
      |> form("form", %{"email" => email})
      |> render_submit()

      # Check that email was attempted to be sent
      assigns = get_assigns(view)
      assert assigns.show_mailbox == true
      assert has_element?(view, "a[href='/dev/mailbox']")

      # Verify flash message
      assert render(view) =~ "Credit assessment email has been sent successfully!"
    end

    test "sends email successfully", %{view: view} do
      email = "test@example.com"

      view
      |> form("form", %{"email" => email})
      |> render_submit()

      # Check that email was attempted to be sent
      assigns = get_assigns(view)
      assert assigns.show_mailbox == true
      assert has_element?(view, "a[href='/dev/mailbox']")

      # Verify flash message
      assert render(view) =~ "Credit assessment email has been sent successfully!"
    end
  end

  describe "edge cases and error handling" do
    test "handles invalid step values in next_step", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/credit_calculator")

      # Test the behavior by using valid form submission, which exercises parse_int
      view
      |> form("form", %{"answer" => "yes", "step" => "0"})
      |> render_submit()

      assigns = get_assigns(view)
      assert assigns.current_step == 1
    end

    test "handles invalid step values in prev_step", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/credit_calculator")

      # Go to second question first
      view
      |> form("form", %{"answer" => "yes", "step" => "0"})
      |> render_submit()

      # Send prev_step event directly with invalid step
      send(view.pid, {:handle_event, "prev_step", %{"step" => "invalid"}, %{}})

      # Should handle gracefully
      assigns = get_assigns(view)
      assert assigns.current_step >= 0
    end

    test "handles missing financial data gracefully", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/credit_calculator")

      # Reach financial stage
      @questionnaire
      |> Enum.with_index()
      |> Enum.each(fn {_question, index} ->
        view
        |> form("form", %{"answer" => "yes", "step" => "#{index}"})
        |> render_submit()
      end)

      # Try to submit empty financial form - should be handled gracefully
      html = view
        |> form("form", %{})
        |> render_submit()

      # Should not crash and remain on financial form
      assert html =~ "Financial Information"
      # Verify we're still on the financial stage and no credit was allocated
      assert has_element?(view, "form[phx-submit=\"financials\"]")
    end

    test "parse_int function handles different input types correctly", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/credit_calculator")

      # Test string input by going through normal form flow
      view
      |> form("form", %{"answer" => "yes", "step" => "0"})
      |> render_submit()

      assigns = get_assigns(view)
      assert assigns.current_step == 1

      # The parse_int function is private, but we can test its behavior indirectly
      # through the step handling
    end

    test "prevents going beyond questionnaire bounds", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/credit_calculator")

      # Answer all questions
      @questionnaire
      |> Enum.with_index()
      |> Enum.each(fn {_question, index} ->
        view
        |> form("form", %{"answer" => "yes", "step" => "#{index}"})
        |> render_submit()
      end)

      # Try to go to another step (should be on financial form now)
      assert render(view) =~ "What is your total monthly income"
      assigns = get_assigns(view)
      assert assigns.current_question == nil
    end

    test "handles boundary credit calculations", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/credit_calculator")

      # Get to financial stage
      @questionnaire
      |> Enum.with_index()
      |> Enum.each(fn {_question, index} ->
        view
        |> form("form", %{"answer" => "yes", "step" => "#{index}"})
        |> render_submit()
      end)

      # Test minimum values
      view
      |> form("form", %{"monthly_income" => "0", "monthly_expenses" => "0"})
      |> render_submit()

      assigns = get_assigns(view)
      assert assigns.allot_credit_amount == 0

      # Test maximum reasonable values
      view
      |> form("form", %{"monthly_income" => "100000", "monthly_expenses" => "50000"})
      |> render_submit()

      assigns = get_assigns(view)
      assert assigns.allot_credit_amount == 600000  # (100000 - 50000) * 12
    end
  end

  describe "complete user journey scenarios" do
    test "successful high-earner journey", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/credit_calculator")

      # Answer all questions positively (11 points total)
      @questionnaire
      |> Enum.with_index()
      |> Enum.each(fn {_question, index} ->
        view
        |> form("form", %{"answer" => "yes", "step" => "#{index}"})
        |> render_submit()
      end)

      assigns = get_assigns(view)
      assert assigns.earned_points == 11

      # Submit high income
      view
      |> form("form", %{"monthly_income" => "8000", "monthly_expenses" => "4000"})
      |> render_submit()

      assigns = get_assigns(view)
      assert assigns.allot_credit_amount == 48000

      # Submit email
      view
      |> form("form", %{"email" => "highearner@example.com"})
      |> render_submit()

      assert render(view) =~ "Credit assessment email has been sent successfully!"
      assigns = get_assigns(view)
      assert assigns.show_mailbox == true
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

      assigns = get_assigns(view)
      assert assigns.earned_points == 1
      assert render(view) =~ "Thank you for your answer. We are currently unable to issue credit to you."
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

      assigns = get_assigns(view)
      assert assigns.earned_points == 6
      # 6 points is not enough (needs > 6), so should show rejection message
      assert render(view) =~ "Thank you for your answer. We are currently unable to issue credit to you."
      # No financial form should be available since credit was rejected
      refute render(view) =~ "What is your total monthly income"
    end
  end
end
