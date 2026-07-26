;;; init.el --- Emacs configuration for miyatarutyyy -*- lexical-binding: t; -*-

;;; Commentary:
;; This file "init.el" is generated from init.org.
;; Edit init.org, not init.el.
;; Please tell me Why I use Emacs.
;; All what I know is that I am insane.

;;; Code:

;; Debugger
  (setq debug-on-error t)

  ;; When I finish writing init.org but forget to tangle it into init.el
  ;; notify that to me
  (defun my/warn-if-init-el-is-stale ()
  "Warn when init.org is newer than the generated init.el."
  (let ((init-org (locate-user-emacs-file "init.org"))
        (init-el  (locate-user-emacs-file "init.el")))
    (when
        (and
         ;; init-org is existing
         (file-exists-p init-org)

         ;; init.el does no exist or init.org is newer
         (or (not (file-exists-p init-el))
             (file-newer-than-file-p init-org init-el)))

      (display-warning
       'my-init
       (format "%s is newer than %s. Please tangle init.org."
               init-org
               init-el)
       :warning))))

(my/warn-if-init-el-is-stale)

;; Keep Customize-generated settings out of init.el.
;; Never contaminate init.el.
(setq custom-file (locate-user-emacs-file "custom.el"))

(when (file-readable-p custom-file)
  (load custom-file))

;; Do not create backup files like foo.txt~.
;; Backup weaken human beings.
(setq make-backup-files nil)

;; Do not create lock files like .#foo.txt.
(setq create-lockfiles nil)

;; Store auto-save files under ~/.emacs.d/auto-save-list/.
(make-directory (locate-user-emacs-file "auto-save-list/") t)

