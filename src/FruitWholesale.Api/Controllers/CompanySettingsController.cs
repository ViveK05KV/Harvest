using FruitWholesale.Application.DTOs.CompanySettings;
using FruitWholesale.Application.Services;
using FruitWholesale.Domain.Enums;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace FruitWholesale.Api.Controllers;

public class CompanySettingsController(ICompanySettingsService service) : ApiControllerBase
{
    private static readonly Dictionary<string, string> AllowedLogoContentTypes = new()
    {
        [".png"] = "image/png",
        [".jpg"] = "image/jpeg",
        [".jpeg"] = "image/jpeg",
        [".svg"] = "image/svg+xml",
        [".webp"] = "image/webp"
    };
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
        if (!AllowedLogoContentTypes.TryGetValue(extension, out var contentType))
        {
            return BadRequest(new { detail = "Logo must be a PNG, JPG, SVG, or WEBP image." });
        }

        using var memoryStream = new MemoryStream();
        await file.CopyToAsync(memoryStream);
        var dataUri = $"data:{contentType};base64,{Convert.ToBase64String(memoryStream.ToArray())}";

        return FromResult(await service.UpdateLogoAsync(dataUri));
    }
}
