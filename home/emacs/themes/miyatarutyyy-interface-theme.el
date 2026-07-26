;;; miyatarutyyy-interface-theme.el --- Black and orange interface theme -*- lexical-binding: t; -*-

;;; Commentary:
;; A personal dark theme based on a black background and orange foreground.

;;; Code:

(deftheme miyatarutyyy-interface
  "A black and orange interface theme.")

(let ((bg        "#000000")
      (bg-alt    "#101010")
      (bg-soft   "#181818")
      (fg        "#F66E25")
      (fg-dim    "#A64E22")
      (fg-muted  "#7A4028")
      (accent    "#FF9A3D")
      (cyan      "#38C7B6")
      (blue      "#5CA7FF")
      (violet    "#B58AFF")
      (green     "#7ACB5A")
      (yellow    "#F2C94C")
      (red       "#FF5C57")
      (magenta   "#FF6FAE")
      (region    "#3A1B0C")
      (border    "#2A160D"))
  (custom-theme-set-faces
   'miyatarutyyy-interface

   ;; Core interface
   `(default ((t (:background ,bg :foreground ,fg))))
   `(cursor ((t (:background ,accent))))
   `(fringe ((t (:background ,bg :foreground ,fg-muted))))
   `(vertical-border ((t (:foreground ,border))))
   `(window-divider ((t (:foreground ,border))))
   `(window-divider-first-pixel ((t (:foreground ,border))))
   `(window-divider-last-pixel ((t (:foreground ,border))))
   `(region ((t (:background ,region))))
   `(highlight ((t (:background ,bg-soft))))
   `(hl-line ((t (:background ,bg-alt))))
   `(shadow ((t (:foreground ,fg-muted))))
   `(link ((t (:foreground ,blue :underline t))))
   `(escape-glyph ((t (:foreground ,yellow))))

   ;; Mode line and tab bar
   `(mode-line ((t (:background ,fg :foreground ,bg :box (:line-width 1 :color ,fg)))))
   `(mode-line-inactive ((t (:background ,bg-soft :foreground ,fg-muted :box (:line-width 1 :color ,border)))))
   `(mode-line-buffer-id ((t (:weight bold))))
   `(tab-bar ((t (:background ,bg :foreground ,fg-muted))))
   `(tab-bar-tab ((t (:background ,fg :foreground ,bg :box (:line-width 1 :color ,fg)))))
   `(tab-bar-tab-inactive ((t (:background ,bg-soft :foreground ,fg-muted :box (:line-width 1 :color ,border)))))

   ;; Line numbers and prompts
   `(line-number ((t (:background ,bg :foreground ,fg-muted))))
   `(line-number-current-line ((t (:background ,bg-alt :foreground ,accent :weight bold))))
   `(minibuffer-prompt ((t (:foreground ,accent :weight bold))))

   ;; Syntax highlighting
   `(font-lock-builtin-face ((t (:foreground ,violet))))
   `(font-lock-comment-face ((t (:foreground ,fg-muted :slant italic))))
   `(font-lock-comment-delimiter-face ((t (:foreground ,fg-muted :slant italic))))
   `(font-lock-constant-face ((t (:foreground ,yellow))))
   `(font-lock-doc-face ((t (:foreground ,fg-dim))))
   `(font-lock-function-name-face ((t (:foreground ,blue))))
   `(font-lock-keyword-face ((t (:foreground ,magenta :weight bold))))
   `(font-lock-negation-char-face ((t (:foreground ,red :weight bold))))
   `(font-lock-preprocessor-face ((t (:foreground ,violet))))
   `(font-lock-regexp-grouping-backslash ((t (:foreground ,yellow))))
   `(font-lock-regexp-grouping-construct ((t (:foreground ,magenta))))
   `(font-lock-string-face ((t (:foreground ,green))))
   `(font-lock-type-face ((t (:foreground ,cyan))))
   `(font-lock-variable-name-face ((t (:foreground ,fg))))
   `(font-lock-warning-face ((t (:foreground ,yellow :weight bold))))

   ;; Search and matching
   `(isearch ((t (:background ,yellow :foreground ,bg :weight bold))))
   `(isearch-fail ((t (:background ,red :foreground ,bg :weight bold))))
   `(lazy-highlight ((t (:background ,bg-soft :foreground ,yellow))))
   `(match ((t (:background ,bg-soft :foreground ,green :weight bold))))
   `(show-paren-match ((t (:background ,accent :foreground ,bg :weight bold))))
   `(show-paren-mismatch ((t (:background ,red :foreground ,bg :weight bold))))

   ;; Diagnostics
   `(error ((t (:foreground ,red :weight bold))))
   `(warning ((t (:foreground ,yellow :weight bold))))
   `(success ((t (:foreground ,green :weight bold))))
   `(flymake-error ((t (:underline (:style wave :color ,red)))))
   `(flymake-warning ((t (:underline (:style wave :color ,yellow)))))
   `(flymake-note ((t (:underline (:style wave :color ,blue)))))

   ;; Completion UI
   `(completions-common-part ((t (:foreground ,accent :weight bold))))
   `(completions-first-difference ((t (:foreground ,yellow :weight bold))))
   `(corfu-default ((t (:background ,bg-soft :foreground ,fg))))
   `(corfu-current ((t (:background ,fg :foreground ,bg))))
   `(corfu-border ((t (:background ,border))))
   `(corfu-popupinfo ((t (:background ,bg-alt :foreground ,fg))))
   `(corfu-popupinfo-border ((t (:background ,border))))
   `(orderless-match-face-0 ((t (:foreground ,accent :weight bold))))
   `(orderless-match-face-1 ((t (:foreground ,cyan :weight bold))))
   `(orderless-match-face-2 ((t (:foreground ,yellow :weight bold))))
   `(orderless-match-face-3 ((t (:foreground ,violet :weight bold))))
   `(marginalia-documentation ((t (:foreground ,fg-muted))))
   `(marginalia-file-name ((t (:foreground ,fg))))
   `(marginalia-key ((t (:foreground ,cyan))))
   `(marginalia-size ((t (:foreground ,yellow))))

   ;; Org
   `(org-level-1 ((t (:foreground ,accent :weight bold :height 1.18))))
   `(org-level-2 ((t (:foreground ,blue :weight bold :height 1.12))))
   `(org-level-3 ((t (:foreground ,cyan :weight bold))))
   `(org-level-4 ((t (:foreground ,green :weight bold))))
   `(org-block ((t (:background ,bg-alt :foreground ,fg))))
   `(org-block-begin-line ((t (:background ,bg-soft :foreground ,fg-muted))))
   `(org-block-end-line ((t (:background ,bg-soft :foreground ,fg-muted))))
   `(org-code ((t (:foreground ,yellow))))
   `(org-verbatim ((t (:foreground ,green))))
   `(org-link ((t (:foreground ,blue :underline t))))
   `(org-todo ((t (:foreground ,red :weight bold))))
   `(org-done ((t (:foreground ,green :weight bold))))

   ;; Dired and diff
   `(dired-directory ((t (:foreground ,blue :weight bold))))
   `(dired-symlink ((t (:foreground ,cyan))))
   `(diff-added ((t (:background "#071507" :foreground ,green))))
   `(diff-removed ((t (:background "#1A0707" :foreground ,red))))
   `(diff-changed ((t (:background "#171300" :foreground ,yellow))))
   `(diff-header ((t (:background ,bg-soft :foreground ,fg))))
   `(diff-file-header ((t (:background ,fg :foreground ,bg :weight bold))))
  ))

(custom-theme-set-variables
 'miyatarutyyy-interface
 '(ansi-color-names-vector
   ["#000000" "#FF5C57" "#7ACB5A" "#F2C94C"
    "#5CA7FF" "#FF6FAE" "#38C7B6" "#F66E25"]))

;;;###theme-autoload
(when load-file-name
  (add-to-list 'custom-theme-load-path
               (file-name-directory load-file-name)))

(provide-theme 'miyatarutyyy-interface)

;;; miyatarutyyy-interface-theme.el ends here
