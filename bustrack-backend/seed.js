require('dotenv').config();
const mongoose = require('mongoose');

const Bus = mongoose.model('Bus', new mongoose.Schema({
  busNumber:    String,
  routeName:    String,
  driverName:   String,
  isActive:     { type: Boolean, default: false },
  lastLat:      Number,
  lastLng:      Number,
}));

const Stop = mongoose.model('Stop', new mongoose.Schema({
  busId:    String,
  stopName: String,
  lat:      Number,
  lng:      Number,
  time:     String,
}));

async function seed() {
  await mongoose.connect(process.env.MONGO_URI);
  console.log('Connected to MongoDB...');

  // Clear old data
  await Bus.deleteMany({});
  await Stop.deleteMany({});
  console.log('Cleared old data...');

  // Add buses
  const buses = await Bus.insertMany([
    {
      busNumber:  'MH-04-BT-001',
      routeName:  'Virar → Churchgate',
      driverName: 'Ramesh Kumar',
      isActive:   false,
    },
    {
      busNumber:  'MH-04-BT-002',
      routeName:  'Vasai → Dadar',
      driverName: 'Suresh Patil',
      isActive:   false,
    },
    {
      busNumber:  'MH-04-BT-003',
      routeName:  'Nalasopara → Andheri',
      driverName: 'Mahesh Jadhav',
      isActive:   false,
    },
  ]);

  console.log(`Added ${buses.length} buses...`);

  // Add stops for Bus 1 — Virar → Churchgate
  await Stop.insertMany([
    { busId: buses[0]._id.toString(), stopName: 'Virar',        lat: 19.4593, lng: 72.8075, time: '07:00' },
    { busId: buses[0]._id.toString(), stopName: 'Nallasopara',  lat: 19.4209, lng: 72.8294, time: '07:15' },
    { busId: buses[0]._id.toString(), stopName: 'Vasai Road',   lat: 19.3919, lng: 72.8397, time: '07:28' },
    { busId: buses[0]._id.toString(), stopName: 'Naigaon',      lat: 19.3647, lng: 72.8522, time: '07:38' },
    { busId: buses[0]._id.toString(), stopName: 'Bhayandar',    lat: 19.3006, lng: 72.8526, time: '07:52' },
    { busId: buses[0]._id.toString(), stopName: 'Mira Road',    lat: 19.2813, lng: 72.8694, time: '08:02' },
    { busId: buses[0]._id.toString(), stopName: 'Borivali',     lat: 19.2307, lng: 72.8567, time: '08:20' },
    { busId: buses[0]._id.toString(), stopName: 'Churchgate',   lat: 18.9322, lng: 72.8264, time: '09:15' },
  ]);

  // Add stops for Bus 2 — Vasai → Dadar
  await Stop.insertMany([
    { busId: buses[1]._id.toString(), stopName: 'Vasai',        lat: 19.3647, lng: 72.8400, time: '08:00' },
    { busId: buses[1]._id.toString(), stopName: 'Naigaon',      lat: 19.3647, lng: 72.8522, time: '08:12' },
    { busId: buses[1]._id.toString(), stopName: 'Bhayandar',    lat: 19.3006, lng: 72.8526, time: '08:28' },
    { busId: buses[1]._id.toString(), stopName: 'Mira Road',    lat: 19.2813, lng: 72.8694, time: '08:40' },
    { busId: buses[1]._id.toString(), stopName: 'Kandivali',    lat: 19.2033, lng: 72.8526, time: '09:00' },
    { busId: buses[1]._id.toString(), stopName: 'Dadar',        lat: 19.0178, lng: 72.8478, time: '09:45' },
  ]);

  // Add stops for Bus 3 — Nalasopara → Andheri
  await Stop.insertMany([
    { busId: buses[2]._id.toString(), stopName: 'Nalasopara',   lat: 19.4209, lng: 72.8294, time: '08:30' },
    { busId: buses[2]._id.toString(), stopName: 'Vasai Road',   lat: 19.3919, lng: 72.8397, time: '08:45' },
    { busId: buses[2]._id.toString(), stopName: 'Naigaon',      lat: 19.3647, lng: 72.8522, time: '08:55' },
    { busId: buses[2]._id.toString(), stopName: 'Bhayandar',    lat: 19.3006, lng: 72.8526, time: '09:10' },
    { busId: buses[2]._id.toString(), stopName: 'Borivali',     lat: 19.2307, lng: 72.8567, time: '09:28' },
    { busId: buses[2]._id.toString(), stopName: 'Andheri',      lat: 19.1136, lng: 72.8697, time: '09:55' },
  ]);

  console.log('Stops added...');
  console.log('');
  console.log('=== DEMO DATA READY ===');
  console.log('');
  console.log('MODERATOR LOGIN:');
  console.log('  → Open app → Moderator');
  console.log('  → Buses tab: see all 3 buses');
  console.log('  → Notify tab: send delay alerts');
  console.log('');
  console.log('DRIVER LOGIN:');
  console.log('  → Open app → Driver');
  console.log('  → Select: MH-04-BT-001 (Ramesh Kumar)');
  console.log('  → Tap Start Trip');
  console.log('');
  console.log('PASSENGER LOGIN:');
  console.log('  → Open app → Passenger');
  console.log('  → Select: Virar → Churchgate');
  console.log('  → Watch bus move live on map');
  console.log('');
  console.log('Bus IDs:');
  buses.forEach(b => console.log(`  ${b.busNumber}: ${b._id}`));

  await mongoose.disconnect();
  console.log('Done!');
}

seed().catch(console.error);