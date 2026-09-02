using FruitWholesale.Application.Common.Interfaces;
using FruitWholesale.Domain.Enums;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace FruitWholesale.Api.Controllers;

// Admin-only, one-off maintenance actions - not part of normal app flow.
public class MaintenanceController(ILedgerService ledgerService) : ApiControllerBase
{
    /// <summary>Recalculates FIFO cost basis for every fruit from scratch. Reuses the same
    /// per-fruit recalculation every Purchase/Supply/Return write already triggers, so it's
    /// safe to re-run - use after a costing-logic change to backfill existing data.</summary>
    [HttpPost("recalculate-cost-basis")]
    [Authorize(Roles = UserRoles.Admin)]
    public async Task<IActionResult> RecalculateCostBasis()
    {
        await ledgerService.RecalculateAllFruitCostBasisAsync();
        return NoContent();
    }
}
