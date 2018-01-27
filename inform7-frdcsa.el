(if (file-exists-p "/var/lib/myfrdcsa/codebases/minor/inform7-frdcsa") 
 (add-to-list 'load-path "/var/lib/myfrdcsa/codebases/minor/inform7-frdcsa"))

(if (file-exists-p "/var/lib/myfrdcsa/codebases/minor/world-state-monitor/inform7/vendor/inform7-mode/inform7-mode.el")
 (progn
  (add-to-list 'load-path "/var/lib/myfrdcsa/codebases/minor/world-state-monitor/inform7/vendor/inform7-mode")
  (autoload 'inform7-mode "inform7-mode"   "Major mode for editing inform 7 story files." t)
  (add-to-list 'auto-mode-alist '("\\.ni" . inform7-mode))
  ))

(if (file-exists-p "/var/lib/myfrdcsa/codebases/minor/world-state-monitor/inform7/vendor/jade-mode/jade-mode.el")
 (progn
  (add-to-list 'load-path "/var/lib/myfrdcsa/codebases/minor/world-state-monitor/inform7/vendor/jade-mode")
  (require 'sws-mode)
  (require 'jade-mode)    
  (add-to-list 'auto-mode-alist '("\\.styl$" . sws-mode))
  (add-to-list 'auto-mode-alist '("\\.jade$" . jade-mode))))

(require 'inform7-mode)

(require 'malyon)

(defvar inform7-frdcsa-current-package nil)
(defvar inform7-frdcsa-machine-type "z8")

(defvar inform7-frdcsa-inform7-buffer-name "*Inform7*")

(global-set-key "\C-c\C-k\C-vif" 'inform7-frdcsa-edit-story)
(global-set-key "\C-c\C-k\C-viF" 'inform7-frdcsa-edit-story-reload)
(global-set-key "\C-c\C-k\C-vIF" 'inform7-frdcsa-quick-start)

(load-library "inform7-mode")
(add-hook 'inform7-mode-hook
 '(lambda ()
   (define-key inform7-mode-map "\C-ci" 'inform7-frdcsa-reload-story-glulx-cli)
   (define-key inform7-mode-map "\C-cI" 'inform7-frdcsa-reload-story)
   (define-key inform7-mode-map "\C-c9" 'inform7-frdcsa-launch-story-9000)
   (define-key inform7-mode-map "\C-ca" 'inform7-frdcsa-restart-all)
   ))

(load-library "malyon")
(add-hook 'malyon-mode-hook
 '(lambda ()
   (define-key malyon-keymap-read "\C-cx" 'inform7-frdcsa-quit-story)
   ))
(add-hook 'shell-mode-hook
 '(lambda ()
   (define-key shell-mode-map "\C-cx" 'inform7-frdcsa-quit-story)
   ))

(defun inform7-frdcsa-current-story-ni ()
 (interactive)
 (frdcsa-el-concat-dir
  (list inform7-frdcsa-current-package "Source" "story.ni")))

(defun inform7-frdcsa-quick-start (&optional overwrite)
 ""
 (interactive)
 (setq inform7-frdcsa-current-package "/var/lib/myfrdcsas/versions/myfrdcsa-1.0/codebases/minor/normal-form/inform7/Normal-Form/Normal Form.inform")
 (ffap (inform7-frdcsa-current-story-ni))
 (inform7-frdcsa-launch-story-9000 t)
 (flp-set-windows-with-additionals t))

(defun inform7-frdcsa-edit-story (&optional overwrite)
 ""
 (interactive)
 (let ((package (inform7-frdcsa-get-package overwrite)))
  (ffap (concat package "/Source/story.ni"))))

(defun inform7-frdcsa-edit-story-reload ()
 ""
 (interactive)
 (inform7-frdcsa-edit-story t))

(defun inform7-frdcsa-reload-story ()
 ""
 (interactive)
 (inform7-frdcsa-load-story t))

(defun inform7-frdcsa-reload-story-glulx-cli ()
 ""
 (interactive)
 (inform7-frdcsa-load-story t "glulx"))

(defun inform7-frdcsa-load-story (&optional recompile machine-type use-9000)
 ""
 (interactive)
 (setq inform7-frdcsa-compile-errors nil)
 (let ((compile-errors-buffer "*Inform7-Compile-Errors*")
       (package (inform7-frdcsa-get-package)))
  (if (and
       (not use-9000)
       (or
	recompile
	(not (file-exists-p (concat package "/Build/output.z8")))
	(not (file-exists-p (concat package "/Build/output.ulx")))
	))
   (let*
    ((result
      (see (shell-command-to-string
       (concat 
     	"/var/lib/myfrdcsa/codebases/minor/inform7-frdcsa/scripts/compile-inform7-package.pl -m "
     	(or machine-type inform7-frdcsa-machine-type)
     	" -p " 
     	(shell-quote-argument package)
	" --verbose"))))
     (result-without-carriage-returns (gnus-replace-in-string result "\n" " ")))
    (if (string-match "Error" result-without-carriage-returns)
     (setq inform7-frdcsa-compile-errors result))))
  (let* ((inform7-frdcsa-parsed-result 
	  (shell-command-to-string
	   (see (concat 
	    "/var/lib/myfrdcsa/codebases/minor/normal-form/conversion/release-inform7-part-2.pl"
	    " -i " (shell-quote-argument (concat (inform7-frdcsa-get-package) 
					  "/Source/story.ni" )))))))
   (message inform7-frdcsa-parsed-result)
   (if use-9000
    (progn
     (if recompile
      (if (get-buffer inform7-frdcsa-inform7-buffer-name)
       (kill-buffer inform7-frdcsa-inform7-buffer-name)))
     (run-in-shell
      (see (concat "/var/lib/myfrdcsa/codebases/minor/inform7-frdcsa/9000 -r "
       (if recompile "1" "0")
       " -m "
       machine-type
       " -p "
       (shell-quote-argument (inform7-frdcsa-get-package))))
      inform7-frdcsa-inform7-buffer-name))
    (progn
     (if (> (length inform7-frdcsa-compile-errors) 0)
      (with-output-to-temp-buffer compile-errors-buffer
       (prin1 inform7-frdcsa-compile-errors)
       (pop-to-buffer compile-errors-buffer))
      (if (string= machine-type "glulx")
       (run-in-shell
	(see (concat "/var/lib/myfrdcsa/sandbox/glulxe-0.5.2/glulxe-0.5.2/glulxe " 
	 (shell-quote-argument (concat package "/Build/output.ulx"))))
	"*Inform7*")
       (if (string= machine-type "z8")
	(malyon (concat package "/Build/output.z8"))
	(error "No machine specified")))))))))

(defun inform7-frdcsa-quit-story ()
 ""
 (interactive)
 (if (kmax-mode-is-derived-from 'malyon-mode)
  (malyon-quit)
  (if (kmax-mode-is-derived-from 'shell-mode)
   (kill-buffer))))

(defun inform7-frdcsa-get-package (&optional overwrite)
 ""
 (if (and inform7-frdcsa-current-package (not overwrite))
  inform7-frdcsa-current-package
  (setq inform7-frdcsa-current-package
   (completing-read "Package? "
    (read
     (shell-command-to-string
      "/var/lib/myfrdcsa/codebases/minor/inform7-frdcsa/scripts/find-story-packages.pl"))))))

(defun inform7-frdcsa-launch-story-9000 (arg)
 ""
 (interactive "P")
 (if uea-connected
  (inform7-frdcsa-load-story
   (if arg
    t
    (if (non-nil (get-buffer "*Inform7*"))
     t
     nil))
   "glulx" t)
  (error "UniLang Emacs Agent not connected")))

(defun inform7-frdcsa-restart-all ()
 ""
 (interactive)
 (kill-buffer (get-buffer "*Inform7*"))
 (ushell-restart)
 (inform7-frdcsa-launch-story-9000 t))

(defun inform7-frdcsa-open-game-library ()
 ""
 (interactive)
 (dired "/var/lib/myfrdcsa/codebases/minor/inform7-frdcsa/data/www.ifarchive.org/if-archive/games/zcode"))

;; ps auxwww | grep inform | awk '{print $2}' | xargs kill -9
