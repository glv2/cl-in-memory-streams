;;;; This file is part of in-memory-streams
;;;; Copyright 2022 Guillaume LE VAILLANT
;;;; Distributed under the GNU GPL v3 or later.
;;;; See the file LICENSE for terms of use and distribution.

(defpackage :in-memory-streams/tests
  (:use :cl :fiveam :in-memory-streams)
  (:import-from :in-memory-streams
                add-element
                add-elements
                buffer
                buffer-count
                buffer-element-type
                buffer-end
                buffer-size
                buffer-start
                clear
                resize
                ring-buffer
                take-element
                take-elements))

(in-package :in-memory-streams/tests)


(def-suite in-memory-streams
  :description "Unit tests for in-memory streams")


(def-suite ring-buffers
  :description "Unit tests for ring buffers"
  :in in-memory-streams)

(in-suite ring-buffers)

(test make-instance
  (let* ((b (make-array 10 :element-type 'fixnum))
         (rb (make-instance 'ring-buffer
                            :buffer b
                            :size 10
                            :element-type 'fixnum
                            :start 2
                            :end 5
                            :count 3)))
    (is (typep rb 'ring-buffer))
    (is (= 10 (buffer-size rb)))
    (is (eql 'fixnum (buffer-element-type rb)))
    (is (= 2 (buffer-start rb)))
    (is (= 5 (buffer-end rb)))
    (is (= 3 (buffer-count rb)))))

(test clear
  (let* ((b (make-array 10 :element-type 'fixnum))
         (rb (make-instance 'ring-buffer
                            :buffer b
                            :size 10
                            :element-type 'fixnum
                            :start 2
                            :end 5
                            :count 3)))
    (clear rb)
    (is (= 10 (buffer-size rb)))
    (is (eql 'fixnum (buffer-element-type rb)))
    (is (= 0 (buffer-start rb)))
    (is (= 0 (buffer-end rb)))
    (is (= 0 (buffer-count rb)))))

(test resize
  (let* ((b (make-array 10
                        :element-type 'fixnum
                        :initial-contents '(0 0 5 6 7 0 0 0 0 0)))
         (rb (make-instance 'ring-buffer
                            :buffer b
                            :size 10
                            :element-type 'fixnum
                            :start 2
                            :end 5
                            :count 3)))
    (resize rb 20)
    (is (= 20 (buffer-size rb)))
    (is (eql 'fixnum (buffer-element-type rb)))
    (is (= 0 (buffer-start rb)))
    (is (= 3 (buffer-end rb)))
    (is (= 3 (buffer-count rb)))
    (is (equalp #(5 6 7) (subseq (buffer rb) 0 3))))
  (let* ((b (make-array 10
                        :element-type 'fixnum
                        :initial-contents '(7 8 0 0 0 0 0 0 5 6)))
         (rb (make-instance 'ring-buffer
                            :buffer b
                            :size 10
                            :element-type 'fixnum
                            :start 8
                            :end 2
                            :count 4)))
    (resize rb 20)
    (is (= 20 (buffer-size rb)))
    (is (eql 'fixnum (buffer-element-type rb)))
    (is (= 0 (buffer-start rb)))
    (is (= 4 (buffer-end rb)))
    (is (= 4 (buffer-count rb)))
    (is (equalp #(5 6 7 8) (subseq (buffer rb) 0 4)))))

(test add-element
  (let* ((b (make-array 10
                        :element-type 'fixnum
                        :initial-contents '(0 0 5 6 7 0 0 0 0 0)))
         (rb (make-instance 'ring-buffer
                            :buffer b
                            :size 10
                            :element-type 'fixnum
                            :start 2
                            :end 5
                            :count 3)))
    (add-element rb 8)
    (add-element rb 9)
    (add-element rb 10)
    (is (= 10 (buffer-size rb)))
    (is (eql 'fixnum (buffer-element-type rb)))
    (is (= 2 (buffer-start rb)))
    (is (= 8 (buffer-end rb)))
    (is (= 6 (buffer-count rb)))
    (is (equalp #(0 0 5 6 7 8 9 10 0 0) (buffer rb)))
    (loop :for i :from 11 :to 19
          :do (add-element rb i))
    (is (= 20 (buffer-size rb)))
    (is (eql 'fixnum (buffer-element-type rb)))
    (is (= 0 (buffer-start rb)))
    (is (= 15 (buffer-end rb)))
    (is (= 15 (buffer-count rb)))
    (is (equalp #(5 6 7 8 9 10 11 12 13 14 15 16 17 18 19)
                (subseq (buffer rb) 0 15))))
  (let* ((b (make-array 10
                        :element-type 'fixnum
                        :initial-contents '(7 8 0 0 0 0 0 0 5 6)))
         (rb (make-instance 'ring-buffer
                            :buffer b
                            :size 10
                            :element-type 'fixnum
                            :start 8
                            :end 2
                            :count 4)))
    (add-element rb 9)
    (add-element rb 10)
    (add-element rb 11)
    (is (= 10 (buffer-size rb)))
    (is (eql 'fixnum (buffer-element-type rb)))
    (is (= 8 (buffer-start rb)))
    (is (= 5 (buffer-end rb)))
    (is (= 7 (buffer-count rb)))
    (is (equalp #(7 8 9 10 11 0 0 0 5 6) (buffer rb)))
    (loop :for i :from 12 :to 19
          :do (add-element rb i))
    (is (= 20 (buffer-size rb)))
    (is (eql 'fixnum (buffer-element-type rb)))
    (is (= 0 (buffer-start rb)))
    (is (= 15 (buffer-end rb)))
    (is (= 15 (buffer-count rb)))
    (is (equalp #(5 6 7 8 9 10 11 12 13 14 15 16 17 18 19)
                (subseq (buffer rb) 0 15)))))

(test add-elements
  (let* ((b (make-array 10
                        :element-type 'fixnum
                        :initial-contents '(0 0 5 6 7 0 0 0 0 0)))
         (rb (make-instance 'ring-buffer
                            :buffer b
                            :size 10
                            :element-type 'fixnum
                            :start 2
                            :end 5
                            :count 3)))
    (add-elements rb #(8 9 10))
    (is (= 10 (buffer-size rb)))
    (is (eql 'fixnum (buffer-element-type rb)))
    (is (= 2 (buffer-start rb)))
    (is (= 8 (buffer-end rb)))
    (is (= 6 (buffer-count rb)))
    (is (equalp #(0 0 5 6 7 8 9 10 0 0) (buffer rb)))
    (add-elements rb #(11 12 13 14 15 16 17 18 19))
    (is (= 20 (buffer-size rb)))
    (is (eql 'fixnum (buffer-element-type rb)))
    (is (= 0 (buffer-start rb)))
    (is (= 15 (buffer-end rb)))
    (is (= 15 (buffer-count rb)))
    (is (equalp #(5 6 7 8 9 10 11 12 13 14 15 16 17 18 19)
                (subseq (buffer rb) 0 15))))
  (let* ((b (make-array 10
                        :element-type 'fixnum
                        :initial-contents '(7 8 0 0 0 0 0 0 5 6)))
         (rb (make-instance 'ring-buffer
                            :buffer b
                            :size 10
                            :element-type 'fixnum
                            :start 8
                            :end 2
                            :count 4))
         (nums #(9 10 11 12 13 14 15 16 17 18 19)))
    (add-elements rb nums :end 3)
    (is (= 10 (buffer-size rb)))
    (is (eql 'fixnum (buffer-element-type rb)))
    (is (= 8 (buffer-start rb)))
    (is (= 5 (buffer-end rb)))
    (is (= 7 (buffer-count rb)))
    (is (equalp #(7 8 9 10 11 0 0 0 5 6) (buffer rb)))
    (add-elements rb nums :start 3)
    (is (= 20 (buffer-size rb)))
    (is (eql 'fixnum (buffer-element-type rb)))
    (is (= 0 (buffer-start rb)))
    (is (= 15 (buffer-end rb)))
    (is (= 15 (buffer-count rb)))
    (is (equalp #(5 6 7 8 9 10 11 12 13 14 15 16 17 18 19)
                (subseq (buffer rb) 0 15)))))

(test take-element
  (let* ((b (make-array 10
                        :element-type 'fixnum
                        :initial-contents '(0 0 5 6 7 0 0 0 0 0)))
         (rb (make-instance 'ring-buffer
                            :buffer b
                            :size 10
                            :element-type 'fixnum
                            :start 2
                            :end 5
                            :count 3)))
    (is (= 5 (take-element rb)))
    (is (= 6 (take-element rb)))
    (is (= 10 (buffer-size rb)))
    (is (eql 'fixnum (buffer-element-type rb)))
    (is (= 4 (buffer-start rb)))
    (is (= 5 (buffer-end rb)))
    (is (= 1 (buffer-count rb)))
    (is (equalp #(0 0 5 6 7 0 0 0 0 0) (buffer rb)))
    (is (= 7 (take-element rb)))
    (is-false (take-element rb))
    (is (= 10 (buffer-size rb)))
    (is (eql 'fixnum (buffer-element-type rb)))
    (is (= 5 (buffer-start rb)))
    (is (= 5 (buffer-end rb)))
    (is (= 0 (buffer-count rb)))
    (is (equalp #(0 0 5 6 7 0 0 0 0 0) (buffer rb))))
  (let* ((b (make-array 10
                        :element-type 'fixnum
                        :initial-contents '(7 8 0 0 0 0 0 0 5 6)))
         (rb (make-instance 'ring-buffer
                            :buffer b
                            :size 10
                            :element-type 'fixnum
                            :start 8
                            :end 2
                            :count 4)))
    (is (= 5 (take-element rb)))
    (is (= 6 (take-element rb)))
    (is (= 10 (buffer-size rb)))
    (is (eql 'fixnum (buffer-element-type rb)))
    (is (= 0 (buffer-start rb)))
    (is (= 2 (buffer-end rb)))
    (is (= 2 (buffer-count rb)))
    (is (equalp #(7 8 0 0 0 0 0 0 5 6) (buffer rb)))
    (is (= 7 (take-element rb)))
    (is (= 8 (take-element rb)))
    (is-false (take-element rb))
    (is (= 10 (buffer-size rb)))
    (is (eql 'fixnum (buffer-element-type rb)))
    (is (= 2 (buffer-start rb)))
    (is (= 2 (buffer-end rb)))
    (is (= 0 (buffer-count rb)))
    (is (equalp #(7 8 0 0 0 0 0 0 5 6) (buffer rb)))))

(test take-elements
  (let* ((b (make-array 10
                        :element-type 'fixnum
                        :initial-contents '(0 0 5 6 7 0 0 0 0 0)))
         (rb (make-instance 'ring-buffer
                            :buffer b
                            :size 10
                            :element-type 'fixnum
                            :start 2
                            :end 5
                            :count 3))
         (seq (make-array 5 :element-type 'fixnum)))
    (= 2 (take-elements rb seq :end 2))
    (is (= 10 (buffer-size rb)))
    (is (eql 'fixnum (buffer-element-type rb)))
    (is (= 4 (buffer-start rb)))
    (is (= 5 (buffer-end rb)))
    (is (= 1 (buffer-count rb)))
    (is (equalp #(0 0 5 6 7 0 0 0 0 0) (buffer rb)))
    (is (= 3 (take-elements rb seq :start 2)))
    (is (= 0 (take-elements rb seq)))
    (is (= 10 (buffer-size rb)))
    (is (eql 'fixnum (buffer-element-type rb)))
    (is (= 5 (buffer-start rb)))
    (is (= 5 (buffer-end rb)))
    (is (= 0 (buffer-count rb)))
    (is (equalp #(0 0 5 6 7 0 0 0 0 0) (buffer rb))))
  (let* ((b (make-array 10
                        :element-type 'fixnum
                        :initial-contents '(7 8 0 0 0 0 0 0 5 6)))
         (rb (make-instance 'ring-buffer
                            :buffer b
                            :size 10
                            :element-type 'fixnum
                            :start 8
                            :end 2
                            :count 4))
         (seq (make-array 5 :element-type 'fixnum)))
    (is (= 3 (take-elements rb seq :end 3)))
    (is (= 10 (buffer-size rb)))
    (is (eql 'fixnum (buffer-element-type rb)))
    (is (= 1 (buffer-start rb)))
    (is (= 2 (buffer-end rb)))
    (is (= 1 (buffer-count rb)))
    (is (equalp #(7 8 0 0 0 0 0 0 5 6) (buffer rb)))
    (is (= 4 (take-elements rb seq :start 3)))
    (is (= 4 (take-elements rb seq :start 4)))
    (is (= 10 (buffer-size rb)))
    (is (eql 'fixnum (buffer-element-type rb)))
    (is (= 2 (buffer-start rb)))
    (is (= 2 (buffer-end rb)))
    (is (= 0 (buffer-count rb)))
    (is (equalp #(7 8 0 0 0 0 0 0 5 6) (buffer rb)))))


(def-suite input-streams
  :description "Unit tests for input streams"
  :in in-memory-streams)

(in-suite input-streams)

(test make-input-stream
  (is-true (typep (make-input-stream #()) 'stream))
  (is-true (typep (make-input-stream #(0 1 2 3)) 'stream))
  (is-true (typep (make-input-stream #(0 1 2 3 4 5 6 7 8 9) :start 3) 'stream))
  (is-true (typep (make-input-stream #(0 1 2 3 4 5 6 7 8 9) :start 3 :end 5)
                  'stream))
  (is-true (typep (make-input-stream #(0 1 2 3 4 5 6 7 8 9)
                                     :start 3 :end 5 :element-type 'fixnum)
                  'stream))
  (with-input-stream (s #())
    (is-true (typep s 'stream))
    (is (equalp #() (stream-elements s))))
  (with-input-stream (s #(0 1 2 3))
    (is-true (typep s 'stream))
    (is (equalp #(0 1 2 3) (stream-elements s))))
  (with-input-stream (s '(0 1 2 3 4 5 6 7 8 9) :start 3)
    (is-true (typep s 'stream))
    (is (equalp #(3 4 5 6 7 8 9) (stream-elements s))))
  (with-input-stream (s #(0 1 2 3 4 5 6 7 8 9) :start 3 :end 5)
    (is-true (typep s 'stream))
    (is (eql t (stream-element-type s)))
    (is (equalp #(3 4) (stream-elements s))))
  (with-input-stream (s '(0 1 2 3 4 5 6 7 8 9)
                        :start 3 :end 5 :element-type 'fixnum)
    (is-true (typep s 'stream))
    (is (eql 'fixnum (stream-element-type s))))
  (with-input-stream (s #(0.0 -1.1 2.2 -3.3 4.4 -5.5)
                        :element-type 'single-float)
    (is-true (typep s 'stream))
    (is (eql 'single-float (stream-element-type s)))))

(test listen
  (with-input-stream (s #(1 2 3))
    (is-true (listen s))
    (read-element s)
    (is-true (listen s))
    (read-element s)
    (is-true (listen s))
    (read-element s)
    (is-false (listen s))))

(test read-element
  (with-input-stream (s #(#c(-0.1d0 0.5d0) #c(0.0d0 -1.0d0) #c(1.0d0 0.0d0))
                        :element-type '(complex double-float))
    (is (= 3 (stream-length s)))
    (is (= #c(-0.1d0 0.5d0) (read-element s)))
    (is (= 2 (stream-length s)))
    (is (= #c(0.0d0 -1.0d0) (read-element s)))
    (is (= 1 (stream-length s)))
    (is (= #c(1.0d0 0.0d0) (read-element s)))
    (is (= 0 (stream-length s)))
    (signals end-of-file (read-element s))
    (is (eql :eof (read-element s nil :eof))))
  (with-input-stream (s #(0 1 2 3 4 5 6 7 8 9) :start 3 :end 8)
    (is (= 3 (read-element s)))
    (is (= 4 (read-element s)))
    (is (= 5 (read-element s)))
    (is (= 6 (read-element s)))
    (is (= 7 (read-element s)))
    (is (eql :eof (read-element s nil :eof)))
    (signals end-of-file (read-element s)))
  (with-input-stream (s #(t 5 nil "abc" #(3.14 1.41)))
    (is-true (read-element s))
    (is (= 5 (read-element s)))
    (is-false (read-element s))
    (is (string= "abc" (read-element s)))
    (is (equalp #(3.14 1.41) (read-element s)))
    (is (eql :eof (read-element s nil :eof)))
    (signals end-of-file (read-element s))))

(test read-sequence
  (with-input-stream (s #(0 1 2 3 4 5 6 7 8 9) :element-type 'fixnum)
    (let ((seq (make-array 5 :element-type 'fixnum)))
      (is (= 2 (read-sequence seq s :end 2)))
      (is (equalp #(0 1) (subseq seq 0 2)))
      (is (= 4 (read-sequence seq s :start 2 :end 4)))
      (is (equalp #(0 1 2 3) (subseq seq 0 4)))
      (is (= 5 (read-sequence seq s)))
      (is (equalp #(4 5 6 7 8) seq))
      (is (= 1 (read-sequence seq s)))
      (is (equalp #(9) (subseq seq 0 1)))
      (is (zerop (read-sequence seq s)))))
  (with-input-stream (s #(t 5 nil "abc" #(3.14 1.41)))
    (let ((seq (make-array 5)))
      (is (= 5 (read-sequence seq s)))
      (is (equalp #(t 5 nil "abc" #(3.14 1.41)) seq)))))

(test clear-input
  (with-input-stream (s #(0 1 2 3 4 5 6 7 8 9))
    (is (= 0 (read-element s)))
    (is (= 1 (read-element s)))
    (is (= 2 (read-element s)))
    (clear-input s)
    (signals end-of-file (read-element s))))


(def-suite output-streams
  :description "Unit tests for output streams"
  :in in-memory-streams)

(in-suite output-streams)

(test make-output-stream
  (is-true (typep (make-output-stream) 'stream))
  (is-true (typep (make-output-stream :element-type 'string) 'stream))
  (with-output-stream (s)
    (is-true (typep s 'stream))
    (is (eql t (stream-element-type s))))
  (with-output-stream (s :element-type '(unsigned-byte 8))
    (is-true (typep s 'stream))
    (is (equalp '(unsigned-byte 8) (stream-element-type s)))))

(test write-element
  (let ((seq (with-output-stream (s)
               (is (= 1 (write-element 1 s)))
               (is (eql nil (write-element nil s)))
               (is (string= "abc" (write-element "abc" s)))
               (is (equalp '(1 2 3) (write-element '(1 2 3) s)))
               (is (= #c(-0.12d0 0.3d0) (write-element #c(-0.12d0 0.3d0) s))))))
    (is (= 5 (length seq)))
    (is (equalp #(1 nil "abc" (1 2 3) #c(-0.12d0 0.3d0)) seq)))
  (let ((seq (with-output-stream (s :element-type 'string)
               (is (= 0 (stream-length s)))
               (is (string= "abc" (write-element "abc" s)))
               (is (= 1 (stream-length s)))
               (is (string= "123" (write-element "123" s)))
               (is (= 2 (stream-length s)))
               (is (string= "XYZ" (write-element "XYZ" s)))
               (is (= 3 (stream-length s))))))
    (is (= 3 (length seq)))
    (is (equalp #("abc" "123" "XYZ") seq))))

(test write-sequence
  (with-output-stream (s :element-type 'fixnum)
    (let ((seq (make-array 500 :element-type 'fixnum)))
      (dotimes (i 500)
        (setf (aref seq i) (- (mod (expt i 5) 1000) 500)))
      (is (eq seq (write-sequence seq s :end 5)))
      (is (eq seq (write-sequence seq s :start 5 :end 10)))
      (is (equalp #(-500 -499 -468 -257 -476 -375 276 307 268 -451)
                  (get-elements s)))
      (is (eq seq (write-sequence seq s)))
      (is (equalp seq (get-elements s)))
      (is (eq seq (write-sequence seq s :start 490)))
      (is (equalp #(-500 -49 -268 193 -276 -125 476 -243 468 -1)
                  (get-elements s))))))

(test clear-output
  (let ((seq (with-output-stream (s)
               (is (eql t (write-element t s)))
               (is (eql nil (write-element nil s)))
               (is (eql nil (write-element nil s)))
               (is (eql t (write-element t s)))
               (is (eql t (write-element t s)))
               (clear-output s))))
    (is (= 0 (length seq)))))


(def-suite io-streams
  :description "Unit tests for io streams"
  :in in-memory-streams)

(in-suite io-streams)

(test make-io-stream
  (is-true (typep (make-io-stream) 'stream))
  (is-true (typep (make-io-stream :element-type 'string) 'stream))
  (with-io-stream (s)
    (is-true (typep s 'stream))
    (is (eql t (stream-element-type s)))
    (dotimes (i (- *initial-buffer-size* 2))
      (write-element 0 s))
    (write-element 0 s)
    (write-element 1 s)
    (dotimes (i (- *initial-buffer-size* 2))
      (read-element s))
    (write-element 2 s)
    (write-element 3 s)
    (is (equalp #(0 1 2 3) (stream-elements s))))
  (with-io-stream (s :element-type '(unsigned-byte 8))
    (is-true (typep s 'stream))
    (is (equalp '(unsigned-byte 8) (stream-element-type s)))))

(test listen/io
  (with-io-stream (s)
    (is-false (listen s))
    (write-sequence #(1 2 3) s)
    (is-true (listen s))
    (read-element s)
    (is-true (listen s))
    (read-element s)
    (is-true (listen s))
    (read-element s)
    (is-false (listen s))))

(test read-element/io
  (with-io-stream (s :element-type '(complex double-float))
    (write-sequence #(#c(-0.1d0 0.5d0) #c(0.0d0 -1.0d0) #c(1.0d0 0.0d0)) s)
    (is (= 3 (stream-length s)))
    (is (= #c(-0.1d0 0.5d0) (read-element s)))
    (is (= 2 (stream-length s)))
    (is (= #c(0.0d0 -1.0d0) (read-element s)))
    (is (= 1 (stream-length s)))
    (is (= #c(1.0d0 0.0d0) (read-element s)))
    (is (= 0 (stream-length s)))
    (signals end-of-file (read-element s))
    (is (eql :eof (read-element s nil :eof))))
  (with-io-stream (s)
    (write-sequence #(0 1 2 3 4 5 6 7 8 9) s :start 3 :end 8)
    (is (= 3 (read-element s)))
    (is (= 4 (read-element s)))
    (is (= 5 (read-element s)))
    (is (= 6 (read-element s)))
    (is (= 7 (read-element s)))
    (is (eql :eof (read-element s nil :eof)))
    (signals end-of-file (read-element s)))
  (with-io-stream (s)
    (write-sequence #(t 5 nil "abc" #(3.14 1.41)) s)
    (is-true (read-element s))
    (is (= 5 (read-element s)))
    (is-false (read-element s))
    (is (string= "abc" (read-element s)))
    (is (equalp #(3.14 1.41) (read-element s)))
    (is (eql :eof (read-element s nil :eof)))
    (signals end-of-file (read-element s))))

(test read-sequence/io
  (with-io-stream (s :element-type 'fixnum)
    (write-sequence #(0 1 2 3 4 5 6 7 8 9) s)
    (let ((seq (make-array 5 :element-type 'fixnum)))
      (is (= 2 (read-sequence seq s :end 2)))
      (is (equalp #(0 1) (subseq seq 0 2)))
      (is (= 4 (read-sequence seq s :start 2 :end 4)))
      (is (equalp #(0 1 2 3) (subseq seq 0 4)))
      (is (= 5 (read-sequence seq s)))
      (is (equalp #(4 5 6 7 8) seq))
      (is (= 1 (read-sequence seq s)))
      (is (equalp #(9) (subseq seq 0 1)))
      (is (zerop (read-sequence seq s)))))
  (with-io-stream (s)
    (write-sequence #(t 5 nil "abc" #(3.14 1.41)) s)
    (let ((seq (make-array 5)))
      (is (= 5 (read-sequence seq s)))
      (is (equalp #(t 5 nil "abc" #(3.14 1.41)) seq)))))

(test clear-input/io
  (with-io-stream (s)
    (write-sequence #(0 1 2 3 4 5 6 7 8 9) s)
    (is (= 0 (read-element s)))
    (is (= 1 (read-element s)))
    (is (= 2 (read-element s)))
    (clear-input s)
    (signals end-of-file (read-element s))))

(test write-element/io
  (with-io-stream (s)
    (is (= 1 (write-element 1 s)))
    (is (eql nil (write-element nil s)))
    (is (string= "abc" (write-element "abc" s)))
    (is (equalp '(1 2 3) (write-element '(1 2 3) s)))
    (is (= #c(-0.12d0 0.3d0) (write-element #c(-0.12d0 0.3d0) s)))
    (is (equalp #(1 nil "abc" (1 2 3) #c(-0.12d0 0.3d0))
                (get-elements s))))
  (with-io-stream (s :element-type 'string)
    (is (= 0 (stream-length s)))
    (is (string= "abc" (write-element "abc" s)))
    (is (= 1 (stream-length s)))
    (is (string= "123" (write-element "123" s)))
    (is (= 2 (stream-length s)))
    (is (string= "XYZ" (write-element "XYZ" s)))
    (is (= 3 (stream-length s)))
    (is (equalp #("abc" "123" "XYZ") (get-elements s)))))

(test write-sequence/io
  (with-io-stream (s :element-type 'fixnum)
    (let ((seq (make-array 500 :element-type 'fixnum)))
      (dotimes (i 500)
        (setf (aref seq i) (- (mod (expt i 5) 1000) 500)))
      (is (eq seq (write-sequence seq s :end 5)))
      (is (eq seq (write-sequence seq s :start 5 :end 10)))
      (is (equalp #(-500 -499 -468 -257 -476 -375 276 307 268 -451)
                  (get-elements s)))
      (is (eq seq (write-sequence seq s)))
      (is (equalp seq (get-elements s)))
      (is (eq seq (write-sequence seq s :start 490)))
      (is (equalp #(-500 -49 -268 193 -276 -125 476 -243 468 -1)
                  (get-elements s))))))

(test clear-output/io
  (with-io-stream (s)
    (is (eql t (write-element t s)))
    (is (eql nil (write-element nil s)))
    (is (eql nil (write-element nil s)))
    (is (eql t (write-element t s)))
    (is (eql t (write-element t s)))
    (clear-output s)
    (is (equalp #() (get-elements s)))))
