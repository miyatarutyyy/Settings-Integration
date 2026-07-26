;;; init.el --- Main configuration -*- lexical-binding: t; -*-

;;; Commentary:
;; Personal Emacs configuration for miyatarutyyy.

;;; Code:

;;; ==========================================================
;;; Basic Settings
;;; ==========================================================

(setq custom-file (locate-user-emacs-file "custom.el"))
(when (file-exists-p custom-file)
  (load custom-file))

;; Disable backup files and else
(setq make-backup-files nil
      create-lockfiles nil)

;; Put auto-save files in ~/.emacs.d/auto-save-list/
(make-directory (locate-user-emacs-file "auto-save-list/") t)

(setq auto-save-default t
      auto-save-file-name-transforms
      `((".*" ,(locate-user-emacs-file "auto-save-list/") t)))

;; Disable ring bell alert sound
(setq ring-bell-function #'ignore)

;; Use space instead of tabs
(setq-default indent-tabs-mode nil
	          tab-width 4)

;; Save the cursor's previous position
(save-place-mode 1)

;; Save previous opening files
(recentf-mode 1)

;; Reload automatically when the file has been changed
(global-auto-revert-mode 1)

;; Ask Question through Emacs mini buffer
(setq use-dialog-box nil)

;; y-or-n instead of yes-or-no
(setq use-short-answers t)

;;; ==========================================================
;;; straight.el bootstrap
;;; ==========================================================

(defvar bootstrap-version)

(let ((bootstrap-file
       (expand-file-name
        "straight/repos/straight.el/bootstrap.el"
        user-emacs-directory))
      (bootstrap-version 7))
  (unless (file-exists-p bootstrap-file)
    (with-current-buffer
        (url-retrieve-synchronously
         "https://raw.githubusercontent.com/radian-software/straight.el/develop/install.el"
         'silent 'inhibit-cookies)
      (goto-char (point-max))
      (eval-print-last-sexp)))
  (load bootstrap-file nil 'nomessage))

(setq straight-use-package-by-default t)

(straight-use-package 'use-package)

(require 'use-package)

;;; ==========================================================
;;; Org publishing
;;; ==========================================================

(use-package ox-hub
  :straight (:type git
                   :host github
                   :repo "miyatarutyyy/my-ox-hub"
                   :branch "master"
                   :files ("ox-hub.el"))
  :commands
  (ox-hub-new-article
   ox-hub-export-current-buffer
   ox-hub-export-current-buffer-to-zenn
   ox-hub-export-current-buffer-to-qiita))

;;; ==========================================================
;;; UI
;;; ==========================================================

;; Load my original theme
(add-to-list 'custom-theme-load-path
             (locate-user-emacs-file "theme/"))

(load-theme 'my-theme t)

(set-fringe-mode 10)

(global-display-line-numbers-mode 1)

;; Change line-number color depending on whether the buffer is editable.
(defvar-local my/editable-line-number-face-cookie nil
  "Face remap cookie for line numbers in editable buffers.")

(defvar-local my/editable-current-line-number-face-cookie nil
  "Face remap cookie for the current line number in editable buffers.")

(defun my/update-line-number-color-by-read-only ()
  "Use subdued line numbers in read-only buffers, vivid ones in editable buffers."
  ;; Remove previous temporary overrides.
  (when my/editable-line-number-face-cookie
    (face-remap-remove-relative my/editable-line-number-face-cookie)
    (setq my/editable-line-number-face-cookie nil))

  (when my/editable-current-line-number-face-cookie
    (face-remap-remove-relative my/editable-current-line-number-face-cookie)
    (setq my/editable-current-line-number-face-cookie nil))

  (if buffer-read-only
      (progn
        (setq my/editable-line-number-face-cookie
              (face-remap-add-relative
               'line-number
               '(:foreground "#3A3A3A")))

        (setq my/editable-current-line-number-face-cookie
              (face-remap-add-relative
               'line-number-current-line
               '(:foreground "#5A5A5A" :weight bold))))
    (setq my/editable-line-number-face-cookie
          (face-remap-add-relative
           'line-number
           '(:foreground "#6F7A1F")))

    (setq my/editable-current-line-number-face-cookie
          (face-remap-add-relative
           'line-number-current-line
           '(:foreground "#39FF14" :weight bold)))))

(add-hook 'read-only-mode-hook
          #'my/update-line-number-color-by-read-only)

(add-hook 'find-file-hook
          #'my/update-line-number-color-by-read-only)

(add-hook 'after-change-major-mode-hook
          #'my/update-line-number-color-by-read-only)

;; Do not visually wrap long lines
(setq-default truncate-lines t)

;; Disable line numbers in special buffers
(dolist (mode '(term-mode-hook
                vterm-mode-hook
                shell-mode-hook
                eshell-mode-hook
                help-mode-hook
                treemacs-mode-hook))
  (add-hook mode (lambda ()
                   (display-line-numbers-mode 0))))

;; Keep the mode line compact and put Git state before the buffer name.
(require 'subr-x)

(defun my/mode-line-git-branch ()
  "Return the current Git branch for `mode-line-format'."
  (when-let* ((raw (and vc-mode
                        (string-trim
                         (if (stringp vc-mode)
                             vc-mode
                           (format-mode-line vc-mode)))))
              (_ (not (string-empty-p raw))))
    (when (string-match-p "\\`Git[:-]?" raw)
      (setq raw (string-trim (replace-regexp-in-string "\\`Git[:-]?" "" raw)))
      (unless (string-empty-p raw)
        (concat "Git: " raw)))))

