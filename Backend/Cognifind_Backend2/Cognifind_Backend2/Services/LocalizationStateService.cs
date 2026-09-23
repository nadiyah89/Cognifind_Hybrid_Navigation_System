using System.Collections.Concurrent;

namespace Cognifind_Backend2.Services
{
    public class LocalizationStateService
    {
        // -------------------------
        // RSSI Memory
        // -------------------------

        // EMA-smoothed RSSI
        public ConcurrentDictionary<string, double> LastRssi { get; }
     = new();

        public ConcurrentDictionary<string, double> LastStableRssi { get; }
            = new();

        // -------------------------
        // Position Memory
        // -------------------------

        public double? LastX { get; set; }
        public double? LastY { get; set; }

        // -------------------------
        // Kalman Filter State
        // -------------------------

        public bool KalmanInitialized { get; set; }

        public double KalmanX { get; set; }

        public double KalmanY { get; set; }

        public double ErrorCovarianceX { get; set; } = 1;

        public double ErrorCovarianceY { get; set; } = 1;

        // -------------------------
        // Floor Memory
        // -------------------------

        public int? LastFloor { get; set; }
        public int FloorConfirmationCount { get; set; }

        // -------------------------
        // Map Matching Memory
        // -------------------------

        public string? LastNodeId { get; set; }

        public double LastNodeDistance { get; set; }
        // Candidate node waiting for confirmation
        public string? PendingNodeId { get; set; }

        // Consecutive scans
        public int PendingNodeCount { get; set; }
    }
}