# 🚗 Vehicle LogBook & TA Bill Generator

A premium Flutter Android application for managing vehicle logbooks and generating Travelling Allowance (TA) bills. Originally an Excel VBA workbook (`.xlsm`), this app was fully migrated to a native mobile experience.

> **Version:** 1.3.0 | **Platform:** Android | **Framework:** Flutter

---

## 📱 Screenshots & Features

### ✨ Key Features

| Feature | Description |
|---------|-------------|
| 🏢 **Division Setup** | Configure division name, head quarter, city class, and incharge designation |
| 👥 **Staff Management** | Add, edit, delete, and reorder staff members with full details (Emp No, designation, salary, mobile) |
| 🚙 **Vehicle Management** | Manage up to 12 vehicles with number plates and nicknames |
| 📋 **Daily Reports** | Log daily trips with 5 different trip types, KM readings, time tracking, and DA eligibility |
| 📄 **PDF Generation** | Generate Vehicle LogBook (landscape) and TA Bill (2-page: Front voucher + Back journey table) |
| 📊 **Excel Generation** | Export LogBook and TA Bill as styled `.xlsx` spreadsheets |
| 💾 **Backup & Restore** | Export all data as JSON and import it back |
| 🌙 **Dark & Light Theme** | Premium Material 3 design with system-adaptive theming |

### 🔄 5 Trip Types

| Trip Type | Description |
|-----------|-------------|
| **Normal** | Regular trip with vehicle, staff, KM, time, journey, purpose |
| **No Trip** | Vehicle logged but no journey (only KM readings) |
| **Vehicle Allotted** | Vehicle assigned to external employees (names typed manually) |
| **Staff Allotted** | Staff uses external vehicle (vehicle details typed manually) |
| **Employee Training** | Training trip with fare calculation, no vehicle KM, manual distance |

### 💰 DA (Daily Allowance) Calculation

- **Eligibility:** Distance ≥ 8 km AND Duration ≥ 8 hours, OR trip type is Employee Training
- **Rate lookup:** 5 salary tiers × 4 city classes (A-1, A, B-1, Other)
- **Real-time indicator:** Green/Red badge shows DA eligibility while entering trip data

---

## 🏗️ Architecture

```
lib/
├── main.dart                          # App entry + animated splash screen
├── db/
│   └── database_helper.dart           # SQLite database (singleton, full CRUD)
├── generators/
│   ├── logbook_generator.dart         # Vehicle LogBook → PDF
│   ├── logbook_excel_generator.dart   # Vehicle LogBook → Excel
│   ├── ta_bill_generator.dart         # TA Bill → PDF (Front + Back)
│   └── ta_bill_excel_generator.dart   # TA Bill → Excel (2 sheets)
├── models/
│   ├── config.dart                    # Division configuration
│   ├── da_rate.dart                   # DA rate lookup table
│   ├── daily_report.dart              # Daily report / trip entry
│   ├── staff.dart                     # Staff member
│   └── vehicle.dart                   # Vehicle
├── screens/
│   ├── home_screen.dart               # Bottom navigation (4 tabs)
│   ├── division_setup_screen.dart     # First-time / edit config
│   ├── daily_report_list_screen.dart  # Report list with filters & delete
│   ├── trip_entry_screen.dart         # Trip entry form (5 types)
│   ├── generate_screen.dart           # PDF/Excel generation
│   ├── staff_management_screen.dart   # Staff CRUD + reorder
│   ├── vehicle_management_screen.dart # Vehicle CRUD
│   └── settings_screen.dart           # Settings, backup, DA rates
├── theme/
│   └── app_theme.dart                 # Material 3 light/dark theme
└── utils/
    ├── constants.dart                 # App constants & certificates
    └── rupee_to_words.dart            # ₹ → Indian words converter
```

### Tech Stack

| Component | Technology |
|-----------|-----------|
| Framework | Flutter 3.x (Dart) |
| Database | SQLite via `sqflite` |
| PDF Engine | `pdf` + `printing` packages |
| Excel Engine | `excel` package |
| Design System | Material 3 with Google Fonts (Inter, Outfit) |
| File Sharing | `share_plus` |
| State | `setState` + Singleton DB pattern |

