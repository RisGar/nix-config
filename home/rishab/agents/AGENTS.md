# Agent Skills Guide

This document provides instructions for agents on what guidelines and rules to follow.

## Guidelines

- **Skills**: When appropriate always use the `find-docs` and `nix-search` skills to consult library and NixOS documentation.

## General Rules

- **Missing Binaries**: If you cannot find a required binary on the system:
  1. Find the package that provides the binary using `nix-locate -w bin/<binary>`.
  2. Use `nix run nixpkgs#<PACKAGE>` to execute it.

## Script Execution Rules

- **Python**: General Python scripts should be run with `uv` instead of `python`.
- **JavaScript/TypeScript**: Scripts should be run with `bun` instead of `node`.
