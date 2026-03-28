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