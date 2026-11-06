# ShopMart: Flutter Shopping App

A clothing shopping app built with Flutter and Cloud Firestore for the Mobile Applications course at Princess Sumaya University for Technology (PSUT), 2026. Built by a team of two.

## Features

- **Product grid** with category filter chips, search with suggestions (autocomplete and a search screen), and sorting (recommended, price low to high, price high to low, title A to Z)
- **Favorites** tab, with a heart toggle on every product
- **Basket** tab with quantity controls, swipe-to-delete, a live subtotal, and a checkout summary dialog
- **Product details** with an image carousel, expandable product and shipping sections, and a button that opens a link in the browser
- **Login form** with validation and a live password-strength meter and requirements checklist
- **Navigation drawer** with Login, Settings (clear cart), and Contact Us (tap an email to open the mail app)
- **Firestore saving:** each user's favorites and cart items are written to Cloud Firestore under `users/{email}/favorites` and `users/{email}/cart`
- Flutter concepts practiced: `FutureBuilder`, `StreamBuilder`, sliver widgets (`CustomScrollView`, `SliverGrid`), `RefreshIndicator`, `Dismissible`, `Hero` animations, `AnimatedSwitcher`

## Tech stack

Flutter (Dart), Cloud Firestore (`cloud_firestore`, `firebase_core`), `url_launcher`

## Limitations

This is a course project, so some parts are simplified on purpose:

- The product list is hardcoded in the app, with a short delay to simulate loading.
- The login screen validates the form but does not authenticate against a server. Firebase Authentication is not used.
- Favorites and cart are saved to Firestore but not loaded back when the app starts.
- Checkout shows a subtotal dialog only. There are no payments or orders.
- The flash-sale countdown is a demo timer.
- Firestore writes require rules that allow access. The project's rules are locked, so saves are rejected unless you point the app at your own Firebase project.

## Running the project

1. Install [Flutter](https://docs.flutter.dev/get-started/install).
2. Clone the repository and run `flutter pub get`.
3. Create your own Firebase project with Cloud Firestore enabled, then run `flutterfire configure` to generate `lib/firebase_options.dart`.
4. Run `flutter run`.
