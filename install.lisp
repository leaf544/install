(defvar *system-password* "dsads")

(defmacro with-sudo (control-string &rest fmt-arguments)
  `(format nil "echo ~a | sudo -S ~a"  *system-password*
	   (format nil ,control-string ,@fmt-arguments)))

;;; XBPS

(defun xbps-install (package &optional (args "") &key (output *standard-output*))
  (uiop:run-program
   (with-sudo "~a ~a ~a" "xbps-install" args package) :output output))

(defun xbps-remove (package &optional (args "") &key (output *standard-output*))
  (uiop:run-program
   (with-sudo "~a ~a ~a" "xbps-remove " args package) :output output))

;;; Misc

(defun package-exists-p (package)
  (uiop:string-prefix-p
   "ii"
   (uiop:run-program (format nil "xbps-query -l | grep ~a" package) :output :string)))

(defun read-from-file (path)
  (with-open-file (str path
		       :direction :input
		       :if-does-not-exist :create)
    str))

(defun write-to-file (path content &key if-exists)
  (with-open-file (str path
		       :direction :output
		       :if-exists if-exists
		       :if-does-not-exist :create)
    (format str content)))

;;; Preliminary

(uiop:chdir "~/")
(xbps-install "" "-Syu" :output *standard-output*) ;; Updating repository

;;; Packages

(loop for pkg in (uiop:read-file-lines "packages") do (xbps-install pkg "-Syu" :output output))

;;; Stump WM

(ql:quickload :clx)
(ql:quickload :cl-ppcre)
(ql:quickload :alexandria)

(uiop:run-program (format nil "git clone https://github.com/madand/clx-truetype ~/quicklisp/local-projects")
		  :ignore-error-status t)

(uiop:run-program "git clone https://github.com/stumpwm/stumpwm"
		  :ignore-error-status t)

(uiop:run-program "git clone https://github.com/stumpwm/stumpwm-contrib/"
		  :ignore-error-status t)

(uiop:chdir "stumpwm/")
(uiop:run-program "./autogen.sh")
(uiop:run-program "./configure")
(uiop:run-program "make")
(uiop:run-program (with-sudo "~a" "make install"))

;;; End

(load "destinations.lisp")

(write-line "Copying files to their destination")

(loop for dest in *destinations* do
  (if (not (file-exists-p (car dest)))
      (uiop:run-program (format nil "cp -r ~a" (car dest)))
      
      (uiop:copy-file (car dest)
		      (cdr dest))))

(write-line "File copying done")
