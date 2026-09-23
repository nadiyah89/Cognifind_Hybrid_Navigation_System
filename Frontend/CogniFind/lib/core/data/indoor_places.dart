/// IndoorPlace model
/// Represents a searchable indoor location
class IndoorPlace {

  final String name;
  final String nodeId;
  final int type;

  const IndoorPlace({
    required this.name,
    required this.nodeId,
    required this.type,
  });

  /// Floor prefix from the "F0:Name" convention ("F0" / "F1" / "F2"), or null.
  String? get floorTag {
    final i = name.indexOf(':');
    return i > 0 ? name.substring(0, i) : null;
  }

  /// Display name with the "F0:" floor prefix stripped.
  String get label {
    final i = name.indexOf(':');
    return i >= 0 ? name.substring(i + 1) : name;
  }
}

/// Indoor destination datasets keyed by building id. Only buildings with an
/// indoor map + graph appear here; every other building has no searchable
/// indoor rooms and routes outdoor-only.
///
/// Indoor destinations are NOT globally unique — "Dean", "Faculty-Room" and
/// the like recur across buildings — so they are always resolved *within* a
/// selected building (building-first search), never globally.
const Map<String, List<IndoorPlace>> indoorPlacesByBuilding = {
  'AB-IV': indoorPlacesABIV,
  'AB-III': indoorPlacesABIII,
};

/// Indoor destinations for [buildingId], or an empty list when the building
/// has no indoor dataset.
List<IndoorPlace> indoorPlacesForBuilding(String? buildingId) {
  if (buildingId == null) return const [];
  return indoorPlacesByBuilding[buildingId] ?? const [];
}

