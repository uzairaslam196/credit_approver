defmodule CreditApprover.DataCase do
  @moduledoc """
  This module defines the setup for tests requiring
  access to the application's data layer.

  Since we're not using a database, this is simplified.
  """

  use ExUnit.CaseTemplate

  using do
    quote do
      # No database imports needed
      import CreditApprover.DataCase
    end
  end

  setup _tags do
    # No database setup needed
    :ok
  end
end
