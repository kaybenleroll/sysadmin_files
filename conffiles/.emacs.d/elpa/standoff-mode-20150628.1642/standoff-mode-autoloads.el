;;; standoff-mode-autoloads.el --- automatically extracted autoloads
;;
;;; Code:
(add-to-list 'load-path (or (file-name-directory #$) (car load-path)))

;;;### (autoloads nil "standoff-mode" "standoff-mode.el" (22635 33104
;;;;;;  837284 263000))
;;; Generated autoloads from standoff-mode.el

(autoload 'standoff-mode "standoff-mode" "\
Stand-Off mode is an Emacs major mode for creating stand-off
markup and annotations. It makes the file (the buffer) which the
the markup refers to read only, and the markup is stored
externally (stand-off).

Since text insertion to a file linked by standoff markup is not
sensible at all, keyboard letters don't allow inserting text but
are bound to commands instead.

\\{standoff-mode-map}

\(fn)" t nil)

;;;***

;;;### (autoloads nil nil ("standoff-api.el" "standoff-dummy.el"
;;;;;;  "standoff-mode-pkg.el" "standoff-relations.el" "standoff-xml.el")
;;;;;;  (22635 33104 952917 48000))

;;;***

;; Local Variables:
;; version-control: never
;; no-byte-compile: t
;; no-update-autoloads: t
;; End:
;;; standoff-mode-autoloads.el ends here
