# SPDX-FileCopyrightText: 2026 David Rabkin
# SPDX-License-Identifier: 0BSD

# Repository Guidelines

Personal dotfiles.
`install.rb` symlinks the configuration files into the home directory and
installs packages on macOS, Linux, and the BSDs.
Read the general guidelines in `~/.claude/AGENTS.md` as well.
This file takes precedence where they conflict.

## Project Structure & Module Organization

Shell configuration lives at the repository root: `aliases`, `bash_profile`,
`bashrc`, `functions`, `xinitrc`, and `zshrc`.
`app/` holds helper scripts such as `lock`, `merge_history.sh`, small
Python utilities, and the third-party `z.sh`.
Per-tool configuration sits in `i3/`, `kitty/`, `mc/`, `terminator/`,
`tmux/`, `vifm/`, and `vim/`.
The `*.do` files are `redo` targets.
`vol` is an encrypted archive of binary and personal data that extracts to
the gitignored `bin/`.
`REUSE.toml` and `LICENSES/` carry the licensing metadata, and CI lives in
`.github/workflows/`.

## Build, Test, and Development Commands

This repository uses `redo` (or `goredo`) as the task runner.

- `redo all`: run the default target.
- `redo lint`: run `actionlint`, `conform`, `dash`, `mksh`, `reuse`,
  `rubocop`, `ruff`, `shellcheck`, `shfmt`, `typos`, `vale`, `yamllint`, and
  `zizmor`.
  Linters run through shellbase's `cmd_runif`, so a missing tool is
  skipped rather than failing the build.
- `./install.rb --no-xorg --pass <pass>`: install on macOS.
  The password decrypts `vol`.

Run `redo lint` before submitting.
CI enforces the same checks through dedicated workflows.

## Secrets & Binary Data

`vol` is an encrypted tarball of personal binary data.
Never commit that data anywhere else.

## Coding Style & Naming Conventions

Write shell as portable `sh` first.
Keep Bash-specific features out unless the file is Bash- or zsh-only, such
as `bashrc` or `zshrc`.
Keep files clean under `shfmt` and `shellcheck`.
Wrap lines at about 79 characters.
Scripts open with the `# vi: lbr noet sw=2 ts=2 tw=79 wrap` modeline and
the two SPDX lines.
Write comments in third-person singular, start them with a capital letter,
and avoid semicolons in comment and prose text.
Do not place comments inside function bodies.

## Licensing

The repository is REUSE 3.3 compliant and `reuse lint` runs in the lint
chain.
Every new file needs `SPDX-FileCopyrightText` and `SPDX-License-Identifier`
tags, with the copyright range starting at the file's first-commit year.
Annotate files that cannot carry headers in `REUSE.toml`: own files as
`0BSD`, third-party files with their upstream license, files without a
findable upstream license as `LicenseRef-unknown`, and `vol` as
`LicenseRef-proprietary`.
Add the matching text under `LICENSES/` for any new license identifier.

## Continuous Integration

`zizmor` enforces the workflow conventions with the policy in
`.github/zizmor.yml`:

- Pin actions to release tags rather than commit hashes.
- Set `persist-credentials: false` on every checkout.
- Keep permissions at `contents: read` unless a step needs more.
- Set `timeout-minutes` on every job.
- Apply `cancel-in-progress` only to pull requests, so pushes to `master`
  always finish.

Dependabot uses a seven-day cooldown.

## Commit & Pull Request Guidelines

Use Conventional Commits with a meaningful scope, for example
`chore(lint): ...` or `build(deps): ...`.
`conform` enforces the header in CI: 72 characters or fewer, lowercase,
in the imperative mood, and spellchecked against US English, per
`.conform.yaml`.
Do not add AI attribution, tool signatures, generated-by trailers, or AI
co-author metadata to commits, pull requests, issues, or code comments.
Before committing, update `BASE_APP_VERSION` (date-based, `0.9.YYYYMMDD`)
in changed `*.do` files and the `SPDX-FileCopyrightText` year in every
changed file, but only alongside a substantive change.
Same-day commits share the version value.
