import 'package:cognifind/models/navigation/building.dart';

/// Central registry of all campus buildings that participate in
/// outdoor navigation.
///
/// - Visible markers are placed at each building's `centerLat`/`centerLng`.
/// - Routing always targets the *nearest* entrance in [entrances].
const List<Building> campusBuildings = [
  ///IMBA
  Building(
    id: 'AB-I',
    name: 'IMBA',
    centerLat: 33.9264335,
    centerLng: 75.0191435,
    entrances: [
      Entrance(
        id: 'AB-I-E1',
        latitude: 33.9266261,
        longitude: 75.0189220,
      ),
      Entrance(
        id: 'AB-I-E2',
        latitude: 33.9264216,
        longitude: 75.0189762,
      ),
      Entrance(
        id: 'AB-I-E3',
        latitude: 33.9262382,
        longitude: 75.0190512,
      ),
      Entrance(
        id: 'AB-I-E4',
        latitude: 33.9260802,
        longitude: 75.0192597,
      ),
    ],

  ),

  ///CSE
  Building(
    id: 'AB-IV',
    name: 'CSE',
    centerLat: 33.9252333,
    centerLng: 75.0201628,
    destinationNodeId: "N217",
    entrances: [
      Entrance(
        id: 'AB-IV-main',
        latitude: 33.9254728,
        longitude: 75.0202015,
      ),
    ],

  ),

  ///lib
  Building(
    id: 'LIB',
    name: 'Rumi Library',
    centerLat: 33.9271258,
    centerLng: 75.0189879,
    entrances: [
      Entrance(
        id: 'LIB-main',
        latitude: 33.9271258,
        longitude: 75.0189879,
      ),
    ],

  ),

  ///start
  ///from here
  ///administrarion
  Building(
    id: 'AD1',
    name: 'Administration Block 1',
    centerLat: 33.9266072,
    centerLng: 75.0186233,
    entrances: [
      Entrance(
        id: 'AD1-main',
        latitude: 33.9265181,
        longitude: 75.0186977,
      ),
    ],

  ),

  ///ab-vi
  Building(
    id: 'AB-VI',
    name: 'Academic Block VI',
    centerLat: 33.9255835,
    centerLng: 75.0193744,
    entrances: [
      Entrance(
        id: 'AB-VI-main',
        latitude: 33.9256188,
        longitude: 75.0194476,
      ),
    ],

  ),

//transport
  Building(
    id: 'T-I',
    name: 'Transport Office',
    centerLat: 33.9267694,
    centerLng: 75.0188460,
    entrances: [
      Entrance(
        id: 'T-I-main',
        latitude: 33.9267113,
        longitude: 75.0188348,
      ),
    ],

  ),

///civil
  Building(
    id: 'AB-II',
    name: 'CIVIL',
    centerLat: 33.9257505,
    centerLng: 75.0188461,
    entrances: [
      Entrance(
        id: 'AB-II-E1',
        latitude: 33.9257520,
        longitude: 75.0188226,
      ),
      Entrance(
        id: 'AB-II-E2',
        latitude: 33.9256347,
        longitude: 75.0188915,
      ),
    ],

  ),

///ECE/MECH
  Building(
    id: 'AB-III',
    name: 'ECE/ELECTRICAL/MECH',
    centerLat: 33.9251309,
    centerLng: 75.0193087,
    entrances: [
      Entrance(
        id: 'AB-III-E1',
        latitude: 33.9249891,
        longitude: 75.0193627,
      ),
      Entrance(
        id: 'AB-III-E2',
        latitude: 33.9253261,
        longitude: 75.0193756,
      ),
    ],

  ),

///Lighthouse
  Building(
    id: 'C-I',
    name: 'Light-House',
    centerLat: 33.9246871,
    centerLng: 75.0194902,
    entrances: [
      Entrance(
        id: 'C-I-main',
        latitude: 33.9247127,
        longitude: 75.0195570,
      ),
    ],

  ),

///Washroom
  Building(
    id: 'W-I',
    name: 'Washroom Building',
    centerLat: 33.9247065,
    centerLng: 75.0191740,
    entrances: [
      Entrance(
        id: 'W-I-main',
        latitude: 33.9246374,
        longitude: 75.0191708,
      ),
    ],

  ),


  ///Masjid
  Building(
    id: 'M-I',
    name: 'Masjid',
    centerLat: 33.9243623,
    centerLng: 75.0190132,
    entrances: [
      Entrance(
        id: 'M-I-main',
        latitude: 33.9244512,
        longitude: 75.0191262,
      ),
    ],

  ),

  ///English
  Building(
    id: 'AB-X',
    name: 'Eng/Journalism',
    centerLat: 33.9245141,
    centerLng: 75.0201382,
    entrances: [
      Entrance(
        id: 'AB-X-main',
        latitude: 33.9245944,
        longitude: 75.0201449,
      ),
    ],

  ),

  ///Arabic
  Building(
    id: 'AB-V',
    name: 'Arabic',
    centerLat: 33.9247142,
    centerLng: 75.0206382,
    entrances: [
      Entrance(
        id: 'AB-V-main',
        latitude: 33.9246864,
        longitude: 75.0204094,
      ),
    ],

  ),


  ///Nursing
  Building(
    id: 'AB-IX',
    name: 'Nursing',
    centerLat: 33.9262159,
    centerLng: 75.0209405,
    entrances: [
      Entrance(
        id: 'AB-IX-main',
        latitude: 33.9261087,
        longitude: 75.0208156,
      ),
    ],

  ),

///foot-tech
  Building(
    id: 'AB-VII',
    name: 'FoodTech/Math',
    centerLat: 33.9257711,
    centerLng: 75.0205175,
    entrances: [
      Entrance(
        id: 'AB-VII-E1',
        latitude: 33.9258275,
        longitude: 75.0203832,
      ),
      Entrance(
        id: 'AB-VII-E2',
        latitude: 33.9258330,
        longitude: 75.0206299,
      ),
    ],

  ),

  ///new
  Building(
    id: 'AB-XI',
    name: 'Civil/Mech/Exam',
    centerLat: 33.9251681,
    centerLng: 75.0186330,
    entrances: [
      Entrance(
        id: 'AB-XI-E1',
        latitude: 33.9250169,
        longitude: 75.0186000,
      ),
      Entrance(
        id: 'AB-XI-E2',
        latitude: 33.9252782,
        longitude: 75.0186425,
      ),
    ],

  ),

  ///Architecture
  Building(
    id: 'AB-XII',
    name: 'Architecture',
    centerLat: 33.9257057,
    centerLng: 75.0183845,
    entrances: [
      Entrance(
        id: 'AB-XII-E1',
        latitude: 33.9256596,
        longitude: 75.0182702,
      ),
      Entrance(
        id: 'AB-XII-E2',
        latitude: 33.9254424,
        longitude: 75.0181986,
      ),
    ],

  ),


  ///nescafe
  Building(
    id: 'C-II',
    name: 'Nescafe',
    centerLat: 33.9268572,
    centerLng: 75.0184013,
    entrances: [
      Entrance(
        id: 'C-II-main',
        latitude: 33.9268572,
        longitude: 75.0184013,
      ),

    ],

  ),
];

/// Helper to look up a [Building] by its ID.
Building? getBuildingById(String id) {
  for (final building in campusBuildings) {
    if (building.id == id) {
      return building;
    }
  }
  return null;
}

