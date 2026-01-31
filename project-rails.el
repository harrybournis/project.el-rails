;;; project-rails.el --- Rails support for project.el -*- lexical-binding: t -*-

;; Copyright (C) 2026

;; Author: Harry Bournis <harrybournis@gmail.com>
;; URL: https://github.com/harrybournis/project-rails
;; Version: 1.0.0
;; Keywords: languages, project.el, rails
;; Package-Requires: ((emacs "28.1") (inflections "2.6"))

;; This file is NOT part of GNU Emacs.

;;; License:

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file COPYING.  If not, write to the
;; Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
;; Boston, MA 02110-1301, USA.

;;; Commentary:
;;
;; project-rails is a rewrite of the projectile-rails package that uses the built-in
;; project.el instead of projectile.  It provides commands to navigate
;; Rails projects, find models, controllers, views, and other resources,
;; and run Rails commands like console and server.
;;
;; Credit is due to Adam Sokolnicki <adam.sokolnicki@gmail.com> and the
;; projectile-rails project (https://github.com/asok/projectile-rails/).
;;
;; To enable it for all Rails projects:
;;
;;    (project-rails-global-mode)
;;
;;; Code:

(require 'project)
(require 'comint)
(require 'inflections)
(require 'cl-lib)

;; Declare sql functions to avoid byte-compile warnings
(declare-function sql-get-product-feature "sql" (product feature))
(declare-function sql-set-product-feature "sql" (product feature newvalue))
(declare-function sql-comint "sql" (product params &optional buf-name))
(declare-function json-read-from-string "json" (string))

(defun project-rails--singularize (str)
  "Singularize STR."
  (inflection-singularize-string str))

(defun project-rails--pluralize (str)
  "Pluralize STR."
  (inflection-pluralize-string str))

;;; Customization

(defgroup project-rails nil
  "Rails mode based on project.el."
  :prefix "project-rails-"
  :group 'project)

(defcustom project-rails-root-file "Gemfile"
  "The file that is used to identify rails root."
  :group 'project-rails
  :type 'string)

(defcustom project-rails-verify-root-files '("config/routes.rb" "config/environment.rb")
  "The list of files that is used to verify rails root directory.
When any of the files are found it means that this is a rails app."
  :group 'project-rails
  :type '(repeat string))

(defcustom project-rails-views-re
  (concat "\\."
          (regexp-opt '("html" "erb" "haml" "slim"
                        "js" "coffee" "ts"
                        "css" "scss" "less"
                        "json" "builder" "jbuilder" "rabl")))
  "Regexp for filtering for view files."
  :group 'project-rails
  :type 'regexp)

(defcustom project-rails-javascript-re
  "\\.js\\(?:\\.\\(?:coffee\\|ts\\)\\)?\\'"
  "Regexp for filtering for Javascript/altJS files."
  :group 'project-rails
  :type 'regexp)

(defcustom project-rails-stylesheet-re
  "\\.css\\(?:\\.\\(?:scss\\|sass\\|less\\)\\)?\\'"
  "Regexp for filtering for stylesheet files."
  :group 'project-rails
  :type 'regexp)

(defcustom project-rails-javascript-dirs
  '("app/assets/javascripts/" "lib/assets/javascripts/" "public/javascripts/" "app/javascript/")
  "The list of directories to look for the javascript files in."
  :group 'project-rails
  :type '(repeat string))

(defcustom project-rails-stylesheet-dirs
  '("app/assets/stylesheets/" "lib/assets/stylesheets/" "public/stylesheets/")
  "The list of directories to look for the stylesheet files in."
  :group 'project-rails
  :type '(repeat string))

(defcustom project-rails-component-dir "app/javascript/packs/"
  "The directory to look for javascript component files in."
  :group 'project-rails
  :type 'string)

(defcustom project-rails-vanilla-command "bundle exec rails"
  "The command for rails."
  :group 'project-rails
  :type 'string)

(defcustom project-rails-spring-command "bundle exec spring"
  "The command for spring."
  :group 'project-rails
  :type 'string)

(defcustom project-rails-custom-console-command nil
  "Override the shell command used to run the rails console."
  :group 'project-rails
  :type '(choice (const nil) string))

(defcustom project-rails-custom-server-command nil
  "Override the shell command used to run rails server."
  :group 'project-rails
  :type '(choice (const nil) string))

(defcustom project-rails-custom-generate-command nil
  "Override the shell command used to run rails generate."
  :group 'project-rails
  :type '(choice (const nil) string))

(defcustom project-rails-custom-destroy-command nil
  "Override the shell command used to run rails destroy."
  :group 'project-rails
  :type '(choice (const nil) string))

(defcustom project-rails-custom-dbconsole-command nil
  "Override the shell command used to run rails dbconsole."
  :group 'project-rails
  :type '(choice (const nil) string))

(defcustom project-rails-add-keywords t
  "If not nil the rails keywords will be font locked in the mode's buffers."
  :group 'project-rails
  :type 'boolean)

(defcustom project-rails-controller-keywords
  '("logger" "polymorphic_path" "polymorphic_url" "mail" "render" "attachments"
    "default" "helper" "helper_attr" "helper_method" "layout" "url_for"
    "serialize" "exempt_from_layout" "filter_parameter_logging" "hide_action"
    "cache_sweeper" "protect_from_forgery" "caches_page" "cache_page"
    "caches_action" "expire_page" "expire_action" "rescue_from" "params"
    "request" "response" "session" "flash" "head" "redirect_to" "redirect_back"
    "render_to_string" "respond_with" "before_filter" "append_before_filter"
    "before_action" "append_before_action"
    "prepend_before_filter" "after_filter" "append_after_filter"
    "prepend_after_filter" "around_filter" "append_around_filter"
    "prepend_around_filter" "skip_before_filter" "skip_after_filter" "skip_filter"
    "prepend_before_action" "after_action" "append_after_action"
    "prepend_after_action" "around_action" "append_around_action"
    "prepend_around_action" "skip_before_action" "skip_after_action" "skip_action")
  "List of keywords to highlight for controllers."
  :group 'project-rails
  :type '(repeat string))

(defcustom project-rails-model-keywords
  '("default_scope" "named_scope" "scope" "serialize" "belongs_to" "has_one"
    "has_many" "has_and_belongs_to_many" "composed_of" "accepts_nested_attributes_for"
    "before_create" "before_destroy" "before_save" "before_update" "before_validation"
    "before_validation_on_create" "before_validation_on_update" "after_create"
    "after_destroy" "after_save" "after_update" "after_validation"
    "after_validation_on_create" "after_validation_on_update" "around_create"
    "around_destroy" "around_save" "around_update" "after_commit" "after_find"
    "after_initialize" "after_rollback" "after_touch" "attr_accessible"
    "attr_protected" "attr_readonly" "validates" "validate" "validate_on_create"
    "validate_on_update" "validates_acceptance_of" "validates_associated"
    "validates_confirmation_of" "validates_each" "validates_exclusion_of"
    "validates_format_of" "validates_inclusion_of" "validates_length_of"
    "validates_numericality_of" "validates_presence_of" "validates_size_of"
    "validates_existence_of" "validates_uniqueness_of" "validates_with"
    "enum" "after_create_commit" "after_update_commit" "after_destroy_commit")
  "List of keywords to highlight for models."
  :group 'project-rails
  :type '(repeat string))

(defcustom project-rails-migration-keywords
  '("create_table" "change_table" "drop_table" "rename_table" "add_column"
    "rename_column" "change_column" "change_column_default" "change_column_null"
    "remove_column" "add_index" "remove_index" "rename_index" "execute"
    "add_timestamps" "remove_timestamps" "add_foreign_key" "remove_foreign_key"
    "add_reference" "remove_reference" "add_belongs_to" "remove_belongs_to"
    "transaction" "reversible" "revert" "announce")
  "List of keywords to highlight for migrations."
  :group 'project-rails
  :type '(repeat string))

(defcustom project-rails-active-support-keywords
  '("alias_attribute" "with_options" "delegate")
  "List of keywords to highlight for all `project-rails-mode' buffers."
  :group 'project-rails
  :type '(repeat string))

(defcustom project-rails-keymap-prefix nil
  "Keymap prefix for `projectile-rails-mode'."
  :group 'projectile-rails
  :type 'string)

;;; Variables

(defvar project-rails-fixture-dirs
  '("test/fixtures/" "test/factories/" "test/fabricators/"
    "spec/fixtures/" "spec/factories/" "spec/fabricators/"))

(defvar project-rails-server-buffer-name "*project-rails-server*")

(defvar project-rails-extracted-region-snippet
  '(("erb"  . "<%%= render '%s' %%>")
    ("haml" . "= render '%s'")
    ("slim" . "= render '%s'"))
  "A template used to insert text after extracting a region.")

(defvar project-rails-generators
  '(("assets" (("app/assets/"
                "app/assets/\\(?:stylesheets\\|javascripts\\)/\\(.+?\\)\\..+$")))
    ("controller" (("app/controllers/" "app/controllers/\\(.+\\)_controller\\.rb$")))
    ("generator" (("lib/generator/" "lib/generators/\\(.+\\)$")))
    ("helper" (("app/helpers/" "app/helpers/\\(.+\\)_helper.rb$")))
    ("integration_test" (("test/integration/" "test/integration/\\(.+\\)_test\\.rb$")))
    ("job" (("app/jobs/" "app/jobs/\\(.+\\)_job\\.rb$")))
    ("mailer" (("app/mailers/" "app/mailers/\\(.+\\)\\.rb$")))
    ("migration" (("db/migrate/" "db/migrate/[0-9]+_\\(.+\\)\\.rb$")))
    ("model" (("app/models/" "app/models/\\(.+\\)\\.rb$")))
    ("resource" (("app/models/" "app/models/\\(.+\\)\\.rb$")))
    ("scaffold" (("app/models/" "app/models/\\(.+\\)\\.rb$")))
    ("task" (("lib/tasks/" "lib/tasks/\\(.+\\)\\.rake$")))))

(defvar project-rails--sql-adapters->products
  '(("mysql2"         "mysql")
    ("mysql"          "mysql")
    ("jdbcmysql"      "mysql")

    ("postgres"       "postgres")
    ("postgresql"     "postgres")
    ("jdbcpostgresql" "postgres")

    ("sqlite"         "sqlite")
    ("sqlite3"        "sqlite")
    ("jdbcsqlite3"    "sqlite")

    ("informix"       "informix")
    ("ingres"         "ingres")
    ("interbase"      "interbase")
    ("linter"         "linter")
    ("ms"             "ms")
    ("oracle"         "oracle")
    ("solid"          "solid")
    ("sybase"         "sybase")
    ("vertica"        "vertica"))
  "Mapping between Ruby database libraries and Emacs sql adapters.")

(defvar project-rails-resource-name-re-list
  `("/app/models/\\(?:.+/\\)?\\(.+\\)\\.rb\\'"
    "/app/controllers/\\(?:.+/\\)?\\(.+\\)_controller\\.rb\\'"
    "/app/views/\\(?:.+/\\)?\\([^/]+\\)/[^/]+\\'"
    "/app/helpers/\\(?:.+/\\)?\\(.+\\)_helper\\.rb\\'"
    ,(concat "/app/assets/javascripts/\\(?:.+/\\)?\\(.+\\)" project-rails-javascript-re)
    ,(concat "/app/assets/stylesheets/\\(?:.+/\\)?\\(.+\\)" project-rails-stylesheet-re)
    "/db/migrate/.*create_\\(.+\\)\\.rb\\'"
    "/spec/.*/\\([a-z_]+?\\)\\(?:_controller\\)?_spec\\.rb\\'"
    "/test/.*/\\([a-z_]+?\\)\\(?:_controller\\)?_test\\.rb\\'"
    "/\\(?:test\\|spec\\)/\\(?:fixtures\\|factories\\|fabricators\\)/\\(.+?\\)\\(?:_fabricator\\)?\\.\\(?:yml\\|rb\\)\\'")
  "List of regexps for extracting a resource name from a buffer file name.")

(defvar project-rails-keyword-face 'project-rails-keyword-face)

(defface project-rails-keyword-face '((t :inherit font-lock-keyword-face))
  "Face to be used for highlighting the rails keywords."
  :group 'project-rails)

(defvar-local project-rails--root-cache nil
  "Cached Rails root directory for the current buffer.")

;;; Core functions

(defun project-rails--rails-app-p (root)
  "Determine if the project at ROOT is a Rails project.
Returns t if any of the relative files in
`project-rails-verify-root-files' is found."
  (cl-some (lambda (file)
             (file-exists-p (expand-file-name file root)))
           project-rails-verify-root-files))

(defun project-rails-root ()
  "Return the root directory of the current Rails project, or nil."
  (or project-rails--root-cache
      (let ((root (locate-dominating-file default-directory project-rails-root-file)))
        (when (and root (project-rails--rails-app-p root))
          (setq project-rails--root-cache (file-name-as-directory root))
          project-rails--root-cache))))

(defun project-rails-expand-root (path)
  "Expand PATH relative to Rails root."
  (expand-file-name path (project-rails-root)))

(defun project-rails--file-exists-p (filepath)
  "Return t if relative FILEPATH exists within current project."
  (file-exists-p (project-rails-expand-root filepath)))

(defmacro project-rails-with-root (&rest body)
  "Execute BODY with `default-directory' set to Rails root."
  (declare (indent 0))
  `(let ((default-directory (project-rails-root)))
     ,@body))

;;; File finding utilities

(defun project-rails--list-files-in-dir (dir)
  "List all files in DIR relative to Rails root."
  (let ((full-dir (project-rails-expand-root dir)))
    (when (file-directory-p full-dir)
      (let ((files '()))
        (dolist (file (directory-files-recursively full-dir "." nil))
          (push (file-relative-name file (project-rails-root)) files))
        (nreverse files)))))

(defun project-rails--choices (dirs)
  "Return a hash table of choices from DIRS.
DIRS is a list of (dir regex &optional prefix) lists.
Returns hash with display names as keys and file paths as values."
  (let ((hash (make-hash-table :test 'equal)))
    (dolist (entry dirs)
      (let ((dir (nth 0 entry))
            (re (nth 1 entry))
            (prefix (nth 2 entry)))
        (dolist (file (project-rails--list-files-in-dir dir))
          (when (string-match re file)
            (puthash (concat (or prefix "") (match-string 1 file))
                     file
                     hash)))))
    hash))

(defun project-rails--completing-read (prompt choices &optional newfile-template)
  "Read a choice from CHOICES with PROMPT.
CHOICES is a hash table with display names as keys and paths as values.
NEWFILE-TEMPLATE is used to create new files if the choice doesn't exist."
  (let* ((keys (hash-table-keys choices))
         (choice (completing-read prompt keys nil nil nil nil))
         (filepath (gethash choice choices)))
    (if filepath
        (find-file (project-rails-expand-root filepath))
      (when newfile-template
        (let ((filename choice))
          (find-file (project-rails-expand-root
                      (format newfile-template filename))))))))

;;; Find resource commands

;;;###autoload
(defun project-rails-find-model ()
  "Find a model."
  (interactive)
  (project-rails--completing-read
   "Model: "
   (project-rails--choices '(("app/models/" "\\(.+\\)\\.rb$")))
   "app/models/%s.rb"))

;;;###autoload
(defun project-rails-find-controller ()
  "Find a controller."
  (interactive)
  (project-rails--completing-read
   "Controller: "
   (project-rails--choices '(("app/controllers/" "\\(.+?\\)\\(_controller\\)?\\.rb$")))
   "app/controllers/%s_controller.rb"))

;;;###autoload
(defun project-rails-find-view ()
  "Find a view template or partial."
  (interactive)
  (project-rails--completing-read
   "View: "
   (project-rails--choices
    `(("app/views/" ,(concat "\\(.+\\)" project-rails-views-re))))
   "app/views/%s"))

;;;###autoload
(defun project-rails-find-layout ()
  "Find a layout file."
  (interactive)
  (project-rails--completing-read
   "Layout: "
   (project-rails--choices
    `(("app/views/layouts/" ,(concat "\\(.+\\)" project-rails-views-re))))
   "app/views/layouts/%s"))

;;;###autoload
(defun project-rails-find-helper ()
  "Find a helper."
  (interactive)
  (project-rails--completing-read
   "Helper: "
   (project-rails--choices '(("app/helpers/" "\\(.+\\)_helper\\.rb$")))
   "app/helpers/%s_helper.rb"))

;;;###autoload
(defun project-rails-find-lib ()
  "Find a file within lib directory."
  (interactive)
  (project-rails--completing-read
   "Lib: "
   (project-rails--choices '(("lib/" "\\(.+\\)\\.rb$")))
   "lib/%s.rb"))

;;;###autoload
(defun project-rails-find-spec ()
  "Find a spec file."
  (interactive)
  (project-rails--completing-read
   "Spec: "
   (project-rails--choices '(("spec/" "\\(.+\\)_spec\\.rb$")))
   "spec/%s_spec.rb"))

;;;###autoload
(defun project-rails-find-test ()
  "Find a test file."
  (interactive)
  (project-rails--completing-read
   "Test: "
   (project-rails--choices '(("test/" "\\(.+\\)_test\\.rb$")))
   "test/%s_test.rb"))

;;;###autoload
(defun project-rails-find-fixture ()
  "Find a fixture file."
  (interactive)
  (project-rails--completing-read
   "Fixture: "
   (project-rails--choices
    (mapcar (lambda (dir)
              (list dir "\\(.+?\\)\\(?:_fabricator\\)?\\.\\(?:rb\\|yml\\)$"))
            project-rails-fixture-dirs))))

;;;###autoload
(defun project-rails-find-feature ()
  "Find a feature file."
  (interactive)
  (project-rails--completing-read
   "Feature: "
   (project-rails--choices '(("features/" "\\(.+\\)\\.feature$")))
   "features/%s.feature"))

;;;###autoload
(defun project-rails-find-migration ()
  "Find a migration."
  (interactive)
  (project-rails--completing-read
   "Migration: "
   (project-rails--choices '(("db/migrate/" "\\(.+\\)\\.rb$")))))

;;;###autoload
(defun project-rails-find-javascript ()
  "Find a javascript file."
  (interactive)
  (project-rails--completing-read
   "Javascript: "
   (project-rails--choices
    (mapcar (lambda (dir) (list dir "\\(.+\\)\\.[^.]+$"))
            project-rails-javascript-dirs))))

;;;###autoload
(defun project-rails-find-component ()
  "Find a javascript component."
  (interactive)
  (project-rails--completing-read
   "Component: "
   (project-rails--choices
    `((,project-rails-component-dir "\\(.+\\.[^.]+\\)$")))))

;;;###autoload
(defun project-rails-find-stylesheet ()
  "Find a stylesheet file."
  (interactive)
  (project-rails--completing-read
   "Stylesheet: "
   (project-rails--choices
    (mapcar (lambda (dir) (list dir "\\(.+\\)\\.[^.]+$"))
            project-rails-stylesheet-dirs))))

;;;###autoload
(defun project-rails-find-initializer ()
  "Find an initializer file."
  (interactive)
  (project-rails--completing-read
   "Initializer: "
   (project-rails--choices '(("config/initializers/" "\\(.+\\)\\.rb$")))
   "config/initializers/%s.rb"))

;;;###autoload
(defun project-rails-find-environment ()
  "Find an environment file."
  (interactive)
  (project-rails--completing-read
   "Environment: "
   (project-rails--choices
    '(("config/" "\\(application\\|environment\\)\\.rb$")
      ("config/environments/" "\\(.+\\)\\.rb$" "environments/")))))

;;;###autoload
(defun project-rails-find-locale ()
  "Find a locale file."
  (interactive)
  (project-rails--completing-read
   "Locale: "
   (project-rails--choices '(("config/locales/" "\\(.+\\)\\.\\(?:rb\\|yml\\)$")))
   "config/locales/%s"))

;;;###autoload
(defun project-rails-find-mailer ()
  "Find a mailer."
  (interactive)
  (project-rails--completing-read
   "Mailer: "
   (project-rails--choices '(("app/mailers/" "\\(.+\\)\\.rb$")))
   "app/mailers/%s.rb"))

;;;###autoload
(defun project-rails-find-validator ()
  "Find a validator."
  (interactive)
  (project-rails--completing-read
   "Validator: "
   (project-rails--choices '(("app/validators/" "\\(.+?\\)\\(_validator\\)?\\.rb\\'")))
   "app/validators/%s_validator.rb"))

;;;###autoload
(defun project-rails-find-job ()
  "Find a job file."
  (interactive)
  (project-rails--completing-read
   "Job: "
   (project-rails--choices '(("app/jobs/" "\\(.+?\\)\\(_job\\)?\\.rb\\'")))
   "app/jobs/%s_job.rb"))

;;;###autoload
(defun project-rails-find-serializer ()
  "Find a serializer."
  (interactive)
  (project-rails--completing-read
   "Serializer: "
   (project-rails--choices '(("app/serializers/" "\\(.+\\)_serializer\\.rb$")))
   "app/serializers/%s_serializer.rb"))

;;;###autoload
(defun project-rails-find-log ()
  "Find a log file and open with `auto-revert-tail-mode'."
  (interactive)
  (let ((logs-dir (cl-loop for dir in '("log/" "spec/dummy/log/" "test/dummy/log/")
                           when (project-rails--file-exists-p dir)
                           return dir)))
    (unless logs-dir
      (user-error "No log directory found"))
    (let* ((full-dir (project-rails-expand-root logs-dir))
           (files (directory-files full-dir nil "\\.log$"))
           (choice (completing-read "Log: " files nil t)))
      (find-file (expand-file-name choice full-dir))
      (auto-revert-tail-mode +1)
      (setq-local auto-revert-verbose nil)
      (buffer-disable-undo))))

;;; Current resource detection

(defun project-rails-current-resource-name ()
  "Return a resource name extracted from the current file name."
  (let* ((file-name (buffer-file-name))
         (name (and file-name
                    (cl-loop for re in project-rails-resource-name-re-list
                             when (string-match re file-name)
                             return (match-string 1 file-name)))))
    (when name
      (project-rails--singularize name))))

(defmacro project-rails-find-current-resource (dir re fallback)
  "Find current resource in DIR matching RE, or call FALLBACK."
  (declare (indent 2))
  `(let* ((singular (project-rails-current-resource-name))
          (plural (and singular (project-rails--pluralize singular))))
     (if (not singular)
         (funcall ,fallback)
       (let* ((re-expanded (format ,re singular plural))
              (choices (project-rails--choices (list (list ,dir re-expanded))))
              (keys (hash-table-keys choices)))
         (if (null keys)
             (funcall ,fallback)
           (if (= (length keys) 1)
               (find-file (project-rails-expand-root (gethash (car keys) choices)))
             (project-rails--completing-read "Which: " choices)))))))

;;;###autoload
(defun project-rails-find-current-model ()
  "Find a model for the current resource."
  (interactive)
  (project-rails-find-current-resource "app/models/"
      "\\(?:%2$s/\\)*%1$s\\.rb$"
    #'project-rails-find-model))

;;;###autoload
(defun project-rails-find-current-controller ()
  "Find a controller for the current resource."
  (interactive)
  (project-rails-find-current-resource "app/controllers/"
      "\\(.*%2$s\\)_controller\\.rb$"
    #'project-rails-find-controller))

;;;###autoload
(defun project-rails-find-current-view ()
  "Find a view for the current resource."
  (interactive)
  (project-rails-find-current-resource "app/views/"
      "%2$s/\\(.+\\)$"
    #'project-rails-find-view))

;;;###autoload
(defun project-rails-find-current-helper ()
  "Find a helper for the current resource."
  (interactive)
  (project-rails-find-current-resource "app/helpers/"
      "\\(%2$s_helper\\)\\.rb$"
    #'project-rails-find-helper))

;;;###autoload
(defun project-rails-find-current-spec ()
  "Find a spec for the current resource."
  (interactive)
  (project-rails-find-current-resource "spec/"
      "\\(.*\\(?:%2$s/\\)*%1$s\\)_spec\\.rb$"
    #'project-rails-find-spec))

;;;###autoload
(defun project-rails-find-current-test ()
  "Find a test for the current resource."
  (interactive)
  (project-rails-find-current-resource "test/"
      "\\(.*\\(?:%2$s/\\)*%1$s\\)_test\\.rb$"
    #'project-rails-find-test))

;;;###autoload
(defun project-rails-find-current-fixture ()
  "Find a fixture for the current resource."
  (interactive)
  (let* ((singular (project-rails-current-resource-name))
         (plural (and singular (project-rails--pluralize singular))))
    (if (not singular)
        (project-rails-find-fixture)
      (let* ((re (format "\\(?:%s\\(?:_fabricator\\)?\\|%s\\)\\.\\(?:yml\\|rb\\)" singular plural))
             (choices (project-rails--choices
                       (mapcar (lambda (dir) (list dir re))
                               project-rails-fixture-dirs)))
             (keys (hash-table-keys choices)))
        (if (null keys)
            (project-rails-find-fixture)
          (if (= (length keys) 1)
              (find-file (project-rails-expand-root (gethash (car keys) choices)))
            (project-rails--completing-read "Which: " choices)))))))

;;;###autoload
(defun project-rails-find-current-migration ()
  "Find a migration for the current resource."
  (interactive)
  (let* ((singular (project-rails-current-resource-name))
         (plural (and singular (project-rails--pluralize singular))))
    (if (not singular)
        (project-rails-find-migration)
      (let* ((re (format "[0-9]\\{14\\}.*_\\(%s\\|%s\\).*\\.rb$" plural singular))
             (choices (project-rails--choices (list (list "db/migrate/" re))))
             (keys (hash-table-keys choices)))
        (if (null keys)
            (project-rails-find-migration)
          (if (= (length keys) 1)
              (find-file (project-rails-expand-root (gethash (car keys) choices)))
            (project-rails--completing-read "Which: " choices)))))))

;;;###autoload
(defun project-rails-find-current-serializer ()
  "Find a serializer for the current resource."
  (interactive)
  (project-rails-find-current-resource "app/serializers/"
      "\\(.*\\(?:%2$s/\\)*%1$s\\)_serializer\\.rb$"
    #'project-rails-find-serializer))

;;; Goto commands

;;;###autoload
(defun project-rails-goto-gemfile ()
  "Visit Gemfile."
  (interactive)
  (find-file (project-rails-expand-root "Gemfile")))

;;;###autoload
(defun project-rails-goto-package ()
  "Visit package.json file."
  (interactive)
  (find-file (project-rails-expand-root "package.json")))

;;;###autoload
(defun project-rails-goto-routes ()
  "Visit config/routes.rb file."
  (interactive)
  (find-file (project-rails-expand-root "config/routes.rb")))

;;;###autoload
(defun project-rails-goto-schema ()
  "Visit db/schema.rb file."
  (interactive)
  (find-file (project-rails-expand-root "db/schema.rb")))

;;;###autoload
(defun project-rails-goto-seeds ()
  "Visit db/seeds.rb file."
  (interactive)
  (find-file (project-rails-expand-root "db/seeds.rb")))

;;;###autoload
(defun project-rails-goto-spec-helper ()
  "Visit spec/spec_helper.rb file."
  (interactive)
  (find-file (project-rails-expand-root "spec/spec_helper.rb")))

;;; Rails commands

(defun project-rails--spring-p ()
  "Return t if spring is running."
  (let ((root (directory-file-name (project-rails-root))))
    (or
     ;; Older versions
     (file-exists-p (format "%s/tmp/spring/spring.pid" root))
     ;; 0.9.2+
     (file-exists-p (format "%s/spring/%s.pid" temporary-file-directory (md5 root)))
     ;; 1.2.0+
     (let* ((path (or (getenv "XDG_RUNTIME_DIR") temporary-file-directory))
            (ruby-version (string-trim (shell-command-to-string "ruby -e 'print RUBY_VERSION'")))
            (application-id (md5 (concat ruby-version root))))
       (or
        (file-exists-p (format "%s/spring/%s.pid" path application-id))
        ;; 1.5.0+
        (file-exists-p (format "%s/spring-%s/%s.pid" path (user-real-uid) application-id)))))))

(defun project-rails--command (custom spring vanilla)
  "Return the appropriate rails command.
Use CUSTOM if set, SPRING if spring is running, otherwise VANILLA."
  (cond
   (custom (concat custom " "))
   ((project-rails--spring-p) spring)
   (t vanilla)))

;;;###autoload
(defun project-rails-console (arg)
  "Start a rails console.
With prefix ARG, prompt for the command."
  (interactive "P")
  (require 'inf-ruby)
  (project-rails-with-root
    (let ((cmd (project-rails--command
                project-rails-custom-console-command
                (concat project-rails-spring-command " rails console")
                (concat project-rails-vanilla-command " console"))))
      (when arg
        (setq cmd (read-string "Rails console: " cmd)))
      (if (fboundp 'inf-ruby-console-run)
          (inf-ruby-console-run cmd "rails")
        (let ((buffer (make-comint "rails-console" "sh" nil "-c" cmd)))
          (switch-to-buffer buffer)
          (project-rails-mode +1))))))

;;;###autoload
(defun project-rails-server ()
  "Run rails server command."
  (interactive)
  (unless (project-rails--file-exists-p "config/environment.rb")
    (user-error "Not in a Rails application"))
  (if (get-buffer project-rails-server-buffer-name)
      (switch-to-buffer project-rails-server-buffer-name)
    (project-rails-with-root
      (let ((cmd (project-rails--command
                  project-rails-custom-server-command
                  (concat project-rails-spring-command " rails server")
                  (concat project-rails-vanilla-command " server"))))
        (compile cmd 'project-rails-server-mode)))))

(defun project-rails--completion-in-region ()
  "Apply Rails generators for text completion in region."
  (interactive)
  (let ((generators (mapcar (lambda (g) (concat (car g) " ")) project-rails-generators)))
    (when (<= (minibuffer-prompt-end) (point))
      (completion-in-region (minibuffer-prompt-end) (point-max) generators))))

;;;###autoload
(defun project-rails-generate ()
  "Run rails generate command."
  (interactive)
  (project-rails-with-root
    (let* ((cmd-prefix (project-rails--command
                        project-rails-custom-generate-command
                        (concat project-rails-spring-command " rails generate ")
                        (concat project-rails-vanilla-command " generate ")))
           (keymap (copy-keymap minibuffer-local-map)))
      (define-key keymap (kbd "<tab>") 'project-rails--completion-in-region)
      (let ((cmd (concat cmd-prefix (read-from-minibuffer cmd-prefix nil keymap))))
        (compile cmd 'project-rails-compilation-mode)))))

;;;###autoload
(defun project-rails-destroy ()
  "Run rails destroy command."
  (interactive)
  (project-rails-with-root
    (let* ((cmd-prefix (project-rails--command
                        project-rails-custom-destroy-command
                        (concat project-rails-spring-command " rails destroy ")
                        (concat project-rails-vanilla-command " destroy ")))
           (keymap (copy-keymap minibuffer-local-map)))
      (define-key keymap (kbd "<tab>") 'project-rails--completion-in-region)
      (let ((cmd (concat cmd-prefix (read-from-minibuffer cmd-prefix nil keymap))))
        (compile cmd 'project-rails-compilation-mode)))))

(defun project-rails--db-config ()
  "Return contents of config/database.yml as a list."
  (json-read-from-string
   (shell-command-to-string
    (format
     "ruby -ryaml -rjson -e 'JSON.dump(YAML.load(ARGF.read, aliases: true), STDOUT)' \"%s\""
     (project-rails-expand-root "config/database.yml")))))

(defun project-rails--determine-sql-product (env)
  "Return Emacs sql adapter that should be used for the given project.
ENV is the name of the rails environment."
  (intern
   (car
    (cdr
     (assoc-string (cdr (assoc-string "adapter" (cdr (assoc-string env (project-rails--db-config)))))
                   project-rails--sql-adapters->products)))))

(defun project-rails--choose-env ()
  "Return rails environment to use.
The candidates are based on the files found in config/environments/."
  (let ((env-dir (project-rails-expand-root "config/environments/")))
    (completing-read
     "Choose env: "
     (mapcar (lambda (f) (file-name-sans-extension f))
             (directory-files env-dir nil "\\.rb$")))))

;;;###autoload
(defun project-rails-dbconsole ()
  "Run rails dbconsole command.
The buffer for interacting with SQL client is created via
`sql-product-interactive'."
  (interactive)
  (require 'sql)
  (project-rails-with-root
    (let* ((env (project-rails--choose-env))
           (product (project-rails--determine-sql-product env))
           (sqli-login      (sql-get-product-feature product :sqli-login))
           (sqli-options    (sql-get-product-feature product :sqli-options))
           (sqli-program    (sql-get-product-feature product :sqli-program))
           (sql-comint-func (sql-get-product-feature product :sqli-comint-func))
           (commands (split-string (project-rails--command
                                    project-rails-custom-dbconsole-command
                                    (concat project-rails-spring-command " rails dbconsole")
                                    (concat project-rails-vanilla-command " dbconsole")))))
      (sql-set-product-feature product :sqli-login '())
      (sql-set-product-feature product :sqli-options '())
      (sql-set-product-feature product :sqli-program (car commands))
      (sql-set-product-feature product :sqli-comint-func (lambda (_ __ &optional buf-name)
                                                           (sql-comint product (cdr commands) buf-name)))

      (sql-product-interactive product)

      (sql-set-product-feature product :sqli-comint-func sql-comint-func)
      (sql-set-product-feature product :sqli-program sqli-program)
      (sql-set-product-feature product :sqli-options sqli-options)
      (sql-set-product-feature product :sqli-login sqli-login))))

(defun project-rails--view-p (path)
  "Return t if PATH is a Rails view file."
  (and path
       (string-prefix-p "app/views/"
                        (file-relative-name path (project-rails-root)))))

;;;###autoload
(defun project-rails-extract-region (partial-name)
  "Extract region to a partial called PARTIAL-NAME.
If called interactively will ask user for the PARTIAL-NAME."
  (interactive (list (file-truename (read-file-name "The name of the partial: " default-directory))))
  (let* ((ext (file-name-extension partial-name))
         (snippet (cdr (assoc ext project-rails-extracted-region-snippet)))
         (views-dir (project-rails-expand-root "app/views/"))
         (relative-path (file-relative-name partial-name views-dir))
         (path-without-ext (file-name-sans-extension relative-path))
         (path (replace-regexp-in-string "/_" "/" path-without-ext)))
    (kill-region (region-beginning) (region-end))
    (deactivate-mark)
    (when (project-rails--view-p (buffer-file-name))
      (insert (format snippet path))
      (indent-according-to-mode)
      (when (not (looking-at-p "\n"))
        (insert "\n")))
    (find-file partial-name)
    (yank)
    (indent-region (point-min) (point-max))))

;;; Keyword highlighting

(defun project-rails--highlight-keywords (keywords)
  "Highlight KEYWORDS in current buffer."
  (font-lock-add-keywords
   nil
   (list (list
          (concat "\\(^\\|[^_:.@$]\\|\\.\\.\\)\\b"
                  (regexp-opt keywords t)
                  "\\_>")
          (list 2 'project-rails-keyword-face)))))

(defun project-rails--add-keywords-for-file-type ()
  "Apply extra font lock keywords specific to models, controllers etc."
  (cl-loop for (re keywords) in `(("_controller\\.rb$" ,project-rails-controller-keywords)
                                  ("app/models/.+\\.rb$" ,project-rails-model-keywords)
                                  ("db/migrate/.+\\.rb$" ,project-rails-migration-keywords))
           do (when (and (buffer-file-name) (string-match-p re (buffer-file-name)))
                (project-rails--highlight-keywords
                 (append keywords project-rails-active-support-keywords)))))

;;; Keymaps

(defvar project-rails-mode-goto-map
  (let ((map (make-sparse-keymap)))
    (define-key map (kbd "g") 'project-rails-goto-gemfile)
    (define-key map (kbd "r") 'project-rails-goto-routes)
    (define-key map (kbd "d") 'project-rails-goto-schema)
    (define-key map (kbd "s") 'project-rails-goto-seeds)
    (define-key map (kbd "h") 'project-rails-goto-spec-helper)
    (define-key map (kbd "p") 'project-rails-goto-package)
    map)
  "Goto keymap for `project-rails-mode'.")
(fset 'project-rails-mode-goto-map project-rails-mode-goto-map)

(defvar project-rails-mode-run-map
  (let ((map (make-sparse-keymap)))
    (define-key map (kbd "c") 'project-rails-console)
    (define-key map (kbd "s") 'project-rails-server)
    (define-key map (kbd "g") 'project-rails-generate)
    (define-key map (kbd "d") 'project-rails-destroy)
    (define-key map (kbd "b") 'project-rails-dbconsole)
    map)
  "Run keymap for `project-rails-mode'.")
(fset 'project-rails-mode-run-map project-rails-mode-run-map)

(defvar project-rails-command-map
  (let ((map (make-sparse-keymap)))
    ;; Find commands
    (define-key map (kbd "m") 'project-rails-find-model)
    (define-key map (kbd "M") 'project-rails-find-current-model)
    (define-key map (kbd "c") 'project-rails-find-controller)
    (define-key map (kbd "C") 'project-rails-find-current-controller)
    (define-key map (kbd "v") 'project-rails-find-view)
    (define-key map (kbd "V") 'project-rails-find-current-view)
    (define-key map (kbd "j") 'project-rails-find-javascript)
    (define-key map (kbd "s") 'project-rails-find-stylesheet)
    (define-key map (kbd "h") 'project-rails-find-helper)
    (define-key map (kbd "H") 'project-rails-find-current-helper)
    (define-key map (kbd "p") 'project-rails-find-spec)
    (define-key map (kbd "P") 'project-rails-find-current-spec)
    (define-key map (kbd "t") 'project-rails-find-test)
    (define-key map (kbd "T") 'project-rails-find-current-test)
    (define-key map (kbd "n") 'project-rails-find-migration)
    (define-key map (kbd "N") 'project-rails-find-current-migration)
    (define-key map (kbd "u") 'project-rails-find-fixture)
    (define-key map (kbd "U") 'project-rails-find-current-fixture)
    (define-key map (kbd "w") 'project-rails-find-component)
    (define-key map (kbd "l") 'project-rails-find-lib)
    (define-key map (kbd "f") 'project-rails-find-feature)
    (define-key map (kbd "i") 'project-rails-find-initializer)
    (define-key map (kbd "o") 'project-rails-find-log)
    (define-key map (kbd "e") 'project-rails-find-environment)
    (define-key map (kbd "a") 'project-rails-find-locale)
    (define-key map (kbd "@") 'project-rails-find-mailer)
    (define-key map (kbd "!") 'project-rails-find-validator)
    (define-key map (kbd "y") 'project-rails-find-layout)
    (define-key map (kbd "b") 'project-rails-find-job)
    (define-key map (kbd "z") 'project-rails-find-serializer)
    (define-key map (kbd "Z") 'project-rails-find-current-serializer)
    ;; Extract region
    (define-key map (kbd "x") 'project-rails-extract-region)
    ;; Submaps
    (define-key map (kbd "g") 'project-rails-mode-goto-map)
    (define-key map (kbd "r") 'project-rails-mode-run-map)
    map)
  "Command keymap for `project-rails-mode'.")
(fset 'project-rails-command-map project-rails-command-map)

(defvar project-rails-mode-map
  (let ((map (make-sparse-keymap)))
    (when project-rails-keymap-prefix
      (define-key map project-rails-keymap-prefix 'project-rails-command-map))
    map)
  "Keymap for `project-rails-mode'.")

;;; Menu

(easy-menu-define project-rails-menu project-rails-mode-map
  "Menu for `project-rails-mode'."
  '("Rails"
    ["Find model"        project-rails-find-model]
    ["Find controller"   project-rails-find-controller]
    ["Find view"         project-rails-find-view]
    ["Find javascript"   project-rails-find-javascript]
    ["Find component"    project-rails-find-component]
    ["Find stylesheet"   project-rails-find-stylesheet]
    ["Find helper"       project-rails-find-helper]
    ["Find spec"         project-rails-find-spec]
    ["Find test"         project-rails-find-test]
    ["Find feature"      project-rails-find-feature]
    ["Find migration"    project-rails-find-migration]
    ["Find fixture"      project-rails-find-fixture]
    ["Find lib"          project-rails-find-lib]
    ["Find initializer"  project-rails-find-initializer]
    ["Find environment"  project-rails-find-environment]
    ["Find log"          project-rails-find-log]
    ["Find locale"       project-rails-find-locale]
    ["Find mailer"       project-rails-find-mailer]
    ["Find validator"    project-rails-find-validator]
    ["Find layout"       project-rails-find-layout]
    ["Find job"          project-rails-find-job]
    ["Find serializer"   project-rails-find-serializer]
    "--"
    ["Go to Gemfile"     project-rails-goto-gemfile]
    ["Go to package"     project-rails-goto-package]
    ["Go to routes"      project-rails-goto-routes]
    ["Go to schema"      project-rails-goto-schema]
    ["Go to seeds"       project-rails-goto-seeds]
    ["Go to spec helper" project-rails-goto-spec-helper]
    "--"
    ["Current model"      project-rails-find-current-model]
    ["Current controller" project-rails-find-current-controller]
    ["Current view"       project-rails-find-current-view]
    ["Current spec"       project-rails-find-current-spec]
    ["Current test"       project-rails-find-current-test]
    ["Current migration"  project-rails-find-current-migration]
    ["Current fixture"    project-rails-find-current-fixture]
    ["Current serializer" project-rails-find-current-serializer]
    "--"
    ["Extract to partial" project-rails-extract-region]
    "--"
    ["Run console"        project-rails-console]
    ["Run dbconsole"      project-rails-dbconsole]
    ["Run server"         project-rails-server]
    ["Run generate"       project-rails-generate]
    ["Run destroy"        project-rails-destroy]))

;;; Minor mode

;;;###autoload
(define-minor-mode project-rails-mode
  "Minor mode for Rails projects using project.el.

\\{project-rails-mode-map}"
  :init-value nil
  :lighter " Rails"
  :keymap project-rails-mode-map
  (when project-rails-mode
    (when project-rails-add-keywords
      (project-rails--add-keywords-for-file-type))))

(defun project-rails--ignore-buffer-p ()
  "Return t if `project-rails' should not be enabled for the current buffer."
  (string-match-p "\\*\\(Minibuf-[0-9]+\\|helm\\|Completions\\)\\*" (buffer-name)))

;;;###autoload
(defun project-rails-on ()
  "Enable `project-rails-mode' minor mode if this is a Rails project."
  (when (and (not (project-rails--ignore-buffer-p))
             (project-rails-root))
    (project-rails-mode +1)))

;;;###autoload
(define-globalized-minor-mode project-rails-global-mode
  project-rails-mode
  project-rails-on)

(defun project-rails-off ()
  "Disable `project-rails-mode' minor mode."
  (project-rails-mode -1))

;;; Compilation modes

(define-derived-mode project-rails-server-mode compilation-mode "Rails Server"
  "Compilation mode for running rails server."
  (setq-local compilation-scroll-output t)
  (project-rails-mode +1)
  (read-only-mode -1))

(define-derived-mode project-rails-compilation-mode compilation-mode "Rails Compilation"
  "Compilation mode used by project-rails."
  (project-rails-mode +1))

(provide 'project-rails)

;;; project-rails.el ends here
