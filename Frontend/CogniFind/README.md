# CogniFind Frontend

The **CogniFind Frontend** is a Flutter-based mobile application developed for hybrid indoor–outdoor campus navigation. It provides the user interface for selecting destinations, viewing maps, following navigation routes, and tracking the user's position during outdoor and indoor navigation.

---

## Features

* Outdoor campus navigation
* Indoor navigation using digitized floor maps
* Hybrid indoor–outdoor navigation
* BLE-based indoor positioning
* Real-time navigation instructions
* Custom campus map
* Route visualization and progress tracking
* Indoor floor map rendering
* BLE beacon scanning and RSSI collection
* REST API communication with the backend

---

## Technologies Used

* **Flutter**
* **Dart**
* **Google Maps SDK**
* **Flutter Blue Plus**
* **Flutter SVG**
* **REST APIs**

---

## Architecture

```text
User
  ↓
Flutter Mobile Application
  ↓
Navigation / UI
  ↓
REST API
  ↓
ASP.NET Core Backend
  ↓
Navigation & Localization Response
  ↓
Flutter Application
```

The application handles user interaction, map display, route visualization, BLE scanning, and presentation of navigation and positioning information received from the backend. 

---

## Navigation

### Outdoor Navigation

The application displays the custom campus map using Google Maps and shows buildings, entrances, walkable pathways, and calculated routes. GPS location is tracked during navigation, while route progress and navigation instructions are updated as the user moves.

### Indoor Navigation

Inside selected buildings, the application displays SVG-based floor maps and renders the calculated indoor route over the floor layout. The user's estimated position and navigation instructions are updated during the journey. 

### Hybrid Navigation

The frontend combines the outdoor and indoor navigation stages into one navigation session. When the user reaches the selected building, the application transitions from outdoor map navigation to indoor floor-map navigation.

## BLE Indoor Positioning

The Flutter application scans nearby BLE beacons using **Flutter Blue Plus** and collects their RSSI values. The collected beacon information is sent to the backend through the Location API, where the user's indoor position is estimated. The returned position is then displayed on the indoor map. 

## Navigation State Management

The application uses **NavigationProvider** to maintain the navigation state throughout the user's journey. It manages outdoor routes, indoor paths, hybrid navigation states, user position, route progress, and navigation instructions.

## Backend Communication

The Flutter application communicates with the ASP.NET Core Web API through REST APIs. These APIs are used to request routes, send BLE positioning data, receive location updates, and retrieve navigation instructions.

---

# Getting Started

## Prerequisites

Make sure the following are installed:

* Flutter SDK
* Dart SDK
* Android Studio or VS Code
* Android device/emulator
* Git

---

## Clone the Repository

```text
git clone https://github.com/Shahfarhan26/CogniFind.git
cd CogniFind
```

## Install Dependencies

```text
flutter pub get
```

## Run the Application

```text
flutter run
```

Make sure the backend API is running and the required device permissions are enabled before testing navigation and BLE functionality.

---

## Project Structure

```text
CogniFind/
│
├── lib/
├── assets/
├── android/
├── ios/
├── pubspec.yaml
└── README.md
```

---

## Contributors

* Nadia Khan
* Inayat Ul Lah Wani
* Farhan Showket

Developed as a B.Tech project for hybrid indoor–outdoor campus navigation.

---

## License

This project was developed as an **academic project**. 
Unless a separate open-source license is added to the repository, the source code should not be assumed to be freely reusable or redistributable.
