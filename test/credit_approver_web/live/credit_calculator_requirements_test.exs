defmodule CreditApproverWeb.CreditCalculatorRequirementsTest do
  use CreditApproverWeb.ConnCase

  import Phoenix.LiveViewTest

  # Test cases that exactly match the requirements document
  describe "credit approval requirements compliance" do
    test "points exactly 6 - should show rejection message", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/credit_calculator")

      # Get exactly 6 points: job (4) + consistent job (2) = 6
      view |> form("form", %{"answer" => "yes", "step" => "0"}) |> render_submit()  # job: +4
      view |> form("form", %{"answer" => "yes", "step" => "1"}) |> render_submit()  # consistent: +2
      view |> form("form", %{"answer" => "no", "step" => "2"}) |> render_submit()   # home: +0
      view |> form("form", %{"answer" => "no", "step" => "3"}) |> render_submit()   # car: +0
      view |> form("form", %{"answer" => "no", "step" => "4"}) |> render_submit()   # additional: +0

      response = render(view)

      # Should show exact rejection message from requirements
      assert response =~ "Thank you for your answer. We are currently unable to issue credit to you"
      assert response =~ "Start New Assessment"

      # Should NOT show financial questions
      refute response =~ "What is your total monthly income"
      refute response =~ "What are your total monthly expenses"
      refute response =~ "Submit Financials"
    end

    test "points less than 6 (5 points) - should show rejection message", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/credit_calculator")

      # Get 5 points: job (4) + car (1) = 5
      view |> form("form", %{"answer" => "yes", "step" => "0"}) |> render_submit()  # job: +4
      view |> form("form", %{"answer" => "no", "step" => "1"}) |> render_submit()   # consistent: +0
      view |> form("form", %{"answer" => "no", "step" => "2"}) |> render_submit()   # home: +0
      view |> form("form", %{"answer" => "yes", "step" => "3"}) |> render_submit()  # car: +1
      view |> form("form", %{"answer" => "no", "step" => "4"}) |> render_submit()   # additional: +0

      response = render(view)

      # Should show exact rejection message from requirements
      assert response =~ "Thank you for your answer. We are currently unable to issue credit to you"
      assert response =~ "Start New Assessment"

      # Should NOT show financial questions
      refute response =~ "What is your total monthly income"
      refute response =~ "What are your total monthly expenses"
      refute response =~ "Submit Financials"
    end

    test "points less than 6 (0 points) - should show rejection message", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/credit_calculator")

      # Get 0 points: all "no" answers
      view |> form("form", %{"answer" => "no", "step" => "0"}) |> render_submit()  # job: +0
      view |> form("form", %{"answer" => "no", "step" => "1"}) |> render_submit()   # consistent: +0
      view |> form("form", %{"answer" => "no", "step" => "2"}) |> render_submit()   # home: +0
      view |> form("form", %{"answer" => "no", "step" => "3"}) |> render_submit()   # car: +0
      view |> form("form", %{"answer" => "no", "step" => "4"}) |> render_submit()   # additional: +0

      response = render(view)

      # Should show exact rejection message from requirements
      assert response =~ "Thank you for your answer. We are currently unable to issue credit to you"
      assert response =~ "Start New Assessment"

      # Should NOT show financial questions
      refute response =~ "What is your total monthly income"
      refute response =~ "What are your total monthly expenses"
      refute response =~ "Submit Financials"
    end

    test "points greater than 6 (7 points) - should continue to financial questions", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/credit_calculator")

      # Get 7 points: job (4) + consistent (2) + car (1) = 7
      view |> form("form", %{"answer" => "yes", "step" => "0"}) |> render_submit()  # job: +4
      view |> form("form", %{"answer" => "yes", "step" => "1"}) |> render_submit()  # consistent: +2
      view |> form("form", %{"answer" => "no", "step" => "2"}) |> render_submit()   # home: +0
      view |> form("form", %{"answer" => "yes", "step" => "3"}) |> render_submit()  # car: +1
      view |> form("form", %{"answer" => "no", "step" => "4"}) |> render_submit()   # additional: +0

      response = render(view)

      # Should show financial questions
      assert response =~ "What is your total monthly income from all income sources (in USD)?"
      assert response =~ "What are your total monthly expenses (in USD)?"
      assert response =~ "Submit Financials"

      # Should NOT show rejection message
      refute response =~ "We are currently unable to issue credit to you"
    end

    test "points greater than 6 (8 points) - should continue to financial questions", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/credit_calculator")

      # Get 8 points: job (4) + consistent (2) + home (2) = 8
      view |> form("form", %{"answer" => "yes", "step" => "0"}) |> render_submit()  # job: +4
      view |> form("form", %{"answer" => "yes", "step" => "1"}) |> render_submit()  # consistent: +2
      view |> form("form", %{"answer" => "yes", "step" => "2"}) |> render_submit()  # home: +2
      view |> form("form", %{"answer" => "no", "step" => "3"}) |> render_submit()   # car: +0
      view |> form("form", %{"answer" => "no", "step" => "4"}) |> render_submit()   # additional: +0

      response = render(view)

      # Should show financial questions
      assert response =~ "What is your total monthly income from all income sources (in USD)?"
      assert response =~ "What are your total monthly expenses (in USD)?"
      assert response =~ "Submit Financials"

      # Should NOT show rejection message
      refute response =~ "We are currently unable to issue credit to you"
    end

    test "maximum points (11) - should continue to financial questions", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/credit_calculator")

      # Get all 11 points: all "yes" answers
      view |> form("form", %{"answer" => "yes", "step" => "0"}) |> render_submit()  # job: +4
      view |> form("form", %{"answer" => "yes", "step" => "1"}) |> render_submit()  # consistent: +2
      view |> form("form", %{"answer" => "yes", "step" => "2"}) |> render_submit()  # home: +2
      view |> form("form", %{"answer" => "yes", "step" => "3"}) |> render_submit()  # car: +1
      view |> form("form", %{"answer" => "yes", "step" => "4"}) |> render_submit()  # additional: +2

      response = render(view)

      # Should show financial questions
      assert response =~ "What is your total monthly income from all income sources (in USD)?"
      assert response =~ "What are your total monthly expenses (in USD)?"
      assert response =~ "Submit Financials"

      # Should NOT show rejection message
      refute response =~ "We are currently unable to issue credit to you"
    end
  end

  describe "credit calculation requirements compliance" do
    test "approved user gets correct credit calculation", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/credit_calculator")

      # Get 7 points to qualify
      view |> form("form", %{"answer" => "yes", "step" => "0"}) |> render_submit()  # job: +4
      view |> form("form", %{"answer" => "yes", "step" => "1"}) |> render_submit()  # consistent: +2
      view |> form("form", %{"answer" => "no", "step" => "2"}) |> render_submit()   # home: +0
      view |> form("form", %{"answer" => "yes", "step" => "3"}) |> render_submit()  # car: +1
      view |> form("form", %{"answer" => "no", "step" => "4"}) |> render_submit()   # additional: +0

      # Submit financial information
      view |> form("form", %{"monthly_income" => "5000", "monthly_expenses" => "3000"}) |> render_submit()

      response = render(view)

      # Should show exact approval message from requirements
      assert response =~ "Congratulations!"
      assert response =~ "You have been approved for credit up to"
      assert response =~ "$24,000"  # With comma formatting
      assert response =~ "Credit Approved"

      # Should show email form
      assert response =~ "Enter your email address"
    end
  end

  describe "navigation requirements compliance" do
    test "Start New Assessment button navigates to credit calculator", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/credit_calculator")

      # Get rejection (6 points)
      view |> form("form", %{"answer" => "yes", "step" => "0"}) |> render_submit()  # job: +4
      view |> form("form", %{"answer" => "yes", "step" => "1"}) |> render_submit()  # consistent: +2
      view |> form("form", %{"answer" => "no", "step" => "2"}) |> render_submit()   # home: +0
      view |> form("form", %{"answer" => "no", "step" => "3"}) |> render_submit()   # car: +0
      view |> form("form", %{"answer" => "no", "step" => "4"}) |> render_submit()   # additional: +0

      response = render(view)

      # Check that Start New Assessment button has correct href
      assert response =~ "href=\"/credit_calculator\""
      assert response =~ "Start New Assessment"
    end

    test "Back to Home link is present during questionnaire", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/credit_calculator")

      # Should show Back to Home link
      assert html =~ "Back to Home"
      assert html =~ "href=\"/\""
    end
  end
end
