;;;; This file is part of in-memory-streams
;;;; Copyright 2022 Guillaume LE VAILLANT
;;;; Distributed under the GNU GPL v3 or later.
;;;; See the file LICENSE for terms of use and distribution.

(defpackage :in-memory-streams
  (:nicknames :ims)
  (:use :cl :trivial-gray-streams)
  (:export *initial-buffer-size*
           get-elements
           make-input-stream
           make-io-stream
           make-output-stream
           read-element
           stream-elements
           stream-length
           write-element
           with-input-stream
           with-io-stream
           with-output-stream))

(in-package :in-memory-streams)


;;;
;;; Ring buffer
;;;

(deftype index ()
  '(mod #.array-dimension-limit))

(defclass ring-buffer ()
  ((buffer :initarg :buffer
           :accessor buffer
           :type simple-array)
   (size :initarg :size
         :accessor buffer-size
         :type index)
   (element-type :initarg :element-type
                 :accessor buffer-element-type)
   (start :initarg :start
          :accessor buffer-start
          :type index)
   (end :initarg :end
        :accessor buffer-end
               :type index)
   (count :initarg :count
          :accessor buffer-count
          :type index)))

(defgeneric clear (ring-buffer)
  (:documentation "Reset indexes of RING-BUFFER to 0."))

(defmethod clear ((ring-buffer ring-buffer))
  (with-slots (start end count) ring-buffer
    (setf start 0)
    (setf end 0)
    (setf count 0))
  nil)

(defgeneric resize (ring-buffer new-size)
  (:documentation "Resize internal array of RING-BUFFER to NEW-SIZE."))

(defmethod resize ((ring-buffer ring-buffer) new-size)
  (with-slots (buffer size element-type start end count) ring-buffer
    (when (> count new-size)
      (error "Wrong size of for a buffer containing ~d bytes: ~d."
             count new-size))
    (let ((new-buffer (make-array new-size :element-type element-type)))
      (when (plusp count)
        (if (< start end)
            (replace new-buffer buffer
                     :start1 0 :end1 count
                     :start2 start :end2 end)
            (let* ((length1 (- size start))
                   (length2 (- count length1)))
              (replace new-buffer buffer
                       :start1 0 :end1 length1
                       :start2 start :end2 size)
              (when (plusp length2)
                (replace new-buffer buffer
                         :start1 length1 :end1 count
                         :start2 0 :end2 length2)))))
      (setf buffer new-buffer)
      (setf size new-size)
      (setf start 0)
      (setf end count)))
  ring-buffer)

(defgeneric add-element (ring-buffer element)
  (:documentation "Add ELEMENT to RING-BUFFER."))

(defmethod add-element ((ring-buffer ring-buffer) element)
  (when (= (buffer-count ring-buffer) (buffer-size ring-buffer))
    (resize ring-buffer (* 2 (buffer-size ring-buffer))))
  (with-slots (buffer size end count) ring-buffer
    (when (= end size)
      (setf end 0))
    (setf (aref buffer end) element)
    (incf count)
    (incf end))
  element)

(defgeneric add-elements (ring-buffer seq &key start end)
  (:documentation
   "Add the elements between START and END in SEQ to RING-BUFFER."))

(defmethod add-elements ((ring-buffer ring-buffer) seq &key (start 0) end)
  (let* ((seq-start start)
         (seq-end (or end (length seq)))
         (length (- seq-end seq-start)))
    (let ((size (buffer-size ring-buffer))
          (count (buffer-count ring-buffer)))
      (when (> (+ count length) size)
        (resize ring-buffer (* 2 (max size length)))))
    (with-slots (buffer size start end count) ring-buffer
      (cond
        ((<= start end)
         (let* ((length1 (min length (- size end)))
                (length2 (- length length1)))
           (replace buffer seq
                    :start1 end :end1 (+ end length1)
                    :start2 seq-start :end2 (+ seq-start length1))
           (when (plusp length2)
             (replace buffer seq
                      :start1 0 :end1 length2
                      :start2 (+ seq-start length1) :end2 seq-end))
           (incf count length)
           (incf end length)
           (when (> end size)
             (decf end size))))
        (t
         (replace buffer seq
                  :start1 end :end1 (+ end length)
                  :start2 seq-start :end2 seq-end)
         (incf count length)
         (incf end length)))))
  seq)

(defgeneric take-element (ring-buffer)
  (:documentation "Take one element from RING-BUFFER."))

(defmethod take-element ((ring-buffer ring-buffer))
  (with-slots (buffer size start end count) ring-buffer
    (if (zerop count)
        (values nil nil)
        (let ((element (aref buffer start)))
          (incf start)
          (when (= start size)
            (setf start 0))
          (decf count)
          (values element t)))))

(defgeneric take-elements (ring-buffer seq &key start end)
  (:documentation
   "Take elements from RING-BUFFER and put them in SEQ between START and END.
The index of the first element of SEQ that was not updated is returned."))

(defmethod take-elements ((ring-buffer ring-buffer) seq &key (start 0) end)
  (let* ((seq-start start)
         (seq-end (or end (length seq)))
         (length (min (- seq-end seq-start) (buffer-count ring-buffer))))
    (with-slots (buffer size start end count) ring-buffer
      (cond
        ((< start end)
         (replace seq buffer
                  :start1 seq-start :end1 (+ seq-start length)
                  :start2 start :end2 (+ start length))
         (incf start length)
         (decf count length))
        (t
         (let* ((length1 (min length (- size start)))
                (length2 (- length length1)))
           (replace seq buffer
                    :start1 seq-start :end1 (+ seq-start length1)
                    :start2 start :end2 (+ start length1))
           (when (plusp length2)
             (replace seq buffer
                      :start1 (+ seq-start length1) :end1 (+ seq-start length)
                      :start2 0 :end2 length2))
           (incf start length)
           (when (>= start size)
             (decf start size))
           (decf count length)))))
    (+ seq-start length)))


;;;
;;; In-memory stream
;;;

(defclass in-memory-stream ()
  ((buffer :initarg :buffer
           :accessor buffer
           :type ring-buffer)))

(defmethod stream-element-type ((stream in-memory-stream))
  (buffer-element-type (buffer stream)))

(defgeneric stream-length (stream)
  (:documentation "Return the number of elements in a STREAM."))

(defmethod stream-length ((stream in-memory-stream))
  (buffer-count (buffer stream)))

(defgeneric stream-elements (stream)
    (:documentation
     "Return a vector containing the elements in STREAM without removing
them from STREAM."))

(defmethod stream-elements ((stream in-memory-stream))
  (with-slots (buffer size element-type start end count) (buffer stream)
    (let ((elements (make-array count :element-type element-type)))
      (if (< start end)
          (replace elements buffer :start2 start :end2 end)
          (let* ((length1 (- size start))
                 (length2 (- count length1)))
            (replace elements buffer :end1 length1 :start2 start)
            (replace elements buffer :start1 length1 :end2 length2)))
      elements)))


;;;
;;; Input stream
;;;

(defclass input-stream (in-memory-stream fundamental-input-stream)
  ())

(defmethod stream-listen ((stream input-stream))
  (plusp (buffer-count (buffer stream))))

(defgeneric read-element (stream &optional eof-error-p eof-value)
  (:documentation
   "Like READ-BYTE, but for input streams containing any type of elements."))

(defmethod read-element ((stream input-stream)
                         &optional (eof-error-p t) eof-value)
  (multiple-value-bind (element elementp) (take-element (buffer stream))
    (cond
      (elementp element)
      (eof-error-p (error 'end-of-file :stream stream))
      (t eof-value))))

(defmethod stream-read-sequence ((stream input-stream) seq start end
                                 &key &allow-other-keys)
  (take-elements (buffer stream) seq :start start :end end))

(defmethod stream-clear-input ((stream input-stream))
  (clear (buffer stream)))

(defun make-input-stream (seq &key (start 0) end element-type)
  "Return an input stream which will supply the elements of SEQ between START
and END in order."
  (let* ((end (or end (length seq)))
         (length (- end start))
         (element-type (cond
                         (element-type element-type)
                         ((vectorp seq) (array-element-type seq))
                         (t t)))
         (buffer (make-array length :element-type element-type)))
    (replace buffer seq :start2 start :end2 end)
    (make-instance 'input-stream
                   :buffer (make-instance 'ring-buffer
                                          :buffer buffer
                                          :size length
                                          :element-type element-type
                                          :start 0
                                          :end length
                                          :count length))))

(defmacro with-input-stream ((var seq &key (start 0) end element-type)
                             &body body)
  "Within BODY, VAR is bound to an input stream defined by SEQ, START, END and
ELEMENT-TYPE. The result of the last form of BODY is returned."
  `(with-open-stream (,var (make-input-stream ,seq
                                              :start ,start
                                              :end ,end
                                              :element-type ,element-type))
     ,@body))


;;;
;;; Output stream
;;;

(defparameter *initial-buffer-size* 128)

(defclass output-stream (in-memory-stream fundamental-output-stream)
  ())

(defgeneric write-element (element stream)
  (:documentation
   "Like WRITE-BYTE, but for output streams containing any type of elements."))

(defmethod write-element (element (stream output-stream))
  (add-element (buffer stream) element))

(defmethod stream-write-sequence ((stream output-stream) seq start end
                                  &key &allow-other-keys)
  (add-elements (buffer stream) seq :start start :end end))

(defmethod stream-clear-output ((stream output-stream))
  (clear (buffer stream)))

(defgeneric get-elements (stream)
  (:documentation "Return the elements that were written to a STREAM."))

(defmethod get-elements ((stream output-stream))
  (let* ((buffer (buffer stream))
         (length (buffer-count buffer))
         (element-type (buffer-element-type buffer))
         (elements (make-array length :element-type element-type)))
    (take-elements buffer elements)
    elements))

(defun make-output-stream (&key element-type)
  "Return an output stream which will accumulate the elements written to it for
the benefit of the GET-ELEMENTS function."
  (let* ((length *initial-buffer-size*)
         (element-type (cond
                         (element-type element-type)
                         (t t)))
         (buffer (make-array length :element-type element-type)))
    (make-instance 'output-stream
                   :buffer (make-instance 'ring-buffer
                                          :buffer buffer
                                          :size length
                                          :element-type element-type
                                          :start 0
                                          :end 0
                                          :count 0))))

(defmacro with-output-stream ((var &key element-type) &body body)
  "Within BODY, VAR is bound to an output stream. After all the forms in BODY
have been executed, the elements that have been written to VAR (and that
haven't been consumed by a call to GET-ELEMENTS within BODY) are returned."
  `(with-open-stream (,var (make-output-stream :element-type ,element-type))
     ,@body
     (get-elements ,var)))


;;;
;;; IO stream
;;;

(defclass io-stream (input-stream output-stream)
  ())

(defun make-io-stream (&key element-type)
  "Return a stream which will supply the elements that have been written to it
in order."
  (let* ((length *initial-buffer-size*)
         (element-type (cond
                         (element-type element-type)
                         (t t)))
         (buffer (make-array length :element-type element-type)))
    (make-instance 'io-stream
                   :buffer (make-instance 'ring-buffer
                                          :buffer buffer
                                          :size length
                                          :element-type element-type
                                          :start 0
                                          :end 0
                                          :count 0))))

(defmacro with-io-stream ((var &key element-type) &body body)
  "Within BODY, VAR is bound to an io stream. The result of the last form of
BODY is returned."
  `(with-open-stream (,var (make-io-stream :element-type ,element-type))
     ,@body))
