FROM mcr.microsoft.com/dotnet/sdk:10.0-alpine AS build
WORKDIR /src

COPY src/FruitWholesale.Domain/FruitWholesale.Domain.csproj src/FruitWholesale.Domain/
COPY src/FruitWholesale.Shared/FruitWholesale.Shared.csproj src/FruitWholesale.Shared/
COPY src/FruitWholesale.Application/FruitWholesale.Application.csproj src/FruitWholesale.Application/
COPY src/FruitWholesale.Infrastructure/FruitWholesale.Infrastructure.csproj src/FruitWholesale.Infrastructure/
COPY src/FruitWholesale.Api/FruitWholesale.Api.csproj src/FruitWholesale.Api/
RUN dotnet restore src/FruitWholesale.Api/FruitWholesale.Api.csproj

COPY src/ src/
RUN dotnet publish src/FruitWholesale.Api/FruitWholesale.Api.csproj -c Release -o /app --no-restore

FROM mcr.microsoft.com/dotnet/aspnet:10.0-alpine AS runtime
RUN apk add --no-cache icu-libs
WORKDIR /app
COPY --from=build /app .
COPY database/*.sql database/*.txt database/

ENV ASPNETCORE_HTTP_PORTS=8080
ENV DOTNET_SYSTEM_GLOBALIZATION_INVARIANT=false
EXPOSE 8080
ENTRYPOINT ["dotnet", "FruitWholesale.Api.dll"]
