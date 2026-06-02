# AGENTS.md

Guidance for coding agents working in `/private/etc/nix-darwin`.

## Nix Search & Documentation

Use the `mcp_nixos_nix` tool to search for packages and options. This tool is the source of truth for the current state of `nixpkgs` and related ecosystem options.

- **Search Packages:**
  `mcp_nixos_nix(action="search", query="firefox")`
- **Search NixOS Options:**
  `mcp_nixos_nix(action="search", query="services.openssh", type="options")`
- **Search nix-darwin Options:**
  `mcp_nixos_nix(action="search", query="networking.computerName", source="darwin")`
- **Search Home Manager Options:**
  `mcp_nixos_nix(action="search", query="programs.fish", source="home-manager")`
- **Search Program Binaries:**
  `mcp_nixos_nix(action="search", query="ls", type="programs")` (finds which package provides a binary)
- **Get Package Versions (History):**
  Use `mcp_nixos_nix_versions(package="nodejs")` to find specific versions and their commit hashes/dates.

Always prefer these tools over `nix search` or web scraping, as they provide structured data and are less likely to be outdated.

## Context7 Documentation

Use the `ctx7` CLI to fetch current documentation whenever the user asks about a library, framework, SDK, API, CLI tool, or cloud service -- even well-known ones like React, Next.js, Prisma, Express, Tailwind, Django, or Spring Boot. This includes API syntax, configuration, version migration, library-specific debugging, setup instructions, and CLI tool usage. Use even when you think you know the answer -- your training data may not reflect recent changes. Prefer this over web search for library docs.

Do not use for: refactoring, writing scripts from scratch, debugging business logic, code review, or general programming concepts.

### Steps

1. Resolve library: `bunx ctx7@latest library <name> "<user's question>"` — use the official library name with proper punctuation (e.g., "Next.js" not "nextjs", "Customer.io" not "customerio", "Three.js" not "threejs")
2. Pick the best match (ID format: `/org/project`) by: exact name match, description relevance, code snippet count, source reputation (High/Medium preferred), and benchmark score (higher is better). If results don't look right, try alternate names or queries (e.g., "next.js" not "nextjs", or rephrase the question)
3. Fetch docs: `bunx ctx7@latest docs <libraryId> "<user's question>"`
4. If you weren't satisfied with the answer, re-run the same command with `--research`. This retries with sandboxed agents that git-pull the actual source repos plus a live web search, then synthesizes a fresh answer. More costly than the default
5. Answer using the fetched documentation

You MUST call `library` first to get a valid ID unless the user provides one directly in `/org/project` format. Use the user's full question as the query -- specific and detailed queries return better results than vague single words. Do not run more than 3 commands per question. Do not include sensitive information (API keys, passwords, credentials) in queries.

For version-specific docs, use `/org/project/version` from the `library` output (e.g., `/vercel/next.js/v14.3.0`).

If a command fails with a quota error, inform the user and suggest `npx ctx7@latest login` or setting `CONTEXT7_API_KEY` env var for higher limits. Do not silently fall back to training data.

## Mission

- Maintain this repository as the source of truth for macOS (`nix-darwin` + Home Manager) and homelab (`NixOS`) systems.
- Prefer minimal, reversible changes that match existing Nix style.
- Keep secrets out of the Nix store and out of committed files.
- Validate affected targets before finishing.
- Always use Context7 when I need library/API documentation, code generation, setup or configuration steps without me having to explicitly ask.

## Repository Shape

- `flake.nix`: entry point with two primary outputs:
  - `darwinConfigurations."Rishabs-MacBook-Pro"`
  - `nixosConfigurations."Rishabs-Homelab"`
- `hosts/macbook/`: nix-darwin host modules.
- `hosts/homelab/`: NixOS host modules.
- `home/rishab/`: Home Manager user config and submodules.
- `secrets/`: agenix secret declarations (public keys + secret names), not plaintext secrets.
- `pkgs/`: custom derivations.

## Build Commands

Run from repo root: `/private/etc/nix-darwin`.

- Evaluate flake outputs:
  - `nix flake show`
- Validate flake metadata and checks:
  - `nix flake check --print-build-logs`
- Build macOS config without switching:
  - `sudo -i darwin-rebuild build --flake .#Rishabs-MacBook-Pro`
- Switch/apply macOS config (USER ONLY - AGENT MUST NEVER RUN THIS OR `darwin-rebuild switch`):
  - `reload`
- Build homelab config without switching:
  - `nix build .#nixosConfigurations.Rishabs-Homelab.config.system.build.toplevel`
- Switch homelab config locally/remotely (USER ONLY - AGENT MUST NEVER RUN THIS):
  - `nixos-rebuild switch --flake .#Rishabs-Homelab --target-host homelab --sudo`

