;;; GNU Guix --- Functional package management for GNU
;;; Copyright © 2017 Oleg Pykhalov <go.wigust@gmail.com>
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

(define-module (wigust packages emacs)
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
  #:use-module (gnu packages guile)
  #:use-module (gnu packages gtk)
  #:use-module (gnu packages gnome)
  #:use-module (gnu packages ncurses)
  #:use-module (gnu packages python)
  #:use-module (gnu packages haskell)
  #:use-module (gnu packages tex)
  #:use-module (gnu packages texinfo)
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

(define-public emacs-company-lua
  (let ((commit "0be8122f3adf57ad27953bf4b03545d6298d3da4")
        (revision "1"))
    (package
      (name "emacs-company-lua")
      (version "0.1")
      (source
       (origin
         (method git-fetch)
         (uri (git-reference
               (url "https://github.com/ptrv/company-lua.git")
               (commit commit)))
         (file-name (string-append name "-" version "-checkout"))
         (sha256
          (base32
           "1d9i165apgmwns7b2fd5wcpjpkah3dyj20v5sb8ynvz6qhhr5r9c"))))
      (build-system emacs-build-system)
      (propagated-inputs
       `(("emacs-company" ,emacs-company)
         ("emacs-s" ,emacs-s)
         ("emacs-f" ,emacs-f)
         ("emacs-lua-mode" ,emacs-lua-mode)))
      (home-page "https://github.com/ptrv/company-lua")
      (synopsis "Company backend for Lua")
      (description "Company backend for Lua")
      (license license:gpl3+))))

(define-public emacs-company-tern
  (package
    (name "emacs-company-tern")
    (version "0.3.0")
    (source
     (origin
       (method url-fetch)
       (uri (string-append "https://github.com/proofit404/company-tern/archive/"
                           "v" version ".tar.gz"))
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
    (description "Tern backend for company-mode.")
    (license license:gpl3+)))

(define-public emacs-discover-my-major
  (package
    (name "emacs-discover-my-major")
    (version "1.0")
    (source
     (origin
       (method url-fetch)
       (uri
        (string-append "https://github.com/steckerhalter/discover-my-major"
                       "/archive/" version ".tar.gz"))
       (file-name (string-append name "-" version ".tar.gz"))
       (sha256
        (base32
         "0nah41f92rrl2l405kpqr6iaks11jyclgl4z7ilfymbr4ifmsiyl"))))
    (build-system emacs-build-system)
    (propagated-inputs
     `(("emacs-makey" ,emacs-makey)))
    (home-page
     "https://github.com/steckerhalter/discover-my-major")
    (synopsis "Discover key bindings for the current Emacs major mode")
    (description
     "Discover key bindings and their meaning for the current Emacs major mode ")
    (license license:gpl3+)))

(define-public emacs-dumb-jump
  (package
    (name "emacs-dumb-jump")
    (version "0.5.0")
    (source
     (origin
       (method url-fetch)
       (uri (string-append "https://github.com/jacktasia/dumb-jump/archive/"
                           "v" version ".tar.gz"))
       (file-name (string-append name "-" version ".tar.gz"))
       (sha256
        (base32
         "14sfnlgfc81y2il5v0njvmdh39lxpy8kz4j0prlc2rzd2bk0a8n5"))))
    (build-system emacs-build-system)
    (propagated-inputs
     `(("emacs-f" ,emacs-f)
       ("emacs-s" ,emacs-s)
       ("emacs-dash" ,emacs-dash)
       ("emacs-popup" ,emacs-popup)))
    (home-page "https://github.com/jacktasia/dumb-jump")
    (synopsis "Jump to definition for multiple languages without configuration")
    (description "Dumb Jump is an Emacs \"jump to definition\" package with
support for multiple programming languages that favors \"just working\" over
speed or accuracy.  This means minimal -- and ideally zero -- configuration
with absolutely no stored indexes (TAGS) or persistent background processes.
Dumb Jump performs best with The Silver Searcher `ag` or ripgrep `rg`
installed.  Dumb Jump requires at least GNU Emacs 24.3. ")
    (license license:gpl3+)))

(define-public emacs-edit-indirect
  (package
    (name "emacs-edit-indirect")
    (version "0.1.4")
    (source
     (origin
       (method url-fetch)
       (uri (string-append "https://github.com/Fanael/edit-indirect/archive/"
                           version ".tar.gz"))
       (sha256
        (base32
         "07kr58rd1p5j764wminsssazr73hy51yw8iqcsv5z2dwgj7msv71"))))
    (build-system emacs-build-system)
    (home-page "https://github.com/Fanael/edit-indirect")
    (synopsis "Edit regions in separate buffers")
    (description "Edit regions in separate buffers, like
@code{org-edit-src-code} but for arbitrary regions.")
  (license license:gpl3+)))

(define-public emacs-edit-server
  (package
    (name "emacs-edit-server")
    (version "1.13")
    (source
     (origin
       (method url-fetch)
       (uri (string-append "https://github.com/stsquad/emacs_chrome/archive/"
                           "v" version ".tar.gz"))
       (file-name (string-append name "-" version ".tar.gz"))
       (sha256
        (base32
         "1r92kqggslqasza718z4ka883mqfbnibdm43f0j9gaipk0msm2wf"))))
    (build-system emacs-build-system)
    (arguments
     `(#:phases
       (modify-phases %standard-phases
         (add-after 'unpack 'chdir-elisp
           ;; Elisp directory is not in root of the source.
           (lambda _
             (chdir "servers"))))))
    (home-page "https://github.com/stsquad/emacs_chrome")
    (synopsis "Server that responds to edit requests from Chromium")
    (description "Provides an edit server to respond to requests from Emacs.

To open pages for editing in new buffers in your existing Emacs
instance:

@code{(when (require 'edit-server nil t)
        (setq edit-server-new-frame nil)
        (edit-server-start))}

To open pages for editing in new frames using a running emacs
started in --daemon mode:

@code{(when (and (require 'edit-server nil t) (daemonp))
        (edit-server-start))}

Buffers are edited in `text-mode' by default; to use a different
major mode, change `edit-server-default-major-mode' or customize
`edit-server-url-major-mode-alist' to specify major modes based
on the remote URL:

@code{(setq edit-server-url-major-mode-alist
        '((\"github\\\\.com\" . markdown-mode)))}

Alternatively, set the mode in `edit-server-start-hook'.  For
example:

@code{(add-hook 'edit-server-start-hook
         (lambda ()
           (when (string-match \"github.com\" (buffer-name))
             (markdown-mode))))}")
    (license license:gpl3+)))

(define-public emacs-elisp-refs
  (package
    (name "emacs-elisp-refs")
    (version "1.2")
    (source
     (origin
       (method url-fetch)
       (uri (string-append "https://github.com/Wilfred/elisp-refs/archive/"
                           version ".tar.gz"))
       (file-name (string-append name "-" version ".tar.gz"))
       (sha256
        (base32
         "0fj6wphwrvbslw46w7wgdk3b4bfr312ygj3lbgr9qw63lpqw26nl"))))
    (build-system emacs-build-system)
    (propagated-inputs
     `(("emacs-dash" ,emacs-dash)
       ("emacs-f" ,emacs-f)
       ("emacs-list-utils" ,emacs-list-utils)
       ("emacs-loop" ,emacs-loop)
       ("emacs-s" ,emacs-s)))
    (home-page "https://github.com/Wilfred/elisp-refs")
    (synopsis "Find callers of elisp functions or macros")
    (description "Find references to functions, macros or variables.  Unlike a
dumb text search, @code{elisp-refs} actually parses the code, so it's never
confused by comments or @code{foo-bar} matching @code{foo}.")
    (license license:gpl3+)))

(define-public emacs-helm-youtube
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

(define-public emacs-helpful
  (package
    (name "emacs-helpful")
    (version "0.1")
    (source (origin
              (method url-fetch)
              (uri (string-append
                    "https://github.com/Wilfred/helpful/archive/"
                    version ".tar.gz"))
              (file-name (string-append name "-" version ".tar.gz"))
              (sha256
               (base32
                "16dx566qzrjj0bf43lnw7h1qlvgs94brqplamw8kppp2ylr72qs9"))))
    (build-system emacs-build-system)
    (propagated-inputs
     `(("emacs-elisp-refs" ,emacs-elisp-refs)))
    (home-page "https://github.com/Wilfred/helpful")
    (synopsis "More contextual information in Emacs help")
    (description "@code{helpful} is an alternative to the built-in Emacs help
that provides much more contextual information.

@itemize
@item Show the source code for interactively defined functions (unlike the
built-in Help).
@item Fall back to the raw sexp if no source is available.
@item Show where a function is being called.
@item Docstrings will Highlight the summary (the first sentence), include
cross-references, hide superfluous puncuation.
@item Show you the properties that have been applied to the current
symbol.  This provides visibility of features like edebug or byte-code
optimisation.
@item Provide a separate @code{helpful-command} function to view interactive
functions.
@item Display any keybindings that apply to interactive functions.
@item Trace, disassemble functions from inside Helpful.  This is discoverable
and doesn't require memorisation of commands.
@end itemize\n")
    (license license:gpl3+)))

(define-public emacs-highlight-defined
  (package
    (name "emacs-highlight-defined")
    (version "0.1.5")
    (source
     (origin
       (method url-fetch)
       (uri (string-append
             "https://github.com/Fanael/highlight-defined/archive/"
             version ".tar.gz"))
       (file-name (string-append name "-" version ".tar.gz"))
       (sha256
        (base32
         "1ryd66989b5byqdw8jmjrjf0c78iiz72wibld750skcnj5h5h506"))))
    (build-system emacs-build-system)
    (home-page "https://github.com/Fanael/highlight-defined")
    (synopsis "Syntax highlighting of known Elisp symbols")
    (description "Minor mode providing syntax highlighting of known Emacs Lisp
symbols.  Currently the code distinguishes Lisp functions, built-in functions,
macros, faces and variables.  To enable call @code{highlight-defined-mode}. ")
    (license license:gpl3+)))

(define-public emacs-highlight-numbers
  (package
    (name "emacs-highlight-numbers")
    (version "0.2.3")
    (source
     (origin
       (method url-fetch)
       (uri (string-append
             "https://github.com/Fanael/highlight-numbers/archive/"
             version ".tar.gz"))
       (file-name (string-append name "-" version ".tar.gz"))
       (sha256
        (base32
         "030v5p11d4n0581ncv499l1fqrmfziy756q6378x2bv22ixghqqp"))))
    (build-system emacs-build-system)
    (propagated-inputs
     `(("emacs-parent-mode" ,emacs-parent-mode)))
    (home-page "https://github.com/Fanael/highlight-numbers")
    (synopsis "Highlight numbers in source code")
    (description "@code{highlight-numbers-mode} provides a minor mode for
syntax highlighting of numeric literals in source code.

It s customizable: it's easy to add or redefine what exactly consitutes a
\"number\" in given major mode.  See @code{highlight-numbers-modelist}.")
    (license license:gpl3+)))

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

(define-public emacs-list-utils
  (package
    (name "emacs-list-utils")
    (version "0.4.4")
    (source
     (origin
       (method url-fetch)
       (uri (string-append "https://github.com/rolandwalker/list-utils/archive/"
                           "v" version ".tar.gz"))
       (file-name (string-append name "-" version ".tar.gz"))
       (sha256
        (base32
         "1xc1xh8c82h5gdjbgpdsdclgwxkxbb7h3x3a2bscpm41g8pnan4p"))))
    (build-system emacs-build-system)
    (home-page "http://github.com/rolandwalker/list-utils")
    (synopsis "List-manipulation utility functions")
    (description "List manipulation library for Emacs.")
    (license license:gpl3+)))

(define-public emacs-loop
  (package
    (name "emacs-loop")
    (version "1.3")
    (source
     (origin
       (method url-fetch)
       (uri (string-append "https://github.com/Wilfred/loop.el/archive/"
                           version ".tar.gz"))
       (sha256
        (base32
         "1z3rhh3zyjabz36410yz0lp4a0qwwj0387as662wvx3z9y54jia9"))))
    (build-system emacs-build-system)
    (home-page "https://github.com/Wilfred/loop.el")
    (synopsis "Imperative loop structures for Emacs")
    (description "Loop structures familiar to users of other languages.  This
library adds a selection of popular loop structures as well as break and
continue.")
    (license license:gpl3+)))

(define-public emacs-makey
  (package
    (name "emacs-makey")
    (version "0.3")
    (source
     (origin
       (method url-fetch)
       (uri (string-append "https://github.com/mickeynp/makey/archive/"
                           version ".tar.gz"))
       (file-name (string-append name "-" version ".tar.gz"))
       (sha256
        (base32
         "0kzl4q1wf2zhkx9nrymxa67n99iq0bj7zqhpaz4byksna1hsxfmv"))))
    (build-system emacs-build-system)
    (home-page "https://github.com/mickeynp/makey")
    (synopsis "Interactive commandline mode")
    (description "Interactive commandline mode")
    (license license:gpl3+)))

(define-public emacs-nnreddit
  (let ((commit "9843f99d01fd8f1eea2fc685965a7c7f4eeb187a")
        (revision "1"))
    (package
      (name "emacs-nnreddit")
      (version (string-append "0.0.1-" revision "."
                              (string-take commit 7)))
      (source (origin
                (method git-fetch)
                (uri (git-reference
                      (url "https://github.com/paul-issartel/nnreddit.git")
                      (commit commit)))
                (file-name (string-append name "-" version "-checkout"))
                (sha256
                 (base32
                  "0j4h3bnga640250jdq8bwyja49r41ssrsjd6lba4gzzllqk02nbn"))))
      (build-system emacs-build-system)
      (home-page "https://github.com/paul-issartel/nnreddit")
      (synopsis "Reddit backend for the Gnus newsreader")
      (description "@url{https://www.reddit.com} backend for the Gnus
newsreader.")
      (license license:gpl3+))))

(define-public emacs-npm-mode
  (package
    (name "emacs-npm-mode")
    (version "0.6.0")
    (source
     (origin
       (method url-fetch)
       (uri (string-append "https://github.com/mojochao/npm-mode/archive/"
                           version ".tar.gz"))
       (file-name (string-append name "-" version ".tar.gz"))
       (sha256
        (base32
         "1kq1ww22dwf8c2i2b4z2ldbbmnihj65kb7n5vzvwkch9h4hxpqh5"))))
    (build-system emacs-build-system)
    (home-page "https://github.com/mojochao/npm-mode")
    (synopsis "Minor mode for working with npm projects")
    (description "@code{npm-mode} provides a minor mode to work with npm
projects.")
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
      (home-page "https://github.com/alphapapa/org-protocol-capture-html.git")
      (synopsis "Captures Web pages into Org using Pandoc to process HTML")
      (description "This package captures Web pages into Org-mode using Pandoc to
process HTML.  It can also use eww's eww-readable functionality to
get the main content of a page.

These are the helper functions that run in Emacs.  To capture pages
into Emacs, you can use either a browser bookmarklet or the
org-protocol-capture-html.sh shell script.  See the README.org file
for instructions.")
      (license license:gpl3+))))

(define-public emacs-parent-mode
  (package
    (name "emacs-parent-mode")
    (version "2.3")
    (source
     (origin
       (method url-fetch)
       (uri (string-append "https://github.com/Fanael/parent-mode/archive/"
                           version ".tar.gz"))
       (file-name (string-append name "-" version ".tar.gz"))
       (sha256
        (base32
         "0gxbl5s1w96v6v55b7aaansgw4sxhzfx9nrsvpk3pfhsibs6yqjd"))))
    (build-system emacs-build-system)
    (home-page "https://github.com/Fanael/parent-mode")
    (synopsis "Get major mode's parent modes")
    (description "Get major mode's parent modes")
    (license license:gpl3+)))

(define-public emacs-rjsx-mode
  (package
    (name "emacs-rjsx-mode")
    (version "0.2.0")
    (source
     (origin
       (method url-fetch)
       (uri (string-append "https://github.com/felipeochoa/rjsx-mode/archive/"
                           "v" version ".tar.gz"))
       (file-name (string-append name "-" version ".tar.gz"))
       (sha256
        (base32
         "1vlk298g79nz0cw5sgnp2683gr72x5sfsqbyxjsg521ka3lyjq98"))))
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

(define-public emacs-seq
  (package
    (name "emacs-seq")
    (version "2.20")
    (source
     (origin
       (method url-fetch)
       (uri (string-append "http://elpa.gnu.org/packages/seq-" version ".tar"))
       (sha256
        (base32
         "0vrpx6nnyjb0gsypknzagimlhvcvi5y1rcdkpxyqr42415zr8d0n"))))
    (build-system emacs-build-system)
    (home-page "http://elpa.gnu.org/packages/seq.html")
    (synopsis "Sequence manipulation functions")
    (description "Sequence-manipulation functions that complement basic
functions provided by subr.el.

All functions are prefixed with \"seq-\".

All provided functions work on lists, strings and vectors.

Functions taking a predicate or iterating over a sequence using a function as
argument take the function as their first argument and the sequence as their
second argument.  All other functions take the sequence as their first
argument.")
    (license license:gpl3+)))

(define-public emacs-slime-company
  (package
    (name "emacs-slime-company")
    (version "1.1")
    (source
     (origin
       (method url-fetch)
       (uri (string-append "https://github.com/anwyn/slime-company/archive/"
                           "v" version ".tar.gz"))
       (sha256
        (base32
         "1myl79pxj501xfr5qc5a24qddsn2l5iaamg7rf7fpny7mr9v70ar"))
       (file-name (string-append name "-" version ".tar.gz"))))
    (build-system emacs-build-system)
    (propagated-inputs
     `(("emacs-slime" ,emacs-slime)
       ("emacs-company" ,emacs-company)))
    (home-page "http://company-mode.github.io")
    (synopsis
     "slime completion backend for company mode")
    (description
     "This is a backend implementation for the completion package company-mode
by Nikolaj Schumacher. Supports the normal and the fuzzy completion modes of
SLIME.

Installation:

 Put this file somewhere into your load-path
 (or just into slime-path/contribs) and then call

  (slime-setup '(slime-company))

Also have the following, more convenient key bindings for company mode in my
.emacs:

  (define-key company-active-map (kbd \"\\C-n\") 'company-select-next)
  (define-key company-active-map (kbd \"\\C-p\") 'company-select-previous)
  (define-key company-active-map (kbd \"\\C-d\") 'company-show-doc-buffer)
  (define-key company-active-map (kbd \"M-.\") 'company-show-location)
")
    (license license:gpl3+)))

(define-public emacs-sourcemap
  (package
    (name "emacs-sourcemap")
    (version "0.03")
    (source
     (origin
       (method url-fetch)
       (uri (string-append "https://github.com/syohex/emacs-sourcemap/archive/"
                           version ".tar.gz"))
       (sha256
        (base32
         "0bmd5l3cx2iyl7vxn84xdhs80b07kpdpfwki28lh5d0kmm5qs6m6"))))
    (build-system emacs-build-system)
    (home-page "https://github.com/syohex/emacs-sourcemap")
    (synopsis "Sourcemap parser")
    (description "Sourcemap parser")
    (license license:gpl3+)))

(define-public emacs-stickyfunc-enhance
  (let ((commit "13bdba51fcd83ccbc3267959d23afc94d458dcb0")
        (revision "1"))
    (package
      (name "emacs-stickyfunc-enhance")
      (version "0.1")
      (source
       (origin
         (method git-fetch)
         (uri (git-reference
               (url "https://github.com/tuhdo/semantic-stickyfunc-enhance.git")
               (commit commit)))
         (file-name (string-append name "-" version "-checkout"))
         (sha256
          (base32
           "16dxjsr5nj20blww4xpd4jzgjprzzh1nwvb810ggdmp9paf4iy0g"))))
      (build-system emacs-build-system)
      (home-page "https://github.com/tuhdo/semantic-stickyfunc-enhance")
      (synopsis "Enhancement to stock @code{semantic-stickyfunc-mode}")
      (description
       "@code{semantic-stickyfunc-mode} shows the function point is currently
in at the first line of the current buffer.  This is useful when you have a
very long function that spreads more than a screen, and you don't have to
scroll up to read the function name and then scroll down to original position.")
      (license license:gpl3+))))

(define-public emacs-stumpwm-mode
  (let ((commit "8fbe071d2c6c040794060a354eb377218dc10b35")
        (revision "1"))
    (package
      (name "emacs-stumpwm-mode")
      (version (string-append "0.0.1-" revision "."
                              (string-take commit 7)))
      (source (origin
                (method git-fetch)
                (uri (git-reference
                      (url "https://github.com/stumpwm/stumpwm-contrib.git")
                      (commit commit)))
                (file-name (string-append name "-" version "-checkout"))
                (sha256
                 (base32
                  "1dfwsvz1c8w6j4jp0kzaz78ml3f5dp0a5pvf090kwpbpg176r7iq"))))
      (build-system emacs-build-system)
      (arguments
       `(#:phases
         (modify-phases %standard-phases
           (add-after 'unpack 'chdir-elisp
             ;; Elisp directory is not in root of the source.
             (lambda _
               (chdir "util/swm-emacs"))))))
      (home-page "https://github.com/stumpwm/stumpwm-contrib")
      (synopsis "Emacs minor-mode for Stumpwm")
      (description "Emacs minor-mode for Stumpwm")
      (license license:gpl3+))))

(define-public emacs-suggest
  (package
    (name "emacs-suggest")
    (version "0.4")
    (source
     (origin
       (method url-fetch)
       (uri (string-append "https://github.com/Wilfred/suggest.el/archive/"
                           version ".tar.gz"))
       (file-name (string-append name "-" version ".tar.gz"))
       (sha256
        (base32
         "1760fm3j19w8xxcawq6s859h86q1rdg69pg9yz48n76kwfk3vlgp"))))
    (build-system emacs-build-system)
    (propagated-inputs
     `(("emacs-loop" ,emacs-loop)
       ("emacs-dash" ,emacs-dash)
       ("emacs-s" ,emacs-s)
       ("emacs-f" ,emacs-f)))
    (home-page "https://github.com/Wilfred/suggest.el")
    (synopsis "Suggest Elisp functions that give the output requested")
    (description "Suggest.el will find functions that give the output
requested.  It's a great way of exploring list, string and arithmetic
functions.")
    (license license:gpl3+)))

(define-public emacs-json-reformat
  (package
    (name "emacs-json-reformat")
    (version "0.0.6")
    (source
     (origin
       (method url-fetch)
       (uri (string-append "https://github.com/gongo/json-reformat/archive/"
                           version ".tar.gz"))
       (file-name (string-append name "-" version ".tar.gz"))
       (sha256
        (base32
         "11fbq4scrgr7m0iwnzcrn2g7xvqwm2gf82sa7zy1l0nil7265p28"))))
    (build-system emacs-build-system)
    (propagated-inputs `(("emacs-undercover" ,emacs-undercover)))
    (inputs
     `(("emacs-dash" ,emacs-dash)         ; for tests
       ("emacs-shut-up" ,emacs-shut-up))) ; for tests
    (arguments
     `(#:phases
       (modify-phases %standard-phases
         (add-before 'install 'check
           (lambda* (#:key inputs #:allow-other-keys)
             (zero? (system* "emacs" "--batch" "-L" "."
                             "-l" "test/test-helper.el"
                             "-l" "test/json-reformat-test.el"
                             "-f" "ert-run-tests-batch-and-exit"))
             ;; Fails
             ;; json-reformat-test:json-reformat-region-occur-error
             ;; json-reformat-test:string-to-string
             #t)))))
    (home-page "https://github.com/gongo/json-reformat")
    (synopsis "Reformatting tool for JSON")
    (description "@code{json-reformat} provides a reformatting tool for
@url{http://json.org/, JSON}.")
    (license license:gpl3+)))

(define-public emacs-json-mode
  (package
    (name "emacs-json-mode")
    (version "1.7.0")
    (source
     (origin
       (method url-fetch)
       (uri (string-append "https://github.com/joshwnj/json-mode/archive/"
                           "v" version ".tar.gz"))
       (file-name (string-append name "-" version ".tar.gz"))
       (sha256
        (base32
         "06h45p4cn767pk9sqi2zb1c65wy5gyyijqxzpglp80zwxhvajdz5"))))
    (build-system emacs-build-system)
    (propagated-inputs
     `(("emacs-json-reformat" ,emacs-json-reformat)
       ("emacs-json-snatcher" ,emacs-json-snatcher)))
    (home-page "https://github.com/joshwnj/json-mode")
    (synopsis "Major mode for editing JSON files")
    (description "@code{json-mode} extends the builtin js-mode syntax
highlighting.")
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

(define-public emacs-web-beautify
  (package
    (name "emacs-web-beautify")
    (version "0.3.2")
    (source
     (origin
       (method url-fetch)
       (uri (string-append "https://github.com/yasuyk/web-beautify/archive/"
                           version ".tar.gz"))
       (file-name (string-append name "-" version ".tar.gz"))
       (sha256
        (base32
         "1j57hwid74id4swkx2g0iljfawx0k9c7qjrwqc0mv657x9p78hcs"))))
    (build-system emacs-build-system)
    (home-page "https://github.com/yasuyk/web-beautify")
    (synopsis "Format HTML, CSS and JavaScript/JSON")
    (description "Add the following to your Emacs init file.

    (require 'web-beautify) ;; Not necessary if using ELPA package
    (eval-after-load 'js2-mode
      '(define-key js2-mode-map (kbd \"C-c b\") 'web-beautify-js))
    (eval-after-load 'json-mode
      '(define-key json-mode-map (kbd \"C-c b\") 'web-beautify-js))
    (eval-after-load 'sgml-mode
      '(define-key html-mode-map (kbd \"C-c b\") 'web-beautify-html))
    (eval-after-load 'css-mode
      '(define-key css-mode-map (kbd \"C-c b\") 'web-beautify-css))

If you want to automatically format before saving a file,
add the following hook to your Emacs configuration:

    (eval-after-load 'js2-mode
      '(add-hook 'js2-mode-hook
                 (lambda ()
                   (add-hook 'before-save-hook 'web-beautify-js-buffer t t))))

    (eval-after-load 'json-mode
      '(add-hook 'json-mode-hook
                 (lambda ()
                   (add-hook 'before-save-hook 'web-beautify-js-buffer t t))))

    (eval-after-load 'sgml-mode
      '(add-hook 'html-mode-hook
                 (lambda ()
                   (add-hook 'before-save-hook 'web-beautify-html-buffer t t))))

    (eval-after-load 'css-mode
      '(add-hook 'css-mode-hook
                 (lambda ()
                   (add-hook 'before-save-hook 'web-beautify-css-buffer t t))))

For more information, See URL https://github.com/yasuyk/web-beautify.")
    (license license:gpl3+)))

(define-public emacs-websocket
  (package
    (name "emacs-websocket")
    (version "1.8")
    (source
     (origin
       (method url-fetch)
       (uri (string-append "https://github.com/ahyatt/emacs-websocket/archive/"
                           version ".tar.gz"))
       (sha256
        (base32
         "07nz1spb2nklyf94fdh1rzbmscms9qxc7ypl77fzyvyw3az6qr50"))))
    (build-system emacs-build-system)
    (home-page "https://github.com/ahyatt/emacs-websocket")
    (synopsis "Emacs WebSocket client and server")
    (description "This implements RFC 6455, which can be found at
@url{http://tools.ietf.org/html/rfc6455}.

This library contains code to connect Emacs as a client to a websocket server,
and for Emacs to act as a server for websocket connections.

Websockets clients are created by calling @code{websocket-open}, which returns
a @code{websocket} struct.  Users of this library use the websocket struct,
and can call methods @code{websocket-send-text}, which sends text over the
websocket, or @code{websocket-send}, which sends a @code{websocket-frame}
struct, enabling finer control of what is sent.  A callback is passed to
@code{websocket-open} that will retrieve websocket frames called from the
websocket.  Websockets are eventually closed with @code{websocket-close}.

Server functionality is similar.  A server is started with
@code{websocket-server} called with a port and the callbacks to use, which
returns a process.  The process can later be closed with
@code{websocket-server-close}.  A @code{websocket} struct is also created for
every connection, and is exposed through the callbacks.")
    (license license:gpl3+)))

(define-public emacs-wordgen
  (package
    (name "emacs-wordgen")
    (version "0.1.4")
    (source
     (origin
       (method url-fetch)
       (uri (string-append "https://github.com/Fanael/wordgen.el/archive/"
                           version ".tar.gz"))
       (sha256
        (base32
         "1h2iyixdm49h53pwj9ics9gb9h3g6wa4hainpnjg6mfarf49jkmg"))))
    (build-system emacs-build-system)
    (home-page "https://github.com/Fanael/wordgen.el")
    (synopsis "Random word generator")
    (description "Generate random words using user-provided rules.

Example:
(wordgen '((result (concat-reeval [(2 1) (5 2) (4 3)] syl))
   (syl (++ c v coda))
   (c [(4 \"p\") (5 \"t\") (5 \"k\") (3 \"m\") (4 \"n\") (3 \"s\") (4
\"l\") (3 \"r\")])
   (v [\"a\" \"e\" \"i\" \"o\" \"u\"])
   (coda [(4 \"\") \"m\" \"n\"]))
 :word-count 5)

=> (\"komlamkim\" \"kepa\" \"mennem\" \"ne\" \"palu\")

See the function `wordgen' for complete description.
")
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

(define-public emacs-know-your-http-well
  (package
    (name "emacs-know-your-http-well")
    (version "0.5.0")
    (source
     (origin
       (method url-fetch)
       (uri (string-append
             "https://github.com/for-GET/know-your-http-well/archive/"
             "v" version ".tar.gz"))
       (file-name (string-append name "-" version ".tar.gz"))
       (sha256
        (base32
         "1y3kwz88awcgwaivlswq0q4g2i02762r23lpwg61bfqy5lrjjqnj"))))
    (arguments
     `(#:phases
       (modify-phases %standard-phases
         (add-after 'unpack 'install-json-files
           (lambda* (#:key outputs #:allow-other-keys)
             (for-each (lambda (directory)
                         (copy-recursively directory
                                           (string-append
                                            (assoc-ref outputs "out")
                                            directory)))
                       '("js" "json"))))
         (add-after 'unpack 'chdir-elisp
           ;; Elisp directory is not in root of the source.
           (lambda _
             (chdir "emacs"))))))
    (build-system emacs-build-system)
    (home-page "https://github.com/for-GET/know-your-http-well")
    (synopsis "Meaning of HTTP headers codes")
    (description "Meaning of HTTP headers codes.")
    (license license:gpl3+)))

(define-public emacs-company-restclient
  (package
    (name "emacs-company-restclient")
    (version "0.1.0")
    (source
     (origin
       (method url-fetch)
       (uri (string-append
             "https://github.com/iquiw/company-restclient/archive/"
             "v" version ".tar.gz"))
       (file-name (string-append name "-" version ".tar.gz"))
       (sha256
        (base32
         "1kr3f0wgqlk7r171bvb2kinv7fanwj2md01wdpx04qkgwcr1as00"))))
    (build-system emacs-build-system)
    (propagated-inputs
     `(("emacs-company" ,emacs-company)
       ("emacs-know-your-http-well" ,emacs-know-your-http-well)
       ("emacs-restclient" ,emacs-restclient)))
    (home-page "https://github.com/iquiw/company-restclient")
    (synopsis "Company-mode completion back-end for restclient-mode")
    (description "@code{company-mode} back-end for
@code{restclient-mode}.

It provides auto-completion for HTTP methods and headers in
@code{restclient-mode}.  Completion source is given by
@code{know-your-http-well}.")
    (license license:gpl3+)))

(define-public emacs-helm-notmuch
  (package
    (name "emacs-helm-notmuch")
    (version "1.1")
    (source
     (origin
       (method url-fetch)
       (uri (string-append "https://github.com/xuchunyang/helm-notmuch/archive/"
                           version ".tar.gz"))
       (sha256
        (base32
         "09b3jllppfmk0mb1qvgcx705jwixqn5ggl0bql6g5a3i7yy6xpyd"))))
    (build-system emacs-build-system)
    ;; TODO: helm-notmuch.el:36:1:Error: Cannot open load file: No such file or directory, notmuch
    (propagated-inputs
     `(("notmuch" ,notmuch)
       ("emacs-helm" ,emacs-helm)))
    (home-page "https://github.com/xuchunyang/helm-notmuch")
    (synopsis "Search emails with Notmuch and Helm")
    (description "Search emails, searching result displays as you type
thanks to helm.")
    (license license:gpl3+)))

(define-public emacs-csv-mode
  (package
    (name "emacs-csv-mode")
    (version "1.6")
    (source
     (origin
       (method url-fetch)
       (uri (string-append "http://elpa.gnu.org/packages/csv-mode-"
                           version ".el"))
       (sha256
        (base32
         "1v86qna1ypnr55spf6kjiqybplfbb8ak5gnnifh9vghsgb5jkb6a"))))
    (build-system emacs-build-system)
    (home-page
     "http://elpa.gnu.org/packages/csv-mode.html")
    (synopsis
     "Major mode for editing comma/char separated values")
    (description
     "This package implements CSV mode, a major mode for editing records
in a generalized CSV (character-separated values) format.  It binds
finds with prefix \".csv\" to `csv-mode' in `auto-mode-alist'.

In CSV mode, the following commands are available:

- C-c C-s (`csv-sort-fields') and C-c C-n (`csv-sort-numeric-fields')
  respectively sort lexicographically and numerically on a
  specified field or column.

- C-c C-r (`csv-reverse-region') reverses the order.  (These
  commands are based closely on, and use, code in `sort.el'.)

- C-c C-k (`csv-kill-fields') and C-c C-y (`csv-yank-fields') kill
  and yank fields or columns, although they do not use the normal
  kill ring.  C-c C-k can kill more than one field at once, but
  multiple killed fields can be yanked only as a fixed group
  equivalent to a single field.

- C-c C-a (`csv-align-fields') aligns fields into columns

- C-c C-u (`csv-unalign-fields') undoes such alignment; separators
  can be hidden within aligned records.

- C-c C-t (`csv-transpose') interchanges rows and columns.  For
  details, see the documentation for the individual commands.

CSV mode can recognize fields separated by any of several single
characters, specified by the value of the customizable user option
`csv-separators'.  CSV data fields can be delimited by quote
characters (and must if they contain separator characters).  This
implementation supports quoted fields, where the quote characters
allowed are specified by the value of the customizable user option
`csv-field-quotes'.  By default, the only separator is a comma and
the only field quote is a double quote.  These user options can be
changed ONLY by customizing them, e.g. via M-x customize-variable.

CSV mode commands ignore blank lines and comment lines beginning
with the value of the buffer local variable `csv-comment-start',
which by default is #.  The user interface is similar to that of
the standard commands `sort-fields' and `sort-numeric-fields', but\nsee the major mode documentation below.

The global minor mode `csv-field-index-mode' provides display of
the current field index in the mode line, cf. `line-number-mode'
and `column-number-mode'.  It is on by default.

Installation:

Put this file somewhere that Emacs can find it (i.e. in one of the
directories in your `load-path' such as `site-lisp'), optionally
byte-compile it (recommended), and put this in your .emacs file:

(add-to-list 'auto-mode-alist '(\"\\\\.[Cc][Ss][Vv]\\\\'\" . csv-mode))
(autoload 'csv-mode \"csv-mode\"
  \"Major mode for editing comma-separated value files.\" t)")
    (license license:gpl3+)))

(define-public emacs-parsebib
  (package
    (name "emacs-parsebib")
    (version "2.3.1")
    (source
     (origin
       (method url-fetch)
       (uri (string-append "https://github.com/joostkremers/parsebib/archive/"
                           version ".tar.gz"))
       (sha256
        (base32
         "0cxagnmc5ab6idmb26axpizhr4sqglkncc59768yavn3p04jyq63"))))
    (build-system emacs-build-system)
    (home-page "https://github.com/joostkremers/parsebib")
    (synopsis "A library for parsing bib files")
    (description "A library for parsing bib files")
    (license license:gpl3+)))

(define-public emacs-biblio
  (package
    (name "emacs-biblio")
    (version "0.1")
    (source
     (origin
       (method url-fetch)
       (uri (string-append "https://github.com/cpitclaudel/biblio.el/archive/"
                           version ".tar.gz"))
       (sha256
        (base32
         "109fvivsb4r0rbqljngqrmxqvbnbkqlivczx6brrvlr7ci625lhf"))))
    (build-system emacs-build-system)
    (home-page "https://github.com/cpitclaudel/biblio.el")
    (synopsis "Browse and import bibliographic references from
CrossRef, arXiv, DBLP, HAL, Dissemin, and doi.org")
    (description "# biblio.el: An extensible Emacs package for
browsing and fetching references

biblio.el makes it easy to browse and gather bibliographic references and
publications from various sources, by keywords or by DOI.  References are
automatically fetched from well-curated sources, and formatted as BibTeX.

## Supported sources:

* ‘CrossRef’, an exhaustive academic search engine (recommended)
* ‘arXiv’, an archive of pre-prints in various scientific fields
* ‘DBLP’, a database of Computer Science publications
* ‘HAL’, a French repository of Open Access publications
* ‘doi.org’, a DOI resolver (to retrieve BibTeX records from DOIs)
* ‘CrossCite’, an alternative DOI resolver and BibTeX formatting service
* ‘Dissemin’, a database tracking the open access status of scholarly articles

## Usage

Quick start: ‘M-x biblio-lookup’.  Each source can also be accessed independently:

* ‘M-x crossref-lookup’ to query CrossRef
* ‘M-x arxiv-lookup` to query arXiv
* `M-x dblp-lookup’ to query DBLP
* ‘M-x doi-insert’ to insert a BibTeX record by DOI
* ‘M-x dissemin-lookup’ to show information about the open access status of a
  particular DOI

Most of these commands work together: for example, ‘crossref-lookup’ displays a
list of results in ‘biblio-selection-mode’.  In that mode, use:

* ‘RET’ to visit the corresponding web page
* ‘c’ or ‘M-w’ to copy the BibTeX record of the current entry
* ‘i’ or ‘C-y’ to insert the BibTeX record of the current entry
* ‘x’ to run an extended action, such as fetching a Dissemin record

‘C’ and ‘I’ do the same as ‘c’ and ‘i’, but additionally close the search window.

## Examples

* To insert a clean BibTeX entry for http://doi.org/10.1145/2676726.2677006
  in the current buffer, use

        M-x crossref-lookup RET fiat deductive delaware RET i

  (the last ‘i’ inserts the BibTeX record of the currently selected entry in
   your buffer).

* To find publications by computer scientist Leslie Lamport, use ‘M-x
  dblp-lookup RET author:Lamport RET’ (see more info about DBLP's syntax at
  <http://dblp.uni-trier.de/search/>)

* To check whether an article is freely available online, use ‘x’ in the list
  of results.  For example ‘M-x crossref-lookup RET Emacs stallman RET’
  followed by ‘x Dissemin RET’ will help you find open access copies of
  Stallman's paper on EMACS (spoiler: http://hdl.handle.net/1721.1/5736).

See http://github.com/cpitclaudel/biblio.el for more information, including
documentation on extending this framework.
")
    (license license:gpl3+)))

(define-public emacs-helm-bibtex
  (let ((commit "8ed898fb5a68f18e9bb9973832a5c1f8abcfc463")
        (revision "1"))
    (package
      (name "emacs-helm-bibtex")
      (version (string-append "2.0.0" "-" revision "."
                              (string-take commit 7)))
      (source
       (origin
         (method git-fetch)
         (uri (git-reference
               (url "https://github.com/tmalsburg/helm-bibtex.git")
               (commit commit)))
         (file-name (string-append name "-" version "-checkout"))
         (sha256
          (base32
           "14lyx0vbqr97p3anzrsp7m3q0kqclyjcdwplpraim403fcklzbnz"))))
      (build-system emacs-build-system)
      (propagated-inputs
       `(("emacs-helm" ,emacs-helm)
         ("emacs-parsebib" ,emacs-parsebib)
         ("emacs-s" ,emacs-s)
         ("emacs-dash" ,emacs-dash)
         ("emacs-f" ,emacs-f)
         ("emacs-biblio" ,emacs-biblio)))
      (home-page "https://github.com/tmalsburg/helm-bibtex")
      (synopsis "A bibliography manager based on Helm")
      (description "A bibliography manager for Emacs, based on Helm and
the bibtex-completion backend.

Key features:
- Quick access to your bibliography from within Emacs
- Powerful search capabilities
- Provides instant search results as you type
- Tightly integrated with LaTeX authoring, emails, Org mode, etc.
- Open the PDFs, URLs, or DOIs associated with an entry
- Insert LaTeX cite commands, Ebib links, or Pandoc citations,
  BibTeX entries, or plain text references at point, attach PDFs to
  emails
- Support for note taking
- Quick access to online bibliographic databases such as Pubmed,
  arXiv, Google Scholar, Library of Congress, etc.
- Imports BibTeX entries from CrossRef and other sources.")
      (license license:gpl3+))))

(define-public emacs-org-ref
  (let ((commit "8c9b5d7efb9f0c1ad5186b8203bdd017f4249129")
        (revision "1"))
    (package
      (name "emacs-org-ref")
      (version (string-append "1.1.1" "-" revision "."
                              (string-take commit 7)))
      (source
       (origin
         (method git-fetch)
         (uri (git-reference
               (url "https://github.com/jkitchin/org-ref.git")
               (commit commit)))
         (file-name (string-append name "-" version "-checkout"))
         (sha256
          (base32
           "1rxz0bjdsayk0slv23i07d9xhj2m7s4hsc81wc2d1cs52dkr5zmz"))))
      (build-system emacs-build-system)
      (propagated-inputs
       `(("emacs-dash" ,emacs-dash)
         ("emacs-helm" ,emacs-helm)
         ("emacs-helm-bibtex" ,emacs-helm-bibtex)
         ("emacs-ivy" ,emacs-ivy)
         ("emacs-hydra" ,emacs-hydra)
         ("emacs-key-chord" ,emacs-key-chord)
         ("emacs-s" ,emacs-s)
         ("emacs-f" ,emacs-f)
         ("emacs-pdf-tools" ,emacs-pdf-tools)))
      (home-page "https://github.com/jkitchin/org-ref")
      (synopsis "Citations, cross-references and bibliographies in org-mode")
      (description
       "Lisp code to setup bibliography, cite, ref and label org-mode links.
Also sets up reftex and helm for org-mode citations.  The links are
clickable and do things that are useful.

The default setup uses helm-bibtex.

You should really read org-ref.org in this package for details.")
      (license license:gpl3+))))

(define-public emacs-irfc
  (package
    (name "emacs-irfc")
    (version "20130824.507")
    (source
     (origin
       (method url-fetch)
       (uri "https://www.emacswiki.org/emacs/download/irfc.el")
       (file-name (string-append "irfc-" version ".el"))
       (sha256
        (base32
         "197ybqwbj8qjh2p9pkf5mvqnrkpcgmv8c5s2gvl6msyrabk0mnca"))))
    (build-system emacs-build-system)
    (home-page
     "http://www.emacswiki.org/emacs/download/irfc.el")
    (synopsis "Interface for IETF RFC document.")
    (description
     "Interface for IETF RFC document.

This package use some code from `rfcview.el'.
Thanks \"Neil W.  Van Dyke\"!

The features this package provide:

* Format RFC document for easy reading.
* Single keystroke for fast view.
* Render status switch.
* Smart table and content switch.
* Visit RFC link around point.
* Jump to RFC reference around point.
* Download RFC document *asynchronous*.

Below are commands you can use:

`irfc-render-toggle'         Toggle render status with RFC buffer.
`irfc-quit'                  Quit RFC buffer.
`irfc-visit'                 Ask for RFC number and visit document.
`irfc-reference-goto'        Ask for RFC reference and jump to it.
`irfc-head-goto'             Ask for heading name and jump to it.
`irfc-head-number-goto'      Ask for heading number and jump to it.
`irfc-follow'                Visit RFC document around point.
`irfc-table-jump'            Switch between table and content.
`irfc-page-goto'             Goto page.
`irfc-page-next'             Jump next page.
`irfc-page-prev'             Jump previous page.
`irfc-page-first'            Jump first page.
`irfc-page-last'             Jump last page.
`irfc-page-table'            Jump table page.
`irfc-head-next'             Jump next heading.
`irfc-head-prev'             Jump previous heading.
`irfc-rfc-link-next'         Jump next RFC link.
`irfc-rfc-link-prev'         Jump previous RFC link.
`irfc-scroll-up-one-line'    Scroll up one line.
`irfc-scroll-down-one-line'  Scroll down one line.

Tips:

You can use command `irfc-render-toggle' to toggle render status.

Command `irfc-table-jump' can switch between table and content,
example you stay cursor at *table*, and type \"G\" will jump corresponding
content in buffer, alike, you can stay at any content and type \"G\"
will jump corresponding table item.

Command `irfc-follow' will visit RFC document around point,
example you stay cursor at \"[RFC3986]\", and type \"o\" will
open rfc3986.txt in storage directory.  If have not found
this file in directory, will download from `http://www.ietf.org/rfc/'
and open it when download complete.

And command ‘irfc-follow’ can also use at title of RFC document.
Example rfc3986.txt contain “Obsoletes: 2732, 2396, 1808” at title,
you can move cursor to “2732” and type “o” will visit RFC 2732 document.
‘irfc-follow’ support below keywords in title:

       “Request for Comments:”
       “Updates:”
       “Obsoletes:”

You can use command `irfc-rfc-link-next' or `irfc-rfc-link-prev'
to jump next or previous RFC link in document.

Command `irfc-visit' will ask the user for a RFC number and will
visit that document, either from `irfc-directory', if exists, or by
downloading it.  This command can serve as entry point for Irfc,
to go to a RFC without having to visit the file or remember
whether it is already in `irfc-directory'.
And if you visit same document with your previous type, so just
hit RET, and don't need type RFC document number.

Command `irfc-reference-goto' will ask the user for a reference
number and will jump to that citation in the Normative
References/Informative References heading.

Command `irfc-head-goto' will ask the user for a heading name and
will jump to that heading.  Completion list in minibuffer is
available.

Command `irfc-head-number-goto' will ask the user for a heading
number and will jump to that heading.  Completion list in minibuffer
is available.



Installation:

Put irfc.el to your load-path.
The load-path is usually ~/elisp/.
It's set in your ~/.emacs like this:
(add-to-list 'load-path (expand-file-name \"~/elisp\"))

And the following to your ~/.emacs startup file.

(require 'irfc)

Setup your storage directory for RFC documents.

(setq irfc-directory \"YourStorageDirectory\")

If you want make RFC document load `irfc-mode' automatically,
setup like below:

(setq irfc-assoc-mode t)")
    (license license:gpl3+)))

(define-public emacs-move-text
  (package
    (name "emacs-move-text")
    (version "2.0.8")
    (source
     (origin
       (method url-fetch)
       (uri (string-append "https://github.com/emacsfodder/move-text/archive/"
                           version ".tar.gz"))
       (sha256
        (base32
         "1sjfja9r25692pgcldgnjzkapzy970m14jh9l4pajysiqcdk72g0"))))
    (build-system emacs-build-system)
    (home-page "https://github.com/emacsfodder/move-text")
    (synopsis "Move current line or region with M-up or M-down")
    (description "MoveText is a re-write of the old move-text and
compatible with >= Emacs 25.1

It allows you to move the current line using M-up / M-down if a region
is marked, it will move the region instead.

Using the prefix (C-u *number* or META *number*) you can predefine how
many lines move-text will travel.


Installation:

Put move-text.el to your load-path.
The load-path is usually ~/elisp/.
It's set in your ~/.emacs like this:
(add-to-list 'load-path (expand-file-name \"~/elisp\"))
\nAnd the following to your ~/.emacs startup file.

(require 'move-text)
(move-text-default-bindings)

Acknowledgements:

 Original v1.x was a Feature extracted from basic-edit-toolkit.el - by Andy Stewart (LazyCat) ")
    (license license:gpl3+)))

(define-public emacs-git-auto-commit-mode
  (package
    (name "emacs-git-auto-commit-mode")
    (version "4.4.0")
    (source
     (origin
       (method url-fetch)
       (uri (string-append
             "https://github.com/ryuslash/git-auto-commit-mode/archive/"
             version ".tar.gz"))
       (sha256
        (base32
         "04avxmalsl3b7zi2vipfw9rb4wrwysnipsbch96skviql9axk870"))))
    (build-system emacs-build-system)
    (home-page "http://projects.ryuslash.org/git-auto-commit-mode/")
    (synopsis "Emacs Minor mode to automatically commit and push")
    (description "git-auto-commit-mode is an Emacs minor mode that
tries to commit changes to a file after every save.

When `gac-automatically-push-p' is non-nil, it also tries to push to
the current upstream.")
    (license license:gpl3+)))

(define-public emacs-lacarte
  (package
    (name "emacs-lacarte")
    (version "0.1")
    (source (origin
              (method url-fetch)
              (uri "https://www.emacswiki.org/emacs/download/lacarte.el")
              (sha256
               (base32
                "0m3swrvxz0cy01pd4kag626fxqp4l2zzwpgr26yp5wpsfxl9avv8"))))
    (build-system emacs-build-system)
    (home-page "https://www.emacswiki.org/emacs/lacarte.el")
    (synopsis "Execute menu items as commands, with completion")
    (description "Execute menu items as commands, with completion.")
    (license license:gpl3)))

(define-public emacs-visual-regexp
  (package
    (name "emacs-visual-regexp")
    (version "1.1.1")
    (source
     (origin
       (method url-fetch)
       (uri (string-append "https://github.com/benma/visual-regexp.el/archive/"
                           "v" version ".tar.gz"))
       (sha256
        (base32
         "1czmhvcivlcdyz7rfm0vd4a3xsgmy4qbvbl6yjxc217wrxqflr92"))))
    (build-system emacs-build-system)
    (home-page "https://github.com/benma/visual-regexp.el/")
    (synopsis "A regexp command with interactive visual feedback")
    (description "A regexp command with interactive visual feedback")
    (license license:gpl3+)))

(define-public emacs-ido-vertical-mode
  (package
    (name "emacs-ido-vertical-mode")
    (version "0.1.6")
    (source
     (origin
       (method url-fetch)
       (uri (string-append
             "https://github.com/creichert/ido-vertical-mode.el/archive/"
             "v" version ".tar.gz"))
       (sha256
        (base32
         "0dprdxq8wvqd45dinwj92k0kixr07c8xvspa6i613mjcpxgwjg53"))))
    (build-system emacs-build-system)
    (home-page "https://github.com/creichert/ido-vertical-mode.el")
    (synopsis "Makes ido-mode display vertically")
    (description "Makes ido-mode display prospects vertically.")
    (license license:gpl3+)))

(define-public emacs-dashboard
  (package
    (name "emacs-dashboard")
    (version "1.2.4")
    (source
     (origin
       (method url-fetch)
       (uri (string-append
             "https://github.com/rakanalh/emacs-dashboard/archive/"
             version ".tar.gz"))
       (file-name (string-append name "-" version ".tar.gz"))
       (sha256
        (base32
         "1738lmbgq6gk24hcwic0qjyajr21l5xzhya4pv58dw1bhd6vxv9g"))))
    (build-system emacs-build-system)
    (propagated-inputs
     `(("emacs-page-break-lines" ,emacs-page-break-lines)))
    (arguments '(#:include '("\\.el$" "\\.txt$" "\\.png$")))
    (home-page "https://github.com/rakanalh/emacs-dashboard")
    (synopsis "A startup screen extracted from Spacemacs")
    (description "An extensible Emacs dashboard, with sections for
bookmarks, projectil projects, org-agenda and more. ")
    (license license:gpl3+)))

(define-public emacs-sml-mode
  (package
    (name "emacs-sml-mode")
    (version "6.7")
    (source
     (origin
       (method url-fetch)
       (uri (string-append "http://elpa.gnu.org/packages/sml-mode-"
                           version ".el"))
       (sha256
        (base32
         "041dmxx7imiy99si9pscwjh5y4h02y3lirzhv1cfxqr3ghxngf9x"))))
    (build-system emacs-build-system)
    (home-page "http://elpa.gnu.org/packages/sml-mode.html")
    (synopsis "Major mode for editing (Standard) ML")
    (description "SML-MODE is a major Emacs mode for editing Standard ML.
It provides syntax highlighting and automatic indentation and
comes with sml-proc which allows interaction with an inferior SML
interactive loop.")
    (license license:gpl3+)))

(define-public emacs-hy-mode
  (package
    (name "emacs-hy-mode")
    (version "1.0.2")
    (source
     (origin
       (method url-fetch)
       (uri (string-append "https://github.com/hylang/hy-mode/archive/"
                           "v" version ".tar.gz"))
       (sha256
        (base32
         "0sbga36zkyhzrzcczsyjzll7b9qsa215pnlw51m4li2irm23jh17"))))
    (build-system emacs-build-system)
    (propagated-inputs
     `(("emacs-dash" ,emacs-dash)
       ("emacs-s" ,emacs-s)))
    (home-page "http://github.com/hylang/hy-mode")
    (synopsis "Major mode for Hylang")
    (description "Major mode for Hylang")
    (license license:gpl3+)))

(define-public emacs-faceup
  (let ((commit "6c92dad56a133e14e7b27831e1bcf9b3a71ff154")
        (revision "1"))
    (package
      (name "emacs-faceup")
      (version (string-append "0.0.1" "-" revision "."
                              (string-take commit 7)))
      (source
       (origin
         (method git-fetch)
         (uri (git-reference
               (url "https://github.com/Lindydancer/faceup.git")
               (commit commit)))
         (file-name (string-append name "-" version "-checkout"))
         (sha256
          (base32
           "1yzmy7flrhrh0i10bdszx8idx6r8h6czm4vm4q0z6fp5fw94zwrx"))))
      (build-system emacs-build-system)
      (home-page "https://github.com/Lindydancer/faceup")
      (synopsis "Markup language for faces and font-lock regression testing")
      (description "Emacs is capable of highlighting buffers based on
language-specific `font-lock' rules.  This package makes it possible
to perform regression test for packages that provide font-lock rules.")
      (license license:gpl3+))))

(define-public emacs-racket-mode
  (let ((commit "33877b1bb24faea68842e0396bd5718b84e47451")
        (revision "1"))
    (package
      (name "emacs-racket-mode")
      (version (string-append "0.0.1" "-" revision "."
                              (string-take commit 7)))
      (source
       (origin
         (method git-fetch)
         (uri (git-reference
               (url "https://github.com/greghendershott/racket-mode")
               (commit commit)))
         (file-name (string-append name "-" version "-checkout"))
         (sha256
          (base32
           "0681mzwx08zwbh8qg3s26jw1jn4fw2ljp1akxqkhy08sxhafqvb1"))))
      (build-system emacs-build-system)
      (propagated-inputs
       `(("emacs-faceup" ,emacs-faceup)
         ("emacs-s" ,emacs-s)))
      (home-page "https://github.com/greghendershott/racket-mode")
      (synopsis "Major mode for Racket language")
      (description "@code{racket-mode} provides:

@itemize
@item Focus on Racket (not various Schemes).
@item Follow DrRacket concepts where applicable.
@item Thorough font-lock and indent.
@end itemize\n")
      (license license:gpl3+))))

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
       ("emacs-inf-ruby" ,emacs-inf-ruby)
       ("emacs-tuareg" ,emacs-tuareg)
       ("emacs-hy-mode" ,emacs-hy-mode)
       ("emacs-racket-mode" ,emacs-racket-mode)))
    (home-page "https://github.com/kaz-yos/eval-in-repl/")
    (synopsis "Consistent ESS-like eval interface for various REPLs")
    (description "Consistent ESS-like eval interface for various REPLs")
    (license license:gpl3+)))

(define-public emacs-m-buffer-el
  (package
    (name "emacs-m-buffer-el")
    (version "0.15")
    (source
     (origin
       (method url-fetch)
       (uri (string-append "https://github.com/phillord/m-buffer-el"
                           "/archive/" "v" version ".tar.gz"))
       (file-name (string-append name "-" version ".tar.gz"))
       (sha256
        (base32
         "17vdcc8q37q9db98jyww1c0ivinmwfcw4l04zccfacalra63a214"))))
    (arguments
     `(#:phases
       (modify-phases %standard-phases
         (add-before 'install 'check
           (lambda* (#:key inputs #:allow-other-keys)
             (zero? (system* "emacs" "--batch" "-L" "."
                             "-l" "test/m-buffer-test.el"
                             "-l" "test/m-buffer-at-test.el"
                             "-f" "ert-run-tests-batch-and-exit")))))))
    (build-system emacs-build-system)
    (home-page "https://github.com/phillord/m-buffer-el")
    (synopsis "List oriented buffer operations for Emacs")
    (description "@{m-buffer} provides a set of list-orientated
functions for operating over the contents of Emacs buffers.")
    (license license:gpl3+)))

(define-public emacs-load-relative
  (let ((commit "738896e3da491b35399178ed2c6bc92cc728d119")
        (revision "1"))
    (package
      (name "emacs-load-relative")
      (version (string-append "0.0.1" "-" revision "."
                              (string-take commit 7)))
      (source
       (origin
         (method git-fetch)
         (uri (git-reference
               (url "https://github.com/rocky/emacs-load-relative")
               (commit commit)))
         (file-name (string-append name "-" version "-checkout"))
         (sha256
          (base32
           "1rpy5mfncncl6gqgg53d3g25g1700g4b9bivd4c0cfcv5dbxhp73"))))
      (build-system emacs-build-system)
      (home-page "https://github.com/rocky/emacs-load-relative")
      (synopsis "Relative loads for Emacs Lisp files")
      (description "@code{load-relative} allows to write small Emacs
functions or modules in a larger multi-file Emacs package and
facilitate running from the source tree without having to install the
code or fiddle with evil @code{load-path}.")
      (license license:gpl3+))))

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

(define-public emacs-beginend
  (package
    (name "emacs-beginend")
    (version "2.0.0")
    (source
     (origin
       (method url-fetch)
       (uri (string-append "https://github.com/DamienCassou/beginend/archive/"
                           "v" version ".tar.gz"))
       (file-name (string-append name "-" version ".tar.gz"))
       (sha256
        (base32
         "0z4rbwffh9vxfvcrlvym4p73z7gf72q0b5iv33llbpcpbijknnrq"))))
    ;; TODO: Tests.
    ;; (arguments
    ;;  `(#:phases
    ;;    (modify-phases %standard-phases
    ;;      (add-before 'install 'check
    ;;        (lambda* (#:key inputs #:allow-other-keys)
    ;;          (zero? (system* "emacs" "--batch" "-L" "."
    ;;                          "-l" "test/test-helper.el"
    ;;                          "-l" "test/beginend-dired-test.el"
    ;;                          "-l" "test/beginend-marks-test.el"
    ;;                          "-l" "test/beginend-narrowing-test.el"
    ;;                          "-l" "test/beginend-prog-test.el"
    ;;                          "-f" "ert-run-tests-batch-and-exit")))))))
    (build-system emacs-build-system)
    (inputs
     `(("emacs-undercover" ,emacs-undercover))) ; For tests.
    (home-page "https://github.com/DamienCassou/beginend")
    (synopsis "Redefine @code{M-<} and @code{M->} for Emacs modes")
    (description "@code{beginend} redefines @code{M-<} and @code{M->}
keybindings for Emacs modes so that point moves to meaningful
locations. Redefined keys are still accessible by pressing the same
key again.")
    (license license:gpl3+)))

(define-public emacs-eros
  (let ((commit "a42e45c9b2397156c684330b0fc90ee0eba773f5")
        (revision "1"))
    (package
      (name "emacs-eros")
      (version (string-append "0.0.1" "-" revision "."
                              (string-take commit 7)))
      (source
       (origin
         (method git-fetch)
         (uri (git-reference
               (url "https://github.com/xiongtx/eros.git")
               (commit commit)))
         (file-name (string-append name "-" version "-checkout"))
         (sha256
          (base32
           "0whlsq90v13fz69k3wjrwcwb9gkpfxqjd75mg3nrp85j9nwhb5i4"))))
      (build-system emacs-build-system)
      (home-page "https://github.com/xiongtx/eros")
      (synopsis "Evaluation result overlays")
      (description "@code{eros} provides evaluation result overlays.")
      (license license:gpl3+))))

(define-public emacs-parinfer-mode
  (package
    (name "emacs-parinfer-mode")
    (version "0.4.10")
    (source
     (origin
       (method url-fetch)
       (uri (string-append "https://github.com/DogLooksGood/parinfer-mode/archive/"
                           "v" version ".tar.gz"))
       (file-name (string-append name "-" version ".tar.gz"))
       (sha256
        (base32
         "06ba9qi59sm9ih9m38fbr8kj4qkvrm58n0c0ngfjz60gnr9x9pcv"))))
    (propagated-inputs
     `(("emacs-dash" ,emacs-dash)
       ("emacs-rainbow-delimiters" ,emacs-rainbow-delimiters)
       ("emacs-company" ,emacs-company)))
    (build-system emacs-build-system)
    (home-page "https://github.com/DogLooksGood/parinfer-mode/")
    (synopsis "Lisp structure editing mode")
    (description "@code{parinfer-mode} is a proof-of-concept editor
mode for Lisp programming languages.  It will infer some changes to
keep Parens and Indentation inline with one another.")
    (license license:gpl3+)))

(define-public emacs-shift-number
  (package
    (name "emacs-shift-number")
    (version "0.1")
    (source
     (origin
       (method url-fetch)
       (uri (string-append "https://github.com/alezost/shift-number.el"
                           "/archive/" "v" version ".tar.gz"))
       (file-name (string-append name "-" version ".tar.gz"))
       (sha256
        (base32
         "1g79m0hqn9jgpm565vvh8pdfzndc4vw7xisnh5qysj55qfg8cb1x"))))
    (build-system emacs-build-system)
    (home-page "https://github.com/alezost/shift-number.el")
    (synopsis "Increase or decrease the number at point")
    (description "@code{emacs-shift-number} provides commands
@code{shift-number-up} to increase and @code{shift-number-down} to
decrease the number at point.")
    (license license:gpl3+)))

(define-public emacs-download-region
  (let ((commit "eb9e557529a73b4cfc8281c70dd0d95db333fffa")
        (revision "1"))
    (package
      (name "emacs-download-region")
      (version (string-append "0.0.1" "-" revision "."
                              (string-take commit 7)))
      (source
       (origin
         (method git-fetch)
         (uri (git-reference
               (url "https://github.com/zk-phi/download-region.git")
               (commit commit)))
         (file-name (string-append name "-" version "-checkout"))
         (sha256
          (base32
           "0v52djg39b6k2snizd9x0qc009ws5y0ywqsfwhqgcbs5ymzh7dsc"))))
      (build-system emacs-build-system)
      (home-page "https://github.com/zk-phi/download-region")
      (synopsis "In buffer download manager for Emacs")
      (description "@code{download-region} provides in buffer
downloading manager for Emacs.")
      (license license:gpl3+))))

(define-public emacs-emms-player-simple-mpv
  (let ((commit "1af7838037c86872e897bea872d279ff080c28c6")
        (revision "1"))
    (package
      (name "emacs-emms-player-simple-mpv")
      (version (string-append "0.4.0" "-" revision "."
                              (string-take commit 7)))

      (source
       (origin
         (method git-fetch)
         (uri (git-reference
               (url "https://github.com/momomo5717/emms-player-simple-mpv.git")
               (commit commit)))
         (file-name (string-append name "-" version "-checkout"))
         (sha256
          (base32
           "1xgkpw89pyn4p37l5rz9dw8yg065slzq8l5z69n6nam9hndcnjsh"))))
      (build-system emacs-build-system)
      (propagated-inputs `(("emacs-emms" ,emms)))
      (home-page "https://github.com/momomo5717/emms-player-simple-mpv")
      (synopsis "An extension of emms-player-simple.el for mpv JSON IPC")
      (description "@code{emms-player-simple-mpv} provides macros and
functions for defining emms simple players of mpv.")
      (license license:gpl3+))))

(define-public emacs-pulseaudio-control
  (let ((commit "08c59e1dc45ec96edb62f34036e82cf5f14c0e8b")
        (revision "1"))
    (package
      (name "emacs-pulseaudio-control")
      (version (string-append "0.0.1" "-" revision "."
                              (string-take commit 7)))
      (source
       (origin
         (method git-fetch)
         (uri (git-reference
               (url "https://github.com/flexibeast/pulseaudio-control.git")
               (commit commit)))
         (file-name (string-append name "-" version "-checkout"))
         (sha256
          (base32
           "10cgg1r00kz2fsnnryvzay5pf8s1pwb1dzlds1fbjdnyfvdgammv"))))
      (build-system emacs-build-system)
      (home-page "https://github.com/flexibeast/pulseaudio-control")
      (synopsis "Control @code{pulseaudio} from Emacs")
      (description "Control @code{pulseaudio} from Emacs")
      (license license:gpl3+))))

(define-public emacs-helm-firefox
  (let ((commit "0ad34b7b5abc485a86cae6920c14de861cbeb085")
        (revision "1"))
    (package
      (name "emacs-helm-firefox")
      (version (string-append "0.0.1" "-" revision "."
                              (string-take commit 7)))
      (source
       (origin
         (method git-fetch)
         (uri (git-reference
               (url "https://github.com/emacs-helm/helm-firefox.git")
               (commit commit)))
         (file-name (string-append name "-" version "-checkout"))
         (sha256
          (base32
           "08mjsi2f9s29fkk35cj1rrparjnkm836qmbfdwdz7y51f9varjbs"))))
      (build-system emacs-build-system)
      (home-page "https://github.com/emacs-helm/helm-firefox")
      (synopsis "Display firefox bookmarks with Emacs Helm interface")
      (description "Display firefox bookmarks with Emacs Helm interface")
      (license license:gpl3+))))

(define-public emacs-itail
  (let ((commit "6e43c20da03be3b9c6ece93b7dc3495975ec1888")
        (revision "1"))
    (package
      (name "emacs-itail")
      (version (string-append "0.0.1" "-" revision "."
                              (string-take commit 7)))
      (source
       (origin
         (method git-fetch)
         (uri (git-reference
               (url "https://github.com/re5et/itail.git")
               (commit commit)))
         (file-name (string-append name "-" version "-checkout"))
         (sha256
          (base32
           "044nzxh1hq41faxw3lix0wy78vfz304pjcaa5a11dqfz7q3gx5cv"))))
      (build-system emacs-build-system)
      (home-page "https://github.com/re5et/itail")
      (synopsis "Interactive @code{tail} Emacs mode")
      (description "@code{itail} provides interactive @code{tail} mode
that allows you to filter the tail with unix pipes and highlight the
contents of the tailed file.  Works locally or on remote files using
tramp.")
      (license license:gpl3+))))

(define-public emacs-ewmctrl
  (let ((commit "3d0217c4d6cdb5c308b6cb4293574f470d4faacf")
        (revision "1"))
    (package
      (name "emacs-ewmctrl")
      (version (string-append "0.0.1" "-" revision "."
                              (string-take commit 7)))
      (source
       (origin
         (method git-fetch)
         (uri (git-reference
               (url "https://github.com/flexibeast/ewmctrl.git")
               (commit commit)))
         (file-name (string-append name "-" version "-checkout"))
         (sha256
          (base32
           "0ilwvx0qryv3v6xf0gxqwnfm6pf96gxap8h9g3f6z6lk9ff4n1wi"))))
      (build-system emacs-build-system)
      (home-page "https://github.com/flexibeast/ewmctrl")
      (synopsis "")
      (description "ewmctrl provides an Emacs interface to the wmctrl
command-line window-management program.")
      (license license:gpl3+))))

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

(define-public emacs-helm-pass
  (let ((commit "bf5e1ea85ca531f07372eb8e7b9a8812ff3d3a5e")
        (revision "1"))
    (package
      (name "emacs-helm-pass")
      (version (string-append "0.0.1" "-" revision "."
                              (string-take commit 7)))
      (source
       (origin
         (method git-fetch)
         (uri (git-reference
               (url "https://github.com/jabranham/helm-pass.git")
               (commit commit)))
         (file-name (string-append name "-" version "-checkout"))
         (sha256
          (base32
           "1l3dbgl65rcvw7cgqfxm3kvpfj65pj8jhkp9pg4yykli5y0wsbdx"))))
      (build-system emacs-build-system)
      (inputs
       `(("password-store" ,password-store)))
      (propagated-inputs
       `(("emacs-f" ,emacs-f)
         ("emacs-helm" ,emacs-helm)
         ("emacs-password-store" ,emacs-password-store)
         ("emacs-auth-password-store" ,emacs-auth-password-store)))
      (home-page "https://github.com/jabranham/helm-pass")
      (synopsis "Helm interface for @code{pass}")
      (description "Emacs helm interface for pass, the standard unix
password manager.")
      (license license:gpl3+))))

(define-public emacs-xml-rpc
  (package
    (name "emacs-xml-rpc")
    (version "1.6.12")
    (source (origin
              (method url-fetch)
              (uri (string-append
                    "https://github.com/hexmode/xml-rpc-el/archive/"
                    version ".tar.gz"))
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

(define-public emacs-highlight-escape-sequences
  (let ((commit "08d846a7aa748209d65fecead2b6a766c3e5cb41")
        (revision "1"))
    (package
      (name "emacs-highlight-escape-sequences")
      (version (string-append "0.0.1" "-" revision "."
                              (string-take commit 7)))
      (source
       (origin
         (method git-fetch)
         (uri (git-reference
               (url "https://github.com/dgutov/highlight-escape-sequences.git")
               (commit commit)))
         (file-name (string-append name "-" version "-checkout"))
         (sha256
          (base32
           "05mc3w1f8ykf80914a1yddw6j8cmh0h57llm07xh89s53821v2is"))))
      (build-system emacs-build-system)
      (home-page "https://github.com/dgutov/highlight-escape-sequences")
      (synopsis "Highlight escape sequences in Emacs")
      (description "@code{highlight-escape-sequences} provides an
Emacs minor mode to escape sequences in code.")
      (license license:gpl3+))))

(define-public emacs-esup
  (let ((commit "a589005a9a888537deef94d6fe38a9b8790c97c7")
        (revision "1"))
    (package
      (name "emacs-esup")
      (version (string-append "0.6" "-" revision "."
                              (string-take commit 7)))
      (source
       (origin
         (method git-fetch)
         (uri (git-reference
               (url "https://github.com/jschaf/esup.git")
               (commit commit)))
         (file-name (string-append name "-" version "-checkout"))
         (sha256
          (base32
           "04lxmd0h7mfjjl0qghrycgff0vcv950j1wqv0dbkr61jxp64n5fv"))))
      ;; TODO: Add tests
      (build-system emacs-build-system)
      (home-page "https://github.com/jschaf/esup")
      (synopsis "Emacs start up profiler")
      (description "Benchmark Emacs Startup time without ever leaving
your Emacs.")
      (license license:gpl2+))))

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

(define-public emacs-mbsync
  (let ((commit "42077e83ae2db778ce0f8e22f8357b40355526b3")
        (revision "1"))
    (package
      (name "emacs-mbsync")
      (version (string-append "0.0.1" "-" revision "."
                              (string-take commit 7)))
      (source
       (origin
         (method git-fetch)
         (uri (git-reference
               (url "https://github.com/dimitri/mbsync-el.git")
               (commit commit)))
         (file-name (string-append name "-" version "-checkout"))
         (sha256
          (base32
           "0yj93y2mpxlir8x73znlg1slxlv4blm1vjv5h2w3j8lxg8bxvmn6"))))
      (build-system emacs-build-system)
      (home-page "https://github.com/dimitri/mbsync-el")
      (synopsis "Interface to mbsync for Emacs")
      (description "This package allows to call the @code{mbsync} from
within Emacs.")
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

(define-public emacs-org-mind-map
  (let ((commit "9d6e262bedd94daf9de269f4d56de277275677cb")
        (revision "1"))
    (package
      (name "emacs-org-mind-map")
      (version (string-append "0.0.1" "-" revision "."
                              (string-take commit 7)))
      (source
       (origin
         (method git-fetch)
         (uri (git-reference
               (url "https://github.com/theodorewiles/org-mind-map.git")
               (commit commit)))
         (file-name (string-append name "-" version "-checkout"))
         (sha256
          (base32
           "0jgkkgq7g64zckrmjib0hvz0qy3ynz5vz13qbmlpf096l3bb65wn"))))
      (propagated-inputs
       `(("emacs-dash" ,emacs-dash)))
      (build-system emacs-build-system)
      (home-page "https://github.com/theodorewiles/org-mind-map")
      (synopsis "Create graphviz directed graphs from Org files")
      (description "This package creates graphviz directed graphs from
Org files.")
      (license license:gpl3+))))

(define-public emacs-guix-checkout
  (let ((commit "b4d897f7daafb5794809760340548b96b0a89ac3")
        (revision "1"))
    (package
      (inherit emacs-guix)
      (version (string-append (package-version emacs-guix)
                              "-" revision "." (string-take commit 7)))
      (source
       (origin
         (method git-fetch)
         (uri (git-reference
               (url "https://github.com/alezost/guix.el.git")
               (commit commit)))
         (file-name (string-append (package-name emacs-guix)
                                   "-" version "-checkout"))
         (sha256
          (base32
           "1bl6k0vdjl9b10pz76afwnmagjjazp1pxl9rash4m1f6zry4hbj7"))))
      (arguments
       (append (package-arguments emacs-guix)
               '(#:phases
                 (modify-phases %standard-phases
                   (add-after 'unpack 'autogen
                     (lambda _ (zero? (system* "sh" "autogen.sh"))))))))
      (native-inputs
       `(("pkg-config" ,pkg-config)
         ;; 'emacs-minimal' does not find Emacs packages (this is for
         ;; "guix environment").
         ("emacs" ,emacs-no-x)
         ("autoconf" ,autoconf)
         ("automake" ,automake)
         ("texinfo" ,texinfo))))))

(define-public emacs-eless
  (package
    (name "emacs-eless")
    (version "0.3")
    (source (origin
              (method url-fetch)
              (uri (string-append
                    "https://github.com/kaushalmodi/eless/archive/"
                    "v" version ".tar.gz"))
              (file-name (string-append name "-" version ".tar.gz"))
              (sha256
               (base32
                "0gjnnhgw5xs1w3qfnkvwa2nv44gnxr8pkhx3c7qig45p8nh1461h"))))
    (build-system trivial-build-system)
    (inputs
     `(("bash" ,bash)))
    (native-inputs
     `(("tar" ,tar)
       ("gzip" ,gzip)))
    (arguments
     `(#:modules ((guix build utils))
       #:builder
       (begin
         (use-modules (guix build utils))
         (setenv "PATH" (string-append
                         (assoc-ref %build-inputs "tar") "/bin" ":"
                         (assoc-ref %build-inputs "gzip") "/bin"))
         (system* "tar" "xvf" (assoc-ref %build-inputs "source"))
         (chdir (string-append "eless" "-" ,version))
         (substitute* "eless" (("/usr/bin/env bash")
                               (string-append (assoc-ref %build-inputs "bash")
                                              "/bin/bash")))
         (install-file "eless" (string-append %output "/bin"))
         (install-file "doc/eless.info" (string-append %output "/share/info"))
         #t)))
    (home-page "https://github.com/kaushalmodi/eless")
    (synopsis "Combination of Bash script and a Emacs view-mode")
    (description "@code{eless} provides a combination of Bash script
and a minimal Emacs view-mode.

Feautures:

@itemize
@item Independent of a user’s Emacs config.
@item Customizable via the @code{(locate-user-emacs-file \"elesscfg\")} config.
@item Not require an Emacs server to be already running.
@item Syntax highlighting.
@item Org-mode file rendering.
@item @code{man} page viewer.
@item Info viewer.
@item Dired, wdired, (batch edit symbolic links).
@item Colored diffs, git diff, git log, ls with auto ANSI detection.
@item Filter log files lines matching a regexp.
@item Auto-revert log files similar to @code{tail -f}.
@item Quickly change frame and font sizes.
@end itemize\n")
    (license license:expat)))

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

(define-public emacs-datetime
  (package
    (name "emacs-datetime")
    (version "0.3")
    (source (origin
              (method url-fetch)
              (uri (string-append
                    "https://github.com/doublep/datetime/archive/"
                    "0.3" ".tar.gz"))
              (sha256
               (base32
                "12wqpj67rjij2ki7nmw38rz3k2bsq68pk6zswknlcn9qhp1zd9w9"))))
    (build-system emacs-build-system)
    (home-page "https://github.com/doublep/datetime/")
    (synopsis "Library to work with dates in Emacs")
    (description "Parsing, formatting, matching and recoding
timestamps and date-time format strings library for Emacs.")
    (license license:gpl3+)))

(define-public emacs-logview
  (package
    (name "emacs-logview")
    (version "0.8.2")
    (source (origin
              (method url-fetch)
              (uri (string-append
                    "https://github.com/doublep/logview/archive/"
                    "0.8.2" ".tar.gz"))
              (sha256
               (base32
                "1if22ypjdz0w8dbgyxi2vgffaaqid4bc0i3004g0jy345cjr63kn"))))
    (propagated-inputs
     `(("emacs-datetime" ,emacs-datetime)))
    (build-system emacs-build-system)
    (home-page "https://github.com/doublep/logview/")
    (synopsis "Emacs mode for viewing log files")
    (description "@code{logview} provides an Emacs mode to view log files.")
    (license license:gpl3+)))

(define-public emacs-on-screen
  (package
    (name "emacs-on-screen")
    (version "1.3.2")
    (source
     (origin
       (method url-fetch)
       (uri (string-append
             "http://elpa.gnu.org/packages/on-screen-"
             version
             ".el"))
       (sha256
        (base32
         "15d18mjgv1pnwl6kf3pr5w64q1322p1l1qlfvnckglwmzy5sl2qv"))))
    (build-system emacs-build-system)
    (home-page
     "https://github.com/michael-heerdegen/on-screen.el")
    (synopsis "guide your eyes while scrolling")
    (description
     "Scrolling can be distracting because your eyes may lose
orientation.  This library implements a minor mode that highlights
the previously visible buffer part after each scroll.")
    (license license:gpl3+)))

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

(define-public emacs-ibuffer-projectile
  (let ((commit "c18ac540ee46cb759fc5df18747f6e8d23563011")
        (revision "1"))
    (package
      (name "emacs-ibuffer-projectile")
      (version (string-append "0.2" "-" revision "."
                              (string-take commit 7)))
      (source
       (origin
         (method git-fetch)
         (uri (git-reference
               (url "https://github.com/purcell/ibuffer-projectile.git")
               (commit commit)))
         (file-name (string-append name "-" version "-checkout"))
         (sha256
          (base32
           "1nd26cwwdpnwj0g4w393rd59klpyr6wqrnyr6scmwb5d06bsm44n"))))
      (build-system emacs-build-system)
      (propagated-inputs
       `(("emacs-projectile" ,emacs-projectile)))
      (home-page "https://github.com/purcell/ibuffer-projectile")
      (synopsis "Group ibuffer's list by projectile root")
      (description "Adds functionality to Emacs @code{ibuffer} for
grouping buffers by their projectile root directory.")
      (license license:gpl3+))))

(define-public emacs-crux
  (let ((commit "4f5c8fefd5a6aa52e128c4a0401cc86410d6ac8f")
        (revision "1"))
    (package
      (name "emacs-crux")
      (version (string-append "0.3.0" "-" revision "."
                              (string-take commit 7)))
      (source
       (origin
         (method git-fetch)
         (uri (git-reference
               (url "https://github.com/bbatsov/crux.git")
               (commit commit)))
         (file-name (string-append name "-" version "-checkout"))
         (sha256
          (base32
           "1fdxvv25cs01sg6fmvmzxpzvs50i6v8n2jya60lbavxqqhi0sbxd"))))
      (build-system emacs-build-system)
      (home-page "https://github.com/bbatsov/crux")
      (synopsis "Collection of useful functions for Emacs")
      (description
       "@{crux} provides a collection of useful functions for Emacs.")
      (license license:gpl3+))))

(define-public emacs-fancy-narrow
  (package
    (name "emacs-fancy-narrow")
    (version "0.9.5")
    (source
     (origin
       (method url-fetch)
       (uri (string-append "https://github.com/Malabarba/fancy-narrow/archive/"
                           version ".tar.gz"))
       (file-name (string-append name "-" version ".tar.gz"))
       (sha256
        (base32
         "0rf2rnzg82pdqch041yyx3f9ddixffkk9s2ydzg8hwy66sg3385n"))))
    (build-system emacs-build-system)
    (home-page "https://github.com/Malabarba/fancy-narrow/releases")
    (synopsis "Immitate narrow-to-region with more eye-candy")
    (description "Unlike narrow-to-region, which completely hides text
outside the narrowed region, this package simply deemphasizes the
text, makes it readonly, and makes it unreachable. This leads to a
much more natural feeling, where the region stays static (instead of
being brutally moved to a blank slate) and is clearly highlighted with
respect to the rest of the buffer.")
    (license license:gpl2+)))

(define-public emacs-helm-gtags
  (package
    (name "emacs-helm-gtags")
    (version "1.5.6")
    (source (origin
              (method url-fetch)
              (uri (string-append
                    "https://github.com/syohex/emacs-helm-gtags/archive/"
                    version ".tar.gz"))
              (sha256
               (base32
                "1a10snhg6nnnan6w9a7mcziy26vxbsr3c35i0gcarnkdp2yqng36"))))
    (build-system emacs-build-system)
    (home-page "https://github.com/syohex/emacs-helm-gtags")
    (synopsis "Emacs Helm interface to GNU Global")
    (description "@code{emacs-helm-gtags} provides a Emacs Helm
interface to GNU Global.")
    (license license:gpl3+)))

(define-public emacs-benchmark-init
  (package
    (name "emacs-benchmark-init")
    (version "1.0")
    (source (origin
              (method url-fetch)
              (uri (string-append
                    "https://github.com/dholm/benchmark-init-el/archive/"
                    version ".tar.gz"))
              (file-name (string-append name "-" version ".tar.gz"))
              (sha256
               (base32
                "0szyqr4nncwz4vd5gww1vz31kf9r2lx25p4d0d09pm35974x53kz"))))
    (build-system emacs-build-system)
    (home-page "https://github.com/dholm/benchmark-init-el")
    (synopsis "Benchmark Emacs @code{require} and @code{load} calls")
    (description "@code{benchmark-init} provides a way to keep track of where
time is being spent during Emacs startup in order to optimize startup time.")
    (license license:gpl3+)))

(define-public emacs-add-hooks
  (package
    (name "emacs-add-hooks")
    (version "3.1.1")
    (source (origin
              (method url-fetch)
              (uri (string-append
                    "https://github.com/nickmccurdy/add-hooks/archive/"
                    version ".tar.gz"))
              (sha256
               (base32
                "03a28gb3298g7pc2qji9hi44p4d99ljp5mpi9cmg42ldv8fl6549"))))
    (build-system emacs-build-system)
    (home-page "https://github.com/nickmccurdy/add-hooks/")
    (synopsis " Emacs function for setting multiple hooks")
    (description "Typically, you would need to call add-hook multiple
times with similar arguments to declare multiple functions for one
hook, or vice versa. add-hooks-pair is a variant that takes multiple
hooks or functions that apply to each other. The add-hooks function
tidies up duplicate hook and function names further into a single
declarative call (inspired by the bind-key package).")
    (license license:gpl3+)))

(define-public emacs-helm-mode-manager
  (package
    (name "emacs-helm-mode-manager")
    (version "1.0.0")
    (source
     (origin
       (method url-fetch)
       (uri (string-append "https://github.com/istib/helm-mode-manager/"
                           "archive/" version ".tar.gz"))
       (file-name (string-append name "-" version ".tar.gz"))
       (sha256
        (base32
         "0wllj321z16hgrx0ddwzk5wz4mnnx5am7w5nclqclfc5dfdn92wm"))))
    (build-system emacs-build-system)
    (propagated-inputs
     `(("emacs-helm" ,emacs-helm)))
    (home-page "https://github.com/istib/helm-mode-manager/")
    (synopsis "Switch and toggle Emacs major and minor modes using Helm")
    (description "This package provides a Helm interface for toggling Emacs
major or minor mode.

@itemize
@item @code{helm-switch-major-mode} list of all major modes
@item @code{helm-enable-minor-mode} list of all inactive minor modes
@item @code{helm-disable-minor-mode} list of all ACTIVE minor modes
@end itemize\n

Hitting @code{RET} enables the mode, @code{C-z} shows the mode
documentation.")
    (license license:gpl3+)))

(define-public emacs-rsw-elisp
  (package
    (name "emacs-rsw-elisp")
    (version "1.0.5")
    (source (origin
              (method url-fetch)
              (uri (string-append "https://github.com/rswgnu/rsw-elisp"
                                  "/archive/" version ".tar.gz"))

              (sha256
               (base32
                "1jnn7xfwl3wxc87v44ccsf1wwp80par3xgcvfb1icd6zchjmlcps"))))
    (build-system emacs-build-system)
    (home-page "https://github.com/rswgnu/rsw-elisp")
    (synopsis "Improved expressions that interactively evaluate Emacs Lisp")
    (description "This package improves and replaces the GNU Emacs commands
that interactively evaluate Emacs Lisp expressions.  The new commands replace
standard key bindings and are all prefixed with rsw-elisp-.  They work the
same way as the old commands when called non-interactively; only the
interactive behavior should be different.")
    (license license:gpl3+)))

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

(define-public emacs-default-text-scale
  (let ((commit "968e985e219235f3e744d6d967e592acbaf6e0a8")
        (revision "1"))
    (package
      (name "emacs-default-text-scale")
      (version (string-append "0.1" "-" revision "."
                              (string-take commit 7)))
      (source (origin
                (method git-fetch)
                (uri (git-reference
                      (url "https://github.com/purcell/default-text-scale")
                      (commit commit)))
                (file-name (string-append name "-" version "-checkout"))
                (sha256
                 (base32
                  "0zds01c3q5yny6ab1fxfkzzgn1kgl3q23lxxap905f4qd70v922h"))))
      (build-system emacs-build-system)
      (home-page "https://github.com/purcell/default-text-scale")
      (synopsis "Adjust the font size in all Emacs frames")
      (description "This package provides commands for increasing or
decreasing the default font size in all GUI Emacs frames.")
      (license license:gpl3+))))

(define-public emacs-helm-emms
  (let ((commit "8133c1a854c8f9e32b3b4c74638fe197535c08f1")
        (revision "1"))
    (package
      (name "emacs-helm-emms")
      (version (string-append "1.3" "-" revision "."
                              (string-take commit 7)))
      (source (origin
                (method git-fetch)
                (uri (git-reference
                      (url "https://github.com/emacs-helm/helm-emms/")
                      (commit commit)))

                (sha256
                 (base32
                  "06111034rvh770ljzdbw7d6rkvy40bjvp4c06ss5s624pyd6qd74"))))
      (build-system emacs-build-system)
      (home-page "https://github.com/emacs-helm/helm-emms/")
      (synopsis "Basic helm interface to emms")
      (description "Basic helm interface to emms")
      (license license:gpl3+))))

(define-public emacs-interactive-align
  (package
    (name "emacs-interactive-align")
    (version "0.1.0")
    (source
     (origin
       (method url-fetch)
       (uri (string-append "https://github.com/mkcms/interactive-align/"
                           "archive/" "v" version ".tar.gz"))

       (sha256
        (base32
         "0sibpgb4lp6yy3pziak8f3hz4b28yj0dqy2nzh51z3d0b63h528m"))))
    (build-system emacs-build-system)
    (home-page "https://github.com/mkcms/interactive-align/")
    (synopsis "Interactive align-regexp command in Emacs")
    (description "Interactive align-regexp command in Emacs")
    (license license:gpl3+)))

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

(define-public emacs-debbugs-with-bugs
  (package
    (inherit emacs-debbugs)
    (name "emacs-debbugs-with-bugs")
    (source
     (origin
       (inherit (package-source emacs-debbugs))
       (patches (search-patches "emacs-debbugs-recognize-bugs.gnu.org.patch"))))))

(define-public emacs-helm-c-yasnippet
  (let ((commit "65ca732b510bfc31636708aebcfe4d2d845b59b0")
        (revision "1"))
    (package
      (name "emacs-helm-c-yasnippet")
      (version (string-append "0.6.7" "-" revision "."
                              (string-take commit 7)))
      (source (origin
                (method git-fetch)
                (uri (git-reference
                      (url "https://github.com/emacs-jp/helm-c-yasnippet")
                      (commit commit)))
                (file-name (string-append name "-" version "-checkout"))
                (sha256
                 (base32
                  "1cbafjqlzxbg19xfdqsinsh7afq58gkf44rsg1qxfgm8g6zhr7f8"))))
      (build-system emacs-build-system)
      (propagated-inputs
       `(("emacs-helm" ,emacs-helm)
         ("emacs-yasnippet" ,emacs-yasnippet)))
      (home-page "https://github.com/emacs-jp/helm-c-yasnippet")
      (synopsis "Helm integration for Yasnippet")
      (description "This Emacs library provides Helm interface for
Yasnippet.")
      (license license:gpl2+))))

(define-public emacs-hierarchy
  (package
    (name "emacs-hierarchy")
    (version "0.7.0")
    (source
     (origin
       (method url-fetch)
       (uri (string-append
             "https://github.com/DamienCassou/hierarchy/archive/"
             "v" version ".tar.gz"))
       (sha256
        (base32
         "1a463v5zk6zis2p8cs4mads3iyxh266yahi6j6y0paggfl2yhkc8"))))
    (build-system emacs-build-system)
    (home-page "https://github.com/DamienCassou/hierarchy")
    (synopsis "Library to create and display hierarchy structures")
    (description "This package provides an Emacs library to create, query,
navigate and display hierarchy structures.")
    (license license:gpl3+)))

(define-public emacs-tree-mode
  (let ((commit "b06078826d5875d74b0e7b7ac47b0d0917610534")
        (revision "1"))
    (package
      (name "emacs-tree-mode")
      (version (string-append "0.0.1" "-" revision "."
                              (string-take commit 7)))
      (source
       (origin
         (method git-fetch)
         (uri (git-reference
               (url "https://github.com/emacsorphanage/tree-mode.git")
               (commit commit)))
         (file-name (string-append name "-" version "-checkout"))
         (sha256
          (base32
           "13bbdhdmqg4x9yghanhr8fsbsxbnypzxdxgicz31sjjm675kpnix"))))
      (build-system emacs-build-system)
      (home-page "https://github.com/emacsorphanage/tree-mode")
      (synopsis "A mode to manage tree widgets")
      (description
       "This package provides an Emacs library to manage tree widgets.")
      (license license:gpl3+))))

(define-public emacs-md4rd
  (let ((commit "be0fc4951b2d1f5194ffa1fcaac706dbac560500")
        (revision "1"))
    (package
      (name "emacs-md4rd")
      (version (string-append "0.0.1" "-" revision "."
                              (string-take commit 7)))
      (source (origin
                (method git-fetch)
                (uri (git-reference
                      (url "https://github.com/ahungry/md4rd.git")
                      (commit commit)))
                (file-name (string-append name "-" version "-checkout"))
                (sha256
                 (base32
                  "1i93shx5x192gd7cl2r6gvcvhhwyi1k08abi5w3izv1hn3pmksgq"))))
      (propagated-inputs
       `(("emacs-hierarchy" ,emacs-hierarchy)
         ("emacs-request" ,emacs-request)
         ("emacs-dash" ,emacs-dash)
         ("emacs-s" ,emacs-s)
         ("emacs-tree-mode" ,emacs-tree-mode)))
      (build-system emacs-build-system)
      (home-page "https://github.com/ahungry/md4rd")
      (synopsis "Emacs Mode for Reddit")
      (description "Read Reddit from within Emacs interactively.")
      (license license:gpl3+))))

(define-public emacs-browse-at-remote-gnu
  (let ((commit "cd2ccdaef8b1d97337d790175f71cc3dbcfcff64")
        (revision "1"))
    (package
      (inherit emacs-browse-at-remote)
      (name "emacs-browse-at-remote-gnu")
      (version (string-append "0.9.0-" revision "."
                              (string-take commit 7)))
      (source
       (origin
         (method git-fetch)
         (uri (git-reference
               (url "https://github.com/wigust/browse-at-remote.git")
               (commit commit)))
         (file-name (string-append (package-name emacs-browse-at-remote)
                                   "-" version "-checkout"))
         (sha256
          (base32
           "1334xm5lj0j9rb9pvh5zvilnmygmh4l1rv7f9gfcadn50iwprsg8")))))))

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

(define-public emacs-darkroom
  (package
    (name "emacs-darkroom")
    (version "0.1")
    (source (origin
              (method url-fetch)
              (uri (string-append "https://elpa.gnu.org/packages/darkroom-"
                                  version ".el"))
              (sha256
               (base32
                "0fif8fm1h7x7g16949shfnaik5f5488clsvkf8bi5izpqp3vi6ak"))))
    (build-system emacs-build-system)
    (home-page "https://elpa.gnu.org/packages/darkroom.html")
    (synopsis "Remove visual distractions and focus on writing")
    (description "@code{darkroom-mode} makes visual distractions disappear.
The mode-line is temporarily elided, text is enlarged and margins are adjusted
so that it's centered on the window.

@code{darkroom-tentative-mode} is similar, but it doesn't immediately turn-on
@code{darkroom-mode}, unless the current buffer lives in the sole window of
the Emacs frame (i.e. all other windows are deleted).  Whenever the frame is
split to display more windows and more buffers, the buffer exits
@code{darkroom-mode}.  Whenever they are deleted, the buffer re-enters
@code{darkroom-mode}.")
    (license license:gpl3+)))

(define-public emacs-scratch-el
  (let ((commit "2cdf2b841ce7a0987093f65b0cc431947549f897")
        (revision "1"))
    (package
      (name "emacs-scratch-el")
      (version (string-append "1.2" revision "."
                              (string-take commit 7)))
      (source (origin
                (method git-fetch)
                (uri (git-reference
                      (url "https://github.com/ieure/scratch-el.git")
                      (commit commit)))
                (file-name (string-append name "-" version "-checkout"))
                (sha256
                 (base32
                  "0wscsndynjmnliajqaz28r1ww81j8wh84zwaaswx51abhwgl0idf"))))
      (build-system emacs-build-system)
      (native-inputs
       `(("texinfo" ,texinfo)))
      (arguments
       '(#:phases
         (modify-phases %standard-phases
           (add-after 'install 'install-doc
             (lambda* (#:key outputs #:allow-other-keys)
               (unless (invoke "makeinfo" "scratch.texi")
                 (error "makeinfo failed"))
               (install-file "scratch.info"
                             (string-append (assoc-ref outputs "out")
                                            "/share/info")))))))
      (home-page "https://github.com/ieure/scratch-el/")
      (synopsis "Create scratch buffers with the same mode current buffer")
      (description "Scratch is an extension to Emacs that enables one to create
scratch buffers that are in the same mode as the current buffer.  This is
notably useful when working on code in some language; you may grab code into a
scratch buffer, and, by virtue of this extension, do so using the Emacs
formatting rules for that language.")
      (license license:bsd-2))))

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

(define-public emacs-use-package-which
  (package
    (inherit emacs-use-package)
    (name "emacs-use-package-which")
    (source
     (origin
       (inherit (package-source emacs-use-package))
       (patches
        (search-patches "emacs-use-package-add-which-to-bind-key.patch"))))))
