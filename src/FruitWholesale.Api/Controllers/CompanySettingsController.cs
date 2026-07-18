using FruitWholesale.Application.DTOs.CompanySettings;
using FruitWholesale.Application.Services;
using FruitWholesale.Domain.Enums;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace FruitWholesale.Api.Controllers;

public class CompanySettingsController(ICompanySettingsService service, IWebHostEnvironment environment) : ApiControllerBase
{
    private static readonly string[] AllowedLogoExtensions = [".png", ".jpg", ".jpeg", ".svg", ".webp"];
    private const long MaxLogoSizeBytes = 2 * 1024 * 1024;

    [HttpGet]
    public async Task<ActionResult<CompanySettingsDto>> Get()
    {
        var settings = await service.GetAsync();
        return settings is null ? NotFound() : Ok(settings);
    }

    [HttpPut]
    [Authorize(Roles = UserRoles.Admin)]
    public async Task<ActionResult<CompanySettingsDto>> Save(UpsertCompanySettingsDto dto) => Ok(await service.SaveAsync(dto));

    [HttpPost("cash-adjustment")]
    [Authorize(Roles = $"{UserRoles.Admin},{UserRoles.Accountant}")]
    public async Task<ActionResult> ApplyCashAdjustment(CashAdjustmentDto dto) => FromResult(await service.ApplyCashAdjustmentAsync(dto));

    [HttpPost("logo")]
    [Authorize(Roles = UserRoles.Admin)]
    [RequestSizeLimit(MaxLogoSizeBytes)]
    public async Task<ActionResult<CompanySettingsDto>> UploadLogo(IFormFile file)
    {
        if (file.Length == 0)
        {
            return BadRequest(new { detail = "No file was uploaded." });
        }

        if (file.Length > MaxLogoSizeBytes)
        {
            return BadRequest(new { detail = "Logo must be 2 MB or smaller." });
        }

        var extension = Path.GetExtension(file.FileName).ToLowerInvariant();
        if (!AllowedLogoExtensions.Contains(extension))
        {
            return BadRequest(new { detail = "Logo must be a PNG, JPG, SVG, or WEBP image." });
        }

        var webRootPath = environment.WebRootPath ?? Path.Combine(environment.ContentRootPath, "wwwroot");
        var uploadsDir = Path.Combine(webRootPath, "uploads");
        Directory.CreateDirectory(uploadsDir);

        foreach (var existingExtension in AllowedLogoExtensions)
        {
            var stalePath = Path.Combine(uploadsDir, $"company-logo{existingExtension}");
            if (System.IO.File.Exists(stalePath))
            {
                System.IO.File.Delete(stalePath);
            }
        }

        var fileName = $"company-logo{extension}";
        var filePath = Path.Combine(uploadsDir, fileName);
        await using (var stream = new FileStream(filePath, FileMode.Create))
        {
            await file.CopyToAsync(stream);
        }

        return FromResult(await service.UpdateLogoAsync($"/uploads/{fileName}"));
    }
}
