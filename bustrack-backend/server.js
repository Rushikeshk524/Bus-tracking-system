const express = require('express');
const http = require('http');
const { Server } = require('socket.io');
const mongoose = require('mongoose');
const cors = require('cors');
require('dotenv').config();

const app = express();
const server = http.createServer(app);
const io = new Server(server, { cors: { origin: '*' } });

app.use(cors());
app.use(express.json());

// ── Models ──────────────────────────────────────────────
const Bus = mongoose.model('Bus', new mongoose.Schema({
  busNumber:  String,
  routeName:  String,
  driverName: String,
  isActive:   { type: Boolean, default: false },
  lastLat:    Number,
  lastLng:    Number,
}));

const Stop = mongoose.model('Stop', new mongoose.Schema({
  busId:    String,
  stopName: String,
  lat:      Number,
  lng:      Number,
  time:     String,
}));

// Hardcoded users for demo
const USERS = [
  { username: 'mod1',     password: 'mod123',    role: 'moderator', name: 'Priya Sharma' },
  { username: 'mod2',     password: 'mod456',    role: 'moderator', name: 'Rahul Mehta' },
  { username: 'driver1',  password: 'drive123',  role: 'driver',    name: 'Ramesh Kumar' },
  { username: 'driver2',  password: 'drive456',  role: 'driver',    name: 'Suresh Patil' },
  { username: 'driver3',  password: 'drive789',  role: 'driver',    name: 'Mahesh Jadhav' },
];

app.post('/login', (req, res) => {
  const { username, password } = req.body;
  const user = USERS.find(u => u.username === username && u.password === password);
  if (!user) return res.status(401).json({ error: 'Invalid credentials' });
  res.json({ role: user.role, name: user.name, username: user.username });
});

// ── REST routes ─────────────────────────────────────────
app.get('/buses', async (req, res) => {
  res.json(await Bus.find());
});

app.post('/buses', async (req, res) => {
  const bus = await Bus.create(req.body);
  res.json(bus);
});

app.patch('/buses/:id', async (req, res) => {
  const bus = await Bus.findByIdAndUpdate(req.params.id, req.body, { new: true });
  res.json(bus);
});

app.delete('/buses/:id', async (req, res) => {
  await Bus.findByIdAndDelete(req.params.id);
  res.json({ ok: true });
});

app.get('/stops/:busId', async (req, res) => {
  res.json(await Stop.find({ busId: req.params.busId }));
});

app.post('/stops', async (req, res) => {
  const stop = await Stop.create(req.body);
  res.json(stop);
});

app.delete('/stops/:id', async (req, res) => {
  await Stop.findByIdAndDelete(req.params.id);
  res.json({ ok: true });
});

// ── Notification broadcast ──────────────────────────────
app.post('/notify', (req, res) => {
  const { busId, message } = req.body;
  io.to(`bus:${busId}`).emit('notification', { message });
  res.json({ sent: true });
});

// ── Sockets ─────────────────────────────────────────────
io.on('connection', (socket) => {

  // Driver starts trip
  socket.on('driver:join', ({ busId }) => {
    socket.join(`bus:${busId}`);
    Bus.findByIdAndUpdate(busId, { isActive: true }).exec();
  });

  // Driver sends location every 5s
  socket.on('driver:location', ({ busId, lat, lng, speed }) => {
    Bus.findByIdAndUpdate(busId, { lastLat: lat, lastLng: lng }).exec();
    io.to(`bus:${busId}`).emit('bus:location', { lat, lng, speed });
  });

  // Driver ends trip
  socket.on('driver:stop', ({ busId }) => {
    Bus.findByIdAndUpdate(busId, { isActive: false }).exec();
    io.to(`bus:${busId}`).emit('bus:offline');
  });

  // Passenger watches a bus
  socket.on('passenger:watch', ({ busId }) => {
    socket.join(`bus:${busId}`);
  });

  socket.on('disconnect', () => {});
});

// ── Start ────────────────────────────────────────────────
mongoose.connect(process.env.MONGO_URI)
  .then(() => {
    server.listen(process.env.PORT, () =>
      console.log(`BusTrack running on port ${process.env.PORT}`)
    );
  })
  .catch(err => console.error(err));