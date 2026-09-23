using Cognifind_Backend2.Models;
using Cognifind_Backend2.Models.Outdoor_Navigation;
using Microsoft.EntityFrameworkCore;

public class AppDbContext : DbContext
{
    public AppDbContext(DbContextOptions<AppDbContext> options)
        : base(options) { }

    public DbSet<Floor> Floors { get; set; }
    public DbSet<Node> Nodes { get; set; }
    public DbSet<Edge> Edges { get; set; }
    public DbSet<Building> Buildings { get; set; }
    public DbSet<User> Users { get; set; }
    public DbSet<Location> Locations { get; set; }
    public DbSet<BuildingEntrance> BuildingEntrances { get; set; }
    public DbSet<OutdoorNode> OutdoorNodes { get; set; }

    public DbSet<OutdoorEdge> OutdoorEdges { get; set; }
    public DbSet<Beacon> Beacons { get; set; }

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        base.OnModelCreating(modelBuilder);

        //modelBuilder.Entity<BuildingEntrance>()
        //    .HasOne(be => be.Node)
        //    .WithMany()
        //    .HasForeignKey(be => be.NodeId)
        //    .HasPrincipalKey(n => n.NodeId);


        modelBuilder.Entity<Location>()
          .Property(l => l.Type)
          .HasConversion<int>();
    }

}
