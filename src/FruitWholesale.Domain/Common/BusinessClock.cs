namespace FruitWholesale.Domain.Common;

/// <summary>
/// The business operates in India Standard Time, but the server clock (and
/// DateTime.UtcNow) runs in UTC. IST is UTC+5:30, so for roughly 5.5 hours after
/// local midnight each day (00:00-05:30 IST), DateTime.UtcNow.Date still reports
/// yesterday's date even though today's transactions are already being recorded
/// under today's IST date (client-side date pickers use the browser's local
/// date). Any "today" comparison built on UtcNow.Date during that window silently
/// misses same-day rows. Use BusinessClock.Today wherever "today" means the
/// business's calendar day, not a raw UTC timestamp.
/// </summary>
public static class BusinessClock
{
    private static readonly TimeZoneInfo IndiaTimeZone = ResolveIndiaTimeZone();

    public static DateTime Today => TimeZoneInfo.ConvertTimeFromUtc(DateTime.UtcNow, IndiaTimeZone).Date;

    private static TimeZoneInfo ResolveIndiaTimeZone()
    {
        try
        {
            return TimeZoneInfo.FindSystemTimeZoneById("Asia/Kolkata");
        }
        catch (TimeZoneNotFoundException)
        {
            return TimeZoneInfo.FindSystemTimeZoneById("India Standard Time");
        }
    }
}
