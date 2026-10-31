# LUMI SPA
### Spa Booking & Skincare Management Application

**LUMI SPA** is a Flutter-based mobile application designed to provide a modern and convenient digital experience for spa and skincare services.

The application brings together spa service discovery, appointment booking, skincare product browsing, personal wellness journaling, and customer account management within a unified mobile platform.

The project focuses on combining an elegant user interface with practical features and a Firebase-powered backend.

## 1. Project Overview

LUMI SPA is developed as a mobile application project, with the goal of supporting both customer-facing spa services and future administrative management features.

**Project objectives:**
- Simplify the process of discovering and booking spa treatments.
- Provide a digital catalog of skincare products.
- Support personalized customer experiences.
- Organize appointment information and personal wellness activities.
- Integrate cloud-based services for authentication and data management.
- Build a maintainable application that supports collaborative development.

## 2. Core Features

### Authentication & User Accounts

The application includes user authentication and account-related interfaces, supporting a personalized experience for returning customers.

### Home & Service Discovery

The home screen serves as the central navigation point for spa services, skincare products, appointments, and other customer features.

Users can explore available treatments and view detailed service information.

### Spa Services & Appointment Booking

The booking module provides interfaces for selecting spa services and organizing appointment information.

Key components include:
- Spa service catalog
- Service detail screens
- Appointment booking interface
- Customer appointment screens

### Skincare Shopping

LUMI SPA includes a skincare product catalog connected to Firebase Firestore.

The project currently contains a demo dataset of **50 skincare products**, together with scripts for importing and updating product information.

### Wellness Journal

The journal module provides a dedicated interface for personal skincare and wellness-related entries, supporting the application's broader focus on customer self-care.

### Notifications

A dedicated notifications screen is included to support the application's customer communication experience.

### Administration & Future Development

The project is structured to support further development of administrative features, including service management, product management, appointment tracking, and customer operations.

These features represent development directions and should not all be considered completed.

## 3. Technology Stack

| Layer | Technologies |
|---|---|
| Mobile development | Flutter, Dart |
| Backend services | Firebase, Node.js |
| Database | Cloud Firestore |
| Authentication | Firebase Authentication integration |
| Navigation | GoRouter |
| Local persistence | SharedPreferences, Flutter Secure Storage |
| Development environment | Android Studio, VS Code |
| Version control | Git, GitHub |

## 4. Project Structure

```text
lumi_spa/
├── android/
├── assets/
├── backend/
│   ├── firebase.js
│   ├── server.js
│   ├── seed.js
│   ├── lumi_product_import/
│   └── package.json
├── lib/
│   ├── app/
│   ├── core/
│   │   ├── data/
│   │   ├── session/
│   │   └── theme/
│   ├── features/
│   │   ├── auth/
│   │   ├── home/
│   │   ├── onboarding/
│   │   └── splash/
│   ├── firebase_options.dart
│   └── main.dart
├── firebase.json
├── pubspec.yaml
└── README.md
```

## 5. Firebase Integration

LUMI SPA uses a shared Firebase project to support application development.

**Firebase Project ID:** `lumi-spa`

The Firebase integration includes:

- Firebase configuration for the Flutter application
- Cloud Firestore product data
- Firebase Authentication integration
- Backend scripts for importing and updating product information

The product catalog currently includes 50 demo products stored in Firestore.

Firebase permissions and Firestore Security Rules must be reviewed before production deployment.

## 6. Getting Started

### Prerequisites

Install the following tools:

- Flutter SDK
- Dart SDK
- Android Studio or VS Code
- Android emulator or a compatible physical device
- Git

### Clone the Repository

```bash
git clone https://github.com/minhnguyet2810/lumi-spa.git
cd lumi-spa
git switch feature/admin-dashboard
```

The latest integrated development code is currently available on the `feature/admin-dashboard` branch.

### Install Dependencies

```bash
flutter pub get
```

### Run the Application

```bash
flutter run
```

For Android development, make sure the Android SDK, emulator, and project dependencies are correctly configured.

### Backend Setup

The `backend/` directory contains Node.js scripts and Firebase-related utilities.

```bash
cd backend
npm install
```

Backend scripts that access Firebase Admin services require appropriately configured credentials. Never commit service account private keys, access tokens, or `.env` secrets.

The product import scripts should only be executed when necessary, because they can modify shared Firestore data.

## 7. Collaborative Development

LUMI SPA is developed collaboratively using GitHub.

Recommended workflow:

1. Clone the repository.
2. Create a separate branch for your assigned feature.
3. Implement and test your changes.
4. Commit with a descriptive message.
5. Push your branch to GitHub.
6. Open a pull request for review.
7. Merge approved changes into the agreed integration branch.

Example:

```bash
git switch feature/admin-dashboard
git pull origin feature/admin-dashboard
git switch -c feature/my-feature
```

Team members should avoid committing directly to another developer's active feature branch.

## 8. Design Direction

The LUMI SPA interface follows a classic, elegant spa aesthetic.

The visual direction emphasizes:
- Soft blush and rose-inspired colors
- Ivory backgrounds and muted plum typography
- Refined serif headings
- Clean, readable layouts
- Calm and minimal visual interactions
- A premium skincare and wellness experience

The application is designed to feel welcoming, polished, and easy to navigate.

## 9. Development Status

**Status: Active Development**

Implemented or integrated project components include Flutter navigation and screens, service discovery, booking interfaces, skincare catalog, wellness journal, notifications interface, and Firebase configuration.

Planned work includes further backend integration, end-to-end booking functionality, shopping workflows, customer account features, administrative tools, testing, and deployment preparation.

## 10. Project Purpose

LUMI SPA is developed as an academic mobile application project and a practical demonstration of Flutter development, Firebase integration, user interface design, and collaborative software engineering.

The project is intended to evolve into a more complete spa service and skincare management platform.

---

**LUMI SPA — A more thoughtful digital spa experience.**