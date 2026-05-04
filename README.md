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
- **Scan**: Built-in document scanner to digitize your physical papers.
- **Compress**: High-performance offline PDF compression to reduce file sizes.

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

## Technologies Used

- **Flutter & Dart**: For building the cross-platform UI and business logic.
- **State Management**: flutter_bloc for managing the application state.
- **PDF Processing**: Syncfusion Flutter PDF, pdf, pdfrx.
- **Local Storage**: Hive CE for fast, offline storage of app data.

## Architecture

The project follows a feature-first architecture using BLoC for state management. The user interface leverages a modern glassmorphism design with responsive layouts and smooth animations.
