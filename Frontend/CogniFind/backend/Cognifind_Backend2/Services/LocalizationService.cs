using Cognifind_Backend2.Models;
using Microsoft.EntityFrameworkCore;
using System.Diagnostics;


    public class LocalizationService
    {
        private readonly AppDbContext _context;
        private readonly MapMatchingService _mapMatching;
        private readonly ILogger<LocalizationService> _logger;

        public LocalizationService(
            AppDbContext context,
            MapMatchingService mapMatching,
            ILogger<LocalizationService> logger)
        {
            _context = context;
            _mapMatching = mapMatching;
            _logger = logger;
        }
    

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
        var beaconReadings = request.Beacons
            .Where(b => !string.IsNullOrWhiteSpace(b.Id))
            .Where(b => b.Rssi < 0)                  // Ignore invalid RSSI
            .GroupBy(b => b.Id)
            .Select(g => g.OrderByDescending(x => x.Rssi).First())
            .OrderByDescending(b => b.Rssi)          // Strongest first
            .Take(10)
            .ToList();
        _logger.LogInformation("Filtered Beacon Count: {Count}", beaconReadings.Count);

        foreach (var beacon in beaconReadings)
        {
            _logger.LogInformation(
                "Filtered Beacon -> Id: '{Id}', RSSI: {Rssi}",
                beacon.Id,
                beacon.Rssi);
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

        var beacons = allBeacons
            .Where(b => beaconIds.Contains(b.BeaconId))
            .ToList();

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
        // Calculate Weighted Centroid
        // -------------------------------------------------------

        double totalWeight = 0;
        double estimatedX = 0;
        double estimatedY = 0;

        foreach (var beacon in beaconList)
        {
            // Temporary weighting function
            double weight = 1.0 / Math.Abs(beacon.Rssi);

            totalWeight += weight;

            estimatedX += beacon.X * weight;
            estimatedY += beacon.Y * weight;
        }

        estimatedX /= totalWeight;
        estimatedY /= totalWeight;

        // -------------------------------------------------------
        // Weighted Floor Detection
        // -------------------------------------------------------

        var floorWeights = beaconList
            .GroupBy(b => b.FloorId)
            .Select(g => new
            {
                Floor = g.Key,
                Weight = g.Sum(x => 1.0 / Math.Abs(x.Rssi))
            })
            .OrderByDescending(x => x.Weight)
            .First();

        int estimatedFloor = floorWeights.Floor;

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
        // Return Position
        // -------------------------------------------------------
        var snappedPosition = _mapMatching.ProjectOntoRoute(
            estimatedX,
            estimatedY,
            estimatedFloor,
            request.RouteNodeIds);
        _logger.LogInformation("Estimated Position -> X: {X}, Y: {Y}",
    Math.Round(estimatedX, 2),
    Math.Round(estimatedY, 2));

        _logger.LogInformation("Estimated Floor: {Floor}", estimatedFloor);
        _logger.LogInformation("Confidence: {Confidence}",
            Math.Round(confidence, 2));

        _logger.LogInformation("Map Matching Result: {Node}",
            snappedPosition?.NodeId ?? "NULL");
        _logger.LogInformation(
    "Localization Response -> X:{X}, Y:{Y}, NearestNode:{Node}, Floor:{Floor}, Confidence:{Confidence}",
    Math.Round(estimatedX, 2),
    Math.Round(estimatedY, 2),
    strongestBeacon.NearestNodeId,
    estimatedFloor,
    Math.Round(confidence, 2));
        // If map matching fails, return estimated position
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

        // Map matching successful
        return new PositionResult
        {
            // Keep estimated position for smooth blue-dot movement
            X = Math.Round(estimatedX, 2),
            Y = Math.Round(estimatedY, 2),

            // Graph information for routing
            NearestNode = snappedPosition.NodeId,
            Floor = snappedPosition.FloorId,

            Heading = heading,
            Confidence = Math.Round(confidence, 2),
            IsIndoor = true,

            // Debug / future use
            SnappedX = snappedPosition.X,
            SnappedY = snappedPosition.Y
        };

    }
}