(setq auto-save-default t
      auto-save-file-name-transforms
      `((".*" ,(locate-user-emacs-file "auto-save-list/") t)))

;; Reload visited files automatically when they change on disk.
(global-auto-revert-mode 1)

;; Also refresh non-file buffers such as Dired buffers.
(setq global-auto-revert-non-file-buffers t)

;; Check every second when file notifications are unavailable.
(setq auto-revert-interval 1)

;; Nix/Home Manager provides Emacs itself and external commands.
;; straight.el owns Emacs Lisp package installation and updates.
(setq straight-use-package-by-default t)

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
         'silent
         'inhibit-cookies)
      (goto-char (point-max))
      (eval-print-last-sexp)))
  (load bootstrap-file nil 'nomessage))

(straight-use-package 'use-package)

(when (and (fboundp 'treesit-available-p)
           (treesit-available-p))
  (setq treesit-font-lock-level 4))

(defun my/treesit-ready-p (lang)
  "Return non-nil if Tree-sitter grammar for LANG is available."
  (and (fboundp 'treesit-language-available-p)
       (treesit-language-available-p lang)))

(defun my/remap-to-ts-mode (old-mode new-mode lang)
  "Remap OLD-MODE to NEW-MODE when LANG grammar is available."
  (when (and (fboundp new-mode)
             (my/treesit-ready-p lang))
    (add-to-list 'major-mode-remap-alist
                 (cons old-mode new-mode))))

(defun my/add-ts-mode (regexp mode lang)
  "Use MODE for files matching REGEXP when LANG grammar is available."
  (when (and (fboundp mode)
             (my/treesit-ready-p lang))
    (add-to-list 'auto-mode-alist
                 (cons regexp mode))))

;; Remap classic major modes to Tree-sitter based modes.
(my/remap-to-ts-mode 'sh-mode      'bash-ts-mode   'bash)
(my/remap-to-ts-mode 'css-mode     'css-ts-mode    'css)
(my/remap-to-ts-mode 'js-mode      'js-ts-mode     'javascript)
(my/remap-to-ts-mode 'js-json-mode 'json-ts-mode   'json)
(my/remap-to-ts-mode 'python-mode  'python-ts-mode 'python)

;; File extensions whose Tree-sitter modes are usually selected directly.
(my/add-ts-mode "\\.ts\\'"    'typescript-ts-mode 'typescript)
(my/add-ts-mode "\\.tsx\\'"   'tsx-ts-mode        'tsx)
(my/add-ts-mode "\\.ya?ml\\'" 'yaml-ts-mode       'yaml)

(use-package nix-ts-mode
  :mode "\\.nix\\'")

;; TABで、まずインデントし、必要なら補完を開始する。
(setq tab-always-indent 'complete)

;; LSPが返したスニペット形式の補完を展開する。
;;
;; prog-mode-hook は TypeScript固有のhookより先に実行されるため、
;; Eglot接続時には yas-minor-mode が有効になっている。
(use-package yasnippet
  :hook (prog-mode . yas-minor-mode))

;; Language Server Protocol client.
;; Eglot自体は現在のEmacsに組み込まれている。
(use-package eglot
  :straight nil
  :hook ((typescript-ts-mode . eglot-ensure)
         (tsx-ts-mode        . eglot-ensure)
         (js-ts-mode         . eglot-ensure))
  :custom
  ;; プロジェクト最後の管理対象バッファを閉じた際、
  ;; Language Serverも終了する。
  (eglot-autoshutdown t))

;; バッファ内補完候補をポップアップ表示する。
(use-package corfu
  :custom
  ;; 入力中に自動補完する。
  (corfu-auto t)

  ;; 入力停止から補完開始までの秒数。
  (corfu-auto-delay 0.2)

  ;; 2文字入力してから自動補完を開始する。
  ;; 1文字では候補問い合わせが多すぎる場合がある。
  (corfu-auto-prefix 2)

  ;; 候補末尾から先頭へ循環する。
  (corfu-cycle t)

  ;; 最初から候補を選択状態にしない。
  ;; RETによる意図しない確定を防ぐ。
  (corfu-preselect 'prompt)

  ;; 選択候補をバッファに仮表示しない。
  (corfu-preview-current nil)

  :config
  ;; Emacs全体でCorfuを有効化する。
  (global-corfu-mode)

  ;; 選択中候補のドキュメントを追加表示する。
  (when (locate-library "corfu-popupinfo")
    (require 'corfu-popupinfo)
    (corfu-popupinfo-mode)))

;; 候補の照合方式。
(use-package orderless
  :custom
  (completion-styles '(orderless basic))
  (completion-category-defaults nil)
  (completion-category-overrides
   '((file (styles partial-completion)))))

;; ファイルパスなど、LSP以外の補完候補を追加する。
(use-package cape
  :init
  ;; グローバルCAPFの後方にファイル補完を加える。
  (add-hook 'completion-at-point-functions #'cape-file t))

;; Arduino development environment.
;; .ino files are C++-like, but Arduino needs board-aware tooling.

(require 'cc-mode)

(define-derived-mode my/arduino-mode c++-mode "Arduino"
  "Major mode for Arduino sketches.")

(add-to-list 'auto-mode-alist '("\\.ino\\'" . my/arduino-mode))

;; Default Arduino settings.
;; Override these per project with .dir-locals.el.
(defcustom my/arduino-fqbn "arduino:avr:uno"
  "Default Arduino board FQBN."
  :type 'string)

(defcustom my/arduino-port "/dev/ttyACM0"
  "Default Arduino serial port."
  :type 'string)

(defcustom my/arduino-baud "115200"
  "Default Arduino serial monitor baud rate."
  :type 'string)

(defcustom my/arduino-cli-config
  (expand-file-name "~/.arduino15/arduino-cli.yaml")
  "Path to arduino-cli.yaml."
  :type 'file)

;; Allow project-local overrides in .dir-locals.el.
(put 'my/arduino-fqbn 'safe-local-variable #'stringp)
(put 'my/arduino-port 'safe-local-variable #'stringp)
(put 'my/arduino-baud 'safe-local-variable #'stringp)
(put 'my/arduino-cli-config 'safe-local-variable #'stringp)

(defun my/arduino--sketch-dir ()
  "Return the Arduino sketch directory for the current buffer."
  (or
   ;; If sketch.yaml exists, it is a clear project marker.
   (locate-dominating-file default-directory "sketch.yaml")

   ;; Otherwise, search upward for a directory containing an .ino file.
   (locate-dominating-file
    default-directory
    (lambda (dir)
      (seq-some
       (lambda (file)
         (string-match-p "\\.ino\\'" file))
       (directory-files dir))))

   default-directory))

(defun my/arduino-compile ()
  "Compile the current Arduino sketch."
  (interactive)
  (let ((default-directory (my/arduino--sketch-dir)))
    (compile
     (format "arduino-cli compile -b %s %s"
             (shell-quote-argument my/arduino-fqbn)
             (shell-quote-argument default-directory)))))

(defun my/arduino-upload ()
  "Compile and upload the current Arduino sketch."
  (interactive)
  (let ((default-directory (my/arduino--sketch-dir)))
    (compile
     (format "arduino-cli compile -u -p %s -b %s %s"
             (shell-quote-argument my/arduino-port)
             (shell-quote-argument my/arduino-fqbn)
             (shell-quote-argument default-directory)))))

(defun my/arduino-monitor ()
  "Open Arduino serial monitor."
  (interactive)
  (compile
   (format "arduino-cli monitor -p %s -c baudrate=%s"
           (shell-quote-argument my/arduino-port)
           (shell-quote-argument my/arduino-baud))))

;; Eglot integration for arduino-language-server.
(defun my/arduino-eglot-server (_interactive)
  "Return Arduino language server command for Eglot."
  (list "arduino-language-server"
        "-clangd" (or (executable-find "clangd") "clangd")
        "-cli" (or (executable-find "arduino-cli") "arduino-cli")
        "-cli-config" my/arduino-cli-config
        "-fqbn" my/arduino-fqbn))

(with-eval-after-load 'eglot
  (add-to-list 'eglot-server-programs
               '(my/arduino-mode . my/arduino-eglot-server)))

;; Arduino buffer keybindings.
(define-key my/arduino-mode-map (kbd "C-c C-c") #'my/arduino-compile)
(define-key my/arduino-mode-map (kbd "C-c C-u") #'my/arduino-upload)
(define-key my/arduino-mode-map (kbd "C-c C-m") #'my/arduino-monitor)
(define-key my/arduino-mode-map (kbd "C-c C-l") #'eglot)

;; 起動時のスプラッシュ画面を表示しない。
(setq inhibit-startup-screen t)

;; *scratch* バッファの初期メッセージを空にする。
(setq initial-scratch-message nil)

;; Load personal interface theme.
(add-to-list 'custom-theme-load-path
             (locate-user-emacs-file "themes/"))
(load-theme 'miyatarutyyy-interface t)

;; 上部のメニューバーを非表示にする。
(menu-bar-mode -1)

;; アイコン付きツールバーを非表示にする。
(tool-bar-mode -1)

;; 右側のスクロールバーも非表示にする。
(scroll-bar-mode -1)

;;行番号を表示
(global-display-line-numbers-mode t)
(custom-set-variables '(display-line-numbers-width-start t))

;; Tab表示
(tab-bar-mode t)

(use-package vterm
  :commands (vterm my/vterm-project)
  :custom
  ;; vterm が保持するスクロールバック行数。
  ;; 標準ビルドにおける上限は 100000。
  (vterm-max-scrollback 100000)

  ;; シェルを終了したら vterm バッファーも削除する。
  (vterm-kill-buffer-on-exit t))

(defun my/vterm-project ()
  "現在のプロジェクトルートで、そのプロジェクト専用の vterm を開く。"
  (interactive)
  (require 'project)

  (let* ((project (project-current t))
         (root (project-root project))
         (name (file-name-nondirectory
                (directory-file-name root)))
         (buffer-name (format "*vterm:%s*" name))
         (default-directory root))
    (vterm buffer-name)))

;; Org is build into Emacs, but I explicitly install it.
  (require 'org)

;; Start Org buffers with visual indentation.
(setq org-startup-indented t)

;; One outline level = 2 columns of visual indentation.
(setq org-indent-indentation-per-level 2)

;; Fontify source blocks using the source language's major mode.
(setq org-src-fontify-natively t)

;; Let TAB inside source blocks behave more like the source language mode.
(setq org-src-tab-acts-natively t)

;; Indent source block contents by 2 spaces visually/edit-wise.
(setq org-edit-src-content-indentation 2)

;; Enable Org Babel languages.
(org-babel-do-load-languages
 'org-babel-load-languages
 '((emacs-lisp . t)
   (python . t)))

;; Do not ask for confirmation when evaluating source blocks.
(setq org-confirm-babel-evaluate nil)

;; Open ~/.emacs.d/init.org quickly.
(defun my/open-init-org ()
  "Open ~/.emacs.d/init.org."
  (interactive)
  (find-file (locate-user-emacs-file "init.org")))

(when (locate-library "ox-hub")
  (require 'ox-hub))

;; Org -> Beamer -> PDF export
(with-eval-after-load 'org
  ;; Enable Beamer exporter.
  (require 'ox-beamer)

  ;; Japanese documents should usually use LuaLaTeX rather than pdfLaTeX.
  (setq org-latex-compiler "lualatex")

  ;; Use latexmk so references / table of contents / overlays are resolved properly.
  (setq org-latex-pdf-process
        '("latexmk -f -pdf -lualatex -interaction=nonstopmode -output-directory=%o %f"))

  ;; In Beamer, H:2 means:
  ;; * section
  ;; ** frame
  ;;
  ;; This is also controllable per-file with #+OPTIONS: H:2.
  (setq org-beamer-frame-level 2))

;;; Just One Commands update this emacs.
;;; 1. Save init.org
;;; 2. Tangle elisp bable blocks on init.org into init.el
;;; 3. Reload init.el

;; Tangle init.org and load generated init.el.

(defconst my/init-org-file
  (expand-file-name "init.org" user-emacs-directory)
  "Path to my init.org file.")

(defconst my/init-el-file
  (expand-file-name "init.el" user-emacs-directory)
  "Path to my generated init.el file.")

(defun my/tangle-and-load-init ()
  "Tangle init.org to init.el, then load init.el."
  (interactive)
  (unless (file-exists-p my/init-org-file)
    (user-error "init.org does not exist: %s" my/init-org-file))

  ;; If init.org is already open and modified, save it first.
  (when-let ((buffer (find-buffer-visiting my/init-org-file)))
    (with-current-buffer buffer
      (when (buffer-modified-p)
        (save-buffer))))

  ;; org-babel-tangle-file is defined in ob-tangle.
  ;; If Emacs does not have ob-tangle when I execute my/tangle-and-load-init, load it.
  (require 'ob-tangle)

  ;; Tangle only emacs-lisp blocks into init.el.
  (org-babel-tangle-file my/init-org-file my/init-el-file "emacs-lisp")

  ;; Load the generated init.el into the current Emacs session.
  (load-file my/init-el-file)

  (message "Tangled %s and loaded %s"
           my/init-org-file
           my/init-el-file))
