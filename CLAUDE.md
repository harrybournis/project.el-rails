# Project Context

## About this Project
The purpose of this project is to create project-rails, a clone of the projectile-rails Emacs package that uses the built-in project.el package instead.
The two packages should function in a similar manner and for every Interactive command in projectile-rails there should be equivalent command in project-rails.

## About projectile and project.el
projectile and project.el function almost identically, and their purpose is to allow give project-aware functions inside Emacs.
Examples are projectile-find-file/project-find-file that search for a file inside a project or projectile-dired/project-dired that opens dired on the project's root.

## projectile-rails
projectile-rails enhances projectile with helpers for specifically working with Ruby on Rails projects. An example is projectile-rails-find-spec that finds the RSpec file that corresponds to the current file. Similar helpers for finding a model or a controller exist.

## Relevant files
- `./context/projectile-rails` (the projectile-rails source code that we are trying to emulate with project.el instead. we aim to provide the same functionality that it provides)
- `./context/projectile` (the projectile source code)
- `./context/project.el` (the project.el source code)
- `./context/elisp-simple-packages.pdf` (documentation on how to create an Emacs Lisp package)

## Architecture
- The package should be written in Emacs Lisp according to the elisp-simple-packages.pdf file.
- Keep everything in one file for simplicity (projectile-rails has more than one file but we want to keep it simpler).
- Prefix all functions with `project-rails-` for correct namespacing.
