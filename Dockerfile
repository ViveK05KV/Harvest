# Build context is the repo root (not src/FruitWholesale.Api) because the Api
# project references four sibling projects under src/. Deploy with:
#   gcloud run deploy fruitwholesale-api --source . --region us-central1
# which builds this Dockerfile via Cloud Build — no local Docker install needed.

FROM mcr.microsoft.com/dotnet/sdk:10.0 AS build
WORKDIR /src

# Restore first, on just the project files, so this layer is cached across
# builds that only change .cs files.
COPY FruitWholesale.slnx ./
COPY src/FruitWholesale.Api/FruitWholesale.Api.csproj src/FruitWholesale.Api/
COPY src/FruitWholesale.Application/FruitWholesale.Application.csproj src/FruitWholesale.Application/
COPY src/FruitWholesale.Domain/FruitWholesale.Domain.csproj src/FruitWholesale.Domain/
COPY src/FruitWholesale.Infrastructure/FruitWholesale.Infrastructure.csproj src/FruitWholesale.Infrastructure/
COPY src/FruitWholesale.Shared/FruitWholesale.Shared.csproj src/FruitWholesale.Shared/
RUN dotnet restore src/FruitWholesale.Api/FruitWholesale.Api.csproj

COPY src/ src/
RUN dotnet publish src/FruitWholesale.Api/FruitWholesale.Api.csproj -c Release -o /app/publish --no-restore

FROM mcr.microsoft.com/dotnet/aspnet:10.0 AS final
WORKDIR /app
COPY --from=build /app/publish .

# Cloud Run injects PORT (defaults to 8080) and expects the container to
# listen on it; ASPNETCORE_HTTP_PORTS (.NET 8+) does that without touching
# Program.cs or Kestrel config.
ENV ASPNETCORE_HTTP_PORTS=8080
EXPOSE 8080

ENTRYPOINT ["dotnet", "FruitWholesale.Api.dll"]
