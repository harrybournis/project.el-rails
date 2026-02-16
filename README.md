[![MELPA](https://melpa.org/packages/project-rails-badge.svg)](https://melpa.org/#/project-rails)

# project.el-rails

## Overview

**Project.el Rails** is a minor mode for working with Ruby on Rails applications in GNU Emacs. It is inspired by [projectile-rails](https://github.com/asok/projectile-rails) but uses the built-in `project.el` package instead of [Projectile](https://github.com/bbatsov/projectile). This package provides the same Rails-specific functionality as projectile-rails without requiring the Projectile dependency.

Features:
* Navigate through Rails resources (models, controllers, views, helpers, etc.)
* Jump to related files (find the spec for the current model, etc.)
* Run `rails console` with inf-ruby integration
* Run `rails dbconsole` with sql-interactive-mode
* Run `rails generate` and `rails destroy`
* Run `rails server`
* Open log files with `auto-revert-tail-mode` enabled
* See Rails keywords highlighted
* Take advantage of [spring](https://github.com/rails/spring) preloader

## Installation

### use-package (recommended)

```elisp
(use-package project-rails
  :ensure t
  :config
  (project-rails-global-mode))
```

### straight.el

```elisp
(use-package project-rails
  :straight (:host github :repo "harrybournis/project-rails")
  :config
  (project-rails-global-mode))
```

## Usage

### The global mode

Enable the package as a global mode:

```elisp
(project-rails-global-mode)
```

This will automatically turn on `project-rails-mode` for buffers that belong to a Rails project.

## Customizing

### Keywords

Rails keywords are highlighted in mode buffers by default. To disable:

```elisp
(setq project-rails-add-keywords nil)
```

### External commands

Customize how `rails` and `spring` commands are invoked:

```elisp
;; Default values
(setq project-rails-vanilla-command "bundle exec rails")
(setq project-rails-spring-command "bundle exec spring")

;; Use binstubs instead
(setq project-rails-vanilla-command "bin/rails")
(setq project-rails-spring-command "bin/spring")
```

### Custom command overrides

Override specific Rails commands:

```elisp
(setq project-rails-custom-console-command "bin/rails console")
(setq project-rails-custom-server-command "bin/rails server")
(setq project-rails-custom-generate-command "bin/rails generate")
(setq project-rails-custom-destroy-command "bin/rails destroy")
(setq project-rails-custom-dbconsole-command "bin/rails dbconsole")
```

### JavaScript and stylesheet directories

Configure where to look for JavaScript and stylesheet files:

```elisp
(setq project-rails-javascript-dirs
      '("app/assets/javascripts/" "lib/assets/javascripts/"
        "public/javascripts/" "app/javascript/"))

(setq project-rails-stylesheet-dirs
      '("app/assets/stylesheets/" "lib/assets/stylesheets/"
        "public/stylesheets/"))

(setq project-rails-component-dir "app/javascript/packs/")
```

## Interactive Commands

The following table lists all available commands:
By default there are no keys mapped. You can map a prefix in this way, which
will map all of these.
```elisp
(define-key project-rails-mode-map (kbd "C-c r") 'project-rails-command-map)
```

### Find commands

| Command                               | Description                                             | Keybinding   |
|---------------------------------------|---------------------------------------------------------|--------------|
| project-rails-find-model              | Find a model.                                           | `<prefix> m` |
| project-rails-find-current-model      | Go to a model connected with the current resource.      | `<prefix> M` |
| project-rails-find-controller         | Find a controller.                                      | `<prefix> c` |
| project-rails-find-current-controller | Go to a controller connected with the current resource. | `<prefix> C` |
| project-rails-find-view               | Find a template or partial.                             | `<prefix> v` |
| project-rails-find-current-view       | Go to a view connected with the current resource.       | `<prefix> V` |
| project-rails-find-helper             | Find a helper.                                          | `<prefix> h` |
| project-rails-find-current-helper     | Go to a helper connected with the current resource.     | `<prefix> H` |
| project-rails-find-lib                | Find a lib file.                                        | `<prefix> l` |
| project-rails-find-feature            | Find a Cucumber feature file.                           | `<prefix> f` |
| project-rails-find-spec               | Find a spec file.                                       | `<prefix> p` |
| project-rails-find-current-spec       | Go to a spec connected with the current resource.       | `<prefix> P` |
| project-rails-find-test               | Find a test file.                                       | `<prefix> t` |
| project-rails-find-current-test       | Go to a test connected with the current resource.       | `<prefix> T` |
| project-rails-find-migration          | Find a migration.                                       | `<prefix> n` |
| project-rails-find-current-migration  | Go to a migration connected with the current resource.  | `<prefix> N` |
| project-rails-find-fixture            | Find a fixture file.                                    | `<prefix> u` |
| project-rails-find-current-fixture    | Go to a fixture connected with the current resource.    | `<prefix> U` |
| project-rails-find-javascript         | Find a JavaScript file.                                 | `<prefix> j` |
| project-rails-find-component          | Find a JavaScript component.                            | `<prefix> w` |
| project-rails-find-stylesheet         | Find a stylesheet file.                                 | `<prefix> s` |
| project-rails-find-log                | Find a log file and enable `auto-revert-tail-mode`.     | `<prefix> o` |
| project-rails-find-initializer        | Find an initializer file.                               | `<prefix> i` |
| project-rails-find-environment        | Find an environment file.                               | `<prefix> e` |
| project-rails-find-locale             | Find a locale file.                                     | `<prefix> a` |
| project-rails-find-mailer             | Find a mailer file.                                     | `<prefix> @` |
| project-rails-find-validator          | Find a validator file.                                  | `<prefix> !` |
| project-rails-find-layout             | Find a layout file.                                     | `<prefix> y` |
| project-rails-find-job                | Find a job file.                                        | `<prefix> b` |
| project-rails-find-serializer         | Find a serializer file.                                 | `<prefix> z` |
| project-rails-find-current-serializer | Go to a serializer connected with the current resource. | `<prefix> Z` |

### Goto commands

| Command                        | Description                  | Keybinding     |
|--------------------------------|------------------------------|----------------|
| project-rails-goto-gemfile     | Go to `Gemfile`.             | `<prefix> g g` |
| project-rails-goto-package     | Go to `package.json`.        | `<prefix> g p` |
| project-rails-goto-routes      | Go to `config/routes.rb`.    | `<prefix> g r` |
| project-rails-goto-schema      | Go to `db/schema.rb`.        | `<prefix> g d` |
| project-rails-goto-seeds       | Go to `db/seeds.rb`.         | `<prefix> g s` |
| project-rails-goto-spec-helper | Go to `spec/spec_helper.rb`. | `<prefix> g h` |

### Run commands

| Command                 | Description                                    | Keybinding     |
|-------------------------|------------------------------------------------|----------------|
| project-rails-console   | Run `rails console` in an inf-ruby buffer.     | `<prefix> r c` |
| project-rails-server    | Run `rails server`.                            | `<prefix> r s` |
| project-rails-generate  | Run `rails generate`.                          | `<prefix> r g` |
| project-rails-destroy   | Run `rails destroy`.                           | `<prefix> r d` |
| project-rails-dbconsole | Run `rails dbconsole` in sql-interactive-mode. | `<prefix> r b` |

### Other commands

| Command                      | Description                               | Keybinding     |
|------------------------------|-------------------------------------------|----------------|
| project-rails-extract-region | Extract the selected region to a partial. | `<prefix> x`   |

## Hydra Integration

If you use [hydra](https://github.com/abo-abo/hydra), here are some sample hydras that you can add to your init.el file.

```elisp
(defhydra hydra-project-rails-find (:color blue :columns 8)
  "Find a resource"
  ("m" project-rails-find-model       "model")
  ("v" project-rails-find-view        "view")
  ("c" project-rails-find-controller  "controller")
  ("h" project-rails-find-helper      "helper")
  ("l" project-rails-find-lib         "lib")
  ("j" project-rails-find-javascript  "javascript")
  ("w" project-rails-find-component   "component")
  ("s" project-rails-find-stylesheet  "stylesheet")
  ("p" project-rails-find-spec        "spec")
  ("u" project-rails-find-fixture     "fixture")
  ("t" project-rails-find-test        "test")
  ("f" project-rails-find-feature     "feature")
  ("i" project-rails-find-initializer "initializer")
  ("o" project-rails-find-log         "log")
  ("@" project-rails-find-mailer      "mailer")
  ("!" project-rails-find-validator   "validator")
  ("y" project-rails-find-layout      "layout")
  ("n" project-rails-find-migration   "migration")
  ("b" project-rails-find-job         "job")
  ("z" project-rails-find-serializer  "serializer")

  ("M" project-rails-find-current-model      "current model")
  ("V" project-rails-find-current-view       "current view")
  ("C" project-rails-find-current-controller "current controller")
  ("H" project-rails-find-current-helper     "current helper")
  ("P" project-rails-find-current-spec       "current spec")
  ("U" project-rails-find-current-fixture    "current fixture")
  ("T" project-rails-find-current-test       "current test")
  ("N" project-rails-find-current-migration  "current migration")
  ("Z" project-rails-find-current-serializer "current serializer"))

(defhydra hydra-project-rails-goto (:color blue :columns 8)
  "Go to"
  ("g" project-rails-goto-gemfile       "Gemfile")
  ("p" project-rails-goto-package       "package")
  ("r" project-rails-goto-routes        "routes")
  ("d" project-rails-goto-schema        "schema")
  ("s" project-rails-goto-seeds         "seeds")
  ("h" project-rails-goto-spec-helper   "spec helper"))

(defhydra hydra-project-rails-run (:color blue :columns 8)
  "Run external command & interact"
  ("c" project-rails-console    "console")
  ("b" project-rails-dbconsole  "dbconsole")
  ("s" project-rails-server     "server")
  ("g" project-rails-generate   "generate")
  ("d" project-rails-destroy    "destroy")
  ("x" project-rails-extract-region "extract region"))

(defhydra hydra-project-rails (:color blue :columns 8)
  "Project Rails"
  ("f" hydra-project-rails-find/body "Find a resource")
  ("g" hydra-project-rails-goto/body "Goto")
  ("r" hydra-project-rails-run/body "Run & interact"))

(define-key project-rails-mode-map (kbd "s-r") 'hydra-project-rails/body)
```

## Differences from projectile-rails

This package aims to provide the core functionality of projectile-rails while using `project.el` instead of Projectile. The following features from projectile-rails have been intentionally omitted:

### Removed hydras

Keeping the package simpler and leaner. If you use hydra you can copy/paste the hydras from this README file.

### Rake support

The `projectile-rails-rake` command has not been implemented since it wraps the
[rake](https://github.com/asok/rake) package. If you need rake integration, you
can just install the rake package directly and use it.

### Zeus preloader

Support for the [zeus](https://github.com/burke/zeus) preloader has not been implemented. Zeus has fallen out of favor in the Rails community, with Spring being the preferred preloader. If you need zeus support, consider using projectile-rails instead.

### Discover integration

Integration with [discover.el](https://github.com/mickeynp/discover.el) has not been implemented. Discover.el provides a different UI paradigm that is less commonly used today. Hydra integration is provided as an alternative for users who want a visual command menu.

### goto-file-at-point

The `projectile-rails-goto-file-at-point` command has not been implemented. Modern alternatives like [dumb-jump](https://github.com/jacktasia/dumb-jump), LSP servers (via [eglot](https://github.com/joaotavora/eglot) or [lsp-mode](https://github.com/emacs-lsp/lsp-mode)), or [robe](https://github.com/dgutov/robe) provide better navigation capabilities that work across the entire codebase, not just Rails-specific patterns.

