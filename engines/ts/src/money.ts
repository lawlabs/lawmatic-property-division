export const MONEY_TOLERANCE = 0.01;

export function almostEqual(a: number, b: number, tolerance = MONEY_TOLERANCE): boolean {
  return Math.abs(a - b) <= tolerance;
}

export function n(value: number | null | undefined): number {
  return value ?? 0;
}

/** Округление пошлины до рубля: п. 6 ст. 52 НК РФ (требует подтверждения). */
export function roundFeeToRuble(amount: number): number {
  return Math.round(amount);
}

export function addDays(isoDate: string, days: number): string {
  const d = parseIsoDate(isoDate);
  d.setUTCDate(d.getUTCDate() + days);
  return toIsoDate(d);
}

export function addMonths(isoDate: string, months: number): string {
  const d = parseIsoDate(isoDate);
  d.setUTCMonth(d.getUTCMonth() + months);
  return toIsoDate(d);
}

export function addYears(isoDate: string, years: number): string {
  const d = parseIsoDate(isoDate);
  d.setUTCFullYear(d.getUTCFullYear() + years);
  return toIsoDate(d);
}

export function parseIsoDate(isoDate: string): Date {
  const [y, m, day] = isoDate.split("-").map(Number);
  return new Date(Date.UTC(y!, m! - 1, day));
}

export function toIsoDate(d: Date): string {
  return d.toISOString().slice(0, 10);
}

export function daysBetween(from: string, to: string): number {
  const a = parseIsoDate(from).getTime();
  const b = parseIsoDate(to).getTime();
  return Math.round((b - a) / 86_400_000);
}

export function isAfter(a: string, b: string): boolean {
  return a > b;
}

export function maxDate(a: string | null | undefined, b: string | null | undefined): string | null {
  if (!a) return b ?? null;
  if (!b) return a;
  return a > b ? a : b;
}
