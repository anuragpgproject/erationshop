# 🛍️ ErationShop

ErationShop is a Flutter-based e-commerce mobile application that provides a seamless shopping experience with an intuitive user interface, secure authentication, product browsing, cart management, order tracking, and push notifications.

## 📱 Features

- User Authentication (Login & Registration)
- Product Browsing by Categories
- Product Search
- Product Details
- Shopping Cart
- Wishlist
- Secure Checkout
- Order History
- Admin Dashboard
- Push Notifications (OneSignal)
- Responsive UI
- Firebase Integration

## 🛠️ Tech Stack

- Flutter
- Dart
- Firebase Authentication
- Cloud Firestore
- Firebase Storage
- OneSignal Notifications
- Provider / State Management
- Android Studio / VS Code

## 📂 Project Structure

```
lib/
├── admin/
├── models/
├── screens/
├── services/
├── widgets/
├── utils/
└── main.dart

android/
ios/
assets/
```

## 🚀 Getting Started

### Prerequisites

- Flutter SDK
- Dart SDK
- Android Studio or VS Code
- Firebase Project

### Installation

1. Clone the repository

```bash
git clone https://github.com/anuragpgproject/erationshop.git
```

2. Navigate to the project

```bash
cd erationshop
```

3. Install dependencies

```bash
flutter pub get
```

4. Run the application

```bash
flutter run
```

## 🔧 Configuration

Before running the application:

- Configure Firebase for Android and iOS.
- Add your `google-services.json` file inside:

```
android/app/
```

- Add your `GoogleService-Info.plist` for iOS.

- Configure your OneSignal App ID.

> **Important:** Never commit API keys or secret tokens to GitHub. Store them securely using environment variables or configuration files excluded from version control.

## 📸 Screenshots

Add screenshots of the application here.

| Home | Product | Cart |
|------|---------|------|
| ![](screenshots/home.png) | ![](screenshots/product.png) | ![](screenshots/cart.png) |

## 📦 Dependencies

Some major packages used include:

- firebase_core
- firebase_auth
- cloud_firestore
- firebase_storage
- image_picker
- provider
- onesignal_flutter
- shared_preferences

## 👨‍💻 Author

**Anurag P G**

GitHub: https://github.com/anuragpgproject

## 📄 License

This project is intended for educational and learning purposes.

---

⭐ If you found this project useful, consider giving it a star on GitHub.
