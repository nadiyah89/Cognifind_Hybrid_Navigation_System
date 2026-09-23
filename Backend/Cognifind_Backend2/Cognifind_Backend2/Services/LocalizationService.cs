using Cognifind_Backend2.Models;
using Cognifind_Backend2.Services;
using Microsoft.EntityFrameworkCore;
using System.Diagnostics;


public class LocalizationService
{
    private readonly AppDbContext _context;
    private readonly MapMatchingService _mapMatching;
    private readonly ILogger<LocalizationService> _logger;
    private readonly GraphService _graphService;
    private readonly LocalizationStateService _state;

    public LocalizationService(
    AppDbContext context,
    GraphService graphService,
    MapMatchingService mapMatching,
    LocalizationStateService state,
    ILogger<LocalizationService> logger)
    {
        _context = context;
        _mapMatching = mapMatching;
        _state = state;
        _logger = logger;
        _graphService = graphService;
    }
    // ----------------------------
    // Localization Memory
    // ----------------------------

   
    // Parameters
    private const double RssiAlpha = 0.35;          // RSSI smoothing
    private const double PositionAlpha = 0.35;      // Position smoothing

    private const double MovementThreshold = 12.0;   // Ignore tiny movements

    private const double MaxJumpDistance = 40.0;///////////////////////////////////////////reduces impossible jumps 
    private const int FloorConfirmationRequired = 5;

    private const int MinimumBeaconCount = 4;

