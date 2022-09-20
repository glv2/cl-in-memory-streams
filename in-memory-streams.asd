;;;; This file is part of in-memory-streams
;;;; Copyright 2022 Guillaume LE VAILLANT
;;;; Distributed under the GNU GPL v3 or later.
;;;; See the file LICENSE for terms of use and distribution.

(defsystem "in-memory-streams"
  :name "in-memory-streams"
  :description "In-memory streams for any element type"
  :version "1.0"
  :license "GPL-3"
  :author "Guillaume LE VAILLANT"
  :depends-on ("trivial-gray-streams")
  :in-order-to ((test-op (test-op "in-memory-streams/tests")))
  :components ((:file "in-memory-streams")))

(defsystem "in-memory-streams/tests"
  :name "in-memory-streams/tests"
  :description "Unit tests for in-memory-streams"
  :version "1.0"
  :license "GPL-3"
  :author "Guillaume LE VAILLANT"
  :depends-on ("fiveam" "in-memory-streams")
  :in-order-to ((test-op (load-op "in-memory-streams/tests")))
  :perform (test-op (o s)
             (let ((tests (uiop:find-symbol* 'in-memory-streams
                                             :in-memory-streams/tests)))
               (uiop:symbol-call :fiveam 'run! tests)))
  :components ((:file "tests")))
