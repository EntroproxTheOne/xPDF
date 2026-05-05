# xPDF

<p align="center">
  <img src="assets/images/app_logo.png" width="128" alt="xPDF Logo">
</p>

xPDF is an all-in-one mobile PDF suite that allows users to create, edit, convert, and secure PDFs.

## Features

- **Create PDFs**: Generate PDFs from scratch or from existing documents and images.
- **Edit PDFs**: Split pages, add watermarks, insert page numbers, and more.
- **Convert**: Convert documents and images to PDF seamlessly.
- **Secure**: Lock PDFs with passwords to keep your documents safe.
- **Unlock & Check Security**: Unlock PDFs with the correct PIN and check whether a PDF is password-protected before opening.
- **Scan**: Built-in document scanner to digitize your physical papers.
- **Compress**: High-performance offline PDF compression to reduce file sizes.
- **Merge PDFs**: Combine multiple PDFs in order into a single readable document.

## Latest Updates

- Removed the unused profile icon from the mobile top bar.
- Improved History screen alignment so the title, helper text, and controls fit cleanly on mobile.
- Fixed PDF merge failures caused by page insertion issues in the PDF engine.
- Added simple PIN-based PDF locking, unlocking, and lock-status checking.
- Added service tests for PDF merge and security flows.

## Build APK

Create a debug APK with:

```bash
flutter build apk --debug
```

The APK is generated at:

```text
build/app/outputs/flutter-apk/app-debug.apk
```

## Getting Started

To run the application locally, you will need Flutter installed on your machine.

1. Clone the repository:
   ```bash
   git clone https://github.com/EntroproxTheOne/xPDF.git
   ```

2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Run the app:
   ```bash
   flutter run
   ```

4. Run checks:
   ```bash
   flutter analyze
   flutter test
   ```

## Technologies Used

- **Flutter & Dart**: For building the cross-platform UI and business logic.
- **State Management**: flutter_bloc for managing the application state.
- **PDF Processing**: Syncfusion Flutter PDF, pdf, pdfrx.
- **Local Storage**: Hive CE for fast, offline storage of app data.

## Architecture

The project follows a feature-first architecture using BLoC for state management. The user interface leverages a modern glassmorphism design with responsive layouts and smooth animations.
