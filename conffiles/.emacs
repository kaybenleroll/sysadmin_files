
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

(add-to-list 'load-path "~/.emacs.d/library")

(require 'textile-mode)

(add-to-list 'auto-mode-alist '("\\.textile\\'" . textile-mode))


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


;;; Configuration options for ESS

(setq ess-eval-visibly-p nil)        ;otherwise C-c C-r (eval region) takes forever
(setq ess-ask-for-ess-directory nil) ;otherwise you are prompted each time you start an interactive R session


(define-key key-translation-map [?\C-h] [?\C-?]) ;disable keybindings
(setq comint-input-ring-size 100000)             ;Set the size of .Rhistory to 100000


;Set the indent size to 4 spaces
(defun myindent-ess-hook ()
    (setq ess-indent-level 4))

(add-hook 'ess-mode-hook 'myindent-ess-hook)
