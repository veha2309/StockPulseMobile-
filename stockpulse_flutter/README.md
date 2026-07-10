# 📱 StockPulse — Mobile Trading Terminal (Flutter)

StockPulse Mobile is a professional-grade trading simulation application built with **Flutter**. Optimized for high performance and low-latency interaction, it features premium glassmorphic widgets, custom-painted charting tools, local persistence, and secure real-time synchronization with the StockPulse backend.

---

## ✨ Key Mobile Features

### 📊 Advanced Mobile Visualization
* **Custom CandleChart**: High-precision custom-painted candlestick charts designed explicitly for touch screens, with crosshair tracking for Open, High, Low, and Close values.
* **Arc Portfolio Dial**: Sleek visual ring representation for quick viewing of portfolio distribution and performance metrics.
* **Premium Glassmorphic UI**: Tailored `GlassCard` and container components that leverage Flutter's native blur capabilities for a unified premium design.
* **Shimmer Loading States**: Clean visual feedback during network operations using the `shimmer` package.

### 📈 Mobile-First Trading Simulator
* **Sector Filtering**: Sort and filter stocks easily across major sectors (Banking, IT, Pharma, Auto, Energy, Metals, FMCG, etc.).
* **Stop Loss & Take Profit (SL/TP)**: Configure custom bounds for individual trades to trigger risk-management logic.
* **Comprehensive Options Chain**:
  * Real-time generation of Calls (CE) and Puts (PE).
  * Greek approximations including **Delta, Gamma, Theta, Vega, and IV (Implied Volatility)** computed on-device.
* **Automated FIFO Execution**: Trades are settled sequentially following First-In, First-Out pricing rules.

### 🔐 Secure Identity & Sync
* **OTP Verification**: Secure verification flow via `otp_verification_screen.dart` during registration and transaction processes.
* **Sync on Request**: Pull-to-refresh on core views forces an immediate database re-evaluation.
* **Hive Local Persistence**: Safe, encrypted offline cache for user session data.

---

## 🛠️ Mobile Tech Stack

| Layer | Package / Tool | Version | Description |
| :--- | :--- | :--- | :--- |
| **Framework** | Flutter SDK | `^3.11.4` | Cross-platform UI engine |
| **State Management**| Provider | `^6.1.5+1` | Clean reactive state management |
| **Backend Integration** | Supabase Flutter | `^2.12.2` | DB query execution and real-time triggers |
| **Persistence** | Hive / Hive Flutter | `^2.2.3` / `^1.1.0`| Lightweight, fast NoSQL local storage |
| **Charts & Drawing** | Custom Painter & FL Chart | Native / `^1.2.0` | Custom rendering of candles and arcs |
| **Theme / Design** | Google Fonts & Cupertino | `^8.0.2` / `^1.0.8`| Typography and native iOS/Android styling |
| **Security** | BCrypt Dart | `^1.2.0` | Secure encryption and hashing helpers |

---

## 🔌 Core Flutter Architecture

State is managed globally and scoped dynamically via providers located under `lib/providers/`:

```
stockpulse_flutter/
├── lib/
│   ├── models/                # Data structures (UserData, PortfolioItem, OptionPosition)
│   ├── providers/             # State management (AuthProvider, MarketProvider, PortfolioProvider)
│   ├── screens/               # Interactive UI Views
│   │   ├── splash_screen.dart           # App boot and session validation
│   │   ├── login_screen.dart            # User login
│   │   ├── register_screen.dart         # Registration form
│   │   ├── otp_verification_screen.dart # Security token validation
│   │   ├── dashboard_screen.dart        # Unified stats & watchlists
│   │   ├── stock_list_screen.dart       # Sector-filterable equities
│   │   ├── stock_detail_screen.dart     # Interactive charts and trade executor
│   │   ├── options_chain_screen.dart    # CE/PE chains with Greeks
│   │   ├── portfolio_screen.dart        # Holdings & active positions
│   │   ├── recharge_screen.dart         # Request tokens workflow
│   │   ├── profile_screen.dart          # Account settings & details
│   │   └── trade_history_screen.dart    # Equity + options audit logs
│   ├── widgets/               # Premium glassmorphic widgets & graphics
│   │   ├── candle_chart.dart            # Custom-painted interactive candlesticks
│   │   ├── arc_portfolio_dial.dart      # Custom-painted dial representing assets
│   │   ├── dial_card_view.dart          # Wrapper cards for metrics
│   │   ├── glass_card.dart              # Custom glassmorphic cards
│   │   └── trade_modal.dart             # Trade ticket overlay
│   └── main.dart              # App initialization (Hive, Supabase, Providers)
```

---

## ⚙️ Development Setup

### 1. Prerequisites
* Flutter SDK (`v3.19` or higher recommended).
* Java Development Kit (JDK) and Android SDK / Xcode for iOS compilation.

### 2. Configure Environment Variables
Create a `.env` file in the root directory:
```env
SUPABASE_URL=https://<your-project>.supabase.co
SUPABASE_ANON_KEY=<your-anon-key>
SUPABASE_SERVICE_ROLE_KEY=<your-service-role-key>
```
*Note: Make sure `.env` is listed in your `pubspec.yaml` assets so the app can load it at boot time.*

### 3. Installation
```bash
# Get dependencies
flutter pub get

# Generate launcher icons if necessary
flutter pub run flutter_launcher_icons
```

### 4. Running the App
Ensure an emulator is active or a physical device is connected, then run:
```bash
flutter run
```

---

> [!IMPORTANT]
> **Production Safety**: Ensure `SUPABASE_SERVICE_ROLE_KEY` is obfuscated or restricted to server operations before publishing to public stores.

© 2026 StockPulse Team. All rights reserved.