(setq-default mode-line-format
              '("%e"
                mode-line-front-space
                mode-line-mule-info
                mode-line-client
                mode-line-modified
                mode-line-remote
                mode-line-frame-identification
                " | "
                (:eval
                 (when-let ((branch (my/mode-line-git-branch)))
                   (concat branch " | ")))
                mode-line-buffer-identification
                " | "
                mode-line-modes
                (:eval
                 (unless (string-empty-p
                          (string-trim (format-mode-line mode-line-misc-info)))
                   " | "))
                mode-line-misc-info
                mode-line-end-spaces))

;; Browser-like buffer tabs.
(use-package tab-line
  :straight nil
  :demand t
  :bind
  (("C-x C-f" . tab-line-switch-to-next-tab)
   ("C-x C-b" . tab-line-switch-to-prev-tab))
  :custom
  (tab-line-close-button-show t)
  (tab-line-new-button-show nil)
  (tab-line-switch-cycling t)
  (tab-line-tab-name-truncated-max 24)
  (tab-line-tabs-function #'my/tab-line-tabs-project-buffers)
  (tab-line-exclude-modes
   '(completion-list-mode
     help-mode
     treemacs-mode
     vterm-mode
     term-mode
     shell-mode
     eshell-mode
     magit-status-mode
     magit-diff-mode
     magit-log-mode))
  :init
  (require 'project)

  (defvar my/tab-line-hidden-buffer-name-regexp
    (rx string-start (or "*" " "))
    "Regexp for buffer names hidden from the tab line.")

  (defun my/tab-line-buffer-project-root (buffer)
    "Return BUFFER's project root, or nil when BUFFER is outside a project."
    (when (buffer-live-p buffer)
      (with-current-buffer buffer
        (let ((project (project-current nil)))
          (when project
            (expand-file-name (project-root project)))))))

  (defun my/tab-line-buffer-visible-p (buffer)
    "Return non-nil when BUFFER should be shown as a tab."
    (and (buffer-live-p buffer)
         (not (string-match-p my/tab-line-hidden-buffer-name-regexp
                              (buffer-name buffer)))
         (with-current-buffer buffer
           (and (not (minibufferp))
                (not (memq major-mode tab-line-exclude-modes))
                (not tab-line-exclude)
                (or buffer-file-name
                    (derived-mode-p 'prog-mode 'text-mode))))))

  (defun my/tab-line-tabs-project-buffers ()
    "Return visible buffers from the current project for `tab-line'."
    (if (not (my/tab-line-buffer-visible-p (current-buffer)))
        nil
      (let* ((current-root (my/tab-line-buffer-project-root (current-buffer)))
             (buffers
              (seq-filter
               (lambda (buffer)
                 (and (my/tab-line-buffer-visible-p buffer)
                      (if current-root
                          (equal (my/tab-line-buffer-project-root buffer)
                                 current-root)
                        (not (my/tab-line-buffer-project-root buffer)))))
               (tab-line-tabs-buffer-list))))
        (if (memq (current-buffer) buffers)
            buffers
          (cons (current-buffer) buffers)))))
  :config
  (global-tab-line-mode 1))

;; Smooth scrolling (keyboard, mouse, trackpad).
(setq scroll-conservatively 3
      scroll-margin 0
      scroll-step 1
      scroll-preserve-screen-position t
      pixel-scroll-precision-interpolate-page t)
(pixel-scroll-precision-mode 1)

(use-package ultra-scroll
  :demand t
  :config
  (ultra-scroll-mode 1))

(use-package scroll-on-jump
  :demand t
  :custom
  (scroll-on-jump-duration 0.12)
  (scroll-on-jump-smooth t)
  :config
  (dolist (command '(next-line
                     previous-line
                     recenter-top-bottom
                     beginning-of-buffer
                     end-of-buffer))
    (advice-add command :around #'scroll-on-jump-advice--wrapper))
  (dolist (command '(scroll-up-command
                     scroll-down-command))
    (advice-add command :around #'scroll-on-jump-advice--with-scroll-wrapper)))

;; Set the default font size
(set-face-attribute 'default nil :height 100)

;;; ==========================================================
;;; Keybindings
;;; ==========================================================

;; Use C-h as Backspace
(define-key key-translation-map (kbd "C-h") (kbd "<DEL>"))

;; Move Help from C-h to C-c h
(define-key global-map (kbd "C-c h") help-map)

;;; ==========================================================
;;; Japanese input: NSKK
;;; ==========================================================

(use-package nskk
  :straight (:type git
                   :host github
                   :repo "takeokunn/nskk.el"
                   :files ("src/*.el"))
  :demand t
  :custom
  (nskk-state-default-mode 'ascii)
  (nskk-dict-system-dictionary-files
   '("/usr/share/skk/SKK-JISYO.L"
     "/usr/share/skk/SKK-JISYO.jinmei"
     "/usr/share/skk/SKK-JISYO.geo"))
  (nskk-dict-user-dictionary-file
   (locate-user-emacs-file "nskk-jisyo"))
  (nskk-henkan-show-candidates-nth 2)
  (nskk-dict-cache-enabled t)
  :config
  (nskk-global-mode 1))

;;; ===========================================================================
;;; Completion minibuffer: vertico / orderless / marginalia / consult / embark
;;; ===========================================================================

(use-package vertico
  :init
  (vertico-mode 1))

(use-package orderless
  :custom
  (completion-styles '(orderless basic))
  (completion-category-defaults nil)
  (completion-category-overrides '((file (styles basic partial-completion)))))

(use-package marginalia
  :init
  (marginalia-mode 1))

(use-package consult
  :bind
  (("C-s" . consult-line)
   ("C-x b" . consult-buffer)
   ("M-y" . consult-yank-pop)
   ("M-g g" . consult-goto-line)
   ("M-g i" . consult-imenu)
   ("M-g r" . consult-ripgrep)))

(use-package embark
  :bind
  (("C-." . embark-act)
   ("C-;" . embark-dwim)
   ("C-c e b" . embark-bindings)))

(use-package embark-consult
  :after (embark consult))

;;; ==========================================================
;;; In-buffer completion: corfu / cape
;;; ==========================================================

(use-package corfu
  :custom
  (corfu-auto t)
  (corfu-auto-delay 0.2)
  (corfu-auto-prefix 2)
  (corfu-cycle t)
  (corfu-preview-current nil)
  (corfu-on-exact-match nil)
  :bind
  (:map corfu-map
        ("TAB" . corfu-complete)
        ([tab] . corfu-complete)
        ("RET" . nil))
  :init
  (global-corfu-mode 1))

(use-package cape
  :init
  (add-to-list 'completion-at-point-functions #'cape-file t))

;;; ==========================================================
;;; Project
;;; ==========================================================

(use-package project
  :straight nil
  :bind
  (("C-c p f" . project-find-file)
   ("C-c p b" . project-switch-to-buffer)
   ("C-c p p" . project-switch-project)
   ("C-c p g" . project-find-regexp)
   ("C-c p d" . project-dired)))

;;; ==========================================================
;;; Programming support: eglot / flymake / treesit / apheleia
;;; ==========================================================

;; ----------------------------------------------------------
;; LSP client: Eglot
;; ----------------------------------------------------------
;; Eglot is built into Emacs 29+.
;; Language servers themselves must be installed separately.
(use-package eglot
  :straight nil
  :hook
  ((html-ts-mode . eglot-ensure)
   (css-ts-mode . eglot-ensure)
   (js-ts-mode . eglot-ensure)
   (typescript-ts-mode . eglot-ensure)
   (tsx-ts-mode . eglot-ensure)
   (python-mode . eglot-ensure)
   (python-ts-mode . eglot-ensure)
   (c-ts-mode . eglot-ensure)
   (java-ts-mode . eglot-ensure)
   (json-ts-mode . eglot-ensure)
   (yaml-ts-mode . eglot-ensure)
   (yaml-mode . eglot-ensure))
  :custom
  (eglot-autoshutdown t))

;; ----------------------------------------------------------
;; Diagnostics
;; ----------------------------------------------------------
(use-package flymake
  :straight nil
  :hook
  (prog-mode . flymake-mode)
  :bind
  (:map flymake-mode-map
        ("M-n" . flymake-goto-next-error)
        ("M-p" . flymake-goto-prev-error)))

;; ----------------------------------------------------------
;; Formatter runner
;; ----------------------------------------------------------
(use-package apheleia
  :config
  (apheleia-global-mode 1))

;; YAML support.
;; yaml-ts-mode is used when available.
;; yaml-mode is installed as a fallback.
(use-package yaml-mode
  :mode "\\.ya?ml\\'")

;; ----------------------------------------------------------
;; Tree-sitter major mode remapping
;; ----------------------------------------------------------
;; Emacs 29+ has many built-in tree-sitter major modes.
;; This helper only adds remaps when the target mode exists,
;; so the config does not break on older Emacs builds.

(defun my/remap-major-mode-if-available (from-mode to-mode)
  "Remap FROM-MODE to TO-MODE when TO-MODE is available."
  (when (fboundp to-mode)
    (add-to-list 'major-mode-remap-alist
                 (cons from-mode to-mode))))

;; ----------------------------------------------------------
;; Tree-sitter grammars
;; ----------------------------------------------------------
(use-package treesit
  :straight nil
  :init
  ;; Avoid `customize-set-variable' here: reapplying this via `eval-buffer'
  ;; refontifies existing tree-sitter buffers, and python-ts-mode currently
  ;; trips a query incompatibility in Emacs 30.2 + libtree-sitter 0.26.
  (setq treesit-font-lock-level 4)
  :config
  (setq treesit-language-source-alist
        '((html       "https://github.com/tree-sitter/tree-sitter-html")
          (css        "https://github.com/tree-sitter/tree-sitter-css")
          (javascript "https://github.com/tree-sitter/tree-sitter-javascript")
          (typescript "https://github.com/tree-sitter/tree-sitter-typescript" "master" "typescript/src")
          (tsx        "https://github.com/tree-sitter/tree-sitter-typescript" "master" "tsx/src")
          (python     "https://github.com/tree-sitter/tree-sitter-python")
          (c          "https://github.com/tree-sitter/tree-sitter-c")
          (cpp        "https://github.com/tree-sitter/tree-sitter-cpp")
          (java       "https://github.com/tree-sitter/tree-sitter-java")
          (json       "https://github.com/tree-sitter/tree-sitter-json")
          (yaml       "https://github.com/ikatyang/tree-sitter-yaml"))))

(my/remap-major-mode-if-available 'html-mode       'html-ts-mode)
(my/remap-major-mode-if-available 'css-mode        'css-ts-mode)
(my/remap-major-mode-if-available 'js-mode         'js-ts-mode)
(my/remap-major-mode-if-available 'javascript-mode 'js-ts-mode)
(my/remap-major-mode-if-available 'typescript-mode 'typescript-ts-mode)
;; Remove any python-ts-mode remap left behind by earlier `eval-buffer' runs.
;; The built-in python-ts-mode queries are currently incompatible with this
;; Emacs/libtree-sitter combination.
(setq major-mode-remap-alist
      (assq-delete-all 'python-mode major-mode-remap-alist))
(my/remap-major-mode-if-available 'c-mode          'c-ts-mode)
(my/remap-major-mode-if-available 'java-mode       'java-ts-mode)
(my/remap-major-mode-if-available 'json-mode       'json-ts-mode)
(my/remap-major-mode-if-available 'yaml-mode       'yaml-ts-mode)

;; File associations for modes that are not always covered by default.
(add-to-list 'auto-mode-alist '("\\.ts\\'"    . typescript-ts-mode))
(add-to-list 'auto-mode-alist '("\\.jsx\\'"   . tsx-ts-mode))
(add-to-list 'auto-mode-alist '("\\.tsx\\'"   . tsx-ts-mode))
(add-to-list 'auto-mode-alist '("\\.ya?ml\\'" . yaml-mode))

;; Extra highlighting for JavaScript/TypeScript property accesses that are not
;; covered by the compatible tree-sitter feature set below.
(defconst my/typescript-extra-font-lock-keywords
  '(("\\.\\s-*\\([[:alpha:]_$][[:alnum:]_$]*\\)" 1 'font-lock-property-use-face)
    ("\\_<[0-9]+\\(?:\\.[0-9]+\\)?\\_>" 0 'font-lock-number-face)))

;; Work around Emacs 30.2 + libtree-sitter 0.26 query incompatibility.
;; Keep this scoped to TypeScript/TSX so other tree-sitter modes can use
;; the global `treesit-font-lock-level' setting.  The bundled TypeScript
;; `constant' and `number' queries are rejected by this libtree-sitter
;; version, but the remaining level-4 features are useful and stable.
(defun my/typescript-ts-font-lock-workaround ()
  "Use full TypeScript/TSX font-lock except incompatible query features."
  (setq-local treesit-font-lock-level 4)
  (setq-local treesit-font-lock-feature-list
              (mapcar
               (lambda (features)
                 (let ((filtered (copy-sequence features)))
                   (dolist (feature '(constant number) filtered)
                     (setq filtered (delq feature filtered)))))
               treesit-font-lock-feature-list))
  (treesit-font-lock-recompute-features)
  (font-lock-add-keywords nil my/typescript-extra-font-lock-keywords 'append)
  (font-lock-flush))

(add-hook 'typescript-ts-mode-hook #'my/typescript-ts-font-lock-workaround)
(add-hook 'tsx-ts-mode-hook #'my/typescript-ts-font-lock-workaround)

;;; ==========================================================
;;; Git
;;; ==========================================================

(use-package magit
  :bind
  (("C-x g" . magit-status)))

(use-package diff-hl
  :hook
  ((prog-mode . diff-hl-mode)
   (text-mode . diff-hl-mode)
   (magit-post-refresh . diff-hl-magit-post-refresh))
  :config
  (diff-hl-flydiff-mode 1))

;;; ==========================================================
;;; File tree
;;; ==========================================================

(use-package treemacs
  :bind
  (("C-c t t" . treemacs)))

(use-package treemacs-magit
  :after (treemacs magit))

;;; ==========================================================
;;; Go to my init.el
;;; ==========================================================

(defun my/open-init-el ()
  "Open the current Emacs init file."
  (interactive)
  (find-file user-init-file))

;;; ==========================================================
;;; Clipboard
;;; ==========================================================

(setq select-enable-clipboard t
      save-interprogram-paste-before-kill t)

(defun my/wayland-clipboard-available-p ()
  "Return non-nil when Wayland clipboard commands are available."
  (and (getenv "WAYLAND_DISPLAY")
       (getenv "XDG_RUNTIME_DIR")
       (executable-find "wl-copy")
       (executable-find "wl-paste")))

(defun my/wayland-clipboard-copy (text)
  "Copy TEXT to the Wayland clipboard using wl-copy."
  (with-temp-buffer
    (insert text)
    (call-process-region (point-min) (point-max) "wl-copy" nil nil nil)))

(defun my/wayland-clipboard-paste ()
  "Return text from the Wayland clipboard using wl-paste."
  (with-timeout (1 nil)
    (with-temp-buffer
      (when (zerop (call-process "wl-paste" nil t nil "--no-newline"))
        (let ((text (buffer-string)))
          (unless (string-empty-p text)
            text))))))

(when (my/wayland-clipboard-available-p)
  (setq interprogram-cut-function #'my/wayland-clipboard-copy
        interprogram-paste-function #'my/wayland-clipboard-paste))

;;; ==========================================================
;;; Terminal
;;; ==========================================================

(use-package vterm
  :commands
  (vterm
   vterm-other-window)
  :bind
  (("C-c w c" . my/codex-workspace-layout))
  :custom
  (vterm-always-compile-module t)
  (vterm-kill-buffer-on-exit t)
  :config
  (require 'project)
  (require 'seq)

  (with-eval-after-load 'vterm
    ;; paste
    (define-key vterm-mode-map (kbd "C-y") #'vterm-yank)
    (define-key vterm-mode-map (kbd "M-y") #'vterm-yank-pop)

    ;; copy mode
    (define-key vterm-mode-map (kbd "C-c C-y") #'vterm-copy-mode)
    (define-key vterm-mode-map (kbd "C-c C-c") #'vterm-send-C-c)

    ;; Emacs-like keys inside vterm-copy-mode
    (define-key vterm-copy-mode-map (kbd "M-w") #'kill-ring-save)
    (define-key vterm-copy-mode-map (kbd "C-w") #'kill-region)
    (define-key vterm-copy-mode-map (kbd "C-y") #'yank)
    (define-key vterm-copy-mode-map (kbd "q") #'vterm-copy-mode))

  (defun my/vterm-switch (buffer-name directory)
    "Switch to vterm BUFFER-NAME, creating it in DIRECTORY when needed."
    (let ((default-directory directory)
          (vterm-buffer-name buffer-name))
      (vterm)))

  (defun my/buffer-project-directory (buffer)
    "Return BUFFER's project root or `default-directory'."
    (with-current-buffer buffer
      (if-let ((project (project-current nil)))
          (expand-file-name (project-root project))
        default-directory)))

  (defun my/workspace-edit-buffer ()
    "Return the buffer that should stay in the editor window."
    (if (not (derived-mode-p 'vterm-mode))
        (current-buffer)
      (or (seq-find #'my/tab-line-buffer-visible-p (buffer-list))
          (current-buffer))))

  (defun my/codex-workspace-layout ()
    "Arrange a Codex vterm, a CLI vterm, and the current edit buffer."
    (interactive)
    (let* ((edit-buffer (my/workspace-edit-buffer))
           (directory (my/buffer-project-directory edit-buffer))
           (left-top (selected-window))
           (right (progn
                    (delete-other-windows)
                    (split-window left-top nil 'right)))
           (cli-height (max 10 (floor (/ (window-total-height left-top) 3))))
           (left-bottom (split-window left-top (- cli-height) 'below)))
      (select-window left-top)
      (my/vterm-switch "*vterm-codex*" directory)
      (select-window left-bottom)
      (my/vterm-switch "*vterm-cli*" directory)
      (set-window-buffer right edit-buffer)
      (select-window right))))

;;; ==========================================================
;;; AI
;;; ==========================================================

(require 'auth-source)

(defun my/set-iniad-openai-api-key-from-auth-source ()
  "Set INIAD_OPENAI_API_KEY from auth-source.

Expected entry in ~/.authinfo.gpg:

  machine iniad-openai login apikey password YOUR_API_KEY
"
  (let* ((found (car (auth-source-search
                      :host "iniad-openai"
                      :user "apikey"
                      :require '(:secret))))
         (secret (plist-get found :secret)))
    (when secret
      (setenv "INIAD_OPENAI_API_KEY"
              (if (functionp secret)
                  (funcall secret)
                secret)))))

(condition-case err
    (my/set-iniad-openai-api-key-from-auth-source)
  (error
   (message "Could not load INIAD_OPENAI_API_KEY from auth-source: %s"
            (error-message-string err))))

(use-package gptel
  :ensure t
  :config
  (defun my/gptel-iniad-api-key ()
    (or (getenv "INIAD_OPENAI_API_KEY")
        (user-error "INIAD_OPENAI_API_KEY is not set")))

  ;; INIAD OpenAI-compatible API
  ;; GPT-5.4 / o4-mini などはこちら
  (defvar my/gptel-iniad-openai-backend
    (gptel-make-openai "INIAD OpenAI"
      :host "api.openai.iniad.org"
      :endpoint "/api/v1/chat/completions"
      :protocol "https"
      :key #'my/gptel-iniad-api-key
      :stream t
      :models '("o4-mini"
                "gpt-5.4"
                "gpt-5.4-mini"
                "gpt-5.4-nano")))

  ;; INIAD Anthropic-compatible API
  ;; Claude Sonnet 4.6 はこちら
  (defvar my/gptel-iniad-anthropic-backend
    (gptel-make-anthropic "INIAD Anthropic"
      :host "api.anthropic.iniad.org"
      :endpoint "/api/v1/messages"
      :protocol "https"
      :key #'my/gptel-iniad-api-key
      :stream t
      :models '("claude-sonnet-4-6")))

  (setq gptel-backend my/gptel-iniad-openai-backend
        gptel-model "gpt-5.4"))

;;; ----------------------------------------------------------
;;; AI-assisted Magit commit planning
;;; ----------------------------------------------------------

(defgroup my/magit-ai nil
  "AI-assisted commit planning and commit message generation for Magit."
  :group 'tools)

(defcustom my/magit-ai-default-commit-style 'conventional-japanese
  "Default commit message style for `my/magit-ai-insert-commit-message'."
  :type '(choice
          (const :tag "Conventional Commit / Japanese" conventional-japanese)
          (const :tag "Conventional Commit / English" conventional-english)
          (const :tag "Plain Commit / Japanese" plain-japanese)
          (const :tag "Plain Commit / English" plain-english))
  :group 'my/magit-ai)

(defcustom my/magit-ai-max-diff-chars 120000
  "Maximum number of diff characters sent to the AI model."
  :type 'integer
  :group 'my/magit-ai)

(defconst my/magit-ai-commit-style-candidates
  '("conventional-japanese"
    "conventional-english"
    "plain-japanese"
    "plain-english")
  "Commit message styles supported by my Magit AI helpers.")

(defun my/magit-ai--git-root ()
  "Return the current Git repository root."
  (or (and (fboundp 'magit-toplevel)
           (magit-toplevel))
      (locate-dominating-file default-directory ".git")
      (user-error "This buffer is not inside a Git repository")))

(defun my/magit-ai--git-string (root &rest args)
  "Run git with ARGS in ROOT and return its output as a string."
  (with-temp-buffer
    (let ((default-directory root)
          (exit-code (apply #'process-file "git" nil t nil args)))
      (unless (zerop exit-code)
        (user-error "git %s failed:\n%s"
                    (string-join args " ")
                    (string-trim (buffer-string))))
      (buffer-string))))

(defun my/magit-ai--truncate (text)
  "Truncate TEXT so it fits within `my/magit-ai-max-diff-chars'."
  (if (<= (length text) my/magit-ai-max-diff-chars)
      text
    (concat
     (substring text 0 my/magit-ai-max-diff-chars)
     "\n\n[TRUNCATED: diff was longer than my/magit-ai-max-diff-chars]\n")))

(defun my/magit-ai--repo-context (&optional staged-only)
  "Return Git status and diff context.
When STAGED-ONLY is non-nil, include only the staged diff."
  (let* ((root (my/magit-ai--git-root))
         (status (my/magit-ai--git-string root "status" "--short"))
         (staged (my/magit-ai--git-string root "diff" "--staged" "--"))
         (unstaged (unless staged-only
                     (my/magit-ai--git-string root "diff" "--"))))
    (when (and staged-only (string-empty-p (string-trim staged)))
      (user-error "There is no staged diff. Stage changes in Magit first"))
    (my/magit-ai--truncate
     (concat
      "Repository root:\n" root "\n\n"
      "git status --short:\n"
      (if (string-empty-p (string-trim status))
          "[clean]\n"
        status)
      "\n\n"
      "git diff --staged --:\n"
      (if (string-empty-p (string-trim staged))
          "[no staged changes]\n"
        staged)
      (unless staged-only
        (concat
         "\n\n"
         "git diff --:\n"
         (if (string-empty-p (string-trim unstaged))
             "[no unstaged changes]\n"
           unstaged)))))))

(defun my/magit-ai--request (prompt system callback)
  "Send PROMPT to gptel with SYSTEM and call CALLBACK with the response."
  (require 'gptel)
  (unless (fboundp 'gptel-request)
    (user-error "gptel-request is not available"))
  (message "Requesting AI assistance for Git changes...")
  (gptel-request
      prompt
    :system system
    :callback
    (lambda (response info)
      (if (not response)
          (message "AI request failed: %S" info)
        (funcall callback (string-trim response))))))

(defun my/magit-ai--show-buffer (buffer-name title body)
  "Show BODY in BUFFER-NAME with TITLE."
  (let ((buffer (get-buffer-create buffer-name)))
    (with-current-buffer buffer
      (let ((inhibit-read-only t))
        (erase-buffer)
        (insert title "\n"
                (make-string (length title) ?=)
                "\n\n"
                body
                "\n")
        (goto-char (point-min))
        (text-mode)
        (view-mode 1)))
    (display-buffer buffer)))

(defun my/magit-ai--commit-style-label (style)
  "Return a human-readable label for commit STYLE."
  (pcase style
    ('conventional-japanese "Conventional Commit / Japanese")
    ('conventional-english "Conventional Commit / English")
    ('plain-japanese "Plain Commit / Japanese")
    ('plain-english "Plain Commit / English")
    (_ (symbol-name style))))

(defun my/magit-ai-read-commit-style ()
  "Read a commit message style from the minibuffer."
  (intern
   (completing-read
    "Commit message style: "
    my/magit-ai-commit-style-candidates
    nil t nil nil
    (symbol-name my/magit-ai-default-commit-style))))

(defun my/magit-ai-set-default-commit-style ()
  "Set the default commit message style used by my Magit AI helpers."
  (interactive)
  (setq my/magit-ai-default-commit-style
        (my/magit-ai-read-commit-style))
  (message "Default Magit AI commit style: %s"
           (my/magit-ai--commit-style-label
            my/magit-ai-default-commit-style)))

(defun my/magit-ai--plan-system-prompt ()
  "Return the system prompt for commit planning."
  "You are an expert software maintainer helping a developer design a clean Git history.

Analyze the provided git status, staged diff, and unstaged diff.
Propose an appropriate commit split.

Rules:
- Do not invent changes that are not present in the diff.
- Prefer small, reviewable commits.
- Separate unrelated concerns.
- Do not split mechanically by file when one logical change spans multiple files.
- Do not combine unrelated changes merely because they touch the same file.
- Explain why each commit boundary exists.
- Give concrete staging guidance, but do not output shell commands that mutate the repository.
- If the diff is too broad, risky, or truncated, say so clearly.
- For each proposed commit, provide four message candidates:
  1. Conventional Commit in Japanese
  2. Conventional Commit in English
  3. Plain Japanese
  4. Plain English

Output in this exact structure:

# Summary

# Proposed commits

## Commit 1
Purpose:
Files:
Why this boundary:
Suggested staging:
Messages:
- conventional_ja:
- conventional_en:
- plain_ja:
- plain_en:")

(defun my/magit-ai-suggest-commit-plan ()
  "Ask the AI to propose commit granularity, staging boundaries, and messages."
  (interactive)
  (let ((context (my/magit-ai--repo-context nil)))
    (my/magit-ai--request
     context
     (my/magit-ai--plan-system-prompt)
     (lambda (response)
       (my/magit-ai--show-buffer
        "*magit-ai-commit-plan*"
        "Magit AI Commit Plan"
        response)))))

(defun my/magit-ai--message-system-prompt (style)
  "Return the system prompt for commit message generation using STYLE."
  (concat
   "You are an expert at writing Git commit messages.

Generate a commit message from the staged diff only.

Hard rules:
- Use only the staged diff as evidence.
- Do not mention unstaged changes.
- Do not invent changes that are not present in the diff.
- Output only the commit message.
- Do not include markdown fences.
- Do not include explanations.
- Prefer intent and user-visible effect over low-level implementation details.

Selected style: "
   (my/magit-ai--commit-style-label style)
   "\n\n"
   (pcase style
     ('conventional-japanese
      "Style rules:
- Write the message in Japanese.
- Use Conventional Commits.
- Keep the type prefix in English, such as feat:, fix:, docs:, refactor:, chore:, test:.
- If a scope is useful, use type(scope): summary.
- Write the summary after the prefix in Japanese.")
     ('conventional-english
      "Style rules:
- Write the entire message in English.
- Use Conventional Commits.
- If a scope is useful, use type(scope): summary.")
     ('plain-japanese
      "Style rules:
- Write the message in Japanese.
- Do not use Conventional Commit prefixes such as feat:, fix:, docs:, refactor:.
- First line should be a concise summary.
- Add a blank line and a short body only when it improves clarity.")
     ('plain-english
      "Style rules:
- Write the message in English.
- Do not use Conventional Commit prefixes such as feat:, fix:, docs:, refactor:.
- First line should be a concise summary.
- Add a blank line and a short body only when it improves clarity."))))

(defun my/magit-ai--replace-commit-message (message)
  "Insert MESSAGE into the current commit buffer.
Preserve Git comment lines when they exist."
  (let ((inhibit-read-only t))
    (goto-char (point-min))
    (let ((comment-start
           (save-excursion
             (when (re-search-forward "^#" nil t)
               (match-beginning 0)))))
      (if comment-start
          (delete-region (point-min) comment-start)
        (erase-buffer))
      (goto-char (point-min))
      (insert message "\n\n"))))

(defun my/magit-ai--commit-message-buffer-p (buffer)
  "Return non-nil when BUFFER is a Git commit message buffer."
  (when (buffer-live-p buffer)
    (with-current-buffer buffer
      (or (derived-mode-p 'git-commit-mode)
          (string= (buffer-name buffer) "COMMIT_EDITMSG")
          (string-match-p "\\`COMMIT_EDITMSG\\(?:<[0-9]+>\\)?\\'"
                          (buffer-name buffer))
          (and buffer-file-name
               (string= (file-name-nondirectory buffer-file-name)
                        "COMMIT_EDITMSG"))))))

(defun my/magit-ai--find-commit-message-buffer ()
  "Return the most suitable Git commit message buffer, or nil."
  (require 'seq)
  (or (and (my/magit-ai--commit-message-buffer-p (current-buffer))
           (current-buffer))
      (seq-find #'my/magit-ai--commit-message-buffer-p
                (buffer-list))))

(defun my/magit-ai--show-or-insert-message (_target-buffer response)
  "Insert RESPONSE into an existing Git commit message buffer.
If no commit message buffer exists, show RESPONSE in a fallback buffer."
  (if-let ((commit-buffer (my/magit-ai--find-commit-message-buffer)))
      (progn
        (with-current-buffer commit-buffer
          (my/magit-ai--replace-commit-message response))
        (pop-to-buffer commit-buffer)
        (message "Inserted AI commit message into %s"
                 (buffer-name commit-buffer)))
    (my/magit-ai--show-buffer
     "*magit-ai-commit-message*"
     "Magit AI Commit Message"
     (concat
      response
      "\n\n"
      "Note: No COMMIT_EDITMSG buffer was found. "
      "Open Magit commit buffer first, then run "
      "M-x my/magit-ai-insert-commit-message."))))

(defun my/magit-ai-insert-commit-message (&optional style)
  "Generate a commit message from the staged diff and insert it.
When STYLE is nil, prompt for one of the four supported styles."
  (interactive)
  (let* ((style (or style (my/magit-ai-read-commit-style)))
         (context (my/magit-ai--repo-context t))
         (target-buffer (current-buffer)))
    (my/magit-ai--request
     context
     (my/magit-ai--message-system-prompt style)
     (lambda (response)
       (my/magit-ai--show-or-insert-message target-buffer response)))))

(defun my/magit-ai-generate-commit-message-ja-conventional ()
  "Generate a Japanese Conventional Commit message from the staged diff."
  (interactive)
  (my/magit-ai-insert-commit-message 'conventional-japanese))

(defun my/magit-ai-generate-commit-message-en-conventional ()
  "Generate an English Conventional Commit message from the staged diff."
  (interactive)
  (my/magit-ai-insert-commit-message 'conventional-english))

(defun my/magit-ai-generate-commit-message-ja-plain ()
  "Generate a plain Japanese commit message from the staged diff."
  (interactive)
  (my/magit-ai-insert-commit-message 'plain-japanese))

(defun my/magit-ai-generate-commit-message-en-plain ()
  "Generate a plain English commit message from the staged diff."
  (interactive)
  (my/magit-ai-insert-commit-message 'plain-english))

(with-eval-after-load 'magit
  (require 'transient)

  (transient-append-suffix 'magit-status-jump nil
    '("A" "AI commit plan" my/magit-ai-suggest-commit-plan))

  (with-eval-after-load 'git-commit
    (define-key git-commit-mode-map
                (kbd "C-c C-a")
                #'my/magit-ai-insert-commit-message)))

;;; ==========================================================
;;; Org / Org-Babel
;;; ==========================================================

(use-package org
  :straight nil
  :custom
  (org-confirm-babel-evaluate nil)
  (org-src-fontify-natively t)
  (org-src-tab-acts-natively t)
  (org-edit-src-content-indentation 0)
  :config
  (org-babel-do-load-languages
   'org-babel-load-languages
   '((emacs-lisp . t)
     (python . t))))

;;; ==========================================================
;;; Session restore
;;; ==========================================================

(use-package desktop
  :straight nil
  :demand t
  :init
  (setq desktop-dirname user-emacs-directory
        desktop-path (list user-emacs-directory)
        desktop-save t
        desktop-load-locked-desktop 'check-pid
        desktop-auto-save-timeout 30
        desktop-restore-eager 5)
  :config
  (desktop-save-mode 1))

;;; ==========================================================
;;; Emacs client frames
;;; ==========================================================

(use-package server
  :straight nil
  :demand t
  :config
  (defun my/server-switch-to-restored-buffer ()
    "Show the most recent restored normal buffer in a new client frame."
    (when (member (buffer-name) '("*scratch*" "*GNU Emacs*"))
      (when-let ((buffer (seq-find #'my/tab-line-buffer-visible-p
                                   (buffer-list))))
        (switch-to-buffer buffer))))

  (add-hook 'server-after-make-frame-hook
            #'my/server-switch-to-restored-buffer))

;;; ==========================================================
;;; Restart Emacs daemon
;;; ==========================================================

(defun my/restart-emacs-daemon ()
  "Restart the systemd-managed Emacs daemon, then open a new frame."
  (interactive)
  (when (yes-or-no-p "Restart Emacs daemon? ")
    (save-some-buffers t)
    (call-process
     "sh" nil 0 nil
     "-lc"
     "systemd-run --user --collect --unit=restart-emacs-from-emacs sh -lc 'systemctl --user restart emacs.service; sleep 0.5; emacsclient -c'")))

(global-set-key (kbd "C-c r e") #'my/restart-emacs-daemon)

(provide 'init)
;;; init.el ends here
