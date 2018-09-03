;;; GNU Guix --- Functional package management for GNU
;;; Copyright © 2018 Oleg Pykhalov <go.wigust@gmail.com>
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

(define-module (gnu packages wigust-lisp)
  #:use-module (gnu packages lisp)
  #:use-module (gnu packages)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (guix packages)
  #:use-module (gnu packages readline)
  #:use-module (gnu packages texinfo)
  #:use-module (gnu packages tex)
  #:use-module (gnu packages m4)
  #:use-module (guix download)
  #:use-module (guix git-download)
  #:use-module (guix hg-download)
  #:use-module (guix utils)
  #:use-module (guix build-system gnu)
  #:use-module (guix build-system asdf)
  #:use-module (guix build-system trivial)
  #:use-module (gnu packages base)
  #:use-module (gnu packages compression)
  #:use-module (gnu packages fontutils)
  #:use-module (gnu packages maths)
  #:use-module (gnu packages multiprecision)
  #:use-module (gnu packages ncurses)
  #:use-module (gnu packages bdw-gc)
  #:use-module (gnu packages libffi)
  #:use-module (gnu packages libffcall)
  #:use-module (gnu packages readline)
  #:use-module (gnu packages sdl)
  #:use-module (gnu packages libsigsegv)
  #:use-module (gnu packages linux)
  #:use-module (gnu packages admin)
  #:use-module (gnu packages ed)
  #:use-module (gnu packages gl)
  #:use-module (gnu packages gcc)
  #:use-module (gnu packages glib)
  #:use-module (gnu packages gettext)
  #:use-module (gnu packages m4)
  #:use-module (gnu packages pkg-config)
  #:use-module (gnu packages version-control)
  #:use-module (gnu packages xorg)
  #:use-module (ice-9 match)
  #:use-module (srfi srfi-1))

(define-public sbcl-stumpwm-checkout
  (let ((commit "cec7fd9e963e5da59b05ba0ffbe292dc94fd2947"))
    (package
      (inherit sbcl-stumpwm)
      (version (git-version (package-version sbcl-stumpwm) "1" commit))
      (source
       (origin
         (method git-fetch)
         (uri (git-reference
               (url "https://github.com/stumpwm/stumpwm.git")
               (commit commit)))
         (file-name (git-file-name (package-name sbcl-stumpwm) version))
         (sha256
          (base32
           "1qyvhw73dghs167hcds1k2021w2hakh99zfv0039w7lx259gazl9"))))
      (inputs
       `(("sbcl-alexandria" ,sbcl-alexandria)
         ,@(package-inputs sbcl-stumpwm)))
      (native-inputs `(("texinfo" ,texinfo)))
      (outputs (append (package-outputs sbcl-stumpwm) '("doc")))
      (arguments
       (substitute-keyword-arguments
           (package-arguments sbcl-stumpwm)
           ((#:phases phases)
            `(modify-phases ,phases
               (add-after 'build-program 'build-documentation
                 (lambda* (#:key outputs #:allow-other-keys)
                   (invoke "makeinfo" "stumpwm.texi.in")
                   (install-file "stumpwm.info"
                                 (string-append (assoc-ref outputs "doc")
                                                "/share/info")))))))))))