    public async Task<PositionResult> EstimatePositionAsync(LocationRequest request)
    {
        _logger.LogInformation("========== NEW LOCATION REQUEST ==========");
        _logger.LogInformation("BuildingId: {BuildingId}", request.BuildingId);
        _logger.LogInformation("Heading: {Heading}", request.Heading);
        _logger.LogInformation("Request Beacon Count: {Count}", request.Beacons?.Count ?? 0);

        foreach (var beacon in request.Beacons)
        {
            _logger.LogInformation(
                "Incoming Beacon -> Id: '{Id}', RSSI: {Rssi}",
                beacon.Id,
                beacon.Rssi);
        }
        // -----------------------------
        // Step 1 - Validate GPS
        // -----------------------------
        if (request.Gps.Latitude < -90 || request.Gps.Latitude > 90)
            throw new Exception("Invalid Latitude.");

        if (request.Gps.Longitude < -180 || request.Gps.Longitude > 180)
            throw new Exception("Invalid Longitude.");

        // -----------------------------
        // Step 2 - Normalize Heading
        // -----------------------------
        double heading = request.Heading % 360;

        if (heading < 0)
            heading += 360;

        // -----------------------------
        // Step 3 - Filter BLE Readings
        // -----------------------------
     

        // Remove invalid beacons
        var validBeacons = request.Beacons
            .Where(b => !string.IsNullOrWhiteSpace(b.Id))
            .Where(b => b.Rssi < 0)
            .GroupBy(b => b.Id)
            .Select(g => g.OrderByDescending(x => x.Rssi).First())
            .ToList();

        var smoothedBeacons = new List<BeaconReadingDto>();

        foreach (var beacon in validBeacons)
        {
            double currentRssi = beacon.Rssi;

            // -----------------------------
            // Beacon Stability Check
            // -----------------------------
            if (_state.LastStableRssi.TryGetValue(beacon.Id, out var stableRssi))
            {
                double difference = Math.Abs(currentRssi - stableRssi);

                // Ignore sudden RSSI spikes (>15 dBm)
                if (difference > 20)
                {
                    _logger.LogInformation(
                        "Ignoring RSSI spike for Beacon {Beacon}. Current={Current}, Previous={Previous}",
                        beacon.Id,
                        currentRssi,
                        stableRssi);

                    currentRssi = stableRssi +
    Math.Sign(currentRssi - stableRssi) * 10; ;
                }
            }

            // Save latest stable RSSI
            _state.LastStableRssi[beacon.Id] = currentRssi;

            // -----------------------------
            // EMA Smoothing
            // -----------------------------
            double smoothedRssi = currentRssi;

            if (_state.LastRssi.TryGetValue(beacon.Id, out var previousRssi))
            {
                smoothedRssi =
                    (RssiAlpha * currentRssi) +
                    ((1 - RssiAlpha) * previousRssi);
            }

            _state.LastRssi[beacon.Id] = smoothedRssi;

            // Ignore extremely weak beacons
            if (smoothedRssi < -95)
                continue;

            smoothedBeacons.Add(new BeaconReadingDto
            {
                Id = beacon.Id,
                Rssi = (int)Math.Round(smoothedRssi)
            });
        }

        // Keep strongest beacons only
        var beaconReadings = smoothedBeacons
            .OrderByDescending(b => b.Rssi)
        .Take(Math.Min(8, smoothedBeacons.Count)).ToList();

        _logger.LogInformation("Filtered Beacon Count: {Count}", beaconReadings.Count);

        foreach (var beacon in beaconReadings)
        {
            _logger.LogInformation(
                "Filtered Beacon -> Id:'{Id}', Raw RSSI:{Raw}, Smoothed RSSI:{Smooth}",
                beacon.Id,
                request.Beacons.First(x => x.Id == beacon.Id).Rssi,
                beacon.Rssi);
        }

        // Not enough beacons → keep previous position
        if (beaconReadings.Count < MinimumBeaconCount)
        {
            _logger.LogWarning(
                "Only {Count} valid beacons available.",
                beaconReadings.Count);

            return new PositionResult
            {
                X = _state.LastX ?? 0,
                Y = _state.LastY ?? 0,
                Floor = _state.LastFloor ?? -1,
                Heading = heading,
                Confidence = 0.20,
                IsIndoor = true
            };
        }
        // -----------------------------
        // Step 4 - Load Beacon Metadata
        // -----------------------------
        var beaconIds = beaconReadings
         .Select(b => b.Id)
         .ToList();
        _logger.LogInformation("--------------------------------");
        _logger.LogInformation("Requested Beacon IDs:");

        foreach (var id in beaconIds)
        {
            _logger.LogInformation("Beacon ID: {BeaconId}", id);
        }

        var allBeacons = await _context.Beacons.ToListAsync();

        _logger.LogInformation("Total Beacons In Database: {Count}", allBeacons.Count);

        foreach (var b in allBeacons)
        {
            _logger.LogInformation("DB Beacon -> '{Id}'", b.BeaconId);
        }

        var beacons = await _context.Beacons
       .Where(b => beaconIds.Contains(b.BeaconId))
       .ToListAsync();

        _logger.LogInformation("Matched Beacons: {Count}", beacons.Count);
        // -----------------------------
        // Step 5 - Verify Building
        // -----------------------------
        if (request.BuildingId.HasValue)
        {
            beacons = beacons
                .Where(b => b.BuildingId == request.BuildingId.Value)
                .ToList();
        }

        _logger.LogInformation("Beacons After Building Filter: {Count}", beacons.Count);
        // -----------------------------
        // Step 6 - Merge Scan + Metadata
        // -----------------------------
        var localizationData =
            from scan in beaconReadings
            join beacon in beacons
            on scan.Id equals beacon.BeaconId
            select new
            {
                BeaconId = beacon.BeaconId,
                beacon.X,

                beacon.Y,
                beacon.FloorId,
                beacon.NearestNodeId,
                beacon.BuildingId,
                scan.Rssi
            };

        // -------------------------------------------------------
        // PHASE 2 STOPS HERE
        // -------------------------------------------------------
        // Phase 3 will calculate:
        //  • Weighted Centroid
        //  • Sensor Fusion
        //  • Fingerprinting
        //  • Trilateration
        // -------------------------------------------------------
        // -------------------------------------------------------
        // PHASE 3 - BLE LOCALIZATION
        // -------------------------------------------------------

        var beaconList = localizationData.ToList();
        // Determine dominant floor using weighted RSSI
        var dominantFloor = beaconList
            .GroupBy(b => b.FloorId)
            .Select(g => new
            {
                Floor = g.Key,
                Weight = g.Sum(x =>
                {
                    double normalized = Math.Max(1, x.Rssi + 100);
                    return Math.Pow(normalized, 2);
                })
            })
            .OrderByDescending(x => x.Weight)
            .First()
            .Floor; 

        // Keep only beacons from dominant floor
        beaconList = beaconList
            .Where(b => b.FloorId == dominantFloor)
            .ToList();

        beaconList = beaconList
            .Where(b => b.FloorId == dominantFloor)
            .ToList();
        foreach (var b in beaconList)
        {
            _logger.LogInformation(
                "Used Beacon -> Id:{Id}, RSSI:{RSSI}, X:{X}, Y:{Y}, Floor:{Floor}, Node:{Node}",
                b.BeaconId,
                b.Rssi,
                b.X,
                b.Y,
                b.FloorId,
                b.NearestNodeId);
        }
        _logger.LogInformation("Localization Records: {Count}", beaconList.Count);
        _logger.LogInformation("--------------------------------");

        if (!beaconList.Any())
        {
            return new PositionResult
            {
                X = 0,
                Y = 0,
                Floor = -1,
                NearestNode = string.Empty,
                Heading = heading,
                Confidence = 0,
                IsIndoor = false
            };
        }
        // -------------------------------------------------------
        // Calculate Weighted Centroid (Improved)
        // -------------------------------------------------------

        double totalWeight = 0;
        double estimatedX = 0;
        double estimatedY = 0;

        foreach (var beacon in beaconList)
        {
            // Stronger beacons contribute much more than weaker ones
            double normalized = Math.Max(1, beacon.Rssi + 100);

            double weight = Math.Pow(normalized, 3);
            totalWeight += weight;

            estimatedX += beacon.X * weight;
            estimatedY += beacon.Y * weight;
        }

        if (totalWeight > 0)
        {
            estimatedX /= totalWeight;
            estimatedY /= totalWeight;
        }
        else
        {
            estimatedX = 0;
            estimatedY = 0;
        }
        // -------------------------------------------------------
        // Kalman Filter
        // -------------------------------------------------------

        const double ProcessNoise = 0.05;
        const double MeasurementNoise = 6.0;

        if (!_state.KalmanInitialized)
        {
            _state.KalmanX = estimatedX;
            _state.KalmanY = estimatedY;

            _state.KalmanInitialized = true;
        }
        else
        {
            // Prediction
            _state.ErrorCovarianceX += ProcessNoise;
            _state.ErrorCovarianceY += ProcessNoise;

            // Kalman Gain
            double gainX =
                _state.ErrorCovarianceX /
                (_state.ErrorCovarianceX + MeasurementNoise);

            double gainY =
                _state.ErrorCovarianceY /
                (_state.ErrorCovarianceY + MeasurementNoise);

            // Correction
            _state.KalmanX =
                _state.KalmanX +
                gainX * (estimatedX - _state.KalmanX);

            _state.KalmanY =
                _state.KalmanY +
                gainY * (estimatedY - _state.KalmanY);

            _state.ErrorCovarianceX *= (1 - gainX);
            _state.ErrorCovarianceY *= (1 - gainY);
        }

        estimatedX = _state.KalmanX;
        estimatedY = _state.KalmanY;

        _logger.LogInformation(
            "Kalman Position -> X:{X}, Y:{Y}",
            Math.Round(estimatedX, 2),
            Math.Round(estimatedY, 2));
        // -------------------------------------------------------
        // Position EMA (Exponential Moving Average)
        // -------------------------------------------------------

        if (_state.LastX.HasValue && _state.LastY.HasValue)
        {
            estimatedX =
                (PositionAlpha * estimatedX) +
                ((1 - PositionAlpha) * _state.LastX.Value);

            estimatedY =
                (PositionAlpha * estimatedY) +
                ((1 - PositionAlpha) * _state.LastY.Value);
        }

        // -------------------------------------------------------
        // Ignore Tiny Movement
        // -------------------------------------------------------

        if (_state.LastX.HasValue && _state.LastY.HasValue)
        {
            double movement = Math.Sqrt(
                Math.Pow(estimatedX - _state.LastX.Value, 2) +
                Math.Pow(estimatedY - _state.LastY.Value, 2));

            if (movement < MovementThreshold)
            {
                estimatedX = _state.LastX.Value;
                estimatedY = _state.LastY.Value;
            }
        }

        // -------------------------------------------------------
        // Ignore Impossible Jumps
        // -------------------------------------------------------

        if (_state.LastX.HasValue && _state.LastY.HasValue)
        {
            double jump = Math.Sqrt(
                Math.Pow(estimatedX - _state.LastX.Value, 2) +
                Math.Pow(estimatedY - _state.LastY.Value, 2));

            if (jump > MaxJumpDistance)
            {
                _logger.LogWarning(
                    "Ignoring sudden position jump: {Jump}",
                    Math.Round(jump, 2));

                estimatedX = _state.LastX.Value;
                estimatedY = _state.LastY.Value;
            }
        }

        // Save latest position
        _state.LastX = estimatedX;
        _state.LastY = estimatedY;

        // -------------------------------------------------------
        // Weighted Floor Detection
        // -------------------------------------------------------

        var floorWeights = beaconList
            .GroupBy(b => b.FloorId)
            .Select(g => new
            {
                Floor = g.Key,
                Weight = g.Sum(x =>
                {
                    double normalized = Math.Max(1, x.Rssi + 100);
                    return normalized * normalized;
                })
            })
            .OrderByDescending(x => x.Weight)
            .ToList();

        int estimatedFloor = floorWeights.First().Floor;

        // -------------------------------------------------------
        // Floor Lock (Hysteresis)
        // -------------------------------------------------------

        if (!_state.LastFloor.HasValue)
        {
            _state.LastFloor = estimatedFloor;
        }
        else if (_state.LastFloor.Value != estimatedFloor)
        {
            _state.FloorConfirmationCount++;

            _logger.LogInformation(
                "Possible floor change detected. Previous={Previous}, New={New}, Count={Count}",
                _state.LastFloor.Value,
                estimatedFloor,
                _state.FloorConfirmationCount);

            if (_state.FloorConfirmationCount >= FloorConfirmationRequired)
            {
                _logger.LogInformation(
                    "Floor changed from {Previous} to {New}",
                    _state.LastFloor.Value,
                    estimatedFloor);

                _state.LastFloor = estimatedFloor;
                _state.FloorConfirmationCount = 0;
            }
            else
            {
                // Keep previous floor until confirmed
                estimatedFloor = _state.LastFloor.Value;
            }
        }
        else
        {
            // Same floor, reset confirmation counter
            _state.FloorConfirmationCount = 0;
        }

        estimatedFloor = _state.LastFloor.Value;
        // -------------------------------------------------------
        // Strongest Beacon
        // -------------------------------------------------------

        var strongestBeacon = beaconList
            .OrderByDescending(b => b.Rssi)
            .First();

        // -------------------------------------------------------
        // Confidence
        // -------------------------------------------------------

        double averageRssi = beaconList.Average(b => Math.Abs(b.Rssi));

        double confidence =
            0.5 +
            (beaconList.Count * 0.03);

        if (averageRssi < 55)
            confidence += 0.20;
        else if (averageRssi < 65)
            confidence += 0.10;
        else if (averageRssi > 80)
            confidence -= 0.10;

        confidence = Math.Clamp(confidence, 0.0, 1.0);

        // -------------------------------------------------------
        // Final Logging
        // -------------------------------------------------------

        _logger.LogInformation(
            "Estimated Position -> X:{X}, Y:{Y}",
            Math.Round(estimatedX, 2),
            Math.Round(estimatedY, 2));

        _logger.LogInformation(
            "Estimated Floor -> {Floor}",
            estimatedFloor);

        _logger.LogInformation(
            "Confidence -> {Confidence}",
            Math.Round(confidence, 2));

        // -------------------------------------------------------
        // Map Matching
        // -------------------------------------------------------
        _logger.LogInformation(
    "Graph Nodes Before MapMatching: {Count}",
    _graphService.NodeCoordinateMap.Count);

        _logger.LogInformation(
            "Floor Nodes Before MapMatching: {Count}",
            _graphService.NodeFloorMap.Count);
        if (!_graphService.IsLoaded)
        {
            await _graphService.LoadGraphAsync();
        }
        var snappedPosition = _mapMatching.SnapToNearestNode(
      estimatedX,
      estimatedY,
      estimatedFloor,
      request.BuildingId ?? 1);

        if (snappedPosition != null)
        {
            _logger.LogInformation(
                "Snapped Node -> {Node} ({X},{Y}) Floor:{Floor}",
                snappedPosition.NodeId,
                snappedPosition.X,
                snappedPosition.Y,
                snappedPosition.FloorId);
        }
        else
        {
            _logger.LogWarning("Map matching failed.");
        }

        // -------------------------------------------------------
        // Confidence Adjustment
        // -------------------------------------------------------

        if (beaconList.Count < 6)
        {
            confidence -= 0.05;
        }

        if (beaconList.Count < 5)
        {
            confidence -= 0.10;
        }

        if (beaconList.Count < 4)
        {
            confidence -= 0.20;
        }

        confidence = Math.Clamp(confidence, 0.0, 1.0);

        // -------------------------------------------------------
        // Return if Map Matching Failed
        // -------------------------------------------------------

        if (snappedPosition == null)
        {
            return new PositionResult
            {
                X = Math.Round(estimatedX, 2),
                Y = Math.Round(estimatedY, 2),

                Floor = estimatedFloor,
                NearestNode = strongestBeacon.NearestNodeId,

                Heading = heading,
                Confidence = Math.Round(confidence, 2),
                IsIndoor = true
            };
        }

        // -------------------------------------------------------
        // Successful Map Matching
        // -------------------------------------------------------

        return new PositionResult
        {
            // Smooth position for UI
            X = Math.Round(estimatedX, 2),
            Y = Math.Round(estimatedY, 2),

            // Routing information
            NearestNode = snappedPosition.NodeId,
            Floor = snappedPosition.FloorId,

            Heading = heading,

            Confidence = Math.Round(confidence, 2),

            IsIndoor = true,

            // Debug values
            SnappedX = snappedPosition.X,
            SnappedY = snappedPosition.Y
        };
    }
}