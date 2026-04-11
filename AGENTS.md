# AGENTS.md

This file provides guidance to agents when working with code in this repository.

## Project Overview

`project.el-rails` is an Emacs Lisp package that provides Ruby on Rails navigation and tooling for GNU Emacs, using the built-in `project.el` instead of Projectile. It is a rewrite/port of [projectile-rails](https://github.com/asok/projectile-rails).

- **Language**: Emacs Lisp (`.el`)
- **Minimum Emacs version**: 28.1
- **Required dependency**: `inflections >= 2.6`
- **Optional dependencies**: `inf-ruby` (Rails console), `sql` (dbconsole), `json` (database config parsing)

## Development Commands

This is a pure Elisp package with no build system. Key operations:

**Byte-compile** (check for warnings/errors):
```bash
emacs --batch -f batch-byte-compile project-rails.el
```

**Load and test interactively** in a running Emacs:
```elisp
(load-file "/path/to/project-rails.el")
```

**Run ERT tests** (if tests are added):
```bash
emacs --batch -l project-rails.el -f ert-run-tests-batch-and-exit
```

## Architecture

The entire package lives in a single file: `project-rails.el` (~1120 lines). It is organized into these logical sections:

1. **Customization group** — All user-configurable variables (`defcustom`): root detection files, directory paths, regex patterns for views/JS/CSS, command overrides, syntax highlighting keywords.

2. **Utility functions** — Rails root detection (`project-rails-root`, `project-rails--rails-app-p`), path helpers (`project-rails-expand-root`, `project-rails-with-root` macro), file listing and completion candidates.

3. **Find resource commands** — `project-rails-find-*` interactive commands (model, controller, view, spec, migration, etc.). Each uses `project-rails--choices` to build a completing-read list from files in the appropriate Rails directory.

4. **Current resource navigation** — `project-rails-find-current-*` commands that jump to related files based on the current buffer's filename, using `project-rails-resource-name-re-list` to extract resource names.

5. **Goto config commands** — `project-rails-goto-*` commands for fixed files (Gemfile, routes.rb, schema.rb, etc.).

6. **Rails command execution** — `project-rails-console`, `project-rails-server`, `project-rails-generate`, `project-rails-destroy`, `project-rails-dbconsole`. Uses `project-rails--command` to choose between custom/Spring/vanilla `bin/rails`. Spring detection via `project-rails--spring-p`.

7. **SQL/database integration** — Parses `config/database.yml` via `ruby -rjson -ryaml -e ...` to extract DB adapter and map it to Emacs SQL modes.

8. **Keymaps** — Three maps: `project-rails-mode-goto-map`, `project-rails-mode-run-map`, `project-rails-command-map`. Bound under a customizable prefix.

9. **Minor mode** — `project-rails-mode` (buffer-local) and `project-rails-global-mode` (auto-enables for Rails projects detected via `project-rails--rails-app-p`).

## Key Design Decisions

- **No Projectile dependency**: Uses `project.el` (Emacs built-in since 28.1).
- **Intentionally omitted**: Hydra integration, Rake support, Zeus preloader, discover.el, `goto-file-at-point` (deferred to LSP/dumb-jump/robe).
- **Spring detection**: Checks for `tmp/spring/spring.pid` relative to project root.
- **Partial extraction**: `project-rails-extract-region` supports erb, haml, and slim syntax via `project-rails-extracted-region-snippet`.
- **Font lock**: `project-rails--highlight-keywords` adds Rails-specific keywords (controller actions, model macros, migration methods, Active Support) to font-lock based on file type.
