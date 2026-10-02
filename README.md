# 🧭 CogniFind

> **A Cognitive System for Campus Navigation.**

CogniFind is a **smart campus navigation system** that provides **outdoor and indoor navigation** across a university campus.

It combines outdoor map-based navigation with **BLE beacon-based indoor positioning** and graph-based route calculation, allowing users to navigate from an outdoor location into a building and between different campus buildings.

---

## ✨ Features

- 🌍 **Outdoor Navigation** — Navigate between locations across the campus.
- 🏢 **Indoor Navigation** — Navigate to rooms, labs, offices, and other mapped indoor locations.
- 📡 **BLE Beacon Positioning** — BLE beacons installed inside buildings are used for indoor positioning.
- 🔄 **Outdoor → Indoor Navigation** — Continue navigation from the campus area into a building.
- 🏫 **Cross-Building Navigation** — Navigate between different campus buildings.
- 🔎 **Location Search** — Search for mapped campus destinations.
- 📍 **Real-Time Positioning** — Track and update the user's position during navigation.
- 🧭 **Shortest-Path Navigation** — Routes are calculated using **Dijkstra's algorithm**.

---

## 🏗️ How It Works

CogniFind uses different positioning and navigation mechanisms depending on the environment.

### Outdoor

Outdoor navigation uses GPS/location information and the outdoor map.

### Indoor

Inside buildings, **BLE beacons** are deployed at known locations. The application uses the received BLE signals to estimate the user's indoor position.

The indoor environment is represented as a graph of connected navigation nodes. **Dijkstra's shortest-path algorithm** is used to calculate the route to the selected destination.

### Hybrid Navigation

CogniFind connects the two environments:

```text
Outdoor Location
      ↓
Outdoor Navigation
      ↓
Building Entrance
      ↓
BLE-Based Indoor Positioning
      ↓
Indoor Navigation
      ↓
Destination
```

This enables navigation to continue after entering a building instead of stopping at the building entrance.

---

## 🧠 Navigation

CogniFind uses **Dijkstra's shortest-path algorithm** for both outdoor and indoor route calculation.

The navigation environment is represented as a weighted graph:

```text
Start → Node → Node → Node → Destination
```

The algorithm determines the shortest available path based on the defined route costs.

---

## 📡 Indoor Positioning with BLE Beacons

BLE beacons are placed at known positions inside campus buildings.

```text
BLE Beacons
     ↓
BLE Signal Detection
     ↓
Indoor Position Estimation
     ↓
Current Indoor Position
     ↓
Dijkstra Route
     ↓
Destination
```

BLE positioning helps overcome the limitations of GPS inside buildings.

---

## 🛠️ Tech Stack

**Frontend**
- Flutter
- Dart

**Backend**
- API-based backend
- Route and navigation services

**Database**
- Stores campus, building, indoor location, and navigation data

**Positioning**
- GPS for outdoor positioning
- BLE beacons for indoor positioning

**Navigation Algorithm**
- Dijkstra's shortest-path algorithm

---

## 📱 Application Architecture

Key Flutter components include:

- `NavigationProvider` — Navigation state and flow
- `LocationProvider` — Location state
- `IndoorNavigationProvider` — Indoor navigation
- `RealtimePositionProvider` — Real-time position updates
- `BlePositionProvider` — BLE-based indoor positioning
- `HybridRouteService` — Route-related API operations
- `IndoorNode` — Indoor navigation graph nodes
- `AppNavigationMode` — Outdoor/indoor navigation mode

---

## 🎥 Demo

### Outdoor ↔ Indoor Navigation

https://github.com/user-attachments/assets/349bba4d-8baf-44a7-be91-3251d89a809e

### Cross-Building Navigation

https://github.com/user-attachments/assets/9de58f8b-51a6-45bd-94fc-68a32885c0dc

---

## 👥 Team

**CogniFind** was developed by:

- **Nadia Khan**
- **Inayat Ul Lah Wani**
- **Farhan Showket**

A collaborative team project with contributions across the application, navigation system, database, and other project components.

---

## 📌 Project

**CogniFind — Smart Campus Navigation**

Built with **Flutter, BLE Beacons, GPS, Dijkstra's Algorithm, Backend APIs, and a database** to provide navigation across both outdoor and indoor campus environments.
 

