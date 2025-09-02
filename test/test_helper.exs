ExUnit.start()

# Validate Chrome browser for PDF generation tests
defmodule TestHelper do
  def validate_chrome_for_tests do
    chrome_path = Application.get_env(:chromic_pdf, :executable_path)

    cond do
      is_nil(chrome_path) ->
        IO.puts("""

        ⚠️  WARNING: Chrome/Chromium browser path not configured!
        PDF generation tests may fail. Please install Chrome or Chromium:

        macOS: brew install --cask chromium
        Linux: apt-get install chromium-browser

        Then configure the path in config/test.exs or config/config.exs
        """)

      not File.exists?(chrome_path) ->
        IO.puts("""

        ⚠️  WARNING: Chrome/Chromium browser not found at: #{chrome_path}
        PDF generation tests will fail. Please install Chrome/Chromium:

        macOS: brew install --cask chromium
        Linux: apt-get install chromium-browser

        Or update the path in config/test.exs
        """)

      true ->
        IO.puts("✅ Chrome/Chromium browser found for PDF tests: #{chrome_path}")
    end
  end
end

# Run Chrome validation when tests start
TestHelper.validate_chrome_for_tests()
