;;; GNU Guix --- Functional package management for GNU
;;; Copyright © 2017, 2018 Oleg Pykhalov <go.wigust@gmail.com>
;;;
;;; This file is part of GNU Guix.
;;;
;;; GNU Guix is free software; you can redistribute it and/or modify it
;;; under the terms of the GNU General Public License as published by
;;; the Free Software Foundation; either version 3 of the License, or (at
;;; your option) any later version.
;;;
;;; GNU Guix is distributed in the hope that it will be useful, but
;;; WITHOUT ANY WARRANTY; without even the implied warranty of
;;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;;; GNU General Public License for more details.
;;;
;;; You should have received a copy of the GNU General Public License
;;; along with GNU Guix.  If not, see <http://www.gnu.org/licenses/>.

(define-module (gnu packages wigust-emacs)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (guix packages)
  #:use-module (guix download)
  #:use-module (guix git-download)
  #:use-module (guix hg-download)
  #:use-module (guix gexp)
  #:use-module (guix monads)
  #:use-module (guix store)
  #:use-module (guix build-system gnu)
  #:use-module (guix build-system emacs)
  #:use-module (guix build-system glib-or-gtk)
  #:use-module (guix build-system trivial)
  #:use-module (gnu packages)
  #:use-module (gnu packages audio)
  #:use-module (gnu packages bash)
  #:use-module (gnu packages shells)
  #:use-module (gnu packages chez)
  #:use-module (gnu packages code)
  #:use-module (gnu packages gawk)
  #:use-module (gnu packages guile)
  #:use-module (gnu packages gtk)
  #:use-module (gnu packages gnome)
  #:use-module (gnu packages ncurses)
  #:use-module (gnu packages python)
  #:use-module (gnu packages haskell)
  #:use-module (gnu packages tex)
  #:use-module (gnu packages texinfo)
  #:use-module (gnu packages libevent)
  #:use-module (gnu packages tcl)
  #:use-module (gnu packages tls)
  #:use-module (gnu packages pkg-config)
  #:use-module (gnu packages xorg)
  #:use-module (gnu packages lesstif)
  #:use-module (gnu packages image)
  #:use-module (gnu packages mail)
  #:use-module (gnu packages linux)
  #:use-module (gnu packages version-control)
  #:use-module (gnu packages imagemagick)
  #:use-module (gnu packages w3m)
  #:use-module (gnu packages wget)
  #:use-module (gnu packages autotools)
  #:use-module (gnu packages base)
  #:use-module (gnu packages compression)
  #:use-module (gnu packages xml)
  #:use-module (gnu packages glib)
  #:use-module (gnu packages acl)
  #:use-module (gnu packages package-management)
  #:use-module (gnu packages password-utils)
  #:use-module (gnu packages perl)
  #:use-module (gnu packages pdf)
  #:use-module (gnu packages scheme)
  #:use-module (gnu packages statistics)
  #:use-module (gnu packages xiph)
  #:use-module (gnu packages mp3)
  #:use-module (gnu packages gettext)
  #:use-module (gnu packages fribidi)
  #:use-module (gnu packages gd)
  #:use-module (gnu packages fontutils)
  #:use-module (gnu packages ocaml)
  #:use-module (gnu packages emacs)
  #:use-module (gnu packages xdisorg)
  #:use-module (guix utils)
  #:use-module (srfi srfi-1)
  #:use-module (ice-9 match))

(define-public emacs-athena
  ;; GTK+ could kill emacs --daemon,
  ;; see <https://bugzilla.gnome.org/show_bug.cgi?id=85715>.
  (package
    (inherit emacs)
    (name "emacs-athena")
    (source
     (origin
       (inherit (package-source emacs))
       (patches (fold cons* '()
                      (origin-patches (package-source emacs))
                      (search-patches "emacs-xterm-mouse-support.patch")))))
    (synopsis "The extensible, customizable, self-documenting text
editor with athena toolkit" )
    (build-system gnu-build-system)
    (inputs `(("libxaw" ,libxaw)
              ,@(alist-delete "gtk+" (package-inputs emacs))))
    (arguments
     `(#:configure-flags '("--with-x-toolkit=athena")
                         ,@(package-arguments emacs)))))

(define-public emacs-athena-next
  (let ((commit "4122d54067c61bbdff5aab7ddf5dfe5b5797b218"))
    (package
      (inherit emacs-athena)
      (name "emacs-athena-next")
      (version (string-append "26" "." (string-take commit 7)))
      (source
       (origin
         (method url-fetch)
         (uri (string-append "https://git.savannah.gnu.org/cgit/"
                             "emacs.git/snapshot/emacs-"
                             commit ".tar.gz"))
         (file-name (string-append name "-" version ".tar.gz"))
         (patches (search-patches "emacs-exec-path.patch"
                                  "emacs-source-date-epoch.patch"))
         (modules '((guix build utils)))
         (snippet
          ;; Delete the bundled byte-compiled elisp files and
          ;; generated autoloads.
          '(with-directory-excursion "lisp"
             (for-each delete-file
                       (append (find-files "." "\\.elc$")
                               (find-files "." "loaddefs\\.el$")))

             ;; Make sure Tramp looks for binaries in the right places on
             ;; remote GuixSD machines, where 'getconf PATH' returns
             ;; something bogus.
             (substitute* "net/tramp-sh.el"
               ;; Patch the line after "(defcustom tramp-remote-path".
               (("\\(tramp-default-remote-path")
                (format #f "(tramp-default-remote-path ~s ~s ~s ~s "
                        "~/.guix-profile/bin" "~/.guix-profile/sbin"
                        "/run/current-system/profile/bin"
                        "/run/current-system/profile/sbin")))))
         (sha256
          (base32 "1bngb51hjwjygv8gj9hdnbyvch2w1v9c5dg24igmk95sj7ncx0yq"))))
      (native-inputs
       `(("autoconf" ,autoconf)
         ("automake" ,automake)
         ,@(package-native-inputs emacs)))
      (arguments
       (substitute-keyword-arguments
           `(#:parallel-build? #t
             #:tests? #f
             ,@(package-arguments emacs))
         ((#:phases phases)
          `(modify-phases ,phases
             (add-after 'unpack 'autogen
               (lambda _
                 (zero? (system* "sh" "autogen.sh"))))
             (delete 'reset-gzip-timestamps))))))))

(define-public emacs-company-tern
  (package
    (name "emacs-company-tern")
    (version "0.3.0")
    (source
     (origin
       (method url-fetch)
       (uri (string-append
             "https://github.com/proofit404/company-tern/archive/"
             "v" version ".tar.gz"))
       (file-name (string-append name "-" version ".tar.gz"))
       (sha256
        (base32
         "1qgrgnbajgnsnx4az4ajnlrhc73q0xxjikk617nf3cs87x4772a6"))))
    (build-system emacs-build-system)
    (propagated-inputs
     `(("emacs-company" ,emacs-company)
       ("emacs-tern" ,emacs-tern)
       ("emacs-dash" ,emacs-dash)
       ("emacs-s" ,emacs-s)))
    (home-page "https://github.com/proofit404/company-tern")
    (synopsis "Tern backend for company-mode")
    (description "This package provides Tern backend for Company.")
    (license license:gpl3+)))

;; XXX: Broken.  Upstream doesn't respond.  Alternatively use ivy youtube.
#;(define-public emacs-helm-youtube
  (let ((revision "1")
        (commit "202c27fc3b54927611e9d9c764465e1b42ef7e41"))
    (package
      (name "emacs-helm-youtube")
      (version "1.1")
      (source
       (origin
         (method git-fetch)
         (uri (git-reference
               (url "https://github.com/maximus12793/helm-youtube.git")
               (commit commit)))
         (file-name (string-append name "-" version "-checkout"))
         (sha256
          (base32
           "1wqxcz03fq2z31a1n90dg9ap3451vx1376ijbpfy9sg66pgj8yxv"))))
      (build-system emacs-build-system)
      (propagated-inputs
       `(("emacs-request" ,emacs-request)
         ("emacs-helm" ,emacs-helm)))
      (home-page "https://github.com/maximus12793/helm-youtube")
      (synopsis "Query YouTube and play videos in your browser")
      (description "This package provides an interactive prompt to search on
Youtube.")
      (license license:gpl3+))))

(define-public emacs-indium
  (package
    (name "emacs-indium")
    (version "0.7.3")
    (source
     (origin
       (method url-fetch)
       (uri (string-append "https://github.com/NicolasPetton/Indium/archive/"
                           version ".tar.gz"))
       (sha256
        (base32
         "1r4cag75w11giihh5kkczppqibwc0qr237s5p00y5cvv6z3hhy8g"))))
    (build-system emacs-build-system)
    (propagated-inputs
     `(("emacs-seq" ,emacs-seq)
       ("emacs-js2-mode" ,emacs-js2-mode)
       ("emacs-company" ,emacs-company)
       ("emacs-websocket" ,emacs-websocket)
       ("emacs-memoize" ,emacs-memoize)
       ("emacs-sourcemap" ,emacs-sourcemap)))
    (home-page "https://github.com/NicolasPetton/indium")
    (synopsis "JavaScript Awesome Development Environment")
    (description "Indium connects to a browser tab or nodejs process and
provides many features for JavaScript development, including a REPL (with auto
completion) & object inspection, an inspector, with history and navigation,
and even a stepping Debugger, similar to @code{edebug}, or @code{cider}.")
    (license license:gpl3+)))

(define-public emacs-org-protocol-capture-html
  (let ((commit "0e39b7e2261599d28e6bbd094a0657d9315719bc")
        (revision "1"))
    (package
      (name "emacs-org-protocol-capture-html")
      (version (string-append "0.0.1-" revision "."
                              (string-take commit 7)))
      (source
       (origin
         (method git-fetch)
         (uri
          (git-reference
           (url "https://github.com/alphapapa/org-protocol-capture-html.git")
           (commit commit)))
         (file-name (string-append name "-" version "-checkout"))
         (sha256
          (base32
           "0l80nb2dxfm1bws1rqqkavswnpyqbwlv84q1zp4lrsfarjb3l56c"))))
      (build-system emacs-build-system)
      (propagated-inputs
       `(("pandoc" ,ghc-pandoc)))
      (arguments
       `(#:phases
         (modify-phases %standard-phases
           (add-after 'install 'install-shell-script
             (lambda* (#:key outputs #:allow-other-keys)
               (install-file "org-protocol-capture-html.sh"
                             (string-append (assoc-ref outputs "out")
                                            "/bin")))))))
      (home-page "https://github.com/alphapapa/org-protocol-capture-html")
      (synopsis "Captures Web pages into Org using Pandoc to process HTML")
      (description "This package captures Web pages into Org-mode using Pandoc to
process HTML.  It can also use eww's eww-readable functionality to
get the main content of a page.

These are the helper functions that run in Emacs.  To capture pages
into Emacs, you can use either a browser bookmarklet or the
org-protocol-capture-html.sh shell script.  See the README.org file
for instructions.")
      (license license:gpl3+))))

(define-public emacs-rjsx-mode
  (package
    (name "emacs-rjsx-mode")
    (version "0.4.0")
    (source
     (origin
       (method url-fetch)
       (uri (string-append "https://github.com/felipeochoa/rjsx-mode/archive/"
                           "v" version ".tar.gz"))
       (file-name (string-append name "-" version ".tar.gz"))
       (sha256
        (base32
         "0n43wm7s19csbnk2gsqpnb6pcywa7l51rx5z9d35x13bm9f3q0ap"))))
    (build-system emacs-build-system)
    (propagated-inputs
     `(("emacs-js2-mode" ,emacs-js2-mode)))
    (home-page "https://github.com/felipeochoa/rjsx-mode/")
    (synopsis "Real support for JSX")
    (description "Defines a major mode @code{rjsx-mode} based on
@code{js2-mode} for editing JSX files.  @code{rjsx-mode} extends the parser in
@code{js2-mode} to support the full JSX syntax.  This means you get all of the
@code{js2} features plus proper syntax checking and highlighting of JSX code
blocks.

Some features that this mode adds to js2:

@itemize
@item Highlighting JSX tag names and attributes (using the rjsx-tag and
rjsx-attr faces)
@item Highlight undeclared JSX components
@item Parsing the spread operator {...otherProps}
@item Parsing && and || in child expressions {cond && <BigComponent/>}
@item Parsing ternary expressions {toggle ? <ToggleOn /> : <ToggleOff />}
@end itemize

Additionally, since rjsx-mode extends the js2 AST, utilities using
the parse tree gain access to the JSX structure.")
    (license license:gpl3+)))

(define-public emacs-tern
  (package
    (name "emacs-tern")
    (version "0.21.0")
    (source
     (origin
       (method url-fetch)
       (uri (string-append "https://github.com/ternjs/tern/archive/"
                           version ".tar.gz"))
       (file-name (string-append name "-" version ".tar.gz"))
       (sha256
        (base32
         "1pzchd29i6dxfgm0ackr2vc2xqpczjkwl5h6l8jils0bcfaj48ss"))))
    (build-system emacs-build-system)
    (arguments
     `(#:phases
       (modify-phases %standard-phases
         (add-after 'unpack 'chdir-elisp
           ;; Elisp directory is not in root of the source.
           (lambda _
             (chdir "emacs"))))))
    (home-page "http://ternjs.net/")
    (synopsis "Tern-powered JavaScript integration")
    (description "Tern-powered JavaScript integration.")
    (license license:gpl3+)))

(define-public emacs-indium-checkout
  (let ((commit "d98a9e0cd11d8230c4c3d0b59c4ac60520e34ebb")
        (revision "1"))
    (package
      (inherit emacs-indium)
      (name "emacs-indium")
      (version (string-append (package-version emacs-indium) "-" revision "."
                              (string-take commit 7)))
      (source
       (origin
         (method git-fetch)
         (uri (git-reference
               (url "https://github.com/NicolasPetton/Indium.git")
               (commit commit)))
         (file-name (string-append name "-" version "-checkout"))
         (sha256
          (base32
           "1q3yf45fmbjppv3ahb1gdb95pa3kyn18x5m23ihpxz1pziz3a074")))))))

(define-public emacs-helm-notmuch
  (package
    (name "emacs-helm-notmuch")
    (version "1.1")
    (source
     (origin
       (method url-fetch)
       (uri (string-append "https://github.com/xuchunyang/helm-notmuch/archive/"
                           version ".tar.gz"))
       (file-name (string-append name "-" version ".tar.gz"))
       (sha256
        (base32
         "09b3jllppfmk0mb1qvgcx705jwixqn5ggl0bql6g5a3i7yy6xpyd"))))
    (build-system emacs-build-system)
    ;; TODO: helm-notmuch.el:36:1:Error: Cannot open load file:
    ;; No such file or directory, notmuch
    (propagated-inputs
     `(("notmuch" ,notmuch)
       ("emacs-helm" ,emacs-helm)))
    (home-page "https://github.com/xuchunyang/helm-notmuch")
    (synopsis "Search emails with Notmuch and Helm")
    (description
     "Search emails, searching result displays as you type thanks to helm.")
    (license license:gpl3+)))

(define-public emacs-js3-mode
  (let ((commit "229aeb374f1b1f3ee5c59b8ba3eebb6385c232cb"))
    (package
      (name "emacs-js3-mode")
      (version (git-version "1.1.0" "1" commit))
      (source
       (origin
         (method git-fetch)
         (uri (git-reference
               (url "https://github.com/thomblake/js3-mode")
               (commit commit)))
         (file-name (git-file-name name version))
         (sha256
          (base32
           "0yd2lck1kq01pxk86jpxff5ih6fxx1a1wvl7v8b5ys7gi33fjqz2"))))
      (build-system emacs-build-system)
      (home-page "https://github.com/thomblake/js3-mode")
      (synopsis "Improved JavaScript editing mode")
      (description
       "This package provides a JavaScript editing mode for Emacs.")
      (license license:gpl3+))))

(define-public emacs-js-comint
  (package
    (name "emacs-js-comint")
    (version "1.1.1")
    (source
     (origin
       (method url-fetch)
       (uri (string-append "https://github.com/redguardtoo/js-comint/archive/"
                           version ".tar.gz"))
       (sha256
        (base32
         "0prsmz274i3891w5ppp9wzf4q7jwjsi6yaainwpcpiwx23qckrr6"))))
    (build-system emacs-build-system)
    (home-page "https://github.com/redguardtoo/js-comint")
    (synopsis "JavaScript interpreter in Emacs window")
    (description "This package provides a program is a comint mode for Emacs
which allows you to run a compatible javascript REPL like Node.js,
Spidermonkey, Rhino inside Emacs.  It also defines a few functions for sending
JavaScript input to it quickly.")
    (license license:gpl3+)))

(define-public emacs-eval-in-repl
  (package
    (name "emacs-eval-in-repl")
    (version "0.9.6")
    (source
     (origin
       (method url-fetch)
       (uri (string-append
             "https://github.com/kaz-yos/eval-in-repl/archive/"
             "v" version ".tar.gz"))
       (file-name (string-append name "-" version ".tar.gz"))
       (sha256
        (base32
         "1lw97llr0lzipbi4a7q7qrjvqz9g7bip46rkm88sgbagh218sjr4"))))
    (build-system emacs-build-system)
    (propagated-inputs
     `(("emacs-dash" ,emacs-dash)
       ("emacs-paredit" ,paredit)
       ("emacs-ace-window" ,emacs-ace-window)))
    (inputs
     `(("emacs-slime" ,emacs-slime)
       ("emacs-sml-mode" ,emacs-sml-mode)
       ("emacs-cider" ,emacs-cider)
       ("geiser" ,geiser)
       ("emacs-lua-mode" ,emacs-lua-mode)
       ("emacs-js2-mode" ,emacs-js2-mode)
       ("emacs-js3-mode" ,emacs-js3-mode)
       ("emacs-js-comint" ,emacs-js-comint)
       ("emacs-inf-ruby" ,emacs-inf-ruby)
       ("emacs-tuareg" ,emacs-tuareg)
       ("emacs-hy-mode" ,emacs-hy-mode)
       ("emacs-racket-mode" ,emacs-racket-mode)))
    (home-page "https://github.com/kaz-yos/eval-in-repl/")
    (synopsis "Consistent ESS-like eval interface for various REPLs")
    (description "Consistent ESS-like eval interface for various REPLs")
    (license license:gpl3+)))

(define-public emacs-assess
  (package
    (name "emacs-assess")
    (version "0.4")
    (source
     (origin
       (method url-fetch)
       (uri (string-append "https://github.com/phillord/assess"
                           "/archive/" "v" version ".tar.gz"))
       (file-name (string-append name "-" version ".tar.gz"))
       (sha256
        (base32
         "19q1zhalljzidg5lwl3l293ypqpy6x1bn8h1wr4a4jjzzv56ahak"))))
    (inputs
     `(("emacs-m-buffer-el" ,emacs-m-buffer-el)))
    (arguments
     `(#:phases
       (modify-phases %standard-phases
         (add-before 'install 'check
           (lambda* (#:key inputs #:allow-other-keys)
             (zero? (system* "emacs" "--batch" "-L" "."
                             "-L" (string-append
                                   (assoc-ref inputs "emacs-m-buffer-el")
                                   "/share/emacs/site-lisp/guix.d/m-buffer-el-"
                                   ,(package-version emacs-m-buffer-el))
                             "-l" "test/assess-test.el"
                             "-f" "ert-run-tests-batch-and-exit")))))))
    (build-system emacs-build-system)
    (home-page "https://github.com/phillord/assess")
    (synopsis "Test support functions for Emacs")
    (description "@code{assess} provides additional support for
testing Emacs packages.

It provides:

@itemize
@item A set of predicates for comparing strings, buffers and file
contents.
@item Explainer functions for all predicates giving useful output.
@item Macros for creating many temporary buffers at once, and for
restoring the buffer list.
@item Methods for testing indentation, by comparision or
roundtripping.
@item Methods for testing fontification.
@item Assess aims to be a stateless as possible, leaving Emacs
unchanged whether the tests succeed or fail, with respect to buffers,
open files and so on.  This helps to keep tests independent from each
other.
@end itemize\n")
    (license license:gpl3+)))

(define-public emacs-password-store
  (package
    (inherit password-store)
    (name "emacs-password-store")
    (build-system emacs-build-system)
    (arguments
     `(#:phases
       (modify-phases %standard-phases
         (add-after 'unpack 'chdir-elisp
           ;; Elisp directory is not in root of the source.
           (lambda _
             (chdir "contrib/emacs"))))))
    (propagated-inputs
     `(,@(package-propagated-inputs password-store)
       ("emacs-f" ,emacs-f)))
    (synopsis "Emacs interface to @code{password store}")
    (description "Emacs interface to @code{password store}")
    (license license:gpl3+)))

(define-public emacs-auth-password-store
  (package
    (name "emacs-auth-password-store")
    (version "2.0.0")
    (source
     (origin
       (method url-fetch)
       (uri (string-append "https://github.com/DamienCassou"
                           "/auth-password-store"
                           "/archive/" "v" version ".tar.gz"))
       (file-name (string-append name "-" version ".tar.gz"))
       (sha256
        (base32
         "1n9623hsx6vsq87y6a2731ydfi0x8fvfb6m7fbdfy726d4pnr09q"))))
    (build-system emacs-build-system)
    (propagated-inputs
     `(("emacs-dash" ,emacs-dash)
       ("emacs-f" ,emacs-f)
       ("emacs-s" ,emacs-s)
       ("emacs-password-store" ,emacs-password-store)))
    (arguments
     `(#:phases
       (modify-phases %standard-phases
         (add-before 'install 'check
           (lambda* (#:key inputs #:allow-other-keys)
             (zero? (system* "emacs" "--batch" "-L" "."
                             "-L" (string-append
                                   (assoc-ref inputs "emacs-password-store")
                                   "/share/emacs/site-lisp/guix.d/password-store-"
                                   ,(package-version emacs-password-store))
                             "-L" (string-append
                                   (assoc-ref inputs "emacs-f")
                                   "/share/emacs/site-lisp/guix.d/f-"
                                   ,(package-version emacs-f))
                             "-L" (string-append
                                   (assoc-ref inputs "emacs-s")
                                   "/share/emacs/site-lisp/guix.d/s-"
                                   ,(package-version emacs-s))
                             "-L" (string-append
                                   (assoc-ref inputs "emacs-dash")
                                   "/share/emacs/site-lisp/guix.d/dash-"
                                   ,(package-version emacs-dash))
                             "-l" "test/auth-password-store-tests.el"
                             "-f" "ert-run-tests-batch-and-exit")))))))
    (home-page "https://github.com/DamienCassou/auth-password-store")
    (synopsis "Integrate Emacs auth-source with password-store")
    (description "@code{emacs-auth-password-store} integrates Emacs
auth-source library with @code{password-store}.")
    (license license:gpl3+)))

(define-public emacs-xml-rpc
  (package
    (name "emacs-xml-rpc")
    (version "1.6.12")
    (source (origin
              (method url-fetch)
              (uri (string-append
                    "https://github.com/hexmode/xml-rpc-el/archive/"
                    version ".tar.gz"))
              (file-name (string-append name "-" version ".tar.gz"))
              (sha256
               (base32
                "01izmsxk0ja77nxwgjzyb3k5wgndnx7i9qvkyb8f12bwrjn0rga0"))))
    (build-system emacs-build-system)
    ;; TODO: Package tests
    (home-page "https://github.com/hexmode/xml-rpc-el")
    (synopsis "XML-RPC client implementation in elisp")
    (description "This package provides an XML-RPC client
implementation in elisp, capable of both synchronous and asynchronous
method calls.")
    (license license:gpl3+)))

(define-public emacs-debpaste
  (package
    (name "emacs-debpaste")
    (version "0.1.5")
    (source (origin
              (method url-fetch)
              (uri (string-append
                    "https://github.com/alezost/debpaste.el/archive/"
                    "v" version ".tar.gz"))
              (file-name (string-append name "-" version ".tar.gz"))
              (sha256
               (base32
                "16qqa32ys3gvxf9x1va2cnjcmw1zvbwgc16pqasgrf4mh7qwsd9b"))))
    (build-system emacs-build-system)
    (propagated-inputs `(("emacs-xml-rpc" ,emacs-xml-rpc)))
    (home-page "https://github.com/alezost/debpaste.el")
    (synopsis "Emacs interface for the Debian Paste Service")
    (description "Debpaste is an Emacs interface for the
@uref{https://paste.debian.net, Debian Paste Service}.  It provides
receiving, posting and deleting pastes using XML-RPC.")
    (license license:gpl3+)))

(define emacs-wi-web-search
  (let ((commit "33fa377156f487e41deda62cd92110d707907c66"))
    (package
      (name "emacs-wi-web-search")
      (version (string-append "0.0.1" "-" (string-take commit 7)))
      (source
       (origin
         (method git-fetch)
         (uri (git-reference
               (url "https://github.com/wigust/.git")
               (commit commit)))
         (file-name (string-append name "-" version "-checkout"))
         (sha256
          (base32
           "04lxmd0h7mfjjl0qghrycgff0vcv950j1wqv0dbkr61jxp64n5fv"))))
      (build-system emacs-build-system)
      (home-page "https://github.com/wigust/emacs-wi-web-search")
      (synopsis "Emacs function to search in web")
      (description "@code{wi-web-search} provides the Emacs function
to search in web.")
      (license license:gpl3+))))

;; TODO: `M-x mastodon': json-read: End of file while parsing JSON
(define-public emacs-mastodon
  (let ((commit "e08bb5794762d22f90e85fd65cef7c143e6b9318")
        (revision "1"))
    (package
      (name "emacs-mastodon")
      (version (string-append "0.7.1" "-" revision "."
                              (string-take commit 7)))
      (source
       (origin
         (method git-fetch)
         (uri (git-reference
               (url "https://github.com/jdenen/mastodon.el.git")
               (commit commit)))
         (file-name (string-append name "-" version "-checkout"))
         (sha256
          (base32
           "0bil0xxava04pd4acjqm3bfqm1kjdk4g0czd4zqvacsp5c9sl2qp"))))
      (arguments
       `(#:phases
         (modify-phases %standard-phases
           (add-after 'unpack 'chdir-elisp
             ;; Elisp directory is not in root of the source.
             (lambda _
               (chdir "lisp")))
           ;; TODO: Tests:
           ;; (add-before 'install 'check
           ;;   (lambda _
           ;;     (with-directory-excursion ".."
           ;;       (zero? (system* "emacs" "--batch" "-L" "lisp"
           ;;                     "-l" "test/ert-helper.el"
           ;;                     "-f" "ert-run-tests-batch-and-exit")))))
           )))
      (build-system emacs-build-system)
      (home-page "https://github.com/jdenen/mastodon.el")
      (synopsis "Emacs client for Mastodon social network")
      (description "This package provides an Emacs client for
Mastodon federated social network.")
      (license license:gpl3+))))

(define-public emacs-engine-mode-autoload
  (package
    (inherit emacs-engine-mode)
    (name "emacs-engine-mode-autoload")
    (source
     (origin
       (inherit (package-source emacs-engine-mode))
       (modules '((guix build utils)))
       (snippet
        '(substitute* "engine-mode.el"
           (("\\(cl-defmacro defengine" line)
            (string-append ";;;###autoload\n" line))))))))

(define-public emacs-strace-mode-special
  (package
    (inherit emacs-strace-mode)
    (name "emacs-strace-mode-special")
    (arguments
     `(#:phases
       (modify-phases %standard-phases
         (add-after 'unpack 'patch-source
           (lambda _
             (substitute* "strace-mode.el"
               (("fundamental-mode") "special-mode")))))))))

(define-public emacs-24
  (package
    (name "emacs-24")
    (version "24.5")
    (source (origin
              (method url-fetch)
              (uri (string-append "mirror://gnu/emacs/emacs-"
                                  version ".tar.xz"))
              (sha256
               (base32
                "0kn3rzm91qiswi0cql89kbv6mqn27rwsyjfb8xmwy9m5s8fxfiyx"))))
    (build-system glib-or-gtk-build-system)
    (arguments
     '(#:phases (alist-cons-before
                 'configure 'fix-/bin/pwd
                 (lambda _
                   ;; Use `pwd', not `/bin/pwd'.
                   (substitute* (find-files "." "^Makefile\\.in$")
                     (("/bin/pwd")
                      "pwd")))
                 %standard-phases)))
    (inputs
     `(("gnutls"  ,gnutls)
       ("ncurses" ,ncurses)

       ;; TODO: Add the optional dependencies.
       ("libx11"  ,libx11)
       ("gtk+"    ,gtk+)
       ("libxft"  ,libxft)
       ("libtiff" ,libtiff)
       ("giflib"  ,giflib)
       ("libjpeg" ,libjpeg-8)
       ("acl"     ,acl)

       ;; When looking for libpng `configure' links with `-lpng -lz', so we
       ;; must also provide zlib as an input.
       ("libpng" ,libpng)
       ("zlib"   ,zlib)

       ("librsvg"  ,librsvg)
       ("libxpm"   ,libxpm)
       ("libxml2"  ,libxml2)
       ("libice"   ,libice)
       ("libsm"    ,libsm)
       ("alsa-lib" ,alsa-lib)
       ("dbus"     ,dbus)))
    (native-inputs
     `(("pkg-config" ,pkg-config)
       ("texinfo"    ,texinfo)))
    (home-page "http://www.gnu.org/software/emacs/")
    (synopsis "The extensible, customizable, self-documenting text editor")
    (description
     "GNU Emacs is an extensible and highly customizable text editor.  It is
based on an Emacs Lisp interpreter with extensions for text editing.  Emacs
has been extended in essentially all areas of computing, giving rise to a
vast array of packages supporting, e.g., email, IRC and XMPP messaging,
spreadsheets, remote server editing, and much more.  Emacs includes extensive
documentation on all aspects of the system, from basic editing to writing
large Lisp programs.  It has full Unicode support for nearly all human
languages.")
    (license license:gpl3+)))

(define-public emacs-no-x-toolkit-24
  (package (inherit emacs-24)
    (location (source-properties->location (current-source-location)))
    (name "emacs-no-x-toolkit-24")
    (synopsis "The extensible, customizable, self-documenting text
editor (without an X toolkit)" )
    (build-system gnu-build-system)
    (inputs (append `(("inotify-tools" ,inotify-tools))
                    (alist-delete "gtk+" (package-inputs emacs))))
    (arguments (append '(#:configure-flags '("--with-x-toolkit=no"))
                       (package-arguments emacs)))))

(define-public emacs-pcre2el
  (let ((commit "0b5b2a2c173aab3fd14aac6cf5e90ad3bf58fa7d")
        (revision "1"))
      (package
    (name "emacs-pcre2el")
    (version (string-append "1.8" "-" revision "."
                            (string-take commit 7)))
    (source (origin
              (method git-fetch)
              (uri (git-reference
                    (url "https://github.com/joddie/pcre2el")
                    (commit commit)))
              (file-name (string-append name "-" version "-checkout"))
              (sha256
               (base32
                "14br6ad138qx1z822wqssswqiihxiynz1k69p6mcdisr2q8yyi1z"))))
    ;; TODO: Tests:
    ;; (native-inputs
    ;;  `(("ert-runner" ,ert-runner)))
    ;; (arguments
    ;;  `(#:phases
    ;;    (modify-phases %standard-phases
    ;;      (add-after 'install 'check
    ;;        (lambda _
    ;;          (zero? (system* "ert-runner" "pcre2el-tests.el")))))))
    (build-system emacs-build-system)
    (home-page "https://github.com/joddie/pcre2el")
    (synopsis "Convert between PCRE, Emacs and rx regexp syntax")
    (description "Convert between PCRE, Emacs and rx regexp syntax.")
    (license license:gpl3+))))

(define-public emacs-lognav-mode
  (let ((changeset "a9b53f2da040")
        (revision "1"))
      (package
    (name "emacs-lognav-mode")
    (version (string-append "0.0.5-" revision "." changeset))
    (source (origin
              (method hg-fetch)
              (uri (hg-reference
                    (url "https://bitbucket.org/ellisvelo/lognav-mode")
                    (changeset changeset)))
              (file-name (string-append name "-" version "-checkout"))
              (sha256
               (base32
                "0ka92x63zfgraby5ycypn3ri2s3s2b1m2j7fpb4r37bk9xkf90v4"))))
    (build-system emacs-build-system)
    (home-page "https://bitbucket.org/ellisvelo/lognav-mode")
    (synopsis "Navigate log error messages in Emacs")
    (description "Lognav-mode is a minor mode used for finding and navigating
errors within a buffer or a log file.  For example, M-n moves the cursor to
the first error within the log file.  M-p moves the cursor to the previous
error.  Lognav-mode only highlights the errors that are visible on the screen
rather than highlighting all errors found within the buffer.  This is
especially useful when opening up large log files for analysis.")
    (license license:gpl2+))))

(define-public emacs-terminal-here
  (let ((commit "b3659e13d3d41503b4fc59dd2c7ea622631fc3ec")
        (revision "1"))
    (package
      (name "emacs-terminal-here")
      (version (string-append "1.0-" revision "."
                              (string-take commit 7)))
      (source
       (origin
         (method git-fetch)
         (uri (git-reference
               (url "https://github.com/davidshepherd7/terminal-here.git")
               (commit commit)))
         (file-name (string-append name "-" version "-checkout"))
         (sha256
          (base32
           "1z3ngwgv8ybwq42lkpavk51a25zdkl6v9xdfi41njpxdpbfcmx8z"))))
      (build-system emacs-build-system)
      (home-page "https://github.com/davidshepherd7/terminal-here")
      (synopsis "Run an external terminal in current directory")
      (description "Provides commands to help open external terminal emulators
in the directory of the current buffer.")
      (license license:gpl3+))))

(define-public emacs-info-colors
  (package
    (name "emacs-info-colors")
    (version "0.2")
    (source
     (origin
       (method url-fetch)
       (uri (string-append "https://github.com/ubolonton/info-colors/archive/"
                           version ".tar.gz"))
       (file-name (string-append name "-" version ".tar.gz"))
       (sha256
        (base32
         "08xd6y89igxlqpw678xjpxyzs9k28vbbc7sygxcyblgyj6farnml"))
       (patches (search-patches "emacs-info-colors-add-more-syntax.patch"))))
    (build-system emacs-build-system)
    (home-page "https://github.com/ubolonton/info-colors")
    (synopsis "Extra colors for Info-mode")
    (description "This package provides a modern adaption of the extra
coloring provided by Drew Adams @code{info+} package.  To enable this
@code{(add-hook 'Info-selection-hook 'info-colors-fontify-node)}.")
    (license license:gpl3+)))

(define-public emacs-origami
  (let ((commit "1f38085c8f9af7842765ed63f7d6dfe4dab59366")
        (revision "1"))
    (package
      (name "emacs-origami")
      (version (string-append "0.1" revision "."
                              (string-take commit 7)))
      (source (origin
                (method git-fetch)
                (uri (git-reference
                      (url "https://github.com/gregsexton/origami.el.git")
                      (commit commit)))
                (file-name (string-append name "-" version "-checkout"))
                (sha256
                 (base32
                  "0ha1qsz2p36pqa0sa2sp83lspbgx5lr7930qxnwd585liajzdd9x"))))
      (build-system emacs-build-system)
      (propagated-inputs
       `(("emacs-s" ,emacs-s)
         ("emacs-dash" ,emacs-dash)))
      (home-page "https://github.com/gregsexton/origami.el")
      (synopsis "Folding minor mode for Emacs")
      (description
       "This package provides a text folding minor mode for Emacs.")
      (license license:expat))))

(define-public emacs-srfi
  (package
    (name "emacs-srfi")
    (version "1.0")
    (source
     (origin
       (method url-fetch)
       (uri (string-append "https://emacswiki.org/emacs/download/srfi.el"))
       (file-name (string-append "emacs-srfi-" version ".el"))
       (sha256
        (base32
         "05xh6jdgds79xchm01s2r04sv61gglf4v33f1968yw1zfi9g5jhi"))))
    (build-system emacs-build-system)
    (home-page "https://www.emacswiki.org/emacs/srfi.el")
    (synopsis "View Scheme requests for implementation")
    (description "This file provides a functionality to view SRFIs,
Scheme Requests for Implementation, using a simple @code{srfi} command.
To update the local SRFI cache, use @code{srfi-update-cache}.")
    (license license:gpl2+)))

(define-public emacs-awk-it
  (package
    (name "emacs-awk-it")
    (version "0.77")
    (source
     (origin
       (method url-fetch)
       (uri (string-append "https://emacswiki.org/emacs/download/awk-it.el"))
       (file-name (string-append "emacs-awk-it-" version ".el"))
       (sha256
        (base32
         "1r1vbi1r3rdbkyb2naciqwja7hxigjhqfxsfcinnygabsi7fw9aw"))))
    (build-system emacs-build-system)
    (arguments
     `(#:phases
       (modify-phases %standard-phases
         (add-before 'check 'patch-awk-it-file-first-line
           (lambda* (#:key inputs #:allow-other-keys)
             (let ((file "emacs-awk-it.el"))
               (chmod file #o644)
               (emacs-substitute-sexps file
                 ("(defcustom awk-it-file-first-line"
                  (string-append "#!" (assoc-ref inputs "gawk") "/bin/awk"))))
             #t)))))
    (propagated-inputs
     `(("emacs-yasnippet" ,emacs-yasnippet)))
    (inputs
     `(("gawk" ,gawk)))
    (home-page "https://www.emacswiki.org/emacs/awk-it.el")
    (synopsis "Run AWK interactively on region")
    (description "AWK it! allows you to see AWK output as you are typing the
script; it sends selected region to awk and uses yasnippet as interactive UI.

There are 3 modes of AWK code: simplified syntax(default, see below),
single line AWK syntax (regular AWK syntax but only inside the default
match) and raw AWK syntax(full AWK code).  AWK it! can transfrom code
from one mode to another(not perfect, but it will make an effort) and
there is also support for multiple lines.  Data is expanded with
selected yasnippet expand keybinding.")
    (license license:gpl2+)))

(define-public emacs-helm-navi
  (let ((commit "2256591174ff79f889450fdc10822316819d6476"))
    (package
      (name "emacs-helm-navi")
      (version (git-version "0.1" "1" commit))
      (source
       (origin
         (method git-fetch)
         (uri (git-reference
               (url "https://github.com/emacs-helm/helm-navi.git")
               (commit commit)))
         (file-name (git-file-name name version))
         (sha256
          (base32
           "0bbb52v1c81a6ap10qi7mqigi237vwrlmf8mg3ckglm1i710636j"))))
      (build-system emacs-build-system)
      (propagated-inputs
       `(("emacs-helm" ,emacs-helm)
         ("emacs-navi-mode" ,emacs-navi-mode)
         ("emacs-s" ,emacs-s)))
      (home-page "https://github.com/emacs-helm/helm-navi")
      (synopsis "Navigate through a buffer using the headings and keywords")
      (description
       "This file provides commands to navigate a buffer using keywords and
headings provided by @code{navi-mode} and @code{outshine}.")
      (license license:gpl3+))))

(define-public emacs-git-messenger-diff-mode
  (package
    (inherit emacs-git-messenger)
    (name "emacs-git-messenger-diff-mode")
    (source
     (origin
       (inherit (package-source emacs-git-messenger))
       (modules '((guix build utils)))
         (snippet
          '(substitute* "git-messenger.el"
             (("\\(fundamental-mode\\)") "(diff-mode)")))))))

(define-public emacs-atomic-chrome
  (let ((commit "4828a29855f4663add5f2075b7d874354e70c02c"))
    (package
      (name "emacs-atomic-chrome")
      (version (git-version "2.0.0" "1" commit))
      (source (origin
                (method git-fetch)
                (uri (git-reference
                      (url "https://github.com/alpha22jp/atomic-chrome.git")
                      (commit commit)))
                (file-name (git-file-name name version))
                (sha256
                 (base32
                  "15yg8752z3iwizja7wkjvkjrj8pig21ynq5l5m5cr3f1bzx74dx7"))))
      (build-system emacs-build-system)
      (propagated-inputs
       `(("emacs-let-alist" ,emacs-let-alist)
         ("emacs-websocket" ,emacs-websocket)))
      (home-page "https://github.com/alpha22jp/atomic-chrome/")
      (synopsis "Edit text area on Chrome with Emacs using Atomic Chrome")
      (description "This package provides an Emacs version of Atomic Chrome
which is an extension for Google Chrome browser that allows you to edit text
areas of the browser in Emacs.  It's similar to Edit with Emacs, but has some
advantages as below with the help of websocket.")
      (license license:gpl2+))))

(define-public emacs-perl-live
  (package
    (name "emacs-perl-live")
    (version "1")
    (source
     (origin
       (method url-fetch)
       (uri (string-append "https://github.com/vividsnow/perl-live/archive/v"
                           version ".tar.gz"))
       (file-name (string-append name "-" version ".tar.gz"))
       (sha256
        (base32
         "0i1ila542bgfpb5r1w62w5bnhh97mpp9mwpjbfp3kr8qn1ymvqq4"))))
    (build-system emacs-build-system)
    (arguments
     `(#:phases
       (modify-phases %standard-phases
         (add-before 'install 'install-perl-live-pl
           ;; This build phase installs ‘perl-live.pl’ file
           ;; and patches a location to this in ‘perl-live.el’.
           (lambda* (#:key outputs #:allow-other-keys)
             (let ((data (string-append (assoc-ref outputs "out") "/share/"
                                        ,name "-" ,version)))
               (install-file "perl-live.pl" data)
               (let ((file "perl-live.el"))
                 (chmod file #o644)
                 (emacs-substitute-sexps file
                   ("(defcustom perl-live-bin"
                    (which "perl"))
                   ("(defcustom perl-live-script"
                    (string-append data "/perl-live.pl"))))))))))
    (native-inputs
     `(("perl" ,perl)))
    (propagated-inputs
     `(("perl-anyevent" ,perl-anyevent)
       ("perl-package-stash-xs" ,perl-package-stash-xs)
       ("perl-ev" ,perl-ev) ;optional
       ("perl-padwalker" ,perl-padwalker)))
    (home-page "https://github.com/vividsnow/perl-live/")
    (synopsis "Perl live coding")
    (description "This package provides a Perl script for live coding.")
    (license license:gpl3+)))

(define-public emacs-helm-lines
  (let ((commit "4c8d648a2b56e9de79c3199af22e80afe3c01ff5"))
    (package
      (name "emacs-helm-lines")
      (version (git-version "0.1" "1" commit))
      (source (origin
                (method git-fetch)
                (uri (git-reference
                      (url "https://github.com/torgeir/helm-lines.el.git")
                      (commit commit)))
                (file-name (git-file-name name version))
                (sha256
                 (base32
                  "1pxnpplrg1pzs8jgl4ww3hkl2d7r3ixxyjz8f1112634l35ics7c"))))
      (propagated-inputs `(("emacs-helm" ,emacs-helm)))
      (build-system emacs-build-system)
      (home-page "https://github.com/torgeir/helm-lines.el")
      (synopsis "Helm interface for completing by lines elsewhere in a project")
      (description "This package provides a Helm interface for completing by
lines elsewhere in a project.")
      (license license:gpl3+))))

(define-public emacs-bash-completion-2.1.0
  (let ((commit "24088ede85742a94f8e239ba063e8587e553d844"))
    (package
      (inherit emacs-bash-completion)
      (version (git-version "2.1.0" "1" commit))
      (source
       (origin
         (method git-fetch)
         (uri (git-reference
               (url "https://github.com/szermatt/emacs-bash-completion.git")
               (commit commit)))
         (file-name (git-file-name (package-name emacs-bash-completion)
                                   version))
         (sha256
          (base32
           "1jqh8d0w3lbqh9yld3lkr0f7l6j46ivpqic7hmj9q3fxfdbwqb7k"))))
      (arguments
       `(#:phases
         (modify-phases %standard-phases
           (add-before 'install 'configure
             (lambda* (#:key inputs #:allow-other-keys)
               (let ((bash (assoc-ref inputs "bash")))
                 (chmod "bash-completion.el" #o644)
                 (emacs-substitute-variables "bash-completion.el"
                   ("bash-completion-prog" (string-append bash "/bin/bash"))))
               #t))))))))

(define-public emacs-guix-next
  (let ((commit "1ed98be606d41356725f7a9fd1d7f981427aa53a")
        (revision "1"))
    (package
      (inherit emacs-guix)
      (name "emacs-guix-next")
      (version (git-version (package-version emacs-guix) "1" commit))
      (source
       (origin
         (method git-fetch)
         (uri (git-reference
               (url "https://github.com/alezost/guix.el")
               (commit commit)))
         (file-name (git-file-name name version))
         (sha256
          (base32
           "13fcnwcb3kwkkvi8y20nfq7d4xydpv7n6zszb3qq3jrlx7ixbwkw"))))
      (native-inputs
       `(("autoconf" ,autoconf)
         ("automake" ,automake)
         ("texinfo" ,texinfo)
         ,@(package-native-inputs emacs-guix))))))

(define-public emacs-mediawiki
  (let ((commit "8473e12d1839f5287a4227586bf117dad820f867"))
    (package
      (name "emacs-mediawiki")
      (version (git-version "2.2.5" "1" commit))
      (source
       (origin
         (method git-fetch)
         (uri (git-reference
               (url "https://github.com/hexmode/mediawiki-el.git")
               (commit commit)))
         (file-name (git-file-name name version))
         (sha256
          (base32
           "03rpj3yrk3i1l9yjnamnx38idn6y4zi9zg53bc83sx3g2b4m5v04"))))
      (build-system emacs-build-system)
      (home-page
       "https://github.com/hexmode/mediawiki-el")
      (synopsis "Mediawiki Emacs frontend")
      (description "This package provides a Mediawiki Emacs frontend.")
      (license license:gpl3+))))

(define-public emacs-flyspell-correct
  (let ((commit "0486912f57ac2ec70c472b776c63360462cb32d7"))
    (package
      (name "emacs-flyspell-correct")
      (version (git-version "0.4" "1" commit))
      (source
       (origin
         (method git-fetch)
         (uri (git-reference
               (url "https://github.com/d12frosted/flyspell-correct.git")
               (commit commit)))
         (file-name (git-file-name name version))
         (sha256
          (base32
           "0qji0bvm14ra4xjlzx1ww4d0ih752j641n3vms1hh12n439bn6vh"))))
      (build-system emacs-build-system)
      (propagated-inputs
       `(("emacs-helm" ,emacs-helm)
         ("emacs-ivy" ,emacs-ivy)))
      (home-page "https://github.com/d12frosted/flyspell-correct")
      (synopsis "Correct words with @code{flyspell} via custom interface")
      (description "This package provides functionality for correcting words
via custom interfaces.")
      (license license:gpl3+))))

(define-public emms-next
  (let ((commit "9f9a9b81f741692f2d188d1b46e72f2b6db8a9a1"))
    (package
      (inherit emms)
      (name (string-append (package-name emms) "-next"))
      (version (git-version (package-version emms) "1" commit))
      (source
       (origin
         (inherit (package-source emms))
         (uri (string-append
               "https://git.savannah.gnu.org/cgit/emms.git/snapshot/emms-"
               commit ".tar.gz"))
         (sha256
          (base32
           "1wg00dr35h9shs6782s20nds8razqibys9ipzi9aa2kb3yhkdp6q")))))))

(define-public emacs-proc-net
  (let ((commit "10861112a1f3994c8e6374d6c5bb5d734cfeaf73"))
    (package
      (name "emacs-proc-net")
      (version (git-version "0" "1" commit))
      (source
       (origin
         (method git-fetch)
         (uri (git-reference
               (url "https://github.com/nicferrier/emacs-proc-net.git")
               (commit commit)))
         (file-name (git-file-name name version))
         (sha256
          (base32
           "0nly5h0d6w8dc08ifb2fiqcn4cqcn9crkh2wn0jzlz4zd2x75qrb"))))
      (build-system emacs-build-system)
      (home-page "https://github.com/nicferrier/emacs-proc-net")
      (synopsis "Network process tools")
      (description "This package provides an Emacs tools for doing stuff with
network processes.")
      (license license:gpl3+))))

(define-public emacs-build-farm
  (let ((commit "0e0168d75dba589e58d3034d6d865384ee551d86"))
    (package
      (name "emacs-build-farm")
      (version "0.0.1")
      (source (origin
                (method git-fetch)
                (uri (git-reference
                      (url "https://github.com/alezost/build-farm.el")
                      (commit commit)))
                (file-name (git-file-name name version))
                (sha256
                 (base32
                  "07bp00lyl6q175d93p71wa93ygkm5q6x3xhw1a53vqmsvkyahqps"))))
      (build-system emacs-build-system)
      (inputs
       `(("emacs-bui" ,emacs-bui)
         ("emacs-magit-popup" ,emacs-magit-popup)))
      (home-page "https://github.com/alezost/build-farm.el")
      (synopsis " Interface for Hydra and Cuirass (Nix and Guix build farms)")
      (description "Emacs-Build-Farm is an Emacs interface for Hydra and Cuirass
— build farms for Nix and Guix package managers.")
      (license license:gpl3+))))

(define-public emacs-gited
  (package
    (name "emacs-gited")
    (version "0.5.3")
    (source (origin
              (method url-fetch)
              (uri (string-append "https://elpa.gnu.org/packages/gited-"
                                  version ".tar"))
              (sha256
               (base32
                "1bayfclczdzrmay8swszs8lliz5p4nnmjzzz2gh68rc16isjgh2z"))))
    (build-system emacs-build-system)
    (home-page "https://elpa.gnu.org/packages/gited.html")
    (synopsis "Operate on Git branches like dired")
    (description "This Emacs library lists the branches in a Git repository.
Then you can operate on them with a dired-like interface.")
    (license license:gpl3+)))

(define-public emacs-psysh
  (package
    (name "emacs-psysh")
    (version "0.0.4")
    (source
     (origin
       (method url-fetch)
       (uri (string-append "https://github.com/emacs-php/psysh.el/archive/"
                           version ".tar.gz"))
       (file-name (string-append name "-" version ".tar.gz"))
       (sha256
        (base32
         "0h019yarfgwyvfjsvif1l404a9a9j6jlzyfykyahf7j5850k4fhk"))))
    (build-system emacs-build-system)
    (propagated-inputs
     `(("emacs-s" ,emacs-s)
       ("emacs-f" ,emacs-f)))
    (home-page "https://github.com/zonuexe/psysh.el")
    (synopsis "PsySH, PHP interactive shell (REPL)")
    (description
     "This package provides a PHP interactive shell.")
    (license license:gpl3+)))

(define-public emacs-anywhere-mode
  (let ((commit "80a5aa81b7102d27f83e67fb361388a2c80dbc88"))
    (package
      (name "emacs-anywhere-mode")
      (version (git-version "0.1" "1" commit))
      (source
       (origin
         (method git-fetch)
         (uri (git-reference
               (url "https://gitlab.com/wigust/emacs-anywhere-mode.git/")
               (commit commit)))
         (file-name (git-file-name name version))
         (sha256
          (base32
           "0avqg4abv7fngwn4vpphf8p6dvasglllrdibhv7rdswg11dpbs22"))))
      (build-system emacs-build-system)
      (arguments
       '(#:phases
         (modify-phases %standard-phases
           (add-after 'unpack 'patch-paths
             (lambda _
               (substitute* "emacs-anywhere"
                 (("@XDOTOOL_BIN@") (which "xdotool")))
               (substitute* "anywhere-mode.el"
                   (("@XCLIP_BIN@") (which "xclip")))))
           (add-before 'install 'install-shell-script
             (lambda* (#:key outputs #:allow-other-keys)
               (install-file "emacs-anywhere"
                             (string-append (assoc-ref outputs "out")
                                            "/bin")))))))
      (inputs
       `(("xdotool" ,xdotool)
         ("xclip" ,xclip)))
      (synopsis "Emacs Anywhere mode")
      (description "This package provides an Emacs minor-mode for
capturing user input and paste it with @kbd{C-v} after exit.")
      (home-page #f)
      (license license:gpl3+))))

(define-public emacs-redshift
  (let ((commit "303f58cf65fb6c7701b587cdd048ca785019ebd0"))
    (package
      (name "emacs-redshift")
      (version (git-version "0.0.1" "1" commit))
      (source
       (origin
         (method git-fetch)
         (uri (git-reference
               (url "https://gitlab.com/wigust/emacs-redshift")
               (commit commit)))
         (file-name (git-file-name name version))
         (sha256
          (base32
           "112l3hr9vckna8l38x4wi8sdq0mfv3hh4ip10vlz0q78kgkf9q0m"))))
      (build-system emacs-build-system)
      (home-page "https://github.com/wigust/emacs-redshift")
      (synopsis "Emacs interface to Redshift")
      (description
       "This package provides an Emacs interface to Redshift")
      (license license:gpl3+))))

(define-public emacs-terminal-here-checkout
  (let ((commit "c35e7471a33df0e1d37522dc7aad42df9efc40c6"))
    (package
      (inherit emacs-terminal-here)
      (name "emacs-terminal-here-checkout")
      (version (git-version "1.0" "1" commit))
      (source
       (origin
         (method git-fetch)
         (uri (git-reference
               (url "https://gitlab.com/wigust/emacs-terminal-here")
               (commit commit)))
         (file-name (git-file-name name version))
         (sha256
          (base32
           "0m0lydyz80kmd80ibhkjjxdkpf0a62xm3rg5n63yncyjplvi11b9")))))))

(define-public emacs-hydra-timestamp
  (let ((commit "49b029193be57eafe542247e42b28a86fd34cdab"))
    (package
      (name "emacs-hydra-timestamp")
      (version (string-append "0.1" "-" (string-take commit 7)))
      (source
       (origin
         (method git-fetch)
         (uri (git-reference
               (url "https://gitlab.com/wigust/emacs-hydra-timestamp")
               (commit commit)))
         (file-name (git-file-name name version))
         (sha256
          (base32
           "0pyqsmz3144c6avy075bxddv7czwar9g0rzzgm62saxywfwxjxm8"))))
      (build-system emacs-build-system)
      (synopsis "Insert timestamps with Emacs Hydra")
      (description
       "This package provides an Emacs Hydra for inserting timestamps.")
      (home-page #f)
      (license license:gpl3+))))