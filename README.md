# 🎡 Random Helper

A simple and intuitive lucky wheel app for making quick, fair decisions. Perfect for choosing what to eat, picking team members, or organizing activities.

[![Flutter](https://img.shields.io/badge/Flutter-3.5.0%2B-blue)](https://flutter.dev)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](#license)
[![Version](https://img.shields.io/badge/Version-1.0.1-informational)](#about)

## ✨ Features

✅ Create & manage custom wheels  
✅ Search & sort spins (Newest, Oldest, A-Z, Z-A)  
✅ Smooth wheel animations (2-10 second duration)  
✅ Shuffle & restore items (Fisher-Yates algorithm)  
✅ 15+ pre-built templates (Food, Games, Education, etc.)  
✅ Complete spin history & statistics  
✅ Favorites & bookmarks  
✅ Dark/Light mode  
✅ 6+ color palettes  
✅ Share wheels & results (WhatsApp, Email, Facebook)  
✅ Vietnamese UI  
✅ 100% offline - All data stored locally

## 🛠️ Tech Stack

| Component            | Technology                                        |
| -------------------- | ------------------------------------------------- |
| **Framework**        | Flutter 3.5+                                      |
| **Language**         | Dart 3.5+                                         |
| **Architecture**     | Clean Architecture (Presentation - Domain - Data) |
| **State Management** | Provider Pattern                                  |
| **Database**         | SQLite v2.2.8                                     |
| **UI Framework**     | Material Design 3                                 |

**Key Dependencies:**

- `provider: ^6.0.5` - State management
- `sqflite: ^2.2.8` - Local database
- `share_plus: ^7.2.1` - Share functionality
- `shared_preferences: ^2.2.2` - User preferences
- `intl: ^0.18.1` - Internationalization
- `uuid: ^3.0.7` - Unique ID generation

## 📁 Project Structure

```
lib/
├── main.dart                          # App entry point
├── core/
│   └── utils/
│       ├── theme.dart                # Dark/Light themes
│       ├── constants.dart            # App constants
│       ├── templates.dart            # 15+ spin templates
│       ├── color_palettes.dart       # Color schemes
│       ├── sort_options.dart         # Sorting utilities
│       └── vietnamese_helper.dart    # Localization
├── data/
│   ├── local/
│   │   └── db_helper.dart           # SQLite database manager
│   └── repositories/
│       └── spin_repository_impl.dart # Data layer implementation
├── domain/
│   ├── entities/                     # Data models (spin, item, template)
│   ├── repositories/                 # Repository interfaces
│   └── usecases/
│       ├── create_spin.dart
│       ├── spin_once.dart
│       ├── get_spins.dart
│       ├── shuffle_items.dart
│       └── restore_items.dart
└── presentation/
    ├── pages/
    │   ├── main_dashboard.dart       # Bottom navigation host
    │   ├── home_page.dart            # Wheels list & search
    │   ├── spin_page.dart            # Wheel spin screen
    │   ├── create_spin_page.dart     # Create new wheel
    │   ├── edit_spin_page.dart       # Edit wheel
    │   ├── history_page.dart         # Spin history
    │   ├── favorite_spins_page.dart  # Bookmarked wheels
    │   ├── suggestions_page.dart     # Template browser
    │   └── settings_page.dart        # App settings
    ├── providers/
    │   ├── spin_provider.dart        # Main state management
    │   └── theme_provider.dart       # Theme toggle
    └── widgets/
        └── wheel_view.dart           # Animated wheel widget
```

## 🚀 Quick Start

```bash
# Clone repository
git clone https://github.com/MyDang2705/Random_Helper.git
cd Random-helper

# Install dependencies
flutter pub get

# Run the app
flutter run

# Build release APK
flutter build apk --release
```

## 💡 Usage

1. **Create a Wheel** - Tap "+" and add items with custom name & color
2. **Use Templates** - Choose from 15+ pre-built templates in Suggestions
3. **Spin** - Tap the wheel to randomly select an item
4. **Share** - Share results via WhatsApp, Email, Facebook, etc.
5. **Manage** - Search, sort, favorite, and view history of all spins

## 📄 License

MIT License - See [LICENSE](LICENSE) file for details.

## 👨‍💻 Author

**MyDang2705** - [GitHub Profile](https://github.com/MyDang2705)

---

**Version:** 1.0.1+ | **Last Updated:** March 2026
