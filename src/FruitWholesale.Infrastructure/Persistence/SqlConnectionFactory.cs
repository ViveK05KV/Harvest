using System.Data;
using FruitWholesale.Application.Common.Interfaces;
using Npgsql;
using Microsoft.Extensions.Configuration;

namespace FruitWholesale.Infrastructure.Persistence;

public class SqlConnectionFactory : IDbConnectionFactory
{
    private readonly string _connectionString;

    public SqlConnectionFactory(IConfiguration configuration)
    {
        _connectionString = configuration.GetConnectionString("DefaultConnection")
            ?? throw new InvalidOperationException("Connection string 'DefaultConnection' was not found.");
    }

    public IDbConnection CreateConnection() => new NpgsqlConnection(_connectionString);
}
