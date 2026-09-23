namespace Cognifind_Backend2.Services
{
    using System.Xml.Linq;

    public class KmlParserService
    {
        public List<List<(double lat, double lng)>> Parse(string filePath)
        {
            var result = new List<List<(double, double)>>();

            var doc = XDocument.Load(filePath);

            var placemarks = doc.Descendants()
                .Where(x => x.Name.LocalName == "Placemark");

            foreach (var placemark in placemarks)
            {
                var coordinatesNode = placemark.Descendants()
                    .FirstOrDefault(x => x.Name.LocalName == "coordinates");

                if (coordinatesNode == null)
                    continue;

                var coords = new List<(double, double)>();

                var lines = coordinatesNode.Value.Trim().Split(' ');

                foreach (var line in lines)
                {
                    var parts = line.Split(',');

                    if (parts.Length >= 2)
                    {
                        double lng = double.Parse(parts[0]);
                        double lat = double.Parse(parts[1]);

                        coords.Add((lat, lng));
                    }
                }

                result.Add(coords);
            }

            return result;
        }
    }
}
