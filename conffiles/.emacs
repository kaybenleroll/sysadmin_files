
(require 'package) ;; You might already have this line
(add-to-list 'package-archives
	     '("melpa" . "http://melpa.org/packages/"))
(when (< emacs-major-version 24)
  ;; For important compatibility libraries like cl-lib
  (add-to-list 'package-archives '(("gnu"       . "http://elpa.gnu.org/packages/")
       	                           ("marmalade" . "http://marmalade-repo.org/packages/")
			           ("melpa"     . "http://melpa.milkbox.net/packages/")
				   )))
(package-initialize) ;; You might already have this line


;;; Save all backup files to a specific directory in the home dir
(defvar user-temporary-file-directory "/home/mcooney/.emacs.d/backups")

(make-directory user-temporary-file-directory t)

(setq backup-by-copying t)
(setq backup-directory-alist
  `(("." . ,user-temporary-file-directory)))
(setq auto-save-list-file-prefix
  (concat user-temporary-file-directory ".auto-saves-"))
(setq auto-save-file-name-transforms
  `((".*" ,user-temporary-file-directory t)))



;(define-key key-translation-map [?\C-h] [?\C-?])


;(add-to-list 'load-path "/home/mcooney/githubrepos/ESS/lisp")
;(load "/home/mcooney/githubrepos/ESS/lisp/ess-site")
(setq inferior-julia-program-name "/usr/local/bin/julia")

;;; Add in ESS
(require 'ess-site)


;;; Julia mode
(add-to-list 'load-path "/home/mcooney/.emacs.d/library")
(require 'julia-mode)



;;; Remove trailing whitespace
(add-hook 'before-save-hook 'delete-trailing-whitespace)

;;; Ensure tabs are added as spaces
(setq-default indent-tabs-mode nil)

;;; Show the column number
(setq column-number-mode t)



;;; Configuration options for ESS
(setq ess-eval-visibly-p nil)        ;otherwise C-c C-r (eval region) takes forever
;(setq ess-ask-for-ess-directory nil) ;otherwise you are prompted each time you start an interactive R session

(define-key comint-mode-map [C-up]   'comint-previous-matching-input-from-input)
(define-key comint-mode-map [C-down] 'comint-next-matching-input-from-input)

(setq-default comint-input-ring-size 100000)

;Set the indent size to 4 spaces
(defun myindent-ess-hook ()
  (setq ess-indent-level 4))
(add-hook 'ess-mode-hook 'myindent-ess-hook)

;Enable ess-rdired
(autoload 'ess-rdired "ess-rdired"
  "View *R* objects in a dired-like buffer." t)

;Enable syntax highlighting for JAGS
(require 'ess-jags-d)

;Disable the replacement of '_' with ' <- '
(ess-toggle-underscore nil)

(require 'poly-R)
(require 'poly-markdown)

(add-to-list 'auto-mode-alist '("\\.md" .  poly-markdown-mode))
(add-to-list 'auto-mode-alist '("\\.Rnw" . poly-noweb+r-mode))
(add-to-list 'auto-mode-alist '("\\.Rmd" . poly-markdown+r-mode))


(defun mdw-mode ()
  (ess-noweb-mode)
  (setq ess-noweb-default-code-mode 'ess-julia-mode)
  (setq ess-noweb-doc-mode 'markdown-mode))

(setq auto-mode-alist (append (list (cons "\\.mdw$" 'mdw-mode))
                              auto-mode-alist))

(require 'stan-mode)



;;; Enable Octave support
(autoload 'octave-mode "octave-mod" nil t)
(setq auto-mode-alist
(cons '("\\.m$" . octave-mode) auto-mode-alist))

(add-hook 'octave-mode-hook
  (lambda ()
    (abbrev-mode 1)
    (auto-fill-mode 1)
    (if (eq window-system 'x)
      (font-lock-mode 1))))


;;; Enable ido mode
(require 'ido)

(setq ido-enable-flex-matching t)
(setq ido-everywhere t)
(ido-mode t)


;;; Replace buffer functionality with iBuffer
(defalias 'list-buffers 'ibuffer)


;;; Configure org mode
(require 'org-install)
(add-to-list 'auto-mode-alist '("\\.org$" . org-mode))
(define-key global-map "\C-cl" 'org-store-link)
(define-key global-map "\C-ca" 'org-agenda)
(setq org-log-done t)

;; Set to the location of your Org files on your local system
;(setq org-directory "~/games/magegame")
(setq org-mobile-files (list "~/games/magegame/consilium_london.org"
                             "~/games/magegame/session_notes.org"))
(setq org-mobile-directory "~/Dropbox/MobileOrg")


;;; Configure emacs for python
;(require 'ipython)
(put 'downcase-region 'disabled nil)
(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(package-selected-packages
   (quote
    (stan-snippets standoff-mode stan-mode polymode isend-mode))))
(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 )
