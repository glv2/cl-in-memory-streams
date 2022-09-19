;;;; This file is part of in-memory-streams
;;;; Copyright 2022 Guillaume LE VAILLANT
;;;; Distributed under the GNU GPL v3 or later.
;;;; See the file LICENSE for terms of use and distribution.

(defpackage :in-memory-streams/tests
  (:use :cl :fiveam :in-memory-streams))

(in-package :in-memory-streams/tests)


(def-suite in-memory-streams-tests
  :description "Unit tests for in-memory-streams")

(in-suite in-memory-streams-tests)

(test input-stream
  (with-input-stream (s #(0 1 2 3 4 5 6 7 8 9) :element-type 'fixnum)
    (let ((seq (make-array 5 :element-type 'fixnum)))
      (is (eql 'fixnum (stream-element-type s)))
      (is-true (listen s))
      (is (= 0 (read-element s)))
      (is-true (listen s))
      (is (= 1 (read-element s)))
      (is (= 2 (read-element s)))
      (is (= 5 (read-sequence seq s)))
      (is (equalp #(3 4 5 6 7) seq))
      (is (= 8 (read-element s)))
      (is (= 9 (read-element s)))
      (is-false (listen s))
      (signals end-of-file (read-element s)))))

(test output-stream
  (let ((seq (with-output-stream (s :element-type 'fixnum)
               (is (eql 'fixnum (stream-element-type s)))
               (is (= 0 (write-element 0 s)))
               (is (= 1 (write-element 1 s)))
               (is (= 2 (write-element 2 s)))
               (write-sequence #(3 4 5 6 7) s)
               (is (= 8 (write-element 8 s)))
               (is (= 9 (write-element 9 s))))))
    (is (equalp #(0 1 2 3 4 5 6 7 8 9) seq))))

(test io-stream
  (with-io-stream (s :element-type 'fixnum)
    (let ((seq (make-array 5 :element-type 'fixnum)))
      (is (eql 'fixnum (stream-element-type s)))
      (is-false (listen s))
      (is (= 0 (write-element 0 s)))
      (is (= 1 (write-element 1 s)))
      (is (= 0 (read-element s)))
      (is-true (listen s))
      (write-sequence #(2 3 4 5 6 7) s)
      (is (= 1 (read-element s)))
      (is (= 2 (read-element s)))
      (is (= 3 (read-element s)))
      (is (= 8 (write-element 8 s)))
      (is (= 9 (write-element 9 s)))
      (is (= 4 (read-element s)))
      (is (= 5 (read-sequence seq s)))
      (is (equalp #(5 6 7 8 9) seq))
      (is-false (listen s))
      (signals end-of-file (read-element s)))))
