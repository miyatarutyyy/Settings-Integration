;;; early-init.el --- Early startup settings -*- lexical-binding: t; -*-

;; Disable package.el's automatic package activation at startup.
(setq package-enable-at-startup nil)

;; Disable the startup screen.
(setq inhibit-startup-screen t)

;; stop showing menu, tool, scroll bar
(menu-bar-mode -1)
(tool-bar-mode -1)
(scroll-bar-mode -1)
