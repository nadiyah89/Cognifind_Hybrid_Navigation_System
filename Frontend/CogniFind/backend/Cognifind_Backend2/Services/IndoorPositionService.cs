//using Microsoft.EntityFrameworkCore;

//public class IndoorPositionService
//{
//    private readonly AppDbContext _context;

//    public IndoorPositionService(AppDbContext context)
//    {
//        _context = context;
//    }

//    public async Task<IndoorPositionResponse> EstimatePosition(
//    LocalizationService request)
//    {
//        // Step 1: Get beacon IDs from Flutter
//        var beaconIds = request.Beacons
//            .Select(b => b.Id)
//            .ToList();

//        // Step 2: Load beacon information from the database
//        var beacons = await _context.Beacons
//            .Where(b => beaconIds.Contains(b.BeaconId))
//            .ToListAsync();

//        // Step 3: Merge RSSI values with beacon locations
//        var beaconData =
//            from scan in request.Beacons
//            join beacon in beacons
//            on scan.Id equals beacon.BeaconId
//            select new
//            {
//                beacon.BeaconId,
//                beacon.X,
//                beacon.Y,
//                beacon.FloorId,
//                beacon.NearestNodeId,
//                scan.Rssi
//            };

//        // Step 4: Calculate weighted centroid
//        double totalWeight = 0;
//        double x = 0;
//        double y = 0;

//        foreach (var beacon in beaconData)
//        {
//            double weight = 1.0 / Math.Abs(beacon.Rssi);

//            totalWeight += weight;

//            x += beacon.X * weight;
//            y += beacon.Y * weight;
//        }

//        // No matching beacons found
//        if (totalWeight == 0)
//        {
//            return new IndoorPositionResponse
//            {
//                X = 0,
//                Y = 0,
//                Floor = -1,
//                NearestNode = "",
//                Confidence = 0
//            };
//        }

//        x /= totalWeight;
//        y /= totalWeight;

//        // Get floor from the strongest beacon (smallest absolute RSSI)
//        var strongestBeacon = beaconData
//            .OrderBy(b => Math.Abs(b.Rssi))
//            .First();

//        return new IndoorPositionResponse
//        {
//            X = x,
//            Y = y,
//            Floor = strongestBeacon.FloorId,
//            NearestNode = strongestBeacon.NearestNodeId,
//            Confidence = 0.8
//        };
    


  
//    }
//}