using System.Text;
using Amazon.Lambda.AspNetCoreServer.Hosting;
using FruitWholesale.Api.Filters;
using FruitWholesale.Api.Middleware;
using FruitWholesale.Api.Services;
using FruitWholesale.Application;
using FruitWholesale.Application.Common.Interfaces;
using FruitWholesale.Infrastructure;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.IdentityModel.Tokens;
using Microsoft.OpenApi;
using Serilog;

var builder = WebApplication.CreateBuilder(args);

Log.Logger = new LoggerConfiguration()
    .ReadFrom.Configuration(builder.Configuration)
    .Enrich.FromLogContext()
    .WriteTo.Console()
    .WriteTo.File("Logs/log-.txt", rollingInterval: RollingInterval.Day, retainedFileCountLimit: 30)
    .CreateLogger();
builder.Host.UseSerilog();

// Adapts the app to run on AWS Lambda behind a Function URL / HTTP API.
// No-op when not running in Lambda, so local dev is unaffected.
builder.Services.AddAWSLambdaHosting(LambdaEventSource.HttpApi);

builder.Services.Configure<JwtSettings>(builder.Configuration.GetSection("Jwt"));
var jwtSettings = builder.Configuration.GetSection("Jwt").Get<JwtSettings>()
    ?? throw new InvalidOperationException("Jwt configuration section is missing.");

builder.Services
    .AddControllers(options => options.Filters.Add<ValidationFilter>())
    .ConfigureApiBehaviorOptions(options => options.SuppressModelStateInvalidFilter = true);

builder.Services.AddHttpContextAccessor();
builder.Services.AddScoped<ICurrentUserService, CurrentUserService>();

builder.Services.AddApplication();
builder.Services.AddInfrastructure();

builder.Services.AddExceptionHandler<GlobalExceptionHandler>();
builder.Services.AddProblemDetails();

builder.Services.AddCors(options =>
{
    var allowedOrigins = builder.Configuration.GetSection("Cors:AllowedOrigins").Get<string[]>() ?? [];
    options.AddPolicy("Default", policy => policy
        .WithOrigins(allowedOrigins)
        .AllowAnyHeader()
        .AllowAnyMethod());
});

builder.Services.AddAuthentication(options =>
{
    options.DefaultAuthenticateScheme = JwtBearerDefaults.AuthenticationScheme;
    options.DefaultChallengeScheme = JwtBearerDefaults.AuthenticationScheme;
})
.AddJwtBearer(options =>
{
    options.TokenValidationParameters = new TokenValidationParameters
    {
        ValidateIssuer = true,
        ValidateAudience = true,
        ValidateLifetime = true,
        ValidateIssuerSigningKey = true,
        ValidIssuer = jwtSettings.Issuer,
        ValidAudience = jwtSettings.Audience,
        IssuerSigningKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(jwtSettings.Secret)),
        ClockSkew = TimeSpan.FromMinutes(1)
    };
});
// Pin authorization to the JWT scheme so a principal from any other source — notably the IAM
// identity the Lambda adapter derives from the function URL's SigV4 authorizer — can never satisfy
// [Authorize]. See EdgeIdentityMiddleware.
builder.Services.AddAuthorization(options =>
{
    options.DefaultPolicy = new AuthorizationPolicyBuilder(JwtBearerDefaults.AuthenticationScheme)
        .RequireAuthenticatedUser()
        .Build();
});

builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen(options =>
{
    options.SwaggerDoc("v1", new OpenApiInfo
    {
        Title = "Fruit Wholesale Management System API",
        Version = "v1",
        Description = "REST API for the Fruit Wholesale Management System ERP."
    });

    var jwtScheme = new OpenApiSecurityScheme
    {
        Scheme = "bearer",
        BearerFormat = "JWT",
        Name = "Authorization",
        In = ParameterLocation.Header,
        Type = SecuritySchemeType.Http,
        Description = "Enter a valid JWT token."
    };
    options.AddSecurityDefinition("Bearer", jwtScheme);
    options.AddSecurityRequirement(_ => new OpenApiSecurityRequirement
    {
        { new OpenApiSecuritySchemeReference("Bearer", null), new List<string>() }
    });
});

var app = builder.Build();

using (var migrationScope = app.Services.CreateScope())
{
    var migrationRunner = migrationScope.ServiceProvider.GetRequiredService<FruitWholesale.Infrastructure.Persistence.MigrationRunner>();
    var migrationsDirectory = Path.Combine(AppContext.BaseDirectory, "database");
    await migrationRunner.RunAsync(migrationsDirectory);
}

app.UseExceptionHandler();

if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

app.UseSerilogRequestLogging();

app.UseHttpsRedirection();

app.UseStaticFiles();

app.UseCors("Default");

// Must run before authentication: restores the JWT that CloudFront's OAC signing displaces, and
// discards the IAM principal the Lambda adapter would otherwise leave on the request.
app.UseMiddleware<EdgeIdentityMiddleware>();

app.UseAuthentication();
app.UseAuthorization();

app.MapGet("/", () => Results.Ok(new { status = "ok", service = "FruitWholesale.Api" }));

app.MapControllers();

app.Run();
