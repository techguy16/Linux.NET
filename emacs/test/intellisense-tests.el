(require 'ert)

(defun fsharp-mode-wrapper (bufs body)
  "Load fsharp-mode and make sure any completion process is killed after test"
  (unwind-protect
      (progn (load-fsharp-mode)
             (funcall body))
    (sleep-for 1)
    (ac-fsharp-quit-completion-process)
    (dolist (buf bufs)
      (when (get-buffer buf)
        (switch-to-buffer buf)
        (revert-buffer t t)
        (kill-buffer buf)))
    (when (get-buffer "*fsharp-complete*")
      (kill-buffer "*fsharp-complete*"))
    ))

(ert-deftest start-completion-process ()
  "Check that we can start the completion process and request help"
  (fsharp-mode-wrapper '("Program.fs")
   (lambda ()
     (find-file "Test1/Program.fs")
     (ac-fsharp-launch-completion-process)
     (should (buffer-live-p (get-buffer "*fsharp-complete*")))
     (should (process-live-p ac-fsharp-completion-process))
     (process-send-string ac-fsharp-completion-process "help\n")
     (switch-to-buffer "*fsharp-complete*")
     (with-timeout (waittime)
       (while (string= (buffer-string) "")
         (accept-process-output ac-fsharp-completion-process)))
     (should (search-backward "trigger completion request" nil t)))))

(defconst waittime 5
  "Seconds to wait for data from background process")
(defconst sleeptime 1
  "Seconds to wait for data from background process")


(ert-deftest check-project-files ()
  "Check the program files are set correctly"
  (fsharp-mode-wrapper '("Program.fs")
   (lambda ()
     (find-file "Test1/Program.fs")
     (ac-fsharp-load-project "Test1.fsproj")
     (accept-process-output ac-fsharp-completion-process waittime)
     (while (eq nil ac-fsharp-project-files)
       (sleep-for 1))
     (should (string-match-p "Test1/Program.fs" (mapconcat 'identity ac-fsharp-project-files "")))
     (should (string-match-p "Test1/FileTwo.fs" (mapconcat 'identity ac-fsharp-project-files ""))))))


(ert-deftest check-completion ()
  "Check completion-at-point works"
  (fsharp-mode-wrapper '("Program.fs")
   (lambda ()
     (find-file "Test1/Program.fs")
     (ac-fsharp-load-project "Test1.fsproj")
     ;(sleep-for sleeptime)
     (search-forward "X.func")
     (delete-backward-char 2)
     (completion-at-point)
     (accept-process-output ac-fsharp-completion-process waittime)
     (beginning-of-line)
     (should (search-forward "X.func")))))


(ert-deftest check-gotodefn ()
  "Check jump to definition works"
  (fsharp-mode-wrapper '("Program.fs")
   (lambda ()
     (find-file "Test1/Program.fs")
     (ac-fsharp-load-project "Test1.fsproj")
     (while (eq nil ac-fsharp-project-files)
       (sleep-for 1))
     (search-forward "X.func")
     (backward-char 2)
     (call-process "sleep" nil nil nil "3")
     (ac-fsharp-gotodefn-at-point)
     (while (eq (point) 88)
       (sleep-for 1))
     (should (eq (point) 18)))))

(ert-deftest check-tooltip ()
  "Check tooltip request works"
  (fsharp-mode-wrapper '("Program.fs")
   (lambda ()
     (let ((tiptext))
       (flet ((pos-tip-show (s) (setq tiptext s)))
         (find-file "Test1/Program.fs")
         (ac-fsharp-load-project "Test1.fsproj")
         (while (eq nil ac-fsharp-project-files)
           (sleep-for 1))
         (search-forward "X.func")
         (backward-char 2)
         (call-process "sleep" nil nil nil "3")
         (ac-fsharp-tooltip-at-point)
         (while (eq nil tiptext)
           (sleep-for 1))
         (should
          (string-match-p "val func : x:int -> int\n\nFull name: Program.X.func"
                          tiptext)))))))

(ert-deftest check-errors ()
  "Check error underlining works"
  (fsharp-mode-wrapper '("Program.fs")
   (lambda ()
     (let ((tiptext))
       (flet ((pos-tip-show (s) (setq tiptext s)))
         (find-file "Test1/Program.fs")
         (ac-fsharp-load-project "Test1.fsproj")
         (while (eq nil ac-fsharp-project-files)
           (sleep-for 1))
         (search-forward "X.func")
         (delete-backward-char 1)
         (backward-char)
         (call-process "sleep" nil nil nil "3")
         (ac-fsharp-get-errors)
         (while (eq (length (overlays-at (point))) 0)
           (sleep-for 1))
         (should (eq (overlay-get (car (overlays-at (point))) 'face)
                 'fsharp-error-face)))))))

