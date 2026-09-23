# CogniFind Backend

The **CogniFind Backend** provides the server-side functionality for the hybrid indoor–outdoor campus navigation system. It acts as the communication layer between the **Flutter mobile application** and the **PostgreSQL database**.

The backend handles route calculation, indoor localization, map matching, navigation tracking, and navigation instruction generation.


## Features 

* Indoor and outdoor campus navigation
* Hybrid indoor–outdoor routing 
* Outdoor routing using **A***
* Indoor routing using **Dijkstra's algorithm**
* GPS-based outdoor positioning
* BLE-based indoor localization
* Indoor map matching and nearest-node detection
* Navigation progress tracking
* Navigation and floor-change instructions
* REST APIs for Flutter communication
* PostgreSQL database integration
* Entity Framework Core
* JWT-based authentication where required

---

## Technologies Used

* **ASP.NET Core Web API**
* **C#**
* **PostgreSQL**
* **Entity Framework Core**
* **REST API**
* **A* Algorithm**
* **Dijkstra Algorithm**
* **GPS & BLE**
* **JWT Authentication**

---

## Architecture

```text
Flutter Application
        ↓
    REST API
        ↓
ASP.NET Core Backend
        ↓
Routing / Localization
        ↓
PostgreSQL Database
        ↓
Processed Response
        ↓
Flutter Application
```

The backend uses separate services for routing, localization, map matching, navigation tracking, and instruction generation.

---

## Navigation

### Indoor Navigation

Indoor environments are represented using buildings, floors, nodes, and edges. The backend uses **Dijkstra's algorithm** to calculate the shortest indoor route.

### Outdoor Navigation

Outdoor navigation uses GPS coordinates and geographical navigation nodes. The **A*** algorithm is used to calculate efficient outdoor routes.

### Hybrid Navigation

Indoor and outdoor routes are combined to provide navigation between campus locations.

```text
Indoor Location
      ↓
Building Exit
      ↓
Outdoor Route
      ↓
Destination Building
      ↓
Indoor Route
      ↓
Destination
```

---

## BLE Indoor Localization

The Flutter application sends BLE beacon readings to the backend. The backend processes the beacon data to estimate the user's indoor position and floor.

The estimated position is then matched to the nearest valid navigation node and used for route tracking.

---

## Database

CogniFind uses **PostgreSQL** with **Entity Framework Core**.

The database stores information related to:

* Buildings
* Floors
* Indoor Nodes and Edges
* Outdoor Nodes and Edges
* Locations
* BLE Beacons

---

## REST API

Example endpoints include:

```http
GET  /api/test-outdoor/nearest-node
GET  /api/test-outdoor/path
GET  /api/hybridroute
GET  /api/route
POST /api/location
```

These APIs support outdoor routing, indoor routing, hybrid navigation, and indoor localization.

---

# Getting Started

## Prerequisites

Make sure the following are installed:

* .NET 8 SDK
* PostgreSQL
* Git
* Visual Studio or VS Code

---

## Clone the Repository

```bash
git clone https://github.com/1nayat/Cognifind_Backend2.git
cd Cognifind_Backend2
```

---

## Restore Dependencies

```bash
dotnet restore
```

---

## Configure Database

Create a PostgreSQL database and update the connection string in `appsettings.json`:

```json
{
  "ConnectionStrings": {
    "DefaultConnection": "Host=localhost;Port=5432;Database=CogniFind;Username=postgres;Password=YOUR_PASSWORD"
  }
}
```

**Do not commit real passwords, API keys, or JWT secrets to GitHub.**

---

## Apply Migrations

If migrations are included:

```bash
dotnet ef database update
```

If Entity Framework CLI is not installed:

```bash
dotnet tool install --global dotnet-ef
```

---

## Run the Backend

```bash
dotnet run
```

The API will start on the configured HTTP/HTTPS port.

Swagger can be opened using the Swagger URL displayed in the terminal.

---

## Build

```bash
dotnet build
```

---

## Project Structure

```text
CogniFind-Backend/
│
├── Controllers/
├── Services/
├── Models/
├── DTOs/
├── Data/
├── Migrations/
├── Program.cs
├── appsettings.json
└── README.md
```

---

## Security

The backend supports JWT-based authentication and role-based authorization where required.

Sensitive configuration should be stored using secure configuration methods rather than committed to the repository.

---

## Future Improvements

* Improved BLE localization accuracy
* Real-time route recalculation
* Advanced sensor fusion
* Accessibility-aware routing
* Dynamic campus information
* Automated testing and CI/CD
* Cloud deployment and scalability

---

## Contributors

* Nadia Khan
* Inayat Ul Lah Wani
* Farhan Showket

## License

This project is developed as an **academic/project implementation**.

Unless a separate open-source license is added to the repository, the project should not be assumed to be freely reusable or redistributable.
