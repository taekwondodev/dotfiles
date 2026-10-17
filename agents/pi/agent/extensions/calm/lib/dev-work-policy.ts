const record = (value: unknown): value is Record<string, unknown> =>
  typeof value === "object" && value !== null && !Array.isArray(value);

export function failedDevWorkChildren(value: unknown): string[] {
  const items: unknown[] = Array.isArray(value) ? value
    : record(value) && Array.isArray(value.records) ? value.records : [value];
  return [...new Set(items.flatMap((item) =>
    record(item) && item.kind === "agent" && item.status === "failed" &&
      typeof item.id === "string" && /^[a-f0-9]{8}(?:-[a-f0-9]{4}){3}-[a-f0-9]{12}$/.test(item.id)
      ? [item.id] : [],
  ))];
}

export function failedDevWorkOutcomeChildren(content: unknown): string[] {
  if (typeof content !== "string") return [];
  const newline = content.indexOf("\n");
  if (newline < 0) return [];
  try {
    return failedDevWorkChildren(JSON.parse(content.slice(newline + 1)));
  } catch {
    return [];
  }
}

export function calmChildFailureNotice(ids: readonly string[]): string {
  return ids.map((id) => `\x1b[31mChild failed: ${id}. Use /calm to show details.\x1b[39m`).join("\n");
}
