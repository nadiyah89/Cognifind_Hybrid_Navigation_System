# Build stage
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src

COPY Cognifind_Backend2/Cognifind_Backend2.csproj Cognifind_Backend2/
RUN dotnet restore Cognifind_Backend2/Cognifind_Backend2.csproj

COPY . .
WORKDIR /src/Cognifind_Backend2

RUN dotnet publish -c Release -o /app/publish

# Runtime stage
FROM mcr.microsoft.com/dotnet/aspnet:8.0
WORKDIR /app

COPY --from=build /app/publish .

EXPOSE 10000

ENTRYPOINT ["dotnet", "Cognifind_Backend2.dll"]