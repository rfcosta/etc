;; Emacs Initialization
;; P.C.Shyamshankar 'sykora' <sykora@lucentbeing.com>

;; This is rewrite #4.

;; Interpreter Configuration
(setq gc-cons-threshold 100000000)

;; Paths
(defvar user-lisp-directory (concat user-emacs-directory "lisp/"))
(add-to-list 'load-path user-lisp-directory)

(setq custom-theme-directory (concat user-lisp-directory "themes/"))

(setq custom-file (concat user-emacs-directory "customizations.el"))
(load custom-file 'no-error)

;; Package System Initialization -- Must be done ahead of time.
(require 'package)

;; I gave up on melpa-stable, it's anything but.
(add-to-list 'package-archives '("gnu" . "http://elpa.gnu.org/packages/"))
(add-to-list 'package-archives '("melpa" . "https://melpa.org/packages/"))
(add-to-list 'package-archives '("org" . "http://orgmode.org/elpa/"))

(setq package-enable-at-startup nil)
(package-initialize)

(defconst instance-name
  (if (daemonp)
      (daemonp)
    (format "emacs_%d" (emacs-pid)))
  "Unique name of the current emacs instance.
Defaults to `server-name' if present, generated by PID otherwise.")


;; Bootstrap use-package itself, if absent.
(unless (require 'use-package nil 'silent)
  (package-refresh-contents)
  (package-install 'use-package)
  (require 'use-package))

(defmacro setc (variable value)
  `(customize-set-variable ',variable ,value))

(defmacro with-hook (hook &rest body)
  "When `HOOK' is called, execute `BODY'."
  (declare (indent 1))
  `(add-hook ',hook (lambda () (progn ,@body)) t))

;; Appearance
(set-frame-font "Pragmata Pro-10")
(setc default-frame-alist '((font . "Pragmata Pro-10")))

(setc inhibit-splash-screen t)

(load-theme 'skywave)
(add-hook 'after-make-frame-functions
          (lambda (frame)
            (with-selected-frame frame
              (load-theme 'skywave))))

(column-number-mode)

;; Backups and Auto-Saves
(setc backup-directory-alist `(("." . ,(concat user-emacs-directory "backups/"))))
(setc auto-save-file-name-transforms
      `((".*" ,(expand-file-name (concat user-emacs-directory "auto-saves/")))))

(setc backup-by-copying t)
(setc delete-old-versions t)
(setc kept-new-versions 6)
(setc kept-old-versions 2)
(setc version-control t)

;; Behaviour
(setc scroll-step 1)

;; Editing
(setc fill-column 100)
(setc indent-tabs-mode nil)
(setc sentence-end-double-space nil)
(setc tab-width 2)

(with-hook prog-mode-hook
  (setq show-trailing-whitespace t))

;; Miscellaneous
(setc ad-redefinition-action 'accept)
(defalias 'yes-or-no-p 'y-or-n-p)

(put 'narrow-to-region 'disabled nil)
(put 'upcase-region 'disabled nil)
(put 'downcase-region 'disabled nil)

;; Package Initialization
(use-package general
  :ensure t
  :config
  (defvar general-leader "SPC"))

(use-package evil
  :ensure t

  :general (:states 'insert "RET" 'evil-ret-and-indent)

  :general (:states '(normal motion visual)
            "n" 'evil-backward-char
            "e" 'evil-next-visual-line
            "i" 'evil-previous-visual-line
            "o" 'evil-forward-char

            "N" 'beginning-of-line-toggle
            "O" 'end-of-line

            "t" 'evil-search-next
            "T" 'evil-search-previous)

  :general (:states '(normal visual)
            "k" 'evil-yank
            "m" 'evil-paste-after
            "M" 'evil-paste-before)

  :general (:states 'normal
            "h" 'evil-insert-state
            "H" 'evil-insert-line
            "a" 'evil-append
            "A" 'evil-append-line
            "y" 'evil-open-below
            "Y" 'evil-open-above

            "q" 'nil
            "Q" 'evil-record-macro

            "s" 'evil-utility-map)

  :general (:states 'visual
            "y" 'evil-visual-exchange-corners)

  :general (:keymaps 'evil-window-map
            "n" 'evil-window-left
            "e" 'evil-window-down
            "i" 'evil-window-up
            "o" 'evil-window-right

            "C-n" 'evil-window-left
            "C-e" 'evil-window-down
            "C-i" 'evil-window-up
            "C-o" 'evil-window-right

            "q" 'evil-window-delete
            "d" 'delete-other-windows
            "D" 'delete-other-windows-vertically)

  :general (:keymaps 'evil-utility-map
            "v" 'evil-visual-restore
            "m" 'evil-mark-last-yank)

  :general (:keymaps '(evil-operator-state-map evil-visual-state-map)
            "h" 'evil-inner-text-objects-map)

  :general (:states 'emacs
            "C-w" 'evil-window-map)

  :init
  (evil-mode t)

  (defun evil-mark-last-yank ()
    (interactive)
    (evil-visual-make-selection (evil-get-marker ?[) (evil-get-marker ?])))

  (defun beginning-of-line-toggle ()
    (interactive)
    (let ((current (point)))
      (back-to-indentation)
      (when (= current (point))
        (beginning-of-line))))

  :config
  (setc evil-move-beyond-eol t)
  (setc evil-split-window-below t)
  (setc evil-vsplit-window-right t)
  (setc evil-want-fine-undo nil)

  (define-prefix-command 'evil-utility-map))

(use-package evil-surround
  :ensure t
  :general (:states '(normal visual)
            "js" 'evil-surround-region
            "jS" 'evil-Surround-region)
  :init
  (global-evil-surround-mode))

(use-package undo-tree
  :diminish undo-tree-mode
  :general (:states 'normal
            "u" 'undo-tree-undo
            "U" 'undo-tree-redo)

  :general (:keymaps 'undo-tree-visualizer-mode-map
            "n" 'undo-tree-visualize-switch-branch-left
            "e" 'undo-tree-visualize-redo
            "i" 'undo-tree-visualize-undo
            "o" 'undo-tree-visualize-switch-branch-right)

  :general (:states 'normal :prefix general-leader
            "u" 'undo-tree-visualize)

  :init
  (evil-set-initial-state 'undo-tree-visualizer-mode 'emacs))

(use-package winner
  :init (winner-mode t)
  :general (:keymaps 'evil-window-map
            "u" 'winner-undo
            "U" 'winner-redo))

(use-package hydra
  :ensure t
  :general (:states 'normal :prefix general-leader
            "z" 'hydra-zoom/body)
  :init
  (defhydra hydra-zoom (:color amaranth :hint nil :idle 1.0)
    "
Zoom: {_e_} Out | {_i_} In | {_r_} Reset | {_q_} Quit
"
    ("e" text-scale-decrease)
    ("i" text-scale-increase)
    ("r" (text-scale-increase 0))
    ("q" nil))

  :config
  (hydra-add-font-lock))

(use-package magit
  :ensure t
  :commands (magit-status magit-blame)
  :general (:states 'normal :prefix general-leader
            "g" 'hydra-magit/body)

  :general (:keymaps 'magit-mode-map
            "n" 'evil-backward-char
            "e" 'evil-next-line
            "i" 'evil-previous-line
            "o" 'evil-forward-char

            "V" 'set-mark-command

            "M-i" 'magit-section-up)

  :init
  (defhydra hydra-magit (:color blue :hint nil :idle 1.0)
    "
 Git Control: {_b_} Blame | {_s_} Status | {_q_} Quit
"
    ("b" magit-blame)
    ("s" magit-status)
    ("q" nil))

  :config
  (setc magit-popup-show-common-commands nil))

(use-package helm
  :ensure t
  :general (:keymaps 'global
            "M-x" 'helm-M-x)

  :general (:states 'normal :prefix general-leader
            "b" 'hydra-list/body)
  :init
  (defhydra hydra-list (:color blue :idle 1.0 :hint nil)
    "
 Buffers and Files
─────────────────────────────────────────
 {_l_} List Buffers | {_f_} List Files
 {_k_} Kill Buffer  | {_d_} List Directories
 {_o_} Other Buffer | {_m_} List Menu
─────────────────────────────────────────
 {_q_} Quit
"
    ("b" bury-buffer)
    ("d" cd)
    ("f" helm-find-files)
    ("k" kill-this-buffer)
    ("l" helm-buffers-list)
    ("m" helm-imenu)
    ("o" evil-buffer)
    ("q" nil))

  :config
  (setc helm-split-window-in-side-p t)
  (add-to-list 'display-buffer-alist
               `(,(rx bos "*helm" (* not-newline) "*" eos)
                 (display-buffer-in-side-window)
                 (inhibit-same-window . t)
                 (window-height . 0.4))))

(use-package flycheck
  :ensure t

  :general (:states 'normal :prefix general-leader
            "f" 'hydra-flycheck/body)
  :init
  (global-flycheck-mode)

  (defhydra hydra-flycheck (:color blue :idle 1.0 :hint nil)
    "
 Flycheck: {_e_} Next Error | {_i_} Previous Error | {_l_} List Errors | {_b_} Recheck Buffer | {_q_} Quit
 "
    ("e" flycheck-next-error)
    ("i" flycheck-previous-error)
    ("l" flycheck-list-errors)
    ("b" flycheck-buffer)
    ("q" nil))

  :config
  (evil-set-initial-state 'flycheck-error-list-mode 'emacs))

(use-package company
  :ensure t
  :diminish company-mode
  :init
  (global-company-mode))

(use-package imenu
  :config
  (setc imenu-space-replacement "-"))

(use-package smartparens
  :ensure t
  :diminish smartparens-mode
  :general (:keymaps 'evil-utility-map
            "k" 'hydra-smartparens/body)
  :init
  (smartparens-global-strict-mode)

  :config
  (defhydra hydra-smartparens (:color amaranth :idle 1.0 :hint nil)
    "
 SExp Navigation/Manipulation
───────────────────────────────────────────────────
 {_n_} Previous | {_r_} Raise  | {_sn_} Slurp From Left
 {_e_} Down     | {_k_} Kill   | {_so_} Slurp From Right
 {_i_} Up       |           ^^ | {_bn_} Barf To Left
 {_o_} Next     |           ^^ | {_bo_} Barf To Right
───────────────────────────────────────────────────
 {_u_} Undo     | {_U_} Redo
───────────────────────────────────────────────────
 {_q_} Quit     | {_a_} Append | {_h_} Insert
"
    ("n" sp-backward-sexp)
    ("i" sp-up-sexp)
    ("e" sp-down-sexp)
    ("o" sp-forward-sexp)

    ("r" sp-raise-sexp)
    ("k" sp-kill-hybrid-sexp)

    ("sn" sp-backward-slurp-sexp)
    ("so" sp-forward-slurp-sexp)

    ("bn" sp-backward-barf-sexp)
    ("bo" sp-forward-barf-sexp)

    ("u" undo-tree-undo)
    ("U" undo-tree-redo)

    ("a" evil-append :color blue)
    ("h" evil-insert :color blue)

    ("q" nil))

  (sp-pair "'" "'" :unless '(sp-point-after-word-p))

  (sp-with-modes '(emacs-lisp-mode lisp-interaction-mode)
    (sp-local-pair "'" nil :actions nil)
    (sp-local-pair "`" "`" :actions nil)
    (sp-local-pair "`" "'" :when '(sp-in-string-p))))

(use-package help-fns+ :ensure t)

(use-package browse-url
  :init
  (setc browse-url-browser-function 'browse-url-chromium))

(use-package projectile
  :ensure t
  :general (:states 'normal :prefix general-leader
            "p" 'hydra-projectile/body)
  :init
  (use-package helm-ag)
  (use-package helm-projectile)

  (defhydra hydra-projectile (:color teal :hint nil :idle 1.0)
    "
 Projectile
─────────────────────────────────────
 {_p_} Do What I Mean
 {_s_} Switch to Project | {_a_} Search
 {_g_} Version Control   | {_b_} Buffers
 {_d_} Change Directory  | {_f_} Files
─────────────────────────────────────
 {_q_} Quit
"
    ("p" helm-projectile)
    ("s" projectile-switch-project)
    ("g" projectile-vc)
    ("d" (cd (projectile-project-root)))

    ("b" projectile-switch-to-buffer)
    ("f" projectile-find-file-dwim)
    ("a" helm-projectile-ag)

    ("q" nil))

  :config
  (setc projectile-completion-system 'helm)
  (setc projectile-switch-project-action 'projectile-find-file-dwim))

(use-package compile
  :config
  (setc compilation-scroll-output t))

(use-package compilation-manager
  :load-path (concat user-lisp-directory "compilation-manager/")
  :general (:states 'normal :prefix general-leader
            "r" 'hydra-compile/body)
  :init
  (defhydra hydra-compile (:idle 1.0 :color blue :hint nil)
      "
 Compilation Control
─────────────────────────────────────────────────────────────────
 {_c_} Compile   | {_p_} Compile Profile | {_s_} Toggle Skip Threshold
 {_r_} Recompile | {_n_} Name Profile    |
 {_k_} Kill      |
 {_b_} Raise     |
─────────────────────────────────────────────────────────────────
 {_q_} Quit
"
      ("c" compile)
      ("r" recompile)
      ("k" kill-compilation)
      ("b" (if (get-buffer "*compilation*")
               (switch-to-buffer "*compilation*")
             (message "No active compilation session.")))

      ("p" compilation-manager-run-profile)
      ("n" compilation-manager-name-last-profile)

      ("s" compilation-set-skip-threshold)
      ("q" nil)))

(use-package expand-region
  :ensure t
  :general (:states 'visual
            "." 'er/expand-region))

(use-package comment-dwim-toggle
  :load-path user-lisp-directory
  :general (:states 'normal :prefix general-leader
            "c" 'comment-dwim-toggle)
  :general (:states 'normal :prefix general-leader :keymaps 'org-mode-map
            "c" 'org-comment-dwim-toggle)
  :init
  (defun org-comment-dwim-toggle ()
    (interactive)
    (or (org-babel-do-in-edit-buffer
         (comment-dwim-toggle))
        (comment-dwim-toggle))))

(use-package eshell
  :general (:states 'insert :keymaps 'eshell-mode-map
            "RET" 'eshell-queue-input)
  :config
  (use-package em-hist
    :config
    (defun eshell-add-input-to-history (input)
      "Add `INPUT' to history. If already present, move to front."
      (if (funcall eshell-input-filter input)
          (ring-remove+insert+extend eshell-history-ring (replace-regexp-in-string "[ \t\n]*\\'" "" input)))
      (setq eshell-save-history-index eshell-history-index)
      (setq eshell-history-index nil))))

(use-package narrow-or-widen-dwim
  :load-path user-lisp-directory
  :commands (narrow-or-widen-dwim)
  :general (:states 'normal :prefix general-leader
            "n" 'narrow-or-widen-dwim))

(use-package fic-mode
  :ensure t
  :init
  (with-hook prog-mode-hook
    (fic-mode)))

(use-package evil-exchange
  :ensure t
  :general (:keymaps 'evil-utility
            "x" 'evil-exchange
            "X" 'evil-exchange-cancel))

(use-package evil-args
  :ensure t
  :general (:keymaps 'evil-inner-text-objects-map
            "," 'evil-inner-arg)
  :general (:keymaps 'evil-outer-text-objects-map
            "," 'evil-outer-arg))

;; Modes
(use-package lisp-mode
  :mode ("\\.el'" . emacs-lisp-mode)
  :config
  (use-package lisp-plist-indent-function
    :load-path user-lisp-directory
    :config
    (setc lisp-indent-function 'lisp-plist-indent-function))

  (with-hook emacs-lisp-mode-hook
    (add-to-list 'imenu-generic-expression
		 '("Used Packages" "^\s*(use-package \\([a-zA-Z0-9\-]*\\)" 1))

    (font-lock-add-keywords nil '(("(\\(\\<with-hook\\>\\)" 1 'font-lock-keyword-face)))
    (font-lock-add-keywords nil '(("(\\(\\<set[cq]\\>\\)" 1 'font-lock-keyword-face)))))

(use-package haskell-mode
  :ensure t
  :mode ("\\.hs'" . haskell-mode)
  :config
  (use-package haskell-doc
    :diminish haskell-doc-mode)

  (with-hook haskell-mode-hook
    (haskell-decl-scan-mode)
    (haskell-doc-mode)
    (haskell-indentation-mode)))

(use-package K3-mode
  :load-path user-lisp-directory
  :mode ("\\.k3" . K3-mode))

(use-package ledger-mode
  :ensure t
  :mode ("\\.ldg\\'" . ledger-mode)
  :config
  (setc ledger-clear-whole-transactions t)
  (setc ledger-use-iso-dates t)
  (setc ledger-post-account-alignment-column 2)
  (setc ledger-post-amount-alignment-column 80)
  (setc ledger-reconcile-default-commodity "USD"))

(use-package org
  :ensure org-plus-contrib
  :mode ("\\.org\\'" . org-mode)
  :general (:states 'insert :keymaps 'org-mode-map
            "M-n" 'org-metaleft
            "M-e" 'org-metadown
            "M-i" 'org-metaup
            "M-o" 'org-metaright

            "M-RET" 'org-metareturn)
  :general (:keymaps 'org-agenda-mode-map
            "e" 'org-agenda-next-item
            "i" 'org-agenda-previous-item)
  :general (:states 'normal :prefix general-leader
            "o" 'hydra-org/body)
  :init
  (use-package org-agenda
    :commands (org-agenda)
    :config
    (with-hook org-agenda-mode-hook
      (hl-line-mode))

    (setc org-agenda-dim-blocked-tasks t)
    (setc org-agenda-span 14)
    (setc org-agenda-start-on-weekday nil)
    (setc org-agenda-tags-column -100)

    (evil-set-initial-state 'org-agenda-mode 'emacs))

  (use-package org-capture
    :commands (org-capture)
    :config
    (setc org-capture-templates
	  `(("t" "Task" entry (file (concat org-directory "agenda.org"))
	     "* TODO %?" :kill-buffer t :prepend t))))

  (defhydra hydra-org (:color blue :hint nil :idle 1.0)
    "
Org: {_a_} Agenda | {_c_} Capture | {_j_} Jump to Clock | {_q_} Quit
"
    ("a" org-agenda)
    ("c" org-capture)
    ("j" org-clock-goto)
    ("q" nil))

  :config

  (use-package org-open-heading
    :load-path user-lisp-directory
    :general (:states 'normal :keymaps 'org-mode-map
              "M-y" 'org-open-heading-below-and-insert
              "M-Y" 'org-open-heading-above-and-insert))

  ;; Paths
  (setc org-directory "~/org/")
  (setc org-agenda-files '("~/org/agenda.org"))


  ;; Appearance
  (setq org-ellipsis "…")
  (setq org-adapt-indentation nil)

  ;; Babel
  (setc org-babel-load-languages '((emacs-lisp . t)
                                   (restclient . t)
                                   (shell . t)))

  ;; Source Code
  (setc org-src-fontify-natively t)
  (setc org-src-preserve-indentation t)

  (setc org-tags-column -100)

  (with-hook org-mode-hook
    (auto-fill-mode)))

(use-package rust-mode
  :ensure t
  :mode ("\\.rs\\'" . rust-mode)
  :init
  (use-package racer
    :ensure t
    :config
    (with-hook rust-mode-hook
      (racer-mode))

    (setq racer-cmd "/home/sykora/.cargo/bin/racer")
    (setq racer-rust-src-path "/home/sykora/src/scratch/rust/rust/src")))

(use-package tex-mode
  :ensure auctex
  :mode ("\\.tex\\'" . LaTeX-mode)
  :general (:states 'normal :keymaps 'LaTeX-mode-map :prefix general-leader
            "m" 'hydra-latex/body)
  :config

  (put 'LaTeX-narrow-to-environment 'disabled nil)

  (with-hook LaTeX-mode-hook
    (auto-fill-mode)
    (turn-on-reftex))

  (use-package auctex-latexmk
    :ensure t
    :init
    (auctex-latexmk-setup)

    :config
    (defun TeX-latexmk ()
      (interactive)
      (TeX-command "LatexMk" 'TeX-master-file -1)))

  (defhydra hydra-latex (:color blue :hint nil :idle 1.0)
    "
 LaTeX: {_c_} Compile | {_i_} Index | {_v_} View | {_q_} Quit
"
    ("c" TeX-latexmk)
    ("v" TeX-view)
    ("i" reftex-toc)
    ("q" nil))

  (setc latex-item-indent 0)

  (setc font-latex-fontify-sectioning 'color)

  (add-to-list 'TeX-expand-list `("%i" (lambda () instance-name)))
  (add-to-list 'TeX-view-program-list '("QPDFView"
    ("qpdfview --unique --instance %i %o" (mode-io-correlate "#src:%b:%n:1"))))
  (setcdr (assoc 'output-pdf TeX-view-program-selection) '("QPDFView")))

(use-package yaml-mode
  :ensure t
  :mode ("\\.ya?ml\\'" . yaml-mode))

;; Local Variables:
;; flycheck-disabled-checkers: (emacs-lisp emacs-lisp-checkdoc)
;; End:
