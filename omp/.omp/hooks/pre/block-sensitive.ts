const ALLOWLIST = /\.env\.example/i;

const PATTERNS = [
  /\.env($|[^a-zA-Z])/i,
  /[/]\.ssh[/]/i,
  /_rsa(\s|$)/i,
  /_ed25519/i,
  /_ecdsa/i,
  /_dsa(\s|$)/i,
  /\.pem(\s|$)/i,
  /secrets?\.ya?ml/i,
  /secret[-_][a-z]/i,
  /secrets\.fish/i,
];

// tool_call registration/return shape inferred from docs/hooks.md's example only —
// not verified against a running omp instance yet.
export default function hook(pi: { on: (event: string, handler: (event: any) => any) => void }): void {
  pi.on("tool_call", (event) => {
    const input = (event.input ?? {}) as Record<string, unknown>;
    const target = String(
      input.command ?? input.path ?? input.file_path ?? input.filePath ?? ""
    );

    if (!target || ALLOWLIST.test(target)) return;

    for (const pattern of PATTERNS) {
      if (pattern.test(target)) {
        return { block: true, reason: `Bloccato: accesso a file sensibili (pattern: ${pattern})` };
      }
    }
  });
}
