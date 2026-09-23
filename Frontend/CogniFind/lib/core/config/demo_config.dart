/// ============================================================
/// DEMO MODE CONFIGURATION
/// ============================================================
///
/// Master switch for the project demonstration. When [kDemoNavigationMode] is
/// `false` every demo-mode code path is compiled out and the application
/// behaves identically to production (GPS outdoors, BLE indoors).
///
/// When `true`, exactly one thing changes: the SOURCE of the user's position.
/// [DemoPositionDriver] replaces the Geolocator stream and the BLE/backend
/// poll, writing deterministic positions through the same provider entry
/// points those drivers use. Routing, rendering, transitions, route
/// progression, floor synchronisation, instruction banners and arrival
/// detection are the untouched production pipeline in both modes, and the user
/// still searches, previews and starts navigation through the real UI.

/// Master demo switch.
const bool kDemoNavigationMode = true;

/// Playback rate. The simulated walker moves at this multiple of real walking
/// pace, which is purely how fast the demo is played back — the route, the
/// geometry and the distances shown are untouched.
///
/// Outdoor and indoor are scaled differently on purpose. An outdoor campus leg
/// is a few hundred metres: at true pace that is four minutes of watching a dot
/// travel in a straight line, so it is compressed hard. An indoor leg is a few
/// tens of metres and is where the interesting things happen — corridors,
/// stairs, floor changes, the route redrawing on a new floor plan — so it is
/// barely compressed and stays legible.
///
/// Set both to 1.0 to walk the whole journey in real time.
const double kOutdoorTimeScale = 3.0;
const double kIndoorTimeScale = 1.5;

/// Outdoor speed in metres per second. 1.4 m/s is an average human walking
/// pace (~5 km/h) and matches the 83 m/min figure NavigationProvider uses for
/// its ETA estimate.
const double kOutdoorDemoSpeed = 1.4 * kOutdoorTimeScale;

/// Indoor speed in SVG user-space units per second. The campus floor plans are
/// drawn at roughly 20 units per metre (a backend leg labelled "8.2 metres"
/// spans ~165 units), so the base 28 u/s is a deliberate ~1.4 m/s — the same
/// true walking pace as outdoors.
const double kIndoorDemoSpeed = 28.0 * kIndoorTimeScale;

/// Simulation tick. 20 Hz is well under the display refresh rate, so the blue
/// dot and the camera move continuously without flooding the widget tree.
const Duration kDemoTickInterval = Duration(milliseconds: 50);

/// How far the smoothed heading closes on the true segment bearing each tick.
/// At 20 Hz this settles a turn in roughly half a second — quick enough to
/// feel responsive, slow enough that route vertices don't snap the camera.
const double kHeadingEase = 0.12;

/// Pause on a staircase while the rendered floor changes, so a floor change
/// reads as climbing rather than teleporting.
const Duration kFloorChangePause = Duration(milliseconds: 900);
