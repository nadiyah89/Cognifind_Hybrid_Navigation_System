using Cognifind.Api.Repositories;
using Cognifind_Backend;
using Cognifind_Backend.Api.Repositories;
using Cognifind_Backend2.Services;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using Microsoft.OpenApi.Models;
using System.Text;

try
{
    var builder = WebApplication.CreateBuilder(args);

    /// CORS
    builder.Services.AddCors(options =>
    {
        options.AddPolicy("DevCors", policy =>
            policy.AllowAnyOrigin()
                  .AllowAnyHeader()
                  .AllowAnyMethod());
    });

    /// DB (PostgreSQL)
    builder.Services.AddDbContext<AppDbContext>(options =>
        options.UseNpgsql(
            builder.Configuration.GetConnectionString("DefaultConnection")));

    /// Repositories
    builder.Services.AddScoped<IUserRepository, UserRepository>();

    /// Services
    builder.Services.AddScoped<GraphService>();
    builder.Services.AddScoped<DijkstraService>();
    builder.Services.AddScoped<NavigationInstructionService>();
    builder.Services.AddScoped<OutdoorGraphService>();
    builder.Services.AddScoped<OutdoorGraphLoader>();
    builder.Services.AddScoped<OutdoorRoutingService>();
    builder.Services.AddScoped<MapMatchingService>();
    builder.Services.AddSingleton<LocalizationStateService>();
    builder.Services.AddScoped<LocalizationService>(); 
    builder.Services.AddScoped<NavigationTrackingService>();
    builder.Services.AddScoped<RouteDeviationService>();
    builder.Services.AddScoped<NavigationSessionService>();

    /// HttpClient
    builder.Services.AddHttpClient();

    /// Controllers
    builder.Services.AddControllers();
    builder.Services.AddEndpointsApiExplorer();

    /// JWT CONFIG
    var jwtSection = builder.Configuration.GetSection("Jwt");
    var key = jwtSection.GetValue<string>("Key");

    builder.Services
        .AddAuthentication(options =>
        {
            options.DefaultAuthenticateScheme = JwtBearerDefaults.AuthenticationScheme;
            options.DefaultChallengeScheme = JwtBearerDefaults.AuthenticationScheme;
        })
        .AddJwtBearer(options =>
        {
            options.RequireHttpsMetadata = false;
            options.SaveToken = true;

            options.TokenValidationParameters = new TokenValidationParameters
            {
                ValidateIssuer = true,
                ValidateAudience = true,
                ValidateLifetime = true,
                ValidateIssuerSigningKey = true,

                ValidIssuer = jwtSection["Issuer"],
                ValidAudience = jwtSection["Audience"],
                IssuerSigningKey =
                    new SymmetricSecurityKey(Encoding.UTF8.GetBytes(key!))
            };
        });

    builder.Services.AddAuthorization();

    /// Swagger
    builder.Services.AddSwaggerGen(c =>
    {
        c.SwaggerDoc("v1",
            new OpenApiInfo { Title = "Cognifind API", Version = "v1" });

        var jwtSecurityScheme = new OpenApiSecurityScheme
        {
            Name = "Authorization",
            Description = "Enter: Bearer {your JWT token}",
            In = ParameterLocation.Header,
            Type = SecuritySchemeType.Http,
            Scheme = "bearer",
            BearerFormat = "JWT",
            Reference = new OpenApiReference
            {
                Type = ReferenceType.SecurityScheme,
                Id = "Bearer"
            }
        };

        c.AddSecurityDefinition("Bearer", jwtSecurityScheme);

        c.AddSecurityRequirement(new OpenApiSecurityRequirement
        {
            { jwtSecurityScheme, Array.Empty<string>() }
        });
    });

    var app = builder.Build();

    if (app.Environment.IsDevelopment())
    {
        app.UseHttpsRedirection();
    }

    app.UseSwagger();
    app.UseSwaggerUI();

    app.UseCors("DevCors");

    app.UseAuthentication();
    app.UseAuthorization();

    app.MapControllers();

    /// Seeder
    using (var scope = app.Services.CreateScope())
    {
        await SuperAdminSeeder.SeedSuperAdminAsync(
            scope.ServiceProvider,
            app.Configuration);

      
    }

    /// Render PORT binding
    var port = Environment.GetEnvironmentVariable("PORT");

    if (!string.IsNullOrEmpty(port))
    {
        app.Urls.Add($"http://*:{port}");
    }

    app.Run();
}
catch (Exception ex)
{
    Console.WriteLine("STARTUP ERROR:");
    Console.WriteLine(ex.ToString());
    throw;
}