defmodule CreditApproverWeb.PageControllerTest do
  use CreditApproverWeb.ConnCase

  test "GET /", %{conn: conn} do
    conn = get(conn, ~p"/")
    response = html_response(conn, 200)
    assert response =~ "Smart Credit"
    assert response =~ "Assessment"
    assert response =~ "Start Credit Assessment"
    assert response =~ "Quick • Secure • Instant Results"
  end
end
