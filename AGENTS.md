# Agent Skills Guide

This document provides instructions for agents on how to utilize specific skills within this workspace, specifically `find-docs` and `nix-search`.

## 1. `find-docs`

The `find-docs` skill retrieves up-to-date documentation, API references, and code examples for any developer technology. This is essential because training data may not reflect recent API changes or version updates.

### Two-Step Workflow

1. **Resolve the Library ID**
   Always resolve the library name to a Context7-compatible ID first.

   ```bash
   ctx7 library <name> "<query>"
   ```

   _Example: `ctx7 library react "How to clean up useEffect"`_

2. **Query the Documentation**
   Once you have the ID (e.g., `/facebook/react`), query the documentation.

   ```bash
   ctx7 docs <libraryId> "<query>"
   ```

   _Example: `ctx7 docs /facebook/react "How to clean up useEffect"`_

### Guidelines

- **Be Specific**: Write full, descriptive queries rather than single words (e.g., `"React useEffect cleanup function"` instead of `"hooks"`).
- **Security**: Never include sensitive information (API keys, passwords) in queries.
- **Errors**: If you hit a quota error, inform the user and suggest `ctx7 login`, or fall back to your training data (while noting it may be outdated).

---

## 2. `nix-search`

The `nix-search` skill allows you to search NixOS packages and options using `nix-search-tv`. It indexes `nixpkgs`, `home-manager`, `nixos`, `darwin`, and `nur`.

### Key Commands

- **List Available Packages/Options**
  Print all items to filter through them.

  ```bash
  nix-search-tv print --indexes nixpkgs
  ```

- **Get Package/Option Details**
  Retrieve detailed metadata, including descriptions and platforms. Use `--json` for programmatic parsing.

  ```bash
  nix-search-tv preview --indexes nixpkgs --json firefox
  ```

- **Get Source Code Location**
  Find the exact GitHub/source URL for a package definition.

  ```bash
  nix-search-tv source --indexes nixpkgs firefox
  ```

### Guidelines

- **Use Offline Mode**: Append `--offline` (e.g., `nix-search-tv preview --offline ...`) to use cached data instead of making network calls, ensuring faster execution.
- **Multiple Indexes**: If querying multiple indexes at once, remember that package names will be prefixed (e.g., `nixpkgs/firefox`).
