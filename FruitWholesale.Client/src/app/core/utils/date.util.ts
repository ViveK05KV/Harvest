export function firstOfMonth(): Date {
  const now = new Date();
  return new Date(now.getFullYear(), now.getMonth(), 1);
}

/// Formats using the Date object's local calendar fields (getFullYear/Month/Date),
/// never toISOString() — that converts to UTC first, which silently shifts the date
/// by a day for any timezone ahead of UTC (e.g. IST) once local midnight rolls back
/// across the UTC day boundary.
export function toIso(date: Date): string {
  const year = date.getFullYear();
  const month = String(date.getMonth() + 1).padStart(2, '0');
  const day = String(date.getDate()).padStart(2, '0');
  return `${year}-${month}-${day}`;
}
