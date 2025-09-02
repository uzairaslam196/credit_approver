defmodule CreditApproverWeb.CreditCalculator do
  use CreditApproverWeb, :live_view
  alias CreditApprover.Notifier
  alias CreditApprover.Utils

  @questionnaire [
    %{question: "Do you have a paying job?", points: 4},
    %{question: "Did you consistently had a paying job for past 12?", points: 2},
    %{question: "Do you own a home?", points: 2},
    %{question: "Do you own a car?", points: 1},
    %{question: "Do you have any additional source of income?", points: 2}
  ]

  def mount(_, _, socket) do
    {:ok,
     assign(socket,
       earned_points: 0,
       answers: %{},
       financial_answers: %{},
       basic_quesion_form: to_form(%{}),
       income_quesion_form: to_form(%{}),
       email_form: to_form(%{}),
       current_step: 0,
       questionnaire: @questionnaire,
       current_question: Enum.at(@questionnaire, 0),
       allot_credit_amount: 0,
       email_valid: false,
       email_message: "",
       show_mailbox: false
     )}
  end



  def render(assigns) do
    ~H"""
        <!-- Professional Background with Pattern -->
    <div class="min-h-screen relative overflow-hidden"
         style="background: linear-gradient(135deg, #1e3a8a 0%, #3730a3 50%, #1e40af 100%);">
      <!-- Background Pattern -->
      <div class="absolute inset-0 opacity-10"
           style="background-image: url('data:image/svg+xml,%3Csvg width=&quot;60&quot; height=&quot;60&quot; viewBox=&quot;0 0 60 60&quot; xmlns=&quot;http://www.w3.org/2000/svg&quot;%3E%3Cg fill=&quot;none&quot; fill-rule=&quot;evenodd&quot;%3E%3Cg fill=&quot;%23ffffff&quot; fill-opacity=&quot;0.3&quot;%3E%3Ccircle cx=&quot;7&quot; cy=&quot;7&quot; r=&quot;1&quot;/%3E%3C/g%3E%3C/g%3E%3C/svg%3E');"></div>

      <!-- Header Section -->
      <div class="relative z-10 pt-8 pb-4">
        <div class="max-w-4xl mx-auto px-6">
          <!-- Back to Home Link -->
          <div class="mb-6">
            <.link
              navigate={~p"/"}
              class="inline-flex items-center text-sm text-white/80 hover:text-white transition-colors duration-200 bg-white/10 backdrop-blur-sm rounded-full px-4 py-2 border border-white/20"
            >
              <svg class="w-4 h-4 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 19l-7-7 7-7" />
              </svg>
              Back to Home
            </.link>
          </div>

                    <!-- Enhanced Header - Only show during questionnaire -->
          <%= if @current_question do %>
            <div class="text-center mb-8">
              <div class="inline-flex items-center justify-center w-16 h-16 bg-white/10 backdrop-blur-sm rounded-2xl border border-white/20 mb-4">
                <svg class="w-8 h-8 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z" />
                </svg>
              </div>
              <h1 class="text-4xl font-bold text-white mb-2">Credit Assessment</h1>
              <p class="text-white/80 text-lg">Answer a few quick questions to determine your eligibility</p>

              <!-- Progress Indicator -->
              <div class="mt-6 max-w-md mx-auto">
                <div class="flex justify-between text-sm text-white/60 mb-2">
                  <span>Progress</span>
                  <span>{@current_step + 1} of {length(@questionnaire)}</span>
                </div>
                <div class="w-full bg-white/20 rounded-full h-2 backdrop-blur-sm">
                  <div
                    class="bg-gradient-to-r from-blue-400 to-blue-600 h-2 rounded-full transition-all duration-500 ease-out"
                    style={"width: #{((@current_step + 1) / length(@questionnaire)) * 100}%"}
                  ></div>
                </div>
              </div>
            </div>
          <% end %>
        </div>
      </div>

      <!-- Main Content Container -->
      <div class="relative z-10 px-6 pb-12">
        <div class="max-w-2xl mx-auto">
          <div class="bg-gradient-to-br from-slate-50/95 via-blue-50/95 to-indigo-50/95 backdrop-blur-sm rounded-3xl shadow-2xl border border-blue-100/30 p-8 md:p-10">
      <%= if @current_question do %>
        <.simple_form
          :let={bqform}
          for={@basic_quesion_form}
          phx-submit="next_step"
          class="space-y-8 !bg-transparent"
        >
          <div>
            <h3 class="text-2xl font-bold mb-3 text-gray-800 tracking-tight">
              Question {@current_step + 1}
              <span class="text-base font-medium text-gray-500">of {length(@questionnaire)}</span>
            </h3>
            <p class="mb-6 text-gray-800 text-xl font-semibold bg-gradient-to-r from-blue-25 via-slate-25 to-blue-25 rounded-xl px-6 py-4 shadow-sm border border-blue-200/40" style="background: linear-gradient(135deg, #f8fafc 0%, #f1f5f9 50%, #f8fafc 100%);">
              {@current_question.question}
            </p>
            <.gradient_container>
              <.input
                type="radio"
                field={bqform[:answer]}
                options={[{"Yes", "yes"}, {"No", "no"}]}
                value={@answers[@current_step]}
                required
                class="flex flex-row gap-8 justify-center"
              />
            </.gradient_container>
            <.input type="hidden" field={bqform[:step]} value={@current_step} />
          </div>
          <div class="flex gap-6 mt-8">
            <.button
              type="button"
              phx-click="prev_step"
              phx-value-step={@current_step}
              class="w-1/2 bg-gradient-to-r from-gray-500 to-gray-600 hover:from-gray-600 hover:to-gray-700 transition-all duration-200 text-white font-semibold py-3 rounded-xl shadow-lg disabled:opacity-50 disabled:cursor-not-allowed"
              disabled={@current_step == 0}
            >
              <span class="inline-flex items-center gap-2">
                <svg
                  class="w-4 h-4 text-white"
                  fill="none"
                  stroke="currentColor"
                  stroke-width="2"
                  viewBox="0 0 24 24"
                >
                  <path stroke-linecap="round" stroke-linejoin="round" d="M15 19l-7-7 7-7" />
                </svg>
                Previous
              </span>
            </.button>
            <.button
              type="submit"
              class="w-1/2 bg-gradient-to-r from-blue-700 to-blue-800 hover:from-blue-800 hover:to-blue-900 transition-all duration-200 text-white font-semibold py-3 rounded-xl shadow-lg transform hover:scale-105"
            >
              <span class="inline-flex items-center gap-2">
                {if @current_step + 1 == length(@questionnaire), do: "Continue", else: "Next"}
                <svg
                  :if={@current_step + 1 != length(@questionnaire)}
                  class="w-4 h-4 text-white"
                  fill="none"
                  stroke="currentColor"
                  stroke-width="2"
                  viewBox="0 0 24 24"
                >
                  <path stroke-linecap="round" stroke-linejoin="round" d="M9 5l7 7-7 7" />
                </svg>
                <svg
                  :if={@current_step + 1 == length(@questionnaire)}
                  class="w-4 h-4 text-white"
                  fill="none"
                  stroke="currentColor"
                  stroke-width="2"
                  viewBox="0 0 24 24"
                >
                  <path stroke-linecap="round" stroke-linejoin="round" d="M5 13l4 4L19 7" />
                </svg>
              </span>
            </.button>
          </div>
        </.simple_form>
      <% else %>
        <%= cond do %>
          <% @earned_points > 6 && @allot_credit_amount == 0 -> %>
            <div class="text-center mb-8">
              <div class="inline-flex items-center justify-center w-16 h-16 bg-gradient-to-r from-blue-600 to-blue-700 rounded-2xl mb-4">
                <svg class="w-8 h-8 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8c-1.657 0-3 .895-3 2s1.343 2 3 2 3 .895 3 2-1.343 2-3 2m0-8c1.11 0 2.08.402 2.599 1M12 8V7m0 1v8m0 0v1m0-1c-1.11 0-2.08-.402-2.599-1" />
                </svg>
              </div>
              <h2 class="text-3xl font-bold text-gray-800 mb-2">Financial Information</h2>
              <p class="text-gray-600">You've qualified! Now let's calculate your credit amount.</p>
            </div>

            <.simple_form
              :let={finform}
              for={@income_quesion_form}
              phx-submit="financials"
              class="space-y-8 !bg-transparent"
            >
              <.gradient_container>
                <.input
                  field={finform[:monthly_income]}
                  type="number"
                  label="What is your total monthly income from all income sources (in USD)?"
                  min="0"
                  step="0.01"
                  required
                  class="mb-6"
                />
                <.input
                  field={finform[:monthly_expenses]}
                  type="number"
                  label="What are your total monthly expenses (in USD)?"
                  min="0"
                  step="0.01"
                  required
                  class="mb-6"
                />
              </.gradient_container>
              <:actions>
                <.button
                  type="submit"
                  class="w-full bg-gradient-to-r from-blue-700 to-blue-800 hover:from-blue-800 hover:to-blue-900 transition-all duration-200 text-white font-semibold py-3 rounded-xl shadow-lg transform hover:scale-105"
                >
                  <span class="inline-flex items-center gap-2">
                    <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z" />
                    </svg>
                    Submit Financials
                  </span>
                </.button>
              </:actions>
            </.simple_form>
          <% @allot_credit_amount > 0 -> %>
            <div class="text-center py-16">
              <h3 class="text-3xl font-extrabold mb-6 text-green-700">
                Congratulations!
              </h3>
              <div class="text-2xl font-semibold text-gray-700 mb-4">
                You have been approved for credit up to
              </div>
              <div class="text-5xl font-bold text-green-700 mb-6">
                $<%= Utils.format_currency(@allot_credit_amount) %>
              </div>
              <div class="inline-flex items-center gap-2 px-4 py-2 bg-gradient-to-r from-emerald-25 via-green-25 to-emerald-25 rounded-full border border-emerald-200/50" style="background: linear-gradient(135deg, #f0fdf4 0%, #ecfdf5 50%, #f0fdf4 100%);">
                <svg class="w-5 h-5 text-emerald-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z" />
                </svg>
                <span class="text-emerald-800 font-medium">Credit Approved</span>
              </div>
              <div class="mt-10 max-w-md mx-auto">
                <.simple_form
                  :let={emailform}
                  for={@email_form}
                  phx-submit="send_email"
                  phx-change="validate_email"
                  class="space-y-4 !bg-transparent"
                >
                  <.gradient_container>
                    <.input
                      field={emailform[:email]}
                      type="email"
                      label="Enter your email address to receive a copy of your answers"
                      required
                      class="mb-2"
                    />
                    <%= if !@email_valid && @email_message != "" do %>
                      <.error>{@email_message}</.error>
                    <% end %>
                  </.gradient_container>
                  <:actions>
                    <.button
                      type="submit"
                      class="w-full bg-green-600 hover:bg-green-700 text-white font-bold py-2 rounded-lg shadow-md"
                    >
                      Send Copy
                    </.button>
                  </:actions>
                </.simple_form>
              </div>
                            <.link
                :if={@show_mailbox}
                href="/dev/mailbox"
                target="_blank"
                class="mt-4 block text-center text-sm text-blue-600 hover:text-blue-800"
              >
                View sent email in dev mailbox
              </.link>

              <!-- Navigation Buttons -->
              <.render_navigation_buttons />
            </div>
                    <% true -> %>
            <div class="text-center py-16">
              <div class="text-2xl font-bold text-gray-800 mb-8">
                Thank you for your answer. We are currently unable to issue credit to you.
              </div>

              <!-- Points Display (Optional - can be removed if not needed) -->
              <div class="text-lg font-medium text-gray-500 mb-6">
                <span class="inline-block bg-gray-100 px-4 py-2 rounded-lg">
                  <svg
                    class="w-5 h-5 inline-block text-gray-400 mr-2"
                    fill="none"
                    stroke="currentColor"
                    stroke-width="2"
                    viewBox="0 0 24 24"
                  >
                    <path stroke-linecap="round" stroke-linejoin="round" d="M12 8v4l3 3" />
                  </svg>
                  Earned Points: {@earned_points}
                </span>
              </div>

              <!-- Navigation Buttons -->
              <.render_navigation_buttons />
            </div>
        <% end %>
      <% end %>
          </div>
        </div>
      </div>
    </div>
    """
  end

  def handle_event("next_step", %{"answer" => answer, "step" => step}, socket) do
    parsed_step = parse_int(step)
    next_step = parsed_step + 1

    # Update answers map with the current answer
    updated_answers = Map.put(socket.assigns.answers, parsed_step, answer)

    # Recalculate earned_points based on all "yes" answers
    earned_points =
      Enum.reduce(updated_answers, 0, fn
        {idx, "yes"}, acc ->
          acc + (Enum.at(@questionnaire, idx)[:points] || 0)

        _, acc ->
          acc
      end)

    # Prepare form for next step: clear answer if not previously answered, or prefill if exists
    next_form = prepare_form_with_answer(updated_answers, next_step)

    {:noreply,
     socket
     |> assign(
       earned_points: earned_points,
       answers: updated_answers,
       current_step: next_step,
       current_question: Enum.at(@questionnaire, next_step),
       basic_quesion_form: next_form
     )}
  end

  def handle_event("prev_step", %{"step" => step}, socket) do
    parsed_step = parse_int(step)
    prev_step = max(parsed_step - 1, 0)

    # Prepare form for previous step: prefill answer if exists
    prev_form = prepare_form_with_answer(socket.assigns.answers, prev_step)

    {:noreply,
     socket
     |> assign(
       current_step: prev_step,
       current_question: Enum.at(@questionnaire, prev_step),
       basic_quesion_form: prev_form
     )}
  end

  def handle_event("financials", %{"monthly_expenses" => me, "monthly_income" => mi}, socket) do
    {:noreply,
     update(socket, :allot_credit_amount, fn allot_credit_amount ->
       allot_credit_amount + (parse_int(mi) - parse_int(me)) * 12
     end)
     |> assign(:financial_answers, %{"monthly_expenses" => me, "monthly_income" => mi})}
  end

  def handle_event("validate_email", %{"email" => email}, socket) do
    # Simple email validation: check for presence of "@" and "."
    {is_valid, message} =
      case email do
        nil ->
          {false, "Email cannot be empty."}

        "" ->
          {false, "Email cannot be empty."}

        email when is_binary(email) ->
          if Regex.match?(~r/^[^@\s]+@[^@\s]+\.[^@\s]+$/, email) do
            {true, "Email looks good!"}
          else
            {false, "Please enter a valid email address."}
          end

        _ ->
          {false, "Invalid input."}
      end

    {:noreply,
     assign(socket,
       email_form: to_form(%{"email" => email}),
       email_valid: is_valid,
       email_message: message
     )}
  end

  def handle_event("send_email", %{"email" => email}, socket) do
    basic_question_answers =
      Enum.with_index(@questionnaire)
      |> Enum.map(fn {q, idx} ->
        %{
          question: q.question,
          answer: Map.get(socket.assigns.answers, idx, "N/A")
        }
      end)

    # Extract financial answers from the assigns
    financial_question_answers =
      case socket.assigns.financial_answers do
        %{"monthly_income" => mi, "monthly_expenses" => me} ->
          [
            %{
              question: "What is your total monthly income from all income sources (in USD)?",
              answer: mi
            },
            %{
              question: "What are your total monthly expenses (in USD)?",
              answer: me
            }
          ]

        _ ->
          []
      end

    # Send the email using the Notifier
    Notifier.send_email(
      email,
      basic_question_answers,
      financial_question_answers,
      socket.assigns.allot_credit_amount
    )

    {:noreply,
     socket |> assign(show_mailbox: true) |> put_flash(:info, "Email has been sent please check!")}
  end

  defp parse_int(step) when is_binary(step) do
    case Integer.parse(step) do
      {int, _} -> int
      :error -> 0
    end
  end

  defp parse_int(step) when is_integer(step), do: step

  # Private helper functions for code reuse
  defp render_navigation_buttons(assigns) do
    ~H"""
    <div class="mt-8 text-center space-y-4">
      <.link
        navigate={~p"/credit_calculator"}
        class="inline-flex items-center px-6 py-3 text-base font-medium text-white bg-gradient-to-r from-blue-700 to-blue-800 hover:from-blue-800 hover:to-blue-900 rounded-lg transition-all duration-200 shadow-lg transform hover:scale-105"
      >
        <svg class="w-5 h-5 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15" />
        </svg>
        Start New Assessment
      </.link>
      <.link
        navigate={~p"/"}
        class="block text-sm text-blue-600 hover:text-blue-800 transition-colors duration-200"
      >
        Back to Home
      </.link>
    </div>
    """
  end

  defp gradient_container(assigns) do
    ~H"""
    <div class="bg-gradient-to-r from-blue-25 via-slate-25 to-blue-25 rounded-lg p-6 border border-blue-100/30" style="background: linear-gradient(135deg, #f8fafc 0%, #f1f5f9 50%, #f8fafc 100%);">
      <%= render_slot(@inner_block) %>
    </div>
    """
  end

  defp prepare_form_with_answer(answers, step) do
    if Map.has_key?(answers, step) do
      to_form(%{"answer" => answers[step], "step" => step})
    else
      to_form(%{"step" => step})
    end
  end
end
