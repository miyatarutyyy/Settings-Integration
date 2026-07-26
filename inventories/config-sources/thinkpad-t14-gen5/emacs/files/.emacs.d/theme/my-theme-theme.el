;;; my-theme-theme.el --- My custom theme -*- lexical-binding: t; -*-

(deftheme my-theme
  "My custom theme .")

(custom-theme-set-faces
 'my-theme

 '(default ((t (:background "#000000" :foreground "#F66E25"))))
 '(cursor ((t (:background "#F66E25"))))
 '(fringe ((t (:background "#000000"))))
 '(highlight ((t (:background "#241006" :foreground "#FFD166"))))
 '(link ((t (:foreground "#00D7C7" :underline t))))
 '(minibuffer-prompt ((t (:foreground "#00D7C7" :weight bold))))
 '(region ((t (:background "#3A1B0A" :foreground "#FFD166"))))
 '(line-number ((t (:background "#000000" :foreground "#3A3A3A"))))
 '(line-number-current-line ((t (:background "#000000" :foreground "#5A5A5A" :weight bold))))
 '(font-lock-builtin-face ((t (:foreground "#C9A227"))))
 '(font-lock-comment-face ((t (:foreground "#7A4A32"))))
 '(font-lock-comment-delimiter-face ((t (:foreground "#7A4A32"))))
 '(font-lock-constant-face ((t (:foreground "#FFD166"))))
 '(font-lock-doc-face ((t (:foreground "#E6A15C"))))
 '(font-lock-escape-face ((t (:foreground "#FFD166"))))
 '(font-lock-function-call-face ((t (:foreground "#00D7C7"))))
 '(font-lock-function-name-face ((t (:foreground "#00D7C7"))))
 '(font-lock-keyword-face ((t (:foreground "#FFB000"))))
 '(font-lock-number-face ((t (:foreground "#FFD166"))))
 '(font-lock-operator-face ((t (:foreground "#F66E25"))))
 '(font-lock-preprocessor-face ((t (:foreground "#FFB000"))))
 '(font-lock-property-name-face ((t (:foreground "#FF8A3D"))))
 '(font-lock-property-use-face ((t (:foreground "#FF8A3D"))))
 '(font-lock-string-face ((t (:foreground "#E6A15C"))))
 '(font-lock-type-face ((t (:foreground "#C9A227"))))
 '(font-lock-variable-name-face ((t (:foreground "#FF8A3D"))))
 '(font-lock-variable-use-face ((t (:foreground "#F66E25"))))
 '(font-lock-warning-face ((t (:foreground "#FF3B1F" :weight bold))))
 '(tab-line ((t (:background "#000000" :foreground "#7A4A32" :box nil))))
 '(tab-line-tab ((t (:background "#241006" :foreground "#FFD166" :weight bold))))
 '(tab-line-tab-current ((t (:background "#F66E25" :foreground "#000000" :weight bold))))
 '(tab-line-tab-inactive ((t (:background "#000000" :foreground "#7A4A32"))))
 '(tab-line-highlight ((t (:background "#3A1B0A" :foreground "#FFD166"))))
 '(tab-line-close-highlight ((t (:background "#FF3B1F" :foreground "#000000" :weight bold))))
 '(tab-line-tab-modified ((t (:foreground "#39FF14" :weight bold))))
 '(mode-line ((t (:background "#F66E25" :foreground "#000000"))))
 '(mode-line-inactive ((t (:background "#241006" :foreground "#F66E25"))))
 )

(provide-theme 'my-theme)

;;; my-theme-theme.el ends here