/// Indoor locations imported from CSV
const List<IndoorPlace> indoorPlacesABIV = [

  IndoorPlace(
    name: "F0:Classroom-1",
    nodeId: "N037",
    type: 1,
  ),

  IndoorPlace(
    name: "F0:Classroom-2",
    nodeId: "N038",
    type: 1,
  ),

  IndoorPlace(
    name: "F2:Classroom-1",
    nodeId: "N212",
    type: 1,
  ),

  IndoorPlace(
    name: "F2:Classroom-2",
    nodeId: "N210",
    type: 1,
  ),

  IndoorPlace(
    name: "F0:Programming-Lab",
    nodeId: "N040",
    type: 2,
  ),

  IndoorPlace(
    name: "F0:Hardware-Lab",
    nodeId: "N044",
    type: 2,
  ),

  IndoorPlace(
    name: "F0:Networking-Lab",
    nodeId: "N046",
    type: 2,
  ),

  IndoorPlace(
    name: "F1:High-Computational-Lab",
    nodeId: "N105",
    type: 2,
  ),

  IndoorPlace(
    name: "F1:Robotics-Lab",
    nodeId: "N126",
    type: 2,
  ),

  IndoorPlace(
    name: "F2:Lab-1",
    nodeId: "N209",
    type: 2,
  ),

  IndoorPlace(
    name: "F2:Lab-2",
    nodeId: "N224",
    type: 2,
  ),

  IndoorPlace(
    name: "F2:Research-Lab-1",
    nodeId: "N223",
    type: 2,
  ),

  IndoorPlace(
    name: "F2:Research-Lab-2",
    nodeId: "N229",
    type: 2,
  ),

  IndoorPlace(
    name: "F0:Admission-Entrance",
    nodeId: "N008",
    type: 3,
  ),

  IndoorPlace(
    name: "F0:Conference-Room",
    nodeId: "N012",
    type: 3,
  ),

  IndoorPlace(
    name: "F0:Dean-Assistant",
    nodeId: "N015",
    type: 3,
  ),

  IndoorPlace(
    name: "F0:Dean",
    nodeId: "N014",
    type: 3,
  ),

  IndoorPlace(
    name: "F0:Admission-Section",
    nodeId: "N013",
    type: 3,
  ),

  IndoorPlace(
    name: "F0:Lab-Assistant-programming_lab",
    nodeId: "N042",
    type: 3,
  ),

  IndoorPlace(
    name: "F1:Office-1",
    nodeId: "N110",
    type: 3,
  ),

  IndoorPlace(
    name: "F1:Common-Faculty-Room",
    nodeId: "N112",
    type: 3,
  ),

  IndoorPlace(
    name: "F1:Dr.Sahil Sholla Cabin",
    nodeId: "N113",
    type: 3,
  ),

  IndoorPlace(
    name: "F1:Dr.Adil Bashir Cabin",
    nodeId: "N115",
    type: 3,
  ),

  IndoorPlace(
    name: "F1:Dr.Asif Ali Banka Cabin",
    nodeId: "N116",
    type: 3,
  ),

  IndoorPlace(
    name: "F1:Dr.Asif Asad Cabin",
    nodeId: "N117",
    type: 3,
  ),

  IndoorPlace(
    name: "F1:Dr.Sajad lone Cabin",
    nodeId: "N121",
    type: 3,
  ),

  IndoorPlace(
    name: "F1:Office-2",
    nodeId: "N123",
    type: 3,
  ),

  IndoorPlace(
    name: "F1:Office-3",
    nodeId: "N122",
    type: 3,
  ),

  IndoorPlace(
    name: "F1:Mr.Nayeem",
    nodeId: "N124",
    type: 3,
  ),

  IndoorPlace(
    name: "F1:Dr.Mujtiba",
    nodeId: "N127",
    type: 3,
  ),

  IndoorPlace(
    name: "F1:Dr.Zubair Ahmed Shah",
    nodeId: "N129",
    type: 3,
  ),

  IndoorPlace(
    name: "F1:Dr.Ahsan Hussain",
    nodeId: "N131",
    type: 3,
  ),

  IndoorPlace(
    name: "F2:Faculty-Room-1",
    nodeId: "N220",
    type: 3,
  ),

  IndoorPlace(
    name: "F2:Faculty-Room-2",
    nodeId: "N219",
    type: 3,
  ),

  IndoorPlace(
    name: "F2:Faculty-Room-3",
    nodeId: "N218",
    type: 3,
  ),

  IndoorPlace(
    name: "F2:Faculty-Room-4",
    nodeId: "N215",
    type: 3,
  ),

  IndoorPlace(
    name: "F2:Faculty-Room-5",
    nodeId: "N214",
    type: 3,
  ),

  IndoorPlace(
    name: "F2:Staff-WorkStation",
    nodeId: "N222",
    type: 3,
  ),

  IndoorPlace(
    name: "F0:Ladies-Washroom",
    nodeId: "N027",
    type: 4,
  ),

  IndoorPlace(
    name: "F0:Gents-Washroom",
    nodeId: "N030",
    type: 4,
  ),

  IndoorPlace(
    name: "F1:Ladies-Washroom",
    nodeId: "N132",
    type: 4,
  ),

  IndoorPlace(
    name: "F1:Gents-Washroom",
    nodeId: "N134",
    type: 4,
  ),

  IndoorPlace(
    name: "F2:Ladies-Washroom",
    nodeId: "N231",
    type: 4,
  ),

  IndoorPlace(
    name: "F2:Gents-Washroom",
    nodeId: "N233",
    type: 4,
  ),

  IndoorPlace(
    name: "F0:Store-Admission",
    nodeId: "N021",
    type: 5,
  ),

  IndoorPlace(
    name: "F0:Boys-Common-Room",
    nodeId: "N039",
    type: 5,
  ),

  IndoorPlace(
    name: "F0:Girls-Common-Room",
    nodeId: "N036",
    type: 5,
  ),

  IndoorPlace(
    name: "F1:Auditorium",
    nodeId: "N102",
    type: 5,
  ),

  IndoorPlace(
    name: "F1:Auditorium-Store",
    nodeId: "N104",
    type: 5,
  ),

  IndoorPlace(
    name: "F2:Seminar-Hall",
    nodeId: "N202",
    type: 5,
  ),

  IndoorPlace(
    name: "F0:Main Entrance",
    nodeId: "N001",
    type: 6,
  ),

  IndoorPlace(
    name: "F0:Main Entrance",
    nodeId: "N047",
    type: 6,
  ),


];
const List<IndoorPlace> indoorPlacesABIII = [

  IndoorPlace(
    name: "F0:Main Entrance",
    nodeId: "E001",
    type: 6, // Entrance
  ),

  IndoorPlace(
    name: "F0:Classroom-1",
    nodeId: "E034",
    type: 1,
  ),

  IndoorPlace(
    name: "F0:Classroom-2",
    nodeId: "E033",
    type: 1,
  ),

  IndoorPlace(
    name: "F0:Tutorials",
    nodeId: "E032",
    type: 1,
  ),

  IndoorPlace(
    name: "F0:Ladies-Washroom",
    nodeId: "E014",
    type: 4,
  ),

  IndoorPlace(
    name: "F0:Gents-Washroom",
    nodeId: "E015",
    type: 4,
  ),

  IndoorPlace(
    name: "F0:Girls-Common-Room",
    nodeId: "E035",
    type: 5,
  ),

  IndoorPlace(
    name: "F0:DIGITAL-ELECTRONICS Lab",
    nodeId: "E027",
    type: 2,
  ),

  IndoorPlace(
    name: "F0:Microprocessor Lab",
    nodeId: "E022",
    type: 2,
  ),

  IndoorPlace(
    name: "F0:Assistant Professor",
    nodeId: "E012",
    type: 3,
  ),

  IndoorPlace(
    name: "F0:PA Room",
    nodeId: "E011",
    type: 3,
  ),

  IndoorPlace(
    name: "F0: HOD's Room",
    nodeId: "E010",
    type: 3,
  ),

  IndoorPlace(
    name: "F0:ADM General Staff",
    nodeId: "E036",
    type: 3,
  ),


  IndoorPlace(
    name: "F1: Library",
    nodeId: "E108",
    type: 5,
  ),


  IndoorPlace(
    name: "F1:DIGITAL-ELECTRONICS Lab",
    nodeId: "E102",
    type: 2,
  ),

  IndoorPlace(
    name: "F1:ANALOG Lab",
    nodeId: "E133",
    type: 2,
  ),


  IndoorPlace(
    name: "F1:Associate Professor-1",
    nodeId: "E120",
    type: 3,
  ),


  IndoorPlace(
    name: "F1:Associate Professor-2",
    nodeId: "E119",
    type: 3,
  ),

  IndoorPlace(
    name: "F1:Assistant Professor--3",
    nodeId: "E118",
    type: 3,
  ),


  IndoorPlace(
    name: "F1:Assistant Professor--4",
    nodeId: "E117",
    type: 3,
  ),

  IndoorPlace(
    name: "F1:Assistant Professor--5",
    nodeId: "E116",
    type: 3,
  ),

  IndoorPlace(
    name: "F1:Assistant Professor--6",
    nodeId: "E114",
    type: 3,
  ),

  IndoorPlace(
    name: "F1:Assistant Professor--7",
    nodeId: "E113",
    type: 3,
  ),


  IndoorPlace(
    name: "F1:Staff Workstation",
    nodeId: "E121",
    type: 3,
  ),

  IndoorPlace(
    name: "F1:Staff-Common-Room",
    nodeId: "E122",
    type: 5,
  ),

  IndoorPlace(
    name: "F1:Ladies-Washroom",
    nodeId: "E128",
    type: 4,
  ),

  IndoorPlace(
    name: "F1:Gents-Washroom",
    nodeId: "E127",
    type: 4,
  ),


  IndoorPlace(
    name: "F1:Attd Room-1",
    nodeId: "E131",
    type: 5,
  ),

  IndoorPlace(
    name: "F1:Attd Room-2",
    nodeId: "E104",
    type: 5,
  ),


  IndoorPlace(
    name: "F2: Library",
    nodeId: "E223",
    type: 5,
  ),


  IndoorPlace(
    name: "F2:Lab-1",
    nodeId: "E229",
    type: 2,
  ),

  IndoorPlace(
    name: "F2:Lab-2",
    nodeId: "E225",
    type: 2,
  ),


  IndoorPlace(
    name: "F2:Associate Professor-1",
    nodeId: "E214",
    type: 3,
  ),


  IndoorPlace(
    name: "F2:Associate Professor-2",
    nodeId: "E215",
    type: 3,
  ),

  IndoorPlace(
    name: "F2:Assistant Professor--3",
    nodeId: "E216",
    type: 3,
  ),


  IndoorPlace(
    name: "F2:Assistant Professor--4",
    nodeId: "E219",
    type: 3,
  ),

  IndoorPlace(
    name: "F2:Assistant Professor--5",
    nodeId: "E218",
    type: 3,
  ),

  IndoorPlace(
    name: "F2:Assistant Professor--6",
    nodeId: "E220",
    type: 3,
  ),

  IndoorPlace(
    name: "F2:Assistant Professor--7",
    nodeId: "E221",
    type: 3,
  ),


  IndoorPlace(
    name: "F2:Staff Workstation",
    nodeId: "E211",
    type: 3,
  ),

  IndoorPlace(
    name: "F2:Staff-Common-Room",
    nodeId: "E210",
    type: 5,
  ),

  IndoorPlace(
    name: "F2:Ladies-Washroom",
    nodeId: "E206",
    type: 4,
  ),

  IndoorPlace(
    name: "F2:Gents-Washroom",
    nodeId: "E207",
    type: 4,
  ),


  IndoorPlace(
    name: "F2:Attd Room-1",
    nodeId: "E231",
    type: 5,
  ),

  IndoorPlace(
    name: "F2:Attd Room-2",
    nodeId: "E227",
    type: 5,
  ),
];