---

## 🤖 Built with AI

This entire application was **built using AI-assisted development** with **Google's Gemini AI (Antigravity)** — an advanced agentic coding assistant.

### How It Was Built

1. **📊 Analysis Phase** — The AI analyzed the original Excel workbook (`Vehicle LogBook & TA Bill Generator by 220kV Deodar SS(V1.3).xlsm`), extracting:
   - All 16 VBA modules and forms (~6,500 lines of VBA code)
   - Sheet structures, formulas, and data validation rules
   - Print layouts and output formats
   - Business logic for DA calculation, trip types, and Rupee-to-words conversion

2. **📋 Planning Phase** — AI created a detailed implementation plan mapping every Excel feature to Flutter equivalents:
   - VBA `UserForm` → Flutter `Screen`
   - Excel sheets → SQLite tables
   - VBA macros → Dart utility functions
   - Print areas → PDF/Excel generators

3. **⚡ Development Phase** — AI wrote all 22 Dart files in a systematic order:
   - Data models and database layer first
   - Theme and navigation framework
   - All UI screens with business logic
   - PDF and Excel document generators
   - Iterative bug fixing and build verification

4. **🔧 Debugging Phase** — AI resolved:
   - Android SDK compatibility issues (compileSdk, build-tools)
   - Package dependency conflicts (file_picker vs share_plus)
   - Navigation bugs (splash → setup → home flow)
   - Deprecated API migrations

### AI Development Stats

| Metric | Value |
|--------|-------|
| VBA code analyzed | ~6,500 lines across 16 modules |
| Dart files created | 22 files |
| Total Dart code | ~5,000+ lines |
| Build iterations | Multiple cycles with automated fixes |
| Development time | Single conversation session |

> **Note:** While the AI generated the code, all decisions about app design, feature requirements, and platform choice were made by the human developer. The AI served as a pair programming partner, translating requirements into working code.

---

## 🚀 Getting Started

### Prerequisites

- Flutter SDK 3.12+ installed
- Android SDK with API 36
- Android device or emulator

### Installation

```bash
# Clone or navigate to the project
cd vehicle_logbook

# Get dependencies
flutter pub get

# Run on connected device
flutter run

# Build release APK
flutter build apk --release
```

### First Launch

1. **Splash Screen** → Animated branding
2. **Division Setup** → Enter your division, head quarter, city class, and incharge designation
3. **Home Screen** → 4 tabs: Daily Reports, Generate, Staff, Settings
4. **Add Staff & Vehicles** → Go to Staff and Settings tabs to configure
5. **Start Logging** → Tap "New Entry" on Daily Reports to log trips
6. **Generate Documents** → Go to Generate tab to create PDF/Excel LogBook or TA Bill

---

## 📄 Document Output

### Vehicle LogBook (PDF/Excel)
- Landscape format with 12-column table
- Filtered by vehicle and month
- Includes: Sr No, Date, Staff Names, Places, Purpose, KM readings, Time, Distance, Duration
- Total KMs calculation at bottom
- Incharge signature block

### TA Bill (PDF/Excel)
- **Front Page:** Employee details, 7 standard certificates, financial summary (Travel fare + DA), amount in words (Indian Rupee format), 6 signature blocks
- **Back Page:** Detailed journey table with departure/arrival info, fare, KMs, DA days, purpose

---

## 📦 Dependencies

```yaml
sqflite: ^2.4.2        # Local SQLite database
pdf: ^3.11.2            # PDF document generation
printing: ^5.14.2       # PDF preview and printing
excel: ^4.0.6           # Excel spreadsheet generation
intl: ^0.20.2           # Date formatting and localization
path_provider: ^2.1.5   # File system paths
share_plus: ^10.1.4     # Share files via system share sheet
google_fonts: ^8.1.0    # Premium typography (Inter, Outfit)
provider: ^6.1.5        # State management
```

---

## 🏢 About

**General Purpose Use App**

This app digitizes the vehicle logbook and TA bill generation process, replacing the Excel-based workflow with a mobile-first experience that works offline and generates professional documents on-the-go.

---

<p align="center">
  <b></b><br>
  <i>AI-Assisted Development with Google Gemini</i>
</p>
