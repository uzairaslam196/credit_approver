# CreditApprover

CreditApprover is a **credit approval web application** built with [Phoenix LiveView](https://hexdocs.pm/phoenix_live_view/) that assesses users' creditworthiness through a structured questionnaire, calculates eligible credit amounts, and provides professional PDF summaries via email.

---

## 🚀 Quick Start

```bash
git clone <repository-url>
cd credit_approver
mix setup
mix phx.server
```

Visit [http://localhost:4000](http://localhost:4000) to start!

---

## ✨ Features

- **🔍 Risk Assessment**: 5-question credit scoring questionnaire
- **💰 Smart Credit Calculation**: Based on income vs expenses analysis  
- **📊 Real-time UI**: Professional Phoenix LiveView interface
- **📄 PDF Generation**: Automated credit summary reports using [ChromicPDF](https://hex.pm/packages/chromic_pdf) with intelligent Chrome browser detection
- **📧 Scalable Email System**: Modular email architecture with validation, logging, and easy extensibility via [Swoosh](https://hexdocs.pm/swoosh)
- **🎨 Modern Design**: Responsive UI with professional styling

---

## 📋 Requirements

### System Dependencies

- **[Elixir](https://elixir-lang.org/install.html)** (>= 1.14)
- **[Erlang/OTP](https://www.erlang.org/downloads)** 
- **[Node.js](https://nodejs.org/)** (>= 18.x for asset compilation)
- **[Chromium/Chrome](https://www.chromium.org/)** (required for PDF generation)

> **Note**: No database required - this application runs completely in-memory.

### Recommended Installation via asdf

We recommend using [asdf](https://asdf-vm.com/) version manager for consistent development environments:

#### Install asdf (if not already installed):

**macOS (via Homebrew):**
```bash
brew install asdf
echo -e "\n. $(brew --prefix asdf)/libexec/asdf.sh" >> ~/.zshrc
source ~/.zshrc
```

**Linux:**
```bash
git clone https://github.com/asdf-vm/asdf.git ~/.asdf --branch v0.13.1
echo '. "$HOME/.asdf/asdf.sh"' >> ~/.bashrc
echo '. "$HOME/.asdf/completions/asdf.bash"' >> ~/.bashrc
source ~/.bashrc
```

#### Install Elixir & Node.js:

```bash
# Add plugins
asdf plugin add erlang
asdf plugin add elixir  
asdf plugin add nodejs

# Install latest stable versions
asdf install erlang 26.1.2
asdf install elixir 1.15.7-otp-26
asdf install nodejs 18.18.2

# Set global versions
asdf global erlang 26.1.2
asdf global elixir 1.15.7-otp-26
asdf global nodejs 18.18.2

# Verify installations
elixir --version
node --version
```

#### Alternative: Using .tool-versions

This project includes a `.tool-versions` file for automatic version management:

```bash
# Create .tool-versions file in project root
echo "erlang 26.1.2" >> .tool-versions
echo "elixir 1.15.7-otp-26" >> .tool-versions  
echo "nodejs 18.18.2" >> .tool-versions

# Install all versions automatically
asdf install
```

### 🌐 Chrome/Chromium Installation (Required for PDF Generation)

**⚠️ Critical Dependency:** Chrome or Chromium browser is **required** for PDF generation functionality. The application includes intelligent warnings to help you set this up correctly.

#### **macOS Installation:**
```bash
# Option 1: Chromium (recommended)
brew install --cask chromium

# Option 2: Google Chrome  
brew install --cask google-chrome
```

#### **Linux Installation:**
```bash
# Ubuntu/Debian - Chromium
sudo apt-get update
sudo apt-get install chromium-browser

# Ubuntu/Debian - Google Chrome
wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | sudo apt-key add -
echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" | sudo tee /etc/apt/sources.list.d/google-chrome.list
sudo apt-get update
sudo apt-get install google-chrome-stable
```

#### **Windows:**
1. Download Chrome: [https://www.google.com/chrome/](https://www.google.com/chrome/)
2. Or download Chromium: [https://www.chromium.org/getting-involved/download-chromium/](https://www.chromium.org/getting-involved/download-chromium/)

#### **Configuration:**
After installation, update the browser path in `config/runtime.exs`:

```elixir
config :chromic_pdf,
  executable_path: "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
  # Linux: "/usr/bin/chromium-browser" or "/usr/bin/google-chrome"
  # Windows: "C:\\Program Files\\Google\\Chrome\\Application\\chrome.exe"
```

#### **Verification:**

```bash
# Verify installation
/Applications/Google\ Chrome.app/Contents/MacOS/Google\ Chrome --version
# or
chromium --version

# Test PDF generation
mix test test/credit_approver/pdf_generator_test.exs
```

#### **⚡ Smart Warning System:**
The application will automatically detect missing Chrome/Chromium and show helpful warnings:
- 🚨 **Server startup**: Warns if Chrome is missing when starting `mix phx.server`
- 🧪 **Test execution**: Automatically skips PDF tests if Chrome unavailable  
- 🔧 **Runtime errors**: Provides clear error messages with installation instructions

---

## 🛠️ Installation & Setup

**🚨 Prerequisites:** Ensure you have Chrome/Chromium installed for PDF generation (see [Chrome Installation Guide](#-chromechromium-installation-required-for-pdf-generation) above).

### Method 1: Quick Setup (Recommended)

```bash
# Clone the repository
git clone <repository-url>
cd credit_approver

# Install all dependencies and build assets
mix setup

# Start the Phoenix server
mix phx.server
```

**Note:** The server will show Chrome/Chromium status warnings at startup to help you verify PDF generation capabilities.

### Method 2: Manual Setup

```bash
# Install Elixir dependencies
mix deps.get

# Install and setup assets (Tailwind CSS, esbuild)
mix assets.setup
mix assets.build

# Start the server
mix phx.server
```

### 🌐 Access the Application

- **Main App**: [http://localhost:4000](http://localhost:4000)
- **LiveDashboard**: [http://localhost:4000/dev/dashboard](http://localhost:4000/dev/dashboard) 
- **Email Preview**: [http://localhost:4000/dev/mailbox](http://localhost:4000/dev/mailbox) (see sent emails during development)

---

## 🔄 How It Works

### Credit Assessment Process

1. **📝 Risk Assessment Questionnaire** (5 Questions)
   - Employment status (4 points)
   - Job consistency over 12 months (2 points) 
   - Home ownership (2 points)
   - Car ownership (1 point)
   - Additional income sources (2 points)

2. **🎯 Threshold Evaluation**
   - **6 points or less**: Application declined
   - **More than 6 points**: Proceed to financial assessment

3. **💰 Financial Information** (if qualified)
   - Monthly income from all sources
   - Total monthly expenses

4. **🧮 Credit Calculation** (if qualified)
   ```
   Credit Amount = (Monthly Income - Monthly Expenses) × 12
   ```

5. **📊 Results & PDF Generation**
   - Professional credit decision summary
   - Detailed PDF report with all responses

6. **📧 Email Delivery**
   - Instant email with PDF attachment
   - Professional email template

---

## 🧪 Testing

Run the comprehensive test suite:

```bash
# Run all tests
mix test

# Run specific test files
mix test test/credit_approver_web/live/credit_calculator_requirements_test.exs

# Run tests with detailed output
mix test --trace
```

**Test Coverage Includes**:
- ✅ Credit scoring logic validation
- ✅ Threshold evaluation (6 points rule)
- ✅ Financial calculations 
- ✅ PDF generation functionality (with Chrome validation)
- ✅ Modular email system (Base utilities + specific email types)
- ✅ Email validation and error handling
- ✅ LiveView user interactions
- ✅ Chrome/Chromium dependency detection

**📋 Note:** PDF generation tests will automatically skip with helpful warnings if Chrome/Chromium is not installed. See the [Chrome/Chromium Browser Warnings](#chromechromium-browser-warnings) section for examples.

---

## 🏗️ Technical Architecture

### Core Technologies

- **Phoenix LiveView**: Real-time, interactive web interface with stateful session management
- **ChromicPDF**: HTML-to-PDF conversion engine
- **Swoosh**: Email delivery with local preview
- **Tailwind CSS**: Modern utility-first styling
- **ExUnit**: Comprehensive testing framework

### Key Modules

```
lib/
├── credit_approver/
│   ├── application.ex              # OTP application
│   ├── utils.ex                   # Utility functions (currency formatting)
│   ├── credit_assessment.ex       # Combined data structures (Answer, CreditSummary)
│   ├── pdf_generator.ex           # PDF creation logic with Chrome validation
│   ├── notifier.ex                # Main email interface
│   └── notifier/
│       ├── base.ex                # Generic email utilities (DRY)
│       └── credit_assessment_email.ex # Credit-specific email logic
└── credit_approver_web/
    ├── live/
    │   └── credit_calculator.ex   # Main LiveView component
    ├── controllers/
    │   └── page_controller.ex     # Home page controller
    └── router.ex                  # URL routing
```

### Scalable Email Architecture

The application uses a **modular email system** designed for scalability:

- **🎯 Main Interface**: `Notifier` module provides a clean API for all email types
- **🔧 Generic Utilities**: `Notifier.Base` contains reusable email functions (DRY principle)
- **📧 Specific Email Types**: `Notifier.CreditAssessmentEmail` handles credit-related emails
- **✅ Easy Extension**: Adding new email types (welcome, reminders, invoices) is straightforward
- **🛡️ Error Handling**: Comprehensive logging and email validation at module boundaries
- **🔄 Backward Compatibility**: Existing code continues to work seamlessly

### Development Features

- **📧 Dev Mailbox**: Preview all sent emails at `/dev/mailbox`
- **📊 LiveDashboard**: Monitor application metrics at `/dev/dashboard`
- **🔄 Live Reload**: Automatic browser refresh during development
- **✨ Hot Code Reloading**: Real-time code updates

### State Management & Persistence

#### LiveView In-Memory State Storage

- **📝 Session-Based Storage**: All user answers, questionnaire progress, and calculated values are stored exclusively in Phoenix LiveView process memory
- **🚫 No Permanent Persistence**: User responses are **not saved to any database** - data exists only during the active browser session
- **🔄 Session Lifecycle**: When users close their browser or navigate away, all assessment data is immediately lost
- **⚡ Lightning-Fast Interactions**: Zero database I/O means instant form updates and real-time calculations
- **📧 Email-Only Records**: Final results are delivered via email with PDF attachment - this is the only permanent record

#### Technical Implementation

```elixir
# LiveView assigns store all user state
%{
  assigns: %{
    current_step: 1,
    answers: %{},           # User questionnaire responses
    financial_info: %{},    # Income/expense data  
    credit_summary: %{},    # Final calculation results
    email: ""               # Delivery address
  }
}
```

#### Architecture Benefits

- **🚀 Zero Infrastructure**: No database setup, migrations, or backups needed
- **🛡️ Privacy-First**: User data never persists beyond the session
- **⚡ Development Speed**: Instant setup and deployment
- **💰 Cost Effective**: No database hosting costs
- **🔧 Future-Proof**: Database persistence can be easily added when scaling requirements change

> **Architecture Decision**: This implementation prioritizes **simplicity, privacy, and speed** by using LiveView's built-in state management. User sessions are maintained in memory during the assessment process, and results are immediately delivered via email with PDF attachment. For production scale, audit requirements, or user account features, adding database persistence (PostgreSQL/MySQL) would be a straightforward enhancement without changing the core application logic.

---

#### 🧪 **Test Execution Warnings**

**When Chrome/Chromium is missing:**
```bash
$ mix test

⚠️  WARNING: Chrome/Chromium browser not found at: /Applications/Chromium.app/Contents/MacOS/Chromium
PDF generation tests will fail. Please install Chrome/Chromium:

macOS: brew install --cask chromium
Linux: apt-get install chromium-browser

🚨 SKIPPING PDF tests: Chrome/Chromium not found
To run PDF tests, install Chrome/Chromium and update config/test.exs

.............................................................................
Finished in 6.5 seconds (7.2s async, 0.0s sync)
77 tests, 0 failures, 9 skipped
```

**When Chrome/Chromium is available:**
```bash
$ mix test
✅ Chrome/Chromium browser found for PDF tests: /Applications/Google Chrome.app/Contents/MacOS/Google Chrome

.............................................................................
Finished in 13.6 seconds (7.2s async, 6.3s sync)
77 tests, 0 failures
```

> **⚠️ Important Note:** Please read the [Chrome/Chromium Installation Guide](#-chromechromium-installation-required-for-pdf-generation) above for detailed installation steps for Chrome/Chromium browser setup.

#### **Runtime Error Handling:**

When PDF generation is attempted without Chrome:
```elixir
{:error, "Chrome/Chromium browser not found at /path/to/chrome. Please install Chrome/Chromium or update the path in config.exs"}
```

### Email Delivery Problems

1. **Development**: Check the dev mailbox at [http://localhost:4000/dev/mailbox](http://localhost:4000/dev/mailbox)
2. **Email validation**: Ensure valid email format (contains @ and domain)
3. **Logs**: Monitor server output for Swoosh delivery confirmations

### Asset Compilation Issues

```bash
# Rebuild assets
mix assets.build

# Or reinstall asset dependencies
mix assets.setup
```

---

## 📦 Production Deployment

For production deployment:

```bash
# Set environment
export MIX_ENV=prod

# Install dependencies and compile
mix deps.get --only prod
mix compile

# Build optimized assets
mix assets.deploy

# Start the release
mix phx.server
```

> **Note**: Configure proper email delivery service (SMTP/SendGrid/etc.) in production config.

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
