export function firstOfMonth(): Date {
  const now = new Date();
  return new Date(now.getFullYear(), now.getMonth(), 1);
}

export function toIso(date: Date): string {
  return date.toISOString().slice(0, 10);
}
