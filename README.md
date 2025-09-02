# CreditApprover

CreditApprover is a **credit approval web application** built with [Phoenix LiveView](https://hexdocs.pm/phoenix_live_view/) that assesses users' creditworthiness through a structured questionnaire, calculates eligible credit amounts, and provides professional PDF summaries via email.

> **Built as a coding exercise** - This is a full-stack Elixir/Phoenix application demonstrating real-time web interfaces, PDF generation, and email delivery capabilities.

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
- **📄 PDF Generation**: Automated credit summary reports using [ChromicPDF](https://hex.pm/packages/chromic_pdf)
- **📧 Email Delivery**: Instant email notifications with PDF attachments via [Swoosh](https://hexdocs.pm/swoosh)
- **🎨 Modern Design**: Responsive UI with professional styling

---

## 📋 Requirements

### System Dependencies

- **[Elixir](https://elixir-lang.org/install.html)** (>= 1.14)
- **[Erlang/OTP](https://www.erlang.org/downloads)** 
- **[Node.js](https://nodejs.org/)** (for asset compilation)
- **[Chromium/Chrome](https://www.chromium.org/)** (required for PDF generation)

> **Note**: No database required - this application runs completely in-memory.

### Chromium Installation Guide

**Important:** Chromium is required for PDF generation functionality. Please follow the installation instructions for your operating system:

#### macOS:
```bash
brew install chromium
```
Or download directly from [Chromium's download page](https://www.chromium.org/getting-involved/download-chromium/).

#### Ubuntu/Debian:
```bash
sudo apt update
sudo apt install chromium-browser
```

#### Windows:
1. Download the latest Chromium build from [Chromium's download page](https://www.chromium.org/getting-involved/download-chromium/)
2. Extract and install following the on-screen instructions

---

## 🛠️ Installation & Setup

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
- ✅ PDF generation functionality
- ✅ Email delivery system
- ✅ LiveView user interactions

---

## 🏗️ Technical Architecture

### Core Technologies

- **Phoenix LiveView**: Real-time, interactive web interface
- **ChromicPDF**: HTML-to-PDF conversion engine
- **Swoosh**: Email delivery with local preview
- **Tailwind CSS**: Modern utility-first styling
- **ExUnit**: Comprehensive testing framework

### Key Modules

```
lib/
├── credit_approver/
│   ├── application.ex          # OTP application
│   ├── utils.ex               # Utility functions (currency formatting)
│   ├── credit_summary.ex      # Data structure for assessments
│   ├── answer.ex              # Individual Q&A data structure
│   ├── pdf_generator.ex       # PDF creation logic
│   └── notifier.ex            # Email delivery system
└── credit_approver_web/
    ├── live/
    │   └── credit_calculator.ex # Main LiveView component
    ├── controllers/
    │   └── page_controller.ex   # Home page controller
    └── router.ex               # URL routing
```

### Development Features

- **📧 Dev Mailbox**: Preview all sent emails at `/dev/mailbox`
- **📊 LiveDashboard**: Monitor application metrics at `/dev/dashboard`
- **🔄 Live Reload**: Automatic browser refresh during development
- **✨ Hot Code Reloading**: Real-time code updates

---

## 🐛 Troubleshooting

### PDF Generation Issues

```bash
# Verify Chromium installation
chromium --version
# or
google-chrome --version

# Check application logs
mix phx.server
# Look for ChromicPDF error messages
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
