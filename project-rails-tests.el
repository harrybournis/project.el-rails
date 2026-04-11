;;; project-rails-tests.el --- Tests for project-rails  -*- lexical-binding: t; -*-

;; Copyright (C) 2024  Free Software Foundation, Inc.

;; Author: Mistral Vibe <vibe@mistral.ai>
;; Version: 0.1
;; Package-Requires: ((emacs "28.1") (ert "1.0"))
;; Keywords: tools, convenience, rails
;; URL: https://github.com/korkolis/projectel-rails

;; This file is not part of GNU Emacs.

;;; Commentary:
;; Tests for project-rails package

;;; Code:

(require 'ert)
(require 'project-rails)

;; Mock the project-rails-root function for testing
(defun project-rails-root ()
  "/mock/project/root/")

(ert-deftest project-rails--test-path-from-file-tests ()
  "Test the test path mapping function."

  ;; Test with relative paths
  (should (equal (project-rails--test-path-from-file "app/models/project.rb")
                 "test/models/project_test.rb"))

  (should (equal (project-rails--test-path-from-file "app/controllers/users_controller.rb")
                 "test/controllers/users_controller_test.rb"))

  (should (equal (project-rails--test-path-from-file "app/helpers/application_helper.rb")
                 "test/helpers/application_helper_test.rb"))

  (should (equal (project-rails--test-path-from-file "app/serializers/project_serializer.rb")
                 "test/serializers/project_serializer_test.rb"))

  ;; Test with nested paths
  (should (equal (project-rails--test-path-from-file "app/models/admin/user.rb")
                 "test/models/admin/user_test.rb"))

  ;; Test with non-Rails files (should return nil)
  (should (null (project-rails--test-path-from-file "lib/utils.rb")))
  (should (null (project-rails--test-path-from-file "config/application.rb")))
  (should (null (project-rails--test-path-from-file "test/models/project_test.rb")))

  ;; Test with nil input
  (should (null (project-rails--test-path-from-file nil)))

  ;; Test with non-.rb files
  (should (null (project-rails--test-path-from-file "app/assets/stylesheets/application.css")))

  ;; Test with absolute paths
  (should (equal (project-rails--test-path-from-file "/mock/project/root/app/models/project.rb")
                 "test/models/project_test.rb"))
  )

(provide 'project-rails-tests)
;;; project-rails-tests.el ends here