> [!IMPORTANT]
> **AGENTS MUST NEVER APPLY OR SWITCH CONFIGURATIONS.** Only validate builds (`darwin-rebuild build` or `nix build ...toplevel`). Always prompt the user to manually run `reload` or `nixos-rebuild switch` once the build succeeds.

## Lint / Format Commands

- Format Nix files (repo style tool is `nixfmt`):
  - `nixfmt flake.nix`
  - `nixfmt hosts/macbook/default.nix`
  - `nixfmt home/rishab/default.nix`
- Format multiple files when needed:
  - `nixfmt $(rg --files -g '*.nix')`
- Optional static analysis if available in dev shell/environment:
  - `statix check .`
  - `deadnix .`

## Test / Validation Strategy

There is no conventional unit-test suite in this repo; validation is done by evaluation/builds.

- Fastest safety check after edits:
  - `nix flake check --print-build-logs`
- Validate only one target host after host-specific changes:
  - macOS: `sudo -i darwin-rebuild build --flake .#Rishabs-MacBook-Pro`
  - homelab: `nix build .#nixosConfigurations.Rishabs-Homelab.config.system.build.toplevel`
- Validate only one module path via evaluation when possible:
  - `nix eval .#darwinConfigurations."Rishabs-MacBook-Pro".config.programs.fish.enable`
  - `nix eval .#nixosConfigurations."Rishabs-Homelab".config.services.openssh.enable`

## Running a Single Test (Equivalent)

Since there are no per-test binaries, a “single test” means a focused evaluation/build:

1. Pick the narrowest affected output path.
2. Run `nix eval` on that exact config path for quick checks.
3. Run one host build (`darwin-rebuild build` or `nix build ...toplevel`) before finishing.

Examples:

- Single option check:
  - `nix eval .#darwinConfigurations."Rishabs-MacBook-Pro".config.programs.mcp.enable`
- Single service check:
  - `nix eval .#nixosConfigurations."Rishabs-Homelab".config.services.dnscrypt-proxy.enable`

## Code Style (Nix)

- Indentation: two spaces.
- Prefer trailing semicolons for all Nix attr assignments.
- Keep attribute sets grouped logically (system, services, networking, programs, etc.).
- Keep imports sorted in stable, readable order.
- Preserve existing file-local patterns before introducing new abstractions.
- Avoid large refactors unless explicitly requested.

## Imports and Module Structure

- Add modules to existing `imports` lists near related modules.
- Keep host-specific behavior in `hosts/*` modules.
- Keep user/tooling behavior in `home/rishab/*` modules.
- Keep package definitions in `pkgs/*.nix` and consume through overlays.
- Pass shared values through `specialArgs`/`extraSpecialArgs` when needed.

## Naming Conventions

- Match existing output names exactly:
  - `Rishabs-MacBook-Pro`
  - `Rishabs-Homelab`
- Use clear lowercase names for modules/files (e.g., `dnscrypt-proxy.nix`).
- Prefer descriptive attr names over abbreviations unless already established.

## Types and Option Values

- Use correct Nix types strictly:
  - booleans: `true`/`false`
  - strings quoted
  - lists with homogeneous intent
  - attrsets for structured options
- Prefer `lib.mk*` helpers when merging precedence matters.
- Do not coerce values through shell snippets when native Nix options exist.

## Error Handling and Safety

- Fail early with explicit checks where practical (`nix eval` before full builds).
- For shell init logic, guard file reads (`test -r`) before reading.
- Never commit plaintext secrets, tokens, or private keys.
- Keep agenix workflow intact:
  - secret declarations in `secrets/secrets.nix`
  - secret material encrypted externally as `.age`
- Avoid reading secret contents at Nix evaluation time.

## Secrets and Environment Variables

- Prefer runtime secret access (process start) over embedding in declarative values.
- If that is not possible, prefer runtime env templates already used in repo.
- When adjusting secret flow, verify both shell startup and consuming process behavior.

## Git and Change Hygiene

- Do not revert unrelated working tree changes.
- Keep diffs minimal and scoped to the request.
- Update docs when behavior or commands change.
- If command output is long, summarize key failures/success paths in PR notes.

## Agent Workflow Checklist

1. Read nearby modules before editing.
2. Edit minimally and keep style consistent.
3. Format changed `.nix` files with `nixfmt`.
4. Run focused validation for impacted host/module.
5. Run `nix flake check --print-build-logs` when feasible.
6. Report what changed, what was validated, and what remains manual.

## When Unsure

- Prefer the most conservative change that preserves current behavior.
- Ask for clarification only when ambiguity materially affects infrastructure behavior.
- Document assumptions in the final handoff message.
