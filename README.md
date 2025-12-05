# BRACU Student Hub 🎓

A comprehensive Flutter-based mobile application for BRAC University students that connects to the university's Student Learning Management System (SLMS) and provides essential academic tools and information in a mobile-friendly format with offline capabilities.

[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0)
[![Flutter](https://img.shields.io/badge/Flutter-3.8.1+-02569B?logo=flutter)](https://flutter.dev)
[![FastAPI](https://img.shields.io/badge/FastAPI-Backend-009688?logo=fastapi)](https://fastapi.tiangolo.com)

---

## 📋 Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Project Structure](#project-structure)
- [Prerequisites](#prerequisites)
- [Installation](#installation)
  - [Flutter App Setup](#flutter-app-setup)
  - [Backend Server Setup](#backend-server-setup)
- [Configuration](#configuration)
- [Usage](#usage)
- [API Documentation](#api-documentation)
- [Development](#development)
- [Contributing](#contributing)
- [License](#license)
- [Contributors](#contributors)

---

## 🌟 Overview

BRACU Student Hub is designed to enhance the student experience at BRAC University by providing:

- **Mobile-First Design**: Optimized for smartphones with intuitive navigation
- **Offline Capabilities**: Access cached data even without internet connection
- **Academic Management**: View schedules, exam dates, grades, and advising information
- **Social Features**: Share schedules with friends and check their availability
- **Library Integration**: Check borrowed books and manage renewals
- **Notifications**: Set alarms for classes and get reminders for important dates

The project consists of two main components:

1. **Flutter Mobile App** (`cse47020_student_app/`) - Cross-platform mobile application
2. **FastAPI Backend** (`bracu_scrapper_server/`) - Data scraping and API service

---

## ✨ Features

### 🔐 Authentication

- Secure login via BRAC University SSO (Single Sign-On)
- Token-based authentication with automatic refresh
- Secure credential storage using Flutter Secure Storage

### 📚 Academic Features

- **Student Profile**: View personal and academic information
- **Class Schedule**: Daily/weekly class timetable with room numbers
- **Exam Schedule**: Midterm and final exam schedules
- **Advising Info**: Upcoming advising periods and reminders
- **Friend Schedules**: Scan QR codes to share schedules and check friend availability

### 📖 Library Management

- View borrowed books
- Check due dates
- Renew books directly from the app
- Automatic notifications for due books

### 🔔 Notifications & Alarms

- Set custom alarms for classes
- Reminders for upcoming exams
- Library book due date notifications

### 📊 Backend API (BRACU Info API)

- University announcements
- Exam schedules
- Academic calendar dates
- News and updates
- Contact information
- Transport schedules
- People directory

---

## 📁 Project Structure

```
CSE47020_Student_App/
├── cse47020_student_app/          # Flutter mobile application
│   ├── lib/
│   │   ├── main.dart              # App entry point
│   │   ├── api/                   # API integration
│   │   │   └── bracu_auth_manager.dart
│   │   ├── pages/                 # UI screens
│   │   │   ├── home.dart
│   │   │   ├── login.dart
│   │   │   ├── student_profile.dart
│   │   │   ├── student_schedule.dart
│   │   │   ├── exam_schedule.dart
│   │   │   ├── friend_schedule.dart
│   │   │   ├── library.dart
│   │   │   ├── alarms.dart
│   │   │   ├── advising_info.dart
│   │   │   ├── share_schedule.dart
│   │   │   └── scan_schedule.dart
│   │   ├── model/                 # Data models
│   │   ├── services/              # Background services
│   │   │   ├── notification_service.dart
│   │   │   └── credentials_service.dart
│   │   ├── widgets/               # Reusable UI components
│   │   └── tools/                 # Utility functions
│   ├── android/                   # Android-specific files
│   ├── ios/                       # iOS-specific files
│   ├── pubspec.yaml               # Flutter dependencies
│   └── assets/                    # Images and icons
│
├── bracu_scrapper_server/         # Backend API server
│   ├── api.py                     # FastAPI application
│   ├── schema.sql                 # Database schema
│   ├── scrappers/                 # Web scrapers
│   │   ├── db_scrape_announcements.py
│   │   ├── db_scrape_academic_dates.py
│   │   ├── db_scrape_exam_schedule.py
│   │   ├── db_scrape_news.py
│   │   ├── db_scrape_people_info.py
│   │   ├── db_scrape_transport.py
│   │   └── db_scrape_contact_info.py
│   ├── scrapper_template/         # Scraper templates
│   └── client/                    # Frontend HTML pages
│
├── README.md                      # This file
├── CONTRIBUTORS.md                # Contributor information
├── TODO.md                        # Development roadmap
└── LICENSE                        # GPL-3.0 License
```

---

## 🔧 Prerequisites

### For Flutter App

- **Flutter SDK**: Version 3.8.1 or higher
  - [Install Flutter](https://docs.flutter.dev/get-started/install)
- **Dart SDK**: Included with Flutter
- **Android Studio** or **Xcode**: For building Android/iOS apps
- **Git**: For version control

### For Backend Server

- **Python**: 3.8 or higher
- **MySQL**: 8.0 or higher
- **Docker** (optional): For containerized MySQL setup

---

## 🚀 Installation

### Flutter App Setup

1. **Clone the repository**

   ```bash
   git clone https://github.com/ehteshamulhaqueadit/CSE47020_Student_App.git
   cd CSE47020_Student_App/cse47020_student_app
   ```

2. **Install Flutter dependencies**

   ```bash
   flutter pub get
   ```

3. **Generate app icons** (if needed)

   ```bash
   flutter pub run flutter_launcher_icons
   ```

4. **Check Flutter setup**

   ```bash
   flutter doctor
   ```

   Fix any issues reported by Flutter Doctor.

5. **Run the app**

   For Android:

   ```bash
   flutter run
   ```

   For iOS (macOS only):

   ```bash
   flutter run -d ios
   ```

   For web:

   ```bash
   flutter run -d chrome
   ```

6. **Build release version**

   For Android APK:

   ```bash
   flutter build apk --release
   ```

   For Android App Bundle:

   ```bash
   flutter build appbundle --release
   ```

   For iOS (macOS only):

   ```bash
   flutter build ios --release
   ```

---

### Backend Server Setup

1. **Navigate to the server directory**

   ```bash
   cd bracu_scrapper_server
   ```

2. **Install Python dependencies**

   ```bash
   pip install bs4 cloudscraper lxml mysql-connector-python pdfplumber "fastapi[standard-no-fastapi-cloud-cli]" uvicorn sqlalchemy pydantic
   ```

   If `mysql-connector-python` has issues, try:

   ```bash
   pip install pymysql
   ```

3. **Set up MySQL Database**

   **Option A: Using Docker** (Recommended)

   ```bash
   # Start MySQL container
   docker run --name mysql-server -e MYSQL_ALLOW_EMPTY_PASSWORD=yes -p 3306:3306 -d mysql:oraclelinux9

   # Access MySQL container
   docker exec -it mysql-server /bin/bash
   mysql -u root
   ```

   **Option B: Local MySQL Installation**

   - Install MySQL from [official website](https://dev.mysql.com/downloads/mysql/)
   - Start MySQL service

4. **Create and configure database**

   ```sql
   # Run the schema.sql file to create database and tables
   source /path/to/schema.sql;
   ```

   Or manually:

   ```bash
   mysql -u root -p < schema.sql
   ```

5. **Configure database connection**

   Edit `api.py` and update the database credentials:

   ```python
   DB_USER = "root"
   DB_PASSWORD = ""  # Your MySQL password
   DB_HOST = "localhost"
   DB_NAME = "bracu_info"
   ```

6. **Run web scrapers to populate data**

   ```bash
   cd scrappers
   python db_scrape_announcements.py
   python db_scrape_academic_dates.py
   python db_scrape_exam_schedule.py
   python db_scrape_news.py
   python db_scrape_transport.py
   python db_scrape_contact_info.py
   python db_scrape_people_info.py
   ```

7. **Start the FastAPI server**

   ```bash
   fastapi dev api.py
   ```

   The API will be available at: `http://localhost:8000`

   API Documentation: `http://localhost:8000/docs`

8. **Restart MySQL after system reboot** (Docker)
   ```bash
   docker start mysql-server
   ```

---

## ⚙️ Configuration

### Flutter App Configuration

**Update API Endpoints** (if using custom backend):

- Edit files in `lib/api/` to point to your backend server URL

**Configure Notifications**:

- The app uses `flutter_local_notifications` for reminders
- Timezone settings are handled automatically

**Secure Storage**:

- Credentials are stored using `flutter_secure_storage`
- No additional configuration needed

### Backend Configuration

**Database Schema**:
The database includes the following tables:

- `Announcements` - University announcements
- `ExamSchedule` - Exam schedules by course and section
- `AcademicDates` - Important academic dates
- `News` - University news
- `Transport` - Bus routes and schedules
- `ContactInfo` - Department contact information
- `People` - Faculty and staff directory

**Scraper Configuration**:

- Edit scraper files in `scrappers/` to adjust scraping intervals
- Update URLs in `urls.txt` if university website structure changes

---

## 💡 Usage

### For Students

1. **Login**

   - Open the app
   - Enter your BRAC University credentials
   - The app will authenticate via BRACU SSO

2. **View Your Schedule**

   - Navigate to "Student Schedule"
   - View classes organized by day
   - See room numbers and timings

3. **Check Exam Schedule**

   - Go to "Exam Schedule"
   - Filter by course code or section

4. **Share Schedule with Friends**

   - Go to "Share Class Schedule"
   - Generate a QR code
   - Friends can scan to add your schedule

5. **Check Friend Availability**

   - Go to "Friends Availability"
   - View when friends are free or in class

6. **Manage Library Books**

   - Navigate to "Library"
   - Login with library credentials
   - View borrowed books and renew them

7. **Set Alarms**
   - Go to "Set Alarms"
   - Create custom reminders for classes

### For Developers

**Running in Debug Mode**:

```bash
flutter run --debug
```

**Running Tests**:

```bash
flutter test
```

**Analyzing Code**:

```bash
flutter analyze
```

**API Testing**:
Visit `http://localhost:8000/docs` for interactive API documentation (Swagger UI)

---

## 📖 API Documentation

### Available Endpoints

#### 1. **GET /announcements**

Retrieve university announcements

```
Query Parameters:
- start_date (optional): YYYY-MM-DD
- end_date (optional): YYYY-MM-DD
- limit (optional): Maximum number of results
```

#### 2. **GET /exam-schedule**

Get exam schedules

```
Query Parameters:
- exam_type (required): e.g., "Final Fall 2024"
- course_code (required): e.g., "CSE331"
- section (optional): e.g., "1"
- student_id (optional): Filter by student ID
```

#### 3. **GET /academic-dates**

Retrieve academic calendar dates

```
Query Parameters:
- event_name (optional): Search by event name
- start_date (optional): YYYY-MM-DD
- end_date (optional): YYYY-MM-DD
```

#### 4. **GET /news**

Get university news

```
Query Parameters:
- title (optional): Filter by title
- start_date (optional): YYYY-MM-DD
- end_date (optional): YYYY-MM-DD
- exact_date (optional): YYYY-MM-DD
```

#### 5. **GET /transport**

Get transport/bus schedules

#### 6. **GET /contact-info**

Retrieve department contact information

#### 7. **GET /people**

Get faculty and staff directory

**Interactive API Docs**: Available at `/docs` when server is running

---

## 🛠️ Development

### Project Dependencies

**Flutter Packages**:

- `flutter_secure_storage` - Secure credential storage
- `shared_preferences` - Local data persistence
- `http` - HTTP requests
- `connectivity_plus` - Network connectivity
- `webview_flutter` - Embedded web views
- `mobile_scanner` - QR code scanning
- `flutter_local_notifications` - Push notifications
- `intl` - Internationalization
- `permission_handler` - Runtime permissions
- `qr` - QR code generation
- `path_provider` - File system paths
- `timezone` - Timezone handling

**Python Packages**:

- `fastapi` - Web framework
- `uvicorn` - ASGI server
- `sqlalchemy` - Database ORM
- `mysql-connector-python` - MySQL driver
- `pydantic` - Data validation
- `beautifulsoup4` - Web scraping
- `cloudscraper` - Cloudflare bypass
- `pdfplumber` - PDF parsing
- `lxml` - XML/HTML parsing

### Code Style

**Flutter/Dart**:

- Follow [Effective Dart](https://dart.dev/guides/language/effective-dart) guidelines
- Use `flutter analyze` to check code quality
- Format code with `dart format`

**Python**:

- Follow PEP 8 style guide
- Use type hints where applicable
- Document functions with docstrings

### Testing

**Flutter**:

```bash
# Run all tests
flutter test

# Run specific test file
flutter test test/widget_test.dart

# Run tests with coverage
flutter test --coverage
```

**Backend**:

- Test API endpoints using the Swagger UI at `/docs`
- Use tools like Postman or curl for manual testing

---

## 🤝 Contributing

We welcome contributions! Here's how you can help:

1. **Fork the repository**

   ```bash
   git fork https://github.com/ehteshamulhaqueadit/CSE47020_Student_App.git
   ```

2. **Create a feature branch**

   ```bash
   git checkout -b feature/your-feature-name
   ```

3. **Make your changes**

   - Write clean, documented code
   - Follow the existing code style
   - Test your changes thoroughly

4. **Commit your changes**

   ```bash
   git commit -m "Add: Description of your feature"
   ```

5. **Push to your fork**

   ```bash
   git push origin feature/your-feature-name
   ```

6. **Create a Pull Request**
   - Provide a clear description of changes
   - Reference any related issues

### Contribution Guidelines

- **Code Quality**: Ensure code passes all linters and tests
- **Documentation**: Update README and code comments
- **Commit Messages**: Use clear, descriptive commit messages
- **Issues**: Check existing issues before creating new ones
- **Communication**: Be respectful and constructive

### Development Roadmap

See [TODO.md](TODO.md) for planned features and improvements.

---

## 📄 License

This project is licensed under the **GNU General Public License v3.0**.

See [LICENSE](LICENSE) file for details.

**Key Points**:

- ✅ Free to use, modify, and distribute
- ✅ Source code must remain open
- ✅ Changes must be documented
- ⚠️ No warranty provided

---

## 👥 Contributors

**Akid Anis**

- Student ID: 22241087
- Email: akid.anis@g.bracu.ac.bd

**Ehteshamul Haque Adit**

- Repository Owner
- GitHub: [@ehteshamulhaqueadit](https://github.com/ehteshamulhaqueadit)

Want to contribute? See [Contributing](#contributing) section above!

---

## 📞 Support & Contact

### For Users

- **Issues**: Report bugs via [GitHub Issues](https://github.com/ehteshamulhaqueadit/CSE47020_Student_App/issues)
- **BRACU Students**: For app-related questions, contact the development team

### For Developers

- **Documentation**: Check `/docs` endpoint for API documentation
- **Code Questions**: Open a discussion on GitHub

---

## 🙏 Acknowledgments

- BRAC University for providing the platform
- Flutter team for the excellent framework
- FastAPI team for the robust backend framework
- All contributors and testers

---

## 📝 Additional Notes

### Security Considerations

- Never commit credentials or API keys
- Use environment variables for sensitive data
- Keep dependencies updated

### Known Issues

- See [TODO.md](TODO.md) for current limitations
- Check GitHub Issues for reported bugs

### Future Enhancements

- Push notifications for announcements
- Offline mode improvements
- Enhanced friend schedule management
- Integration with more BRACU services
- Dark mode support
- Multi-language support

---

**Made with ❤️ for BRAC University Students**

_Last Updated: December 2024_
