
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


(define-key key-translation-map [?\C-h] [?\C-?])


;;; Remove trailing whitespace
(add-hook 'before-save-hook 'delete-trailing-whitespace)

;;; Enable textile support
(add-to-list 'load-path "~/.emacs.d/library")

(require 'textile-mode)

(add-to-list 'auto-mode-alist '("\\.textile\\'" . textile-mode))


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
