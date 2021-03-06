;; Bootstrap `use-package'
(unless (package-installed-p 'use-package)
  (package-refresh-contents)
  (package-install 'use-package))

(use-package better-defaults
  :config
  (set-face-attribute 'default nil :family "Inconsolata" :height 180)
  (set-face-attribute 'fixed-pitch nil :family "Inconsolata")
  (set-face-attribute 'variable-pitch nil :family "Inconsolata")

  (set-fontset-font "fontset-default" 'unicode "Noto Color Emoji" nil 'prepend)

  (setq epg-gpg-program "gpg2")
  (setq auth-sources '((:source "~/.authinfo.gpg")))
  (setenv "GPG_AGENT_INFO" nil)
  (setq epa-pinentry-mode 'loopback)

  (setq browse-url-browser-function 'eww-browse-url)
  (setq shr-width 70)
  (setq shr-max-image-proportion 0.70)
  (setq inhibit-startup-message t)
  (setq initial-scratch-message nil)
  (setq make-backup-files nil)
  (setq ns-use-srgb-colorspace nil)
  (setq ring-bell-function 'ignore)

  (setq-default indent-tabs-mode nil)
  (setq tab-width 2)
  (setq js-indent-level 2)
  (setq css-indent-offset 2)
  (setq-default c-basic-offset 2)
  (setq c-basic-offset 2)
  (setq-default tab-width 2)
  (setq-default c-basic-indent 2)
  (setq-default indent-tabs-mode nil)
  (global-auto-revert-mode t)

  (setq inhibit-startup-message t)
  (setq inhibit-startup-screen t)         ; or screen
  (setq cursor-in-non-selected-windows t) ; Hide the cursor in inactive windows
  (setq echo-keystrokes 0.1) ; Show keystrokes right away, don't show the message in the scratch buffer
  (setq initial-scratch-message nil)            ; Empty scratch buffer
  (setq sentence-end-double-space nil) ; Sentences should end in one space, come on!
  (setq confirm-kill-emacs 'y-or-n-p) ; y and n instead of yes and no when quitting

  (fset 'yes-or-no-p 'y-or-n-p)      ; y and n instead of yes and no everywhere else
  (delete-selection-mode 1)
  (add-hook 'before-save-hook 'delete-trailing-whitespace)

  (global-set-key (kbd "C-w") 'backward-kill-word)
  (global-set-key (kbd "M-o") 'other-window)
  (global-set-key (kbd "C-c m") 'mu4e)
  (global-set-key (kbd "C-c e") 'elfeed)

  (blink-cursor-mode 0)
  (setq confirm-kill-processes nil)
  (add-hook 'prog-mode-hook 'display-line-numbers-mode)
  (global-set-key (kbd "RET") 'newline-and-indent)

  (setq gnutls-algorithm-priority "NORMAL:-VERS-TLS1.3"))

(use-package modus-vivendi-theme
  :init
  (setq modus-vivendi-theme-distinct-org-blocks t)
  (setq modus-vivendi-theme-rainbow-headings t)
  (setq modus-vivendi-theme-bold-constructs t)
  :config
  (load-theme 'modus-vivendi t))

(use-package company
  :hook (after-init . global-company-mode)
  :bind ("M-/" . company-complete-common))

;; (use-package flycheck)

(use-package nix-mode)

(use-package direnv
  :config
  (direnv-mode))

(use-package nov
  :init
  (add-to-list 'auto-mode-alist '("\\.epub\\'" . nov-mode))
  (setq nov-unzip-program "/run/current-system/sw/bin/unzip")

  (setq nov-text-width 72)

  ;; More flexible filling
  ;; See https://depp.brause.cc/nov.el/
  ;; (setq nov-text-width t)
  ;; (setq visual-fill-column-center-text t)
  ;; (add-hook 'nov-mode-hook 'visual-line-mode)
  ;; (add-hook 'nov-mode-hook 'visual-fill-column-mode)
  )

(use-package org-noter)
(use-package pocket-reader)

(use-package sdcv
  :bind (("C-x t C-d" . sdcv-search-input)
         ("C-x t d" . sdcv-search-pointer+)))

(use-package selectrum
  :config (selectrum-mode +1))

(use-package prescient
  :after (selectrum))

(use-package selectrum-prescient
  :after (selectrum prescient)
  :config
  (selectrum-prescient-mode +1)
  (prescient-persist-mode +1))

(setq flyspell-sort-corrections nil)
(setq flyspell-issue-message-flag nil)

(with-eval-after-load "ispell"
  (setq ispell-program-name "hunspell")
  (setq ispell-dictionary "de_DE,en_US")
  (ispell-set-spellchecker-params)
  (ispell-hunspell-add-multi-dic "de_DE,en_US")
  (setq ispell-personal-dictionary "~/.hunspell_personal"))

;; The personal dictionary file has to exist, otherwise hunspell will
;; silently not use it.
;;(unless (file-exists-p ispell-personal-dictionary)
;;        (write-region "" nil ispell-personal-dictionary nil 0))

(use-package org
  :hook (org-mode . auto-fill-mode)
  :bind (("C-c a" . org-agenda)
         ("C-c l" . org-store-link)
         ("C-c c" . org-capture))
  :init
  (add-to-list 'org-babel-load-languages '(js . t))
  (add-to-list 'org-babel-load-languages '(ruby . t))
  (org-babel-do-load-languages 'org-babel-load-languages org-babel-load-languages)
  (add-to-list 'org-babel-tangle-lang-exts '("js" . "js"))
  :config
  (setq org-directory "~/code/org")
  (setq org-refile-use-outline-path t)
  (setq org-outline-path-complete-in-steps nil)
  (setq org-refile-targets '(("elfeed.org" :maxlevel . 2)
                             (org-agenda-files :maxlevel . 1)))
  (setq org-default-notes-file (concat org-directory "/inbox.org"))
  (setq org-export-html-postamble nil)
  (setq org-hide-leading-stars t)
  (setq org-startup-folded (quote overview))
  (setq org-startup-indented t)
  (setq org-agenda-start-on-weekday nil)
  (setq org-agenda-files (list "~/code/org"))
  (setq org-src-fontify-natively t)
  (setq org-src-tab-acts-natively t)
  (setq org-src-window-setup 'current-window)
  (setq org-log-done 'time)
  (setq org-capture-templates '(("t" "todo" entry (file+headline "inbox.org" "Inbox")
                                 "* TODO %?\n%U\n%a\n" :clock-in t :clock-resume t)
                                ("p" "Pocket article" entry (file+headline "inbox.org" "Inbox")
                                 "* TODO Read %a\n%?%U\n" :clock-in t :clock-resume t)
                                ("a" "Appointment" entry (file+headline "inbox.org" "Inbox")
                                 "* APPT %?\nSCHEDULED: %^t\n")
                                ("s" "Subscribe")
                                ("sr" "RSS feed" entry (file+headline "elfeed.org" "Feeds")
                                 "* [[%^{Feed URL}][%^{Feed name}]]")
                                ("si" "Instagram feed" entry (file+headline "elfeed.org" "Instagram") "* [[http://127.0.0.1:1200/picuki/profile/%^{Instagram Username}][%^{Feed name}]]")
                                ("sy" "Youtube user" entry (file+headline "elfeed.org" "Youtube") "* [[https://www.youtube.com/feeds/videos.xml?user=%^{Youtube Username}][%^{Feed name}]]")
                                ("sc" "Youtube channel" entry (file+headline "elfeed.org" "Youtube") "* [[https://www.youtube.com/feeds/videos.xml?channel_id=%^{Youtube Channel ID}][%^{Feed name}]]")
                                ("g" "german conversation exercise" entry (file "~/code/org/german_conversations.org")
                                 "* %t\n** Conversation\n*** English\n%?\n*** German\n** Review\n*** Google Translation\n** Notes\n")
                                ("d" "org-drill german verb" entry (file "~/code/org/german/verbs.org")
                                 "* %^{verb} :drill:\n:PROPERTIES:\n:DRILL_CARD_TYPE: twosided\n:END:\nTranslate this sentence.\n** English\n%^{english}\n** German\n%^{german}\n** Notes\n%?")
                                ))
  )

(use-package org-bullets
  :after (org-mode)
  :hook org-mode)

;; (use-package org-drill
;; :config
;; (setq org-drill-hide-item-headings-p t))

(use-package try)
(use-package which-key :config (which-key-mode))

;; (use-package pdf-tools :init (pdf-loader-install))
;; (use-package org-pdfview)

;; (use-package nov
;;  :config (add-to-list 'auto-mode-alist '("\\.epub\\'" . nov-mode)))
;;
;; (use-package interleave
;;  :init
;;  (setq interleave-org-notes-dir-list '("~/code/org")))

(use-package smtpmail
  :ensure nil
  :init
  (setq send-mail-function 'smtpmail-send-it)
  (setq smtpmail-smtp-server "smtp.fastmail.com")
  (setq smtpmail-stream-type 'ssl)
  (setq smtpmail-debug-info t)
  (setq smtpmail-smtp-service 465)
  (setq user-mail-address "ara@hacopian.de")
  (setq user-full-name  "Ara Hacopian"))

(defun ah/make-readable ()
  (setq fill-column 80))

(use-package mu4e
  :ensure nil
  :load-path "/run/current-system/sw/share/emacs/site-lisp/mu4e/"
  :hook ((mu4e-view-mode . (lambda ()
                            (ah/make-readable)
                            (mu4e-view-fill-long-lines)))
         (mu4e-compose-mode-hook . (lambda () (set-fill-column 80))))
  :config
  (defun ah/mu4e-action-view-in-default-browser (msg)
    (browse-url-firefox (concat "file://" (mu4e~write-body-to-html msg))))

  (add-to-list 'mu4e-view-actions '("html in browser" . ah/mu4e-action-view-in-default-browser) t)
  (setq mu4e-contexts
        `( ,(make-mu4e-context
             :name "Personal"
             :enter-func (lambda () (mu4e-message "Entering Personal context"))
             :leave-func (lambda () (mu4e-message "Leaving Personal context"))
             ;; we match based on the contact-fields of the message
             :match-func (lambda (msg)
                           (when msg (mu4e-message-contact-field-matches msg :to "ara@hacopian.de")))
             :vars '((mu4e-compose-signature . nil)
                     (user-mail-address . "ara@hacopian.de")
                     (mu4e-compose-reply-to-address . "ara@hacopian.de")))

           ,(make-mu4e-context
             :name "Tehanu"
             :enter-func (lambda () (mu4e-message "Entering Tehanu context"))
             :leave-func (lambda () (mu4e-message "Leaving Tehanu context"))
             ;; we match based on the contact-fields of the message
             :match-func (lambda (msg)
                           (when msg (mu4e-message-contact-field-matches msg :to "ara@tehanu.net")))
             :vars '((mu4e-compose-signature .
                (concat
                  "Ara Hacopian\n"
                  "Tehanu UG (haftungsbeschränkt) • Amtsgericht Berlin-Charlottenburg • HRB 201976 B • Geschäftsführer: Herr Ara Hacopian\n"))
                     (user-mail-address . "ara@tehanu.net")
                     (mu4e-compose-reply-to-address . "ara@tehanu.net")))))
  :init
  (setq mail-user-agent 'mu4e-user-agent)
  (setq mu4e-maildir-shortcuts
        '(("/fastmail/INBOX"     . ?i)
          ("/fastmail/Archive"   . ?a)
          ("/fastmail/Sent"      . ?s)))
  (setq mu4e-get-mail-command "killall mbsync; mbsync fastmail")
  (setq mu4e-attachment-dir "~/Downloads")
  (setq mu4e-change-filenames-when-moving t)
  (setq mu4e-confirm-quit nil)
  (setq mu4e-headers-date-format "%Y-%m-%d %H:%M")
  (setq mu4e-maildir "~/Maildir")
  (setq mu4e-mu-binary "/run/current-system/sw/bin/mu")
  (setq mu4e-refile-folder "/fastmail/Archive")
  (setq mu4e-drafts-folder "/fastmail/Drafts")
  (setq mu4e-sent-folder "/fastmail/Sent")
  (setq mu4e-sent-messages-behavior 'sent)
  (setq mu4e-trash-folder "/fastmail/Trash")
  (setq mu4e-headers-fields '((:human-date . 16)
                              (:flags . 6)
                              (:from-or-to . 18)
                              (:subject . nil)))
  (setq mu4e-update-interval 300)
  (setq mu4e-view-image-max-width 600)
  (setq mu4e-view-prefer-html nil)
  (setq mu4e-compose-format-flowed t)
  (setq fill-flowed-encode-column 998)
  (setq visual-line-fringe-indicators '(left-curly-arrow right-curly-arrow))
  (setq message-kill-buffer-on-exit t)
  (setq mu4e-headers-toggle-threading nil)
  (setq mu4e-view-show-addresses t))

(use-package org-mu4e
  :ensure nil
  :after (mu4e)
  :load-path "/run/current-system/sw/share/emacs/site-lisp/mu4e/"
  :init
  (setq org-mu4e-link-query-in-headers-mode nil))

(use-package pdf-tools
  :config (pdf-tools-install))

(use-package language-detection
  :config
  (defun eww-tag-pre (dom)
    (let ((shr-folding-mode 'none)
          (shr-current-font 'default))
      (shr-ensure-newline)
      (insert (eww-fontify-pre dom))
      (shr-ensure-newline)))

  (defun eww-fontify-pre (dom)
    (with-temp-buffer
      (shr-generic dom)
      (let ((mode (eww-buffer-auto-detect-mode)))
        (when mode
          (eww-fontify-buffer mode)))
      (buffer-string)))

  (defun eww-fontify-buffer (mode)
    (delay-mode-hooks (funcall mode))
    (font-lock-default-function mode)
    (font-lock-default-fontify-region (point-min)
                                      (point-max)
                                      nil))

  (defun eww-buffer-auto-detect-mode ()
    (let* ((map '((ada ada-mode)
                  (awk awk-mode)
                  (c c-mode)
                  (cpp c++-mode)
                  (clojure clojure-mode lisp-mode)
                  (csharp csharp-mode java-mode)
                  (css css-mode)
                  (dart dart-mode)
                  (delphi delphi-mode)
                  (emacslisp emacs-lisp-mode)
                  (erlang erlang-mode)
                  (fortran fortran-mode)
                  (fsharp fsharp-mode)
                  (go go-mode)
                  (groovy groovy-mode)
                  (haskell haskell-mode)
                  (html html-mode)
                  (java java-mode)
                  (javascript javascript-mode)
                  (json json-mode javascript-mode)
                  (latex latex-mode)
                  (lisp lisp-mode)
                  (lua lua-mode)
                  (matlab matlab-mode octave-mode)
                  (objc objc-mode c-mode)
                  (perl perl-mode)
                  (php php-mode)
                  (prolog prolog-mode)
                  (python python-mode)
                  (r r-mode)
                  (ruby ruby-mode)
                  (rust rust-mode)
                  (scala scala-mode)
                  (shell shell-script-mode)
                  (smalltalk smalltalk-mode)
                  (sql sql-mode)
                  (swift swift-mode)
                  (visualbasic visual-basic-mode)
                  (xml sgml-mode)))
           (language (language-detection-string
                      (buffer-substring-no-properties (point-min) (point-max))))
           (modes (cdr (assoc language map)))
           (mode (cl-loop for mode in modes
                          when (fboundp mode)
                          return mode)))
      (message (format "%s" language))
      (when (fboundp mode)
        mode)))

  (setq shr-external-rendering-functions
        '((pre . eww-tag-pre))))

(use-package elfeed
  ;; :straight (elfeed :type git :flavor melpa :host github :repo "skeeto/elfeed"
  ;;                  :fork (:host github :repo "ahacop/elfeed" :branch "add-title-decode-html-for-atom"))
  :hook (elfeed-show-mode . ah/make-readable)
  :bind (:map elfeed-show-mode-map
        ("&" . ah/elfeed-show-visit)
        ("m" . ah/elfeed-show-stream-media)
        :map elfeed-search-mode-map
        ("h" . ah/elfeed-search-reset-filter)
        ("l" . ah/elfeed-switch-to-log)
        ("t" . ah/elfeed-toggle-filter-youtube)
        ("i" . ah/elfeed-toggle-filter-instagram)
        ("j" . next-line)
        ("k" . previous-line))
  :init
  (setq elfeed-search-filter "+unread @2-days-ago ")
  :config
  (defun ah/elfeed-show-visit ()
    (interactive)
    (let ((link (elfeed-entry-link elfeed-show-entry)))
      (when link
        (message "Sent to browser: %s" link)
        (browse-url-firefox link))))

  (defun ah/elfeed-search-reset-filter
      (interactive)
    (elfeed-search-set-filter (default-value 'elfeed-search-filter)))

  (defun ah/elfeed-switch-to-log ()
    (interactive)
    (switch-to-buffer (elfeed-log-buffer)))

  (defun ah/elfeed-toggle-filter-youtube ()
    (interactive)
    (cl-macrolet ((re (re rep str) `(replace-regexp-in-string ,re ,rep ,str)))
      (elfeed-search-set-filter
       (cond
        ((string-match-p "-youtube" elfeed-search-filter)
         (re " *-youtube" " +youtube" elfeed-search-filter))
        ((string-match-p "\\+youtube" elfeed-search-filter)
         (re " *\\+youtube" " -youtube" elfeed-search-filter))
        ((concat elfeed-search-filter " -youtube"))))))

  (defun ah/elfeed-toggle-filter-instagram ()
    (interactive)
    (cl-macrolet ((re (re rep str) `(replace-regexp-in-string ,re ,rep ,str)))
      (elfeed-search-set-filter
       (cond
        ((string-match-p "-instagram" elfeed-search-filter)
         (re " *-instagram" " +instagram" elfeed-search-filter))
        ((string-match-p "\\+instagram" elfeed-search-filter)
         (re " *\\+instagram" " -instagram" elfeed-search-filter))
        ((concat elfeed-search-filter " -instagram"))))))

  (defface elfeed-youtube
    '((t :foreground "#f9f"))
    "Marks YouTube videos in Elfeed."
    :group 'elfeed)

  (push '(youtube elfeed-youtube) elfeed-search-face-alist)

  (defface elfeed-instagram
    '((t :foreground "#0ff"))
    "Marks Instagram feeds in Elfeed."
    :group 'elfeed)

  (push '(instagram elfeed-instagram) elfeed-search-face-alist)

  (defun ah/elfeed-show-stream-media ()
    (interactive)
    (start-process "cvlc" nil "cvlc" "--no-video-title-show" (elfeed-entry-link elfeed-show-entry)))
  )

(use-package elfeed-org
  :config (elfeed-org)
  :init (setq rmh-elfeed-org-files (list "~/code/org/elfeed.org")))
