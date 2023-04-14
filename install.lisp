(write-line "Welcome to leaf's Void Linux install script")
(write-line "Please enter the root password to continue with this installation: ")

(defvar *system-password* "kiwI,.123")

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

;;; Preliminary

(uiop:chdir "~/")
(xbps-install "" "-Syu") ;; Updating repository

;;; Packages

(loop for pkg in (uiop:read-file-lines "packages") do (xbps-install pkg "-Syu"))

;;; ENV

;;; Quicklisp

(uiop:run-program "curl -O https://beta.quicklisp.org/quicklisp.lisp")

(quicklisp-quickstart:install)
(ql:add-to-init-file)

(ql:quickload :clx)
(ql:quickload :cl-ppcre)
(ql:quickload :alexandria)

(uiop:run-program (format nil "git clone https://github.com/madand/clx-truetype ~a/local-projects"
			  (uiop:getenv "HOME")))

;;; Stump WM

(uiop:run-program "git clone https://github.com/stumpwm/stumpwm")
(uiop:chdir "stumpwm/")
(uiop:run-program "./autogen.sh")
(uiop:run-program "./configure")
(uiop:run-program "make")
(uiop:run-program (with-sudo "~a" "make install"))

(with-open-file (str (format nil "~a/.xinitrc" (uiop:getenv "HOME"))
                     :direction :output
                     :if-exists :supersede
                     :if-does-not-exist :create)
  (format str "stumpwm"))

;; Firefox
