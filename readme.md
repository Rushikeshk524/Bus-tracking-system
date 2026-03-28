# 🚌 BusTrack — Live Bus Tracking App

A real-time bus tracking app built with **Flutter** (frontend) and **Node.js + MongoDB** (backend).  
Drivers share their phone GPS, passengers track buses live on a map, and moderators manage everything from a dashboard.

---

## 📁 Project Structure

```
bustrack/
├── bustrack-backend/       ← Node.js backend (API + Sockets)
│   ├── server.js
│   ├── seed.js
│   ├── .env                ← you create this (not in repo)
│   └── package.json
│
└── bustrack_app/           ← Flutter frontend
    ├── lib/
    │   ├── main.dart
    │   ├── config.dart     ← update your IP/URL here
    │   └── screens/
    │       ├── driver_screen.dart
    │       ├── passenger_screen.dart
    │       └── moderator_screen.dart
    └── pubspec.yaml
```

---

## ✅ Prerequisites

Make sure you have all of these installed before starting.

### Everyone needs:
| Tool | Version | Download |
|------|---------|----------|
| Flutter | 3.41.x (stable) | https://docs.flutter.dev/get-started/install |
| Dart | comes with Flutter | — |
| Node.js | 18+ | https://nodejs.org |
| Git | latest | https://git-scm.com |
| Android Studio | latest | https://developer.android.com/studio |

### Verify your setup:
```bash
flutter doctor       # all green except Chrome/VS (optional)
node --version       # should say v18 or higher
```

---

## 🚀 Getting Started

### Step 1 — Clone the repo

```bash
git clone https://github.com/YOUR_USERNAME/bustrack.git
cd bustrack
```

---

### Step 2 — Set up the Backend

```bash
cd bustrack-backend
npm install
```

Create a `.env` file in the `bustrack-backend` folder:

```env
PORT=5000
MONGO_URI=your_mongodb_atlas_connection_string
JWT_SECRET=bustrack_secret
```

> **MongoDB Atlas setup:**
> 1. Go to https://cloud.mongodb.com
> 2. Create a free account → New Project → Free Cluster
> 3. Click Connect → Drivers → copy the connection string
> 4. Replace `<password>` with your DB password
> 5. Paste it as `MONGO_URI` in `.env`

Start the backend:
```bash
npm run dev
```

You should see:
```
BusTrack running on port 5000
MongoDB connected
```

---

### Step 3 — Seed demo data

While the backend is running, open a **new terminal**:

```bash
cd bustrack-backend
node seed.js
```

This adds 3 demo buses with real Mumbai routes (Virar → Churchgate, Vasai → Dadar, Nalasopara → Andheri).

---

### Step 4 — Find your local IP address

The Flutter app needs to connect to YOUR computer's backend.

**Windows:**
```bash
ipconfig
# look for IPv4 Address under your WiFi — e.g. 192.168.0.103
```

**Mac/Linux:**
```bash
ifconfig | grep inet
# look for something like 192.168.0.x
```

---

### Step 5 — Update the Flutter config

Open `bustrack_app/lib/config.dart` and replace the IP with yours:

```dart
const String baseUrl  = 'http://YOUR_IP_HERE:5000';
const String socketUrl = 'http://YOUR_IP_HERE:5000';
```

Example:
```dart
const String baseUrl  = 'http://192.168.0.103:5000';
const String socketUrl = 'http://192.168.0.103:5000';
```

> ⚠️ Everyone who clones this must update this file with their own IP.  
> `localhost` will NOT work — you need the actual network IP.

---

### Step 6 — Install Flutter dependencies

```bash
cd bustrack_app
flutter pub get
```

---

### Step 7 — Run the Flutter app

**On a connected Android phone:**
```bash
flutter devices        # check your phone appears
flutter run            # select your phone from the list
```

**On browser (for quick testing):**
```bash
flutter run -d edge    # or -d chrome
```

> ⚠️ GPS only works on a real Android device, not in browser.

---

## 📱 How to Use the App

### Role Selector
When you open the app you'll see 3 buttons — pick your role.

---

### 🧑‍✈️ Driver
1. Tap **"I am a Driver"**
2. Select your assigned bus from the dropdown
3. Tap **"Start Trip"** — GPS starts broadcasting every 5 seconds
4. Tap **"End Trip"** when done

---

### 🧍 Passenger
1. Tap **"I am a Passenger"**
2. Select a bus from the dropdown
3. The map shows the live bus location with a 🚌 marker
4. If the moderator sends a delay alert, a banner appears at the top

---

### 🛠️ Moderator
1. Tap **"I am a Moderator"**
2. **Buses tab** — see all buses and their live/offline status. Delete a bus if cancelled.
3. **Add Bus tab** — add a new bus with bus number, route, and driver name
4. **Notify tab** — select a bus and send a delay/alert message to all passengers watching it

---

## 🧪 Demo Flow (for presentations)

Open 3 browser tabs or use 3 phones on the same WiFi:

| Tab/Device | Role | Action |
|------------|------|--------|
| Tab 1 | Moderator | Check buses are listed |
| Tab 2 | Driver | Select Bus MH-04-BT-001 → Start Trip |
| Tab 3 | Passenger | Select Virar → Churchgate → watch map |
| Tab 1 | Moderator | Send notification: "Bus delayed by 10 mins" |
| Tab 3 | Passenger | See alert banner pop up instantly |
| Tab 2 | Driver | Tap End Trip |
| Tab 3 | Passenger | See "Bus offline" status |

---

## ⚠️ Common Issues

**`EADDRINUSE: port 5000 already in use`**
```bash
# Windows — find and kill the process
netstat -ano | findstr :5000
taskkill /PID <number> /F

# then restart
npm run dev
```

**`Failed to fetch` error in browser**
- Browser can't reach `192.168.0.x` from another network
- Make sure your phone/laptop is on the **same WiFi** as the backend machine
- Update `config.dart` with the correct IP

**`flutter pub get` fails with SDK constraint error**
- Open `pubspec.yaml` and make sure this exists under `environment`:
```yaml
environment:
  sdk: '^3.10.0'
```

**Phone not showing in `flutter devices`**
- Enable USB Debugging on phone: Settings → About Phone → tap Build Number 7 times → Developer Options → USB Debugging ON
- Plug in via USB → tap "Allow" on the popup
- Run `adb devices` to verify

**Maps not loading**
- Make sure your device has internet access
- OpenStreetMap tiles load over the internet — no API key needed

---

## 📦 Tech Stack

| Layer | Technology |
|-------|-----------|
| Mobile app | Flutter (Dart) |
| Maps | OpenStreetMap via `flutter_map` |
| GPS | `geolocator` package |
| Realtime | Socket.io (WebSockets) |
| Backend | Node.js + Express |
| Database | MongoDB Atlas |
| HTTP | `http` package |

---

## 🗂️ Dependencies

### Backend (`bustrack-backend/package.json`)
```json
"dependencies": {
  "express": "latest",
  "mongoose": "latest",
  "socket.io": "latest",
  "dotenv": "latest",
  "cors": "latest"
}
```

### Flutter (`bustrack_app/pubspec.yaml`)
```yaml
dependencies:
  flutter_map: ^7.0.0
  latlong2: ^0.9.1
  geolocator: ^13.0.2
  socket_io_client: ^3.0.2
  http: ^1.4.0
  permission_handler: ^11.4.0
```

---

## 👥 Team

Built as an MVP for faculty presentation.  
Contributions welcome — fork, branch, and raise a PR.

---

> Made with ☕ and Flutter · BusTrack 2024