# Guidelines

`dotfiles` maintains a set of shell, editor, and desktop settings.
`install` prepares Ruby and hands over to `install.rb`, which symlinks the
configuration files into the home directory and installs packages on macOS,
Linux, and the BSDs.
Read the shared rules at
https://raw.githubusercontent.com/rdavid/prompt/master/README.txt
before starting any task, unless they are already loaded.

## Structure

Shell configuration lives at the repository root: `aliases`, `bash_profile`,
`bashrc`, `functions`, `xinitrc`, and `zshrc`.
`app/` contains helper scripts such as `lock`, `merge_history.sh`, small
Python utilities, and the third-party `z.sh`.
Per-tool configuration sits in `i3/`, `kitty/`, `mc/`, `terminator/`,
`tmux/`, `vifm/`, and `vim/`.
CI lives in `.github/workflows/`.
Targets live in `*.do` files, which `redo` executes directly.
Treat `.redo/` as build metadata for the `redo` workflow, not hand-edited
source.
`vol` is an encrypted archive of binary and personal data that extracts to
the gitignored `bin/`.
Never commit that data anywhere else.
The version variable in `*.do` files is `BASE_APP_VERSION`.
Update it and the `SPDX-FileCopyrightText` year only alongside a substantive
change.
`conform` enforces the commit header per `.conform.yaml`: lowercase, in the
imperative mood, and spellchecked against US English.
Run `redo lint` before committing.

## Build

This project uses `redo` (or `goredo`) as the task runner.

- `redo all`: run the default target, which runs `lint`.
- `redo lint`: run `actionlint`, `conform`, `dash`, `mksh`, `reuse`,
  `rubocop`, `ruff`, `shellcheck`, `shfmt`, `typos`, `vale`, `yamllint`, and
  `zizmor`.
  Linters run through shellbase's `cmd_runif`, so a missing tool is skipped
  rather than failing the build.
  CI enforces the same checks through dedicated workflows.
- `./install --no-xorg`: install without the desktop packages.
  Add `--pass <pass>` to decrypt `vol`.
  `--xorg` adds the desktop packages and requires `--pass`.

## Style

Keep Bash-specific features out unless the file is Bash- or zsh-only, such
as `bashrc` or `zshrc`.
Keep shell files clean under `shfmt` and `shellcheck`.
The repository is REUSE 3.3 compliant.
Start the copyright range of a new file at its first-commit year.
Annotate files that cannot carry headers in `REUSE.toml`: own files as
`0BSD`, third-party files with their upstream license, files without a
findable upstream license as `LicenseRef-unknown`, and `vol` as
`LicenseRef-proprietary`.
Add the matching text under `LICENSES/` for any new license identifier.
`zizmor` enforces the workflow conventions with the policy in
`.github/zizmor.yml`.
Pin actions to release tags rather than commit hashes.
Set `persist-credentials: false` on every checkout.
Keep permissions at `contents: read` unless a step needs more.
Set `timeout-minutes` on every job.
Apply `cancel-in-progress` only to pull requests, so pushes to `master`
always finish.
Dependabot uses a seven-day cooldown.
