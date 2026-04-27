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

  // Add realistic buses with diverse routes
  const buses = await Bus.insertMany([
    {
      busNumber:  'MH-01-AB-5001',
      routeName:  'Dadar — Bandra — Andheri Express',
      driverName: 'Rajesh Kumar',
    },
    {
      busNumber:  'MH-02-XY-7203',
      routeName:  'Central Station → Powai Lake → Hiranandani',
      driverName: 'Vikram Singh',
    },
    {
      busNumber:  'MH-03-CD-4105',
      routeName:  'Thane — Mulund — Fort',
      driverName: 'Pradeep Sharma',
    },
    {
      busNumber:  'MH-04-EF-6204',
      routeName:  'Pune Express (Highway)',
      driverName: 'Suresh Patel',
    },
    {
      busNumber:  'MH-05-GH-8301',
      routeName:  'Navi Mumbai Shuttle',
      driverName: 'Ajay Desai',
    },
    {
      busNumber:  'MH-06-IJ-9402',
      routeName:  'Airport → Vile Parle → Juhu',
      driverName: 'Manish Verma',
    },
    {
      busNumber:  'MH-07-KL-2501',
      routeName:  'Borivali → Malad → Malviya Nagar',
      driverName: 'Deepak Rao',
    },
    {
      busNumber:  'MH-08-MN-3605',
      routeName:  'Colaba → Marine Drive → Gateway of India',
      driverName: 'Mahesh Jadhav',
    },
  ]);

  console.log(`Added ${buses.length} buses...`);

  // 🚌 Bus 1 — Dadar → Bandra → Andheri Express (Premium)
  await Stop.insertMany([
    { busId: buses[0]._id.toString(), stopName: 'Dadar East Station',     lat: 19.0176, lng: 72.8194, time: '06:30' },
    { busId: buses[0]._id.toString(), stopName: 'Mindspace Complex',      lat: 19.0234, lng: 72.8267, time: '06:42' },
    { busId: buses[0]._id.toString(), stopName: 'Bandra Kurla Complex',   lat: 19.0596, lng: 72.8295, time: '06:55' },
    { busId: buses[0]._id.toString(), stopName: 'Bandra Station',         lat: 19.0596, lng: 72.8345, time: '07:05' },
    { busId: buses[0]._id.toString(), stopName: 'Linking Road',           lat: 19.0731, lng: 72.8289, time: '07:18' },
    { busId: buses[0]._id.toString(), stopName: 'Bandra Reclamation',     lat: 19.0445, lng: 72.8268, time: '07:28' },
    { busId: buses[0]._id.toString(), stopName: 'SEEPZ Gate',             lat: 19.1142, lng: 72.8590, time: '07:45' },
    { busId: buses[0]._id.toString(), stopName: 'Andheri West',           lat: 19.1136, lng: 72.8295, time: '08:02' },
    { busId: buses[0]._id.toString(), stopName: 'Andheri Station',        lat: 19.1125, lng: 72.8673, time: '08:15' },
  ]);

  // 🚌 Bus 2 — Central Station → Powai Lake → Hiranandani
  await Stop.insertMany([
    { busId: buses[1]._id.toString(), stopName: 'Central Railway Station', lat: 18.9676, lng: 72.8194, time: '07:00' },
    { busId: buses[1]._id.toString(), stopName: 'Parel (Mill Road)',       lat: 19.0034, lng: 72.8367, time: '07:12' },
    { busId: buses[1]._id.toString(), stopName: 'Curry Road Junction',     lat: 19.0234, lng: 72.8467, time: '07:24' },
    { busId: buses[1]._id.toString(), stopName: 'Mahim Causeway',          lat: 19.0424, lng: 72.8245, time: '07:38' },
    { busId: buses[1]._id.toString(), stopName: 'Powai Lake',              lat: 19.1234, lng: 72.9045, time: '07:58' },
    { busId: buses[1]._id.toString(), stopName: 'Three Tanks',             lat: 19.1267, lng: 72.9078, time: '08:08' },
    { busId: buses[1]._id.toString(), stopName: 'Hiranandani Garden East', lat: 19.1345, lng: 72.9156, time: '08:20' },
  ]);

  // 🚌 Bus 3 — Thane — Mulund — Fort (Local)
  await Stop.insertMany([
    { busId: buses[2]._id.toString(), stopName: 'Thane Railway Station',   lat: 19.2183, lng: 72.9781, time: '06:45' },
    { busId: buses[2]._id.toString(), stopName: 'Thane West Gaiety',       lat: 19.2134, lng: 72.9634, time: '06:58' },
    { busId: buses[2]._id.toString(), stopName: 'Mulund West',             lat: 19.1867, lng: 72.9478, time: '07:18' },
    { busId: buses[2]._id.toString(), stopName: 'Mulund East Toll',        lat: 19.1645, lng: 72.9234, time: '07:35' },
    { busId: buses[2]._id.toString(), stopName: 'Chunabhatti Bridge',      lat: 19.0634, lng: 72.8567, time: '07:58' },
    { busId: buses[2]._id.toString(), stopName: 'Fort Bus Depot',          lat: 18.9634, lng: 72.8345, time: '08:28' },
  ]);

  // 🚌 Bus 4 — Pune Express (Highway Route)
  await Stop.insertMany([
    { busId: buses[3]._id.toString(), stopName: 'Mumbai Central',          lat: 18.9614, lng: 72.8194, time: '05:30' },
    { busId: buses[3]._id.toString(), stopName: 'Sion Circle',             lat: 19.0345, lng: 72.8645, time: '05:50' },
    { busId: buses[3]._id.toString(), stopName: 'Panvel Junction',         lat: 19.1234, lng: 73.1189, time: '06:40' },
    { busId: buses[3]._id.toString(), stopName: 'Khopoli Toll',            lat: 18.9856, lng: 73.2567, time: '07:35' },
    { busId: buses[3]._id.toString(), stopName: 'Lonavala',                lat: 18.7549, lng: 73.4058, time: '09:10' },
    { busId: buses[3]._id.toString(), stopName: 'Khandala Junction',       lat: 18.7445, lng: 73.3634, time: '10:00' },
    { busId: buses[3]._id.toString(), stopName: 'Pune Railway Station',    lat: 18.5204, lng: 73.8567, time: '12:30' },
  ]);

  // 🚌 Bus 5 — Navi Mumbai Shuttle
  await Stop.insertMany([
    { busId: buses[4]._id.toString(), stopName: 'Belapur Railway Station',  lat: 19.0156, lng: 73.0678, time: '07:30' },
    { busId: buses[4]._id.toString(), stopName: 'Kharghar Node',            lat: 19.0534, lng: 73.0245, time: '07:48' },
    { busId: buses[4]._id.toString(), stopName: 'Kamothe',                  lat: 19.0867, lng: 73.0189, time: '08:05' },
    { busId: buses[4]._id.toString(), stopName: 'Panvel Junction',          lat: 19.1234, lng: 73.1189, time: '08:25' },
    { busId: buses[4]._id.toString(), stopName: 'Taloja Phase II',          lat: 19.0645, lng: 73.1567, time: '08:45' },
  ]);

  // 🚌 Bus 6 — Airport → Vile Parle → Juhu (Airport Shuttle)
  await Stop.insertMany([
    { busId: buses[5]._id.toString(), stopName: 'Mumbai Airport T1',        lat: 19.0895, lng: 72.8683, time: '06:00' },
    { busId: buses[5]._id.toString(), stopName: 'Airport T2',               lat: 19.1034, lng: 72.8745, time: '06:12' },
    { busId: buses[5]._id.toString(), stopName: 'Vile Parle East',          lat: 19.1145, lng: 72.8323, time: '06:28' },
    { busId: buses[5]._id.toString(), stopName: 'Four Bunglows',            lat: 19.1023, lng: 72.8234, time: '06:42' },
    { busId: buses[5]._id.toString(), stopName: 'Juhu Beach',               lat: 19.1136, lng: 72.8267, time: '07:00' },
    { busId: buses[5]._id.toString(), stopName: 'Juhu Railway Station',     lat: 19.1078, lng: 72.8289, time: '07:12' },
  ]);

  // 🚌 Bus 7 — Borivali → Malad → Malviya Nagar
  await Stop.insertMany([
    { busId: buses[6]._id.toString(), stopName: 'Borivali East Station',    lat: 19.2308, lng: 72.8517, time: '06:00' },
    { busId: buses[6]._id.toString(), stopName: 'Borivali West',            lat: 19.2389, lng: 72.8023, time: '06:15' },
    { busId: buses[6]._id.toString(), stopName: 'Malad West Junction',      lat: 19.1974, lng: 72.8356, time: '06:35' },
    { busId: buses[6]._id.toString(), stopName: 'Malad East',               lat: 19.1856, lng: 72.8456, time: '06:50' },
    { busId: buses[6]._id.toString(), stopName: 'Malviya Nagar',            lat: 19.1734, lng: 72.8367, time: '07:10' },
  ]);

  // 🚌 Bus 8 — Colaba → Marine Drive → Gateway of India (Tourist Route)
  await Stop.insertMany([
    { busId: buses[7]._id.toString(), stopName: 'Colaba Bus Terminus',      lat: 18.9459, lng: 72.8321, time: '08:00' },
    { busId: buses[7]._id.toString(), stopName: 'Regal Cinema',             lat: 18.9548, lng: 72.8278, time: '08:08' },
    { busId: buses[7]._id.toString(), stopName: 'Strand Cinema',            lat: 18.9623, lng: 72.8245, time: '08:16' },
    { busId: buses[7]._id.toString(), stopName: 'Taj Hotel',                lat: 18.9674, lng: 72.8234, time: '08:24' },
    { busId: buses[7]._id.toString(), stopName: 'Gateway of India',         lat: 18.9689, lng: 72.8345, time: '08:35' },
  ]);

  console.log('');
  console.log('╔════════════════════════════════════════════╗');
  console.log('║  ✅ REALISTIC BUSES & ROUTES LOADED      ║');
  console.log('╚════════════════════════════════════════════╝');
  console.log('');
  
  console.log('📍 AVAILABLE ROUTES:');
  buses.forEach((b, i) => {
    console.log(`  ${i + 1}. ${b.busNumber} — ${b.routeName}`);
    console.log(`     Driver: ${b.driverName}`);
  });

  console.log('');
  console.log('🚌 Ready to track! Try all these routes in the Passenger app!');

  await mongoose.disconnect();
  console.log('✓ Done!');
}

seed().catch(console.error);