;;; spamprod.el -- generate spam complaint email

;; Copyright (C) 2000-2002 Neil W. Van Dyke

;; Author:   Neil W. Van Dyke <neil@neilvandyke.org>
;; Version:  0.5
;; X-URL:    http://www.neilvandyke.org/spamprod/
;; X-CVS:    $Id: spamprod.el,v 1.132 2002/10/16 01:00:05 nwv Exp $

;; This is free software; you can redistribute it and/or modify it under the
;; terms of the GNU General Public License as published by the Free Software
;; Foundation; either version 2, or (at your option) any later version.  This
;; is distributed in the hope that it will be useful, but without any warranty;
;; without even the implied warranty of merchantability or fitness for a
;; particular purpose.  See the GNU General Public License for more details.
;; You should have received a copy of the GNU General Public License along with
;; GNU Emacs; see the file `COPYING'.  If not, write to the Free Software
;; Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307, USA.

;;; Commentary:

;; *** PLEASE DO NOT USE THIS PACKAGE UNLESS YOU KNOW WHAT YOU'RE DOING.   ***
;; *** With contemporary spam, this package does not find a good complaint ***
;; *** address very often; it needs a complete redesign to be useful.      ***
;;
;; Introduction:
;;
;;   Given a spam email message in Emacs, `spamprod.el' generates a complaint
;;   email addressed to various parties who are hopefully in a position to do
;;   something about curtailing the spam.  (SEE *** NOTICE ABOVE.)

;; System Requirements:
;;
;;   The `spamprod.el' package is developed using FSF GNU Emacs 21 on a
;;   GNU/Linux system, and should work with recent Emacs 20 and 21 versions on
;;   Unix variants.  `spamprod.el' has not yet been tested with the XEmacs fork
;;   of Emacs, and I'd welcome any necessary patches.
;;
;;   `spamprod.el' has special support for the VM email reader package by Kyle
;;   E. Jones (`http://www.wonderworks.com/vm/'), although VM is not required.

;; Installation:
;;
;;   1. Put this `spamprod.el' file somewhere in your Emacs Lisp load path.
;;
;;   2. Add the following to your `.emacs' file (or elsewhere):
;;
;;          (require 'spamprod)
;;
;;   3. Optionally set `spamprod-exclude-domains' and
;;      `spamprod-exclude-emailaddrs' in your `.emacs' file (or elsewhere).
;;      For example:
;;
;;          (setq spamprod-exclude-domains
;;                '("foobar.edu"
;;                  "mailhub.someisp.net"))
;;
;;          (setq spamprod-exclude-emailaddrs
;;                '("joe@cs.foobar.edu"
;;                  "sexkitten69@someisp.foo"
;;                  "roleplaying-discussion@mailinglists.bar"))
;;
;;   4. Optionally customize various other option variables (see "Option
;;      Variables" below).

;; How To Use It:
;;
;;   1. Do one of the following, depending on how you are viewing the spam:
;;  
;;      a. In the VM mail reader: Press the `$' key (mnemonics: "$pam" or
;;         "spam=greed=money=$") from within the VM summary or message windows.
;;  
;;      b. In another kind of Emacs buffer: Make sure you are viewing the full
;;         raw original email text (including all headers) in the current
;;         buffer, and then invoke `M-x spamprod-from-buffer RET'.
;;  
;;      An Emacs mail window with a generated complaint email will appear.
;;  
;;   2. Quickly double-check that the complaint email is addressed to the
;;      appropriate parties, make any necessary changes, and then send it
;;      (usually by pressing `C-c C-c').

;; Alternative Package:
;;
;;   If `spamprod.el' does not surpass your every fantasy of Emacs-based spam
;;   complaint aids, you might take a look at `uce.el' by Stanislav Shalunov
;;   <shalunov AT mccme.ru>.  `uce.el' was first created in 1996 with similar
;;   goals, and you may prefer the way it operates.  In addition, it supports
;;   Rmail and Gnus (but not VM).  Any redundancy of `spamprod.el' with respect
;;   to `uce.el' is partly accidental, since I initially hacked up the former
;;   at a time when I had limited Internet access and only a fuzzy recollection
;;   of seeing a similar Emacs package before.
;;   http://www.deja.com/getdoc.xp?AN=661148514&fmt=text

;; Author's To-Do List:
;;
;;   * Code smarter injection point detection heuristic.
;;
;;   * Add Gnus integration.
;;
;;   * Add Rmail integration.  (Actually, wait for an Rmail user to do this and
;;     send us a patch.)
;;
;;   * Make sure that other newline conventions don't break us.
;;
;;   * Be more smart about Received headers, such as not complaining about the
;;     last hop (unless there's only one hop).  Look at more samples to get a
;;     better intuition for the best way.
;;
;;   * Try to avoid mailing to the loopback address.
;;
;;   * Include `^From_' header when attaching spam to complaint mail, unless
;;     the header has been mangled, such as by VM.
;;
;;   * Special-case complaint mechanisms for certain domains (e.g., see
;;     `http://www.nic.it/NA/mailspam-engl.html').
;;
;;   * Add a better way to avoid automatic replies.
;;
;;   * Automatically detect when an icky little spam company is using its own
;;     hosts for spam, and figure out their upstream connectivity provider.
;;
;;   * Try to extract a domain from any `^From_' header.
;;
;;   * Maybe get email addresses out of spam body.
;;
;;   * Maybe extract domain names of any URLs mentioned in spam body.
;;
;;   * Maybe try to get a domain out of the Message-ID.
;;
;;   * Reconcile `spamprod-max-domain-depth' with the fact that we now
;;     recognize that some domains have two or more too-general levels.
;;     Perhaps the easiest way to do this is to instead specify the maximum
;;     depth *below the too-general threshhold*, with the default being 2.
;;
;;   * Maybe don't drill up/down some domains.  For example, there's probably
;;     no point in complaining to subdomains of `compuserve.com'.
;;
;;   * Respond to suggestions from our Gentle Readers.

;;; Change Log:

;; [Version 0.5, 15-Oct-2002] Added notice (we're releasing a package to tell
;; people not to use it).  Updated email address.

;; [Version 0.4, 25-Nov-2001]
;; * Now maintained under Emacs 21.
;; * Fixed `mindegyik' typo in `spamprod-overly-general-domains' (thanks to
;;   Kalle Olavi Niemitalo for spotting this).
;; * Removed "postmaster" from `spamprod-complaint-accounts'.
;; * Kludged around byte-compile problem in `spamprod-from-vm'.
;; * Minor comment changes.
;; * Started to add `spamprod-complaint-address-map', but pretend we didn't.

;; [Version 0.3, 19-Oct-2000] Added `spamprod-ignore-unresolvable-domains-p'
;; feature.  Changed window management for complaint mail buffer -- instead of
;; popping a new frame, use a window that fills the entire current frame, and
;; restore the window configuration upon mail send.  Added
;; `spamprod-ignore-from-header' preference, per request.  Added feature to
;; remove excess whitespace from Subject headers.  Removed the foolish use of
;; `set-buffer-modified-p'.

;; [Version 0.2, 16-Oct-2000] Made `sendmail' be invoked with `-f <>', to
;; disable error replies from some mailers.  Added support for
;; `spamprod-overly-general-domains' and `spamprod-tlds-with-category-slds',
;; for better exclusion of uncomplainable domains (this overkill was sponsored
;; in part by `http://www.norid.no/domreg.html').  Made undo and modified info
;; be reset in mail buffer.

;; [Version 0.1, 14-Oct-2000] Initial release.

;;; Code:

(defconst spamprod-version "0.5")

(require 'mail-extr)
(require 'sendmail)

;; Option Variables:

(defvar spamprod-archive-file "~/.spamprod-archive"
  "*If non-nil, mailbox file in which to archive sent spam complaint emails.")

(defvar spamprod-bcc-p t
  "*If non-nil, address the complaint email using the BCC (blind-carbon-copy)
header instead of the To header.")

(defvar spamprod-boilerplate 
  "The following spam appears to have been sent from or through your site.

Possible reasons for this include: (1) the spam was sent from an email
account at your site; (2) you have an open mail relay; (3) you
propagated spam from another site; (4) the mail headers of the spam were
forged to make it look like your site was used; and (5) the spam uses a
reply email address that appears to be at your site.

Please help discourage and thwart spammers.

    [This message was prepared with the aid of `spamprod.el', but was
     sent manually by me.  Please do not reply to me.  The Reply-To
     header of this message is invalid, to discourage automatic replies.]"
  "*Boilerplate text for the top of the spam complaint email.")

(defvar spamprod-complaint-accounts '("abuse")
  "*Mail account names that are typically appropriate for reporting spam from a
given domain.")

(defvar spamprod-complaint-address-map
  '(("abuse@uswest.net" . "abuse-nonverbose@uswest.net")
    ("abuse@uu.net"     . "abuse-noverbose@uu.net")
    ("abuse@qwest.net"  . "abuse-nonverbose@qwest.net"))
  "*Disregard; we don't actually use this yet...")

(defvar spamprod-debug-unmatched-received-headers-p nil
  "*If non-nil, generate an error when unable to parse a Received header,
rather than ignoring it.  For debugging purposes.")

(defvar spamprod-errors-to "spam@spam.spam"
  "*Email address to use in the Errors-To header of the complaint email.")

(defvar spamprod-exclude-domains '()
  "*List of domain names (in all-lowercase) to never complain to.  Currently,
this is typically the domain(s) for your own email account providers.")

(defvar spamprod-exclude-emailaddrs 
  (if user-mail-address
      (list (downcase user-mail-address)))
  "*List of email addresses (in all-lowercase) which should be assumed not to
be in use by spammers and therefore not considered when finding domains to
complain to.  Typically these are the email addresses for your own email
account(s) and any spam-susceptible mailing lists you are on.")

(defvar spamprod-exclude-headers
  '("status"
    "x-coding-system"
    "x-vm-attributes"
    "x-vm-bookmark"
    "x-vm-imap-retrieved"
    "x-vm-labels"
    "x-vm-last-modified"
    "x-vm-pop-retrieved"
    "x-vm-summary-format"
    "x-vm-v5-data"
    "x-vm-vheader")
  "*List of email header names (all lowercase, and sans colons) to not include
when attaching a copy of the \"original\" spam to the complaint email.  These
are typically headers that are added to the email by your mail reader, and thus
should not be forwarded.")

(defvar spamprod-extract-from-to-header-p t
  "*If non-nil, assume that the To header of the spam is also fair game for
finding domains to complain to.  The rationale being that spammers sometimes
forge To headers that make it appear that a certain service provider is
involved in the spam, and the provider should be informed that the spammer may
be tarnishing the goodwill associated with the provider's name.")

(defvar spamprod-from "spam@spam.spam"
  "*Email address to use in the From and Reply-To headers of the complaint
email.  By default this is an invalid address, to reduce the number of replies
you receive.")

(defvar spamprod-ignore-from-header-p nil
  "*If non-nil, the value of the From header is ignored when scanning the spam
message.  The rationale for this preference feature is that the From header is
believed to be almost always invalid, so the only reason to extract a domain
name from it is that you wish to notify the domain name holder that their name
is being besmirched by spammers.")

(defvar spamprod-ignore-unresolvable-domains-p t
  "*If non-nil, domain names for which no A, CNAME, or MX record can be found
are removed from the list of domains to complain to.  This prevents some mailer
bounces, such as if we were given a domain `somehost.someregion.someisp.tld'
for which `someregion.someisp.tld' is not a deliverable domain for email.")

(defvar spamprod-max-domain-depth 3
  "*When finding domain names to complain to, the maximum depth in the
hierarchical namespace to use.  For example, the domain name
`losedows.cs.beer.edu' has a depth of 4, and setting the maximum depth to 3
would result in complaints addressed to `@cs.beer.edu' and `@beer.edu'.")

(defvar spamprod-nslookup-program
  (let ((filename "/usr/bin/nslookup"))
    (if (file-executable-p filename) filename "nslookup"))
  "*Command name for the `nslookup' program.  This is used if
`spamprod-ignore-unresolvable-domains-p' is non-nil.")

(defvar spamprod-overly-general-domains
  '(
    ;; ag
    "com.ag" "edu.ag" "gov.ag" "net.ag" "org.ag"
    ;; ar
    "com.ar" "net.ar" "org.ar" "gov.ar"
    ;; au
    "asn.au" "com.au" "edu.au" "gov.au" "org.au"
    ;; ba
    "edu.ba" "gov.ba" "net.ba" "org.ba"
    ;; bb
    "co.bb" "com.bb"
    ;; bh
    "com.bh"
    ;; br
    "com.br"
    ;; ca
    "bc.ca" "on.ca" "qz.ca"
    ;; cn
    "ac.cn" "ah.cn" "bj.cn" "com.cn" "cq.cn" "fj.cn" "gd.cn" "gov.cn" "gs.cn"
    "gx.cn" "gz.cn" "ha.cn" "hb.cn" "he.cn" "hi.cn" "hk.cn" "hl.cn" "hn.cn"
    "jl.cn" "js.cn" "jx.cn" "ln.cn" "mo.cn" "net.cn" "nm.cn" "nx.cn" "org.cn"
    "qh.cn" "sc.cn" "sd.cn" "sh.cn" "sn.cn" "sx.cn" "tj.cn" "tw.cn" "xj.cn"
    "xz.cn" "yn.cn" "zj.cn"
    ;; cr
    "ac.cr" "co.cr" "ed.cr" "fi.cr" "go.cr" "or.cr" "sa.cr"
    ;; dz
    "art.dz" "ass.dz" "com.dz" "edu.dz" "gov.dz" "net.dz" "org.dz" "pol.dz"
    ;; ee
    "com.ee" "edu.ee" "org.ee" "pri.ee"
    ;; eg
    "com.eg" "edu.eg" "eun.eg" "gov.eg" "net.eg" "org.eg" "sci.eg"
    ;; et
    "net.et"
    ;; fj
    "ac.fj" "com.fj" "gov.fj" "net.fj" "org.fj"
    ;; fr
    "asso.fr" "com.fr" "nom.fr" "prd.fr" "presse.fr" "tm.fr"
    ;; gh
    "com.gh" "edu.gh" "gov.gh" "mil.gh" "org.gh"
    ;; gi
    "com.gi" "edu.gi" "gov.gi" "ltd.gi" "mod.gi" "org.gi"
    ;; gr
    "com.gr" "edu.gr" "net.gr" "org.gr"
    ;; gt
    "com.gt" "edu.gt" "gob.gt" "ind.gt" "mil.gt" "net.gt" "org.gt"
    ;; hu
    "2000.hu" "agrar.hu" "bolt.hu" "casino.hu" "city.hu" "co.hu" "erotica.hu"
    "erotika.hu" "film.hu" "forum.hu" "games.hu" "hotel.hu" "info.hu"
    "ingatlan.hu" "jogasz.hu" "konyvelo.hu" "lakas.hu" "media.hu"
    "mindegyik.hu" "news.hu" "org.hu" "priv.hu" "reklam.hu" "sex.hu" "shop.hu"
    "sport.hu" "suli.hu" "szex.hu" "tm.hu" "tozsde.hu" "utazas.hu" "video.hu"
    ;; id
    "ac.id" "co.id" "or.id" "net.id" "mil.id" "go.id" "web.id" "sch.id"
    ;; jo
    "edu.jo" "gov.jo" "mil.jo" "net.jo" "org.jo"
    ;; lb
    "edu.lb" "gov.lb" "net.lb" "org.lb"
    ;; lc
    "com.lc" "edu.lc" "org.lc"
    ;; lk
    "gov.lk"
    ;; ls
    "co.ls" "org.ls"
    ;; lv
    "asn.lv" "com.lv" "conf.lv" "edu.lv" "gov.lv" "id.lv" "mil.lv" "net.lv"
    "org.lv"
    ;; ly
    "com.ly" "org.ly" "net.ly"
    ;; mm
    "com.mm" "edu.mm" "gov.mm" "mil.mm" "net.mm" "org.mm"
    ;; mo
    "com.mo" "edu.mo" "gov.mo" "net.mo" "org.mo"
    ;; mt
    "com.mt" "org.mt"
    ;; mx
    "com.mx" "edu.mx" "gob.mx" "net.mx" "org.mx"
    ;; no (Note that not all geographic SLDs are listed.)
    "aa.no" "ah.no" "bu.no" "dep.no" "fhs.no" "fm.no" "folkebibl.no"
    "fylkesbibl.no" "hl.no" "hm.no" "idrett.no" "kommune.no" "mil.no" "mr.no"
    "museum.no" "nl.no" "nt.no" "of.no" "ol.no" "oslo.no" "priv.no" "rl.no"
    "sf.no" "st.no" "svalbard.no" "tm.no" "tr.no" "va.no" "vf.no" "vgs.no"
    ;; np
    "com.np" "gov.np" "net.np" "org.np"
    ;; pg
    "ac.pg" "com.pg" "net.pg"
    ;; ph
    "com.ph"
    ;; pn
    "co.pn" "net.pn" "org.pn"
    ;; tp
    "com.tp" "net.tp" "org.tp"
    ;; ug
    "ac.ug" "co.ug" "go.ug" "or.ug"
    ;; vi
    "co.vi" "com.vi" "gov.vi" "k12.vi" "org.vi"
    ;; ws
    "com.ws" "edu.ws" "gov.ws" "net.ws" "org.ws"
    ;; yu
    "ac.yu" "bg.ac.yu" "co.yu" "edu.yu" "org.yu"
    )
  "*List of domain names (in all-lowercase) which are too general for purposes
of spam complaint.  Note that top-level domains for which all of their
second-level domains are too general should be listed in
`spamprod-tlds-with-category-slds' instead of enumerating their second-level
domain names here.")

(defvar spamprod-tlds-with-category-slds
  '("ae" "ai" "bt" "bz" "ck" "cy" "do" "fk" "hk" "im" "in" "io" "ir" "jp" "ke"
    "kh" "kr" "ky" "my" "nz" "om" "sa" "sb" "sg" "sv" "tw" "tz" "uk" "us" "uy"
    "ve" "vn" "zm")
  "*List of top-level domains (in all-lowercase) for which the second-level
domains are always (or almost always) broad categories (e.g., `co.uk'), and
therefore are too general for spam complaint.")

(defvar spamprod-subject-prefix "[spam] "
  "*If non-nil, string to prefix to the Subject header of the complaint
emails.")

(defvar spamprod-valid-non2letter-tlds
  '("com" "edu" "gov" "int" "mil" "net" "org")
  "*List of the valid top-level domains (in all-lowercase) that do not consist
of two letters.  This is as an aid in disambiguating global fully-qualified
domain names from local ones that appear in some Received headers.")

;; Global Constants:

(defconst spamprod-received-header-pat
  (let ((ws     "[ \t\n\r]+")
        (ws-opt "[ \t\n\r]*")
        (host   "[-\\.0-9a-z]+")
        (ipaddr-bracketed "\\[[\\.0-9]+\\]"))
    (concat "\\`"
            ws-opt
            "from"
            ws
            "\\("                       ; #1< first-host
            host
            "\\)"                       ; #1> first-host
            "\\("                       ; #2< paren-or-ip-or-ws
            ws-opt
            "("
            ws-opt 
            "\\("                       ; #3< first-paren-host-opt
            host
            "\\)?"                      ; #3> first-paren-host-opt
            ws-opt
            ipaddr-bracketed
            ws-opt
            ")"
            ws-opt
            "\\|"                       ; #2| paren-or-ip-or-ws
            ws-opt
            ipaddr-bracketed
            ws-opt
            "\\|"                       ; #2| paren-or-ip-or-ws
            ws
            "\\)?"                      ; #2> paren-or-ip-or-ws
            "by"
            ws
            "\\("                       ; #4< second-host
            host
            "\\)"                       ; #4> second-host
            )))

;; Non-Option Global Variables:

(defvar spamprod-complain-domains nil)

(defvar spamprod-orig-subject nil)

(defvar spamprod-received-hosts nil)

(defvar spamprod-saved-send-mail-function nil)
(make-variable-buffer-local 'spamprod-saved-send-mail-function)

(defvar spamprod-saved-window-configuration nil)
(make-variable-buffer-local 'spamprod-saved-window-configuration)

(defvar spamprod-senderish-emailaddrs nil)

(defvar spamprod-to nil)

(defvar spamprod-unresolvable-domains nil)

;; Macros:

(defmacro spamprod-list-append-element (list-var element)
  `(setq ,list-var (nconc ,list-var (list ,element))))

(defmacro spamprod-list-prepend-element (list-var element)
  `(setq ,list-var (cons ,element ,list-var)))

(defmacro spamprod-looking-at-cs (&rest args)
  `(let ((case-fold-search nil))
     (looking-at ,@args)))

(defmacro spamprod-string-match-ci (&rest args)
  `(let ((case-fold-search t))
     (string-match ,@args)))

;; Functions:

(defun spamprod-build-complain-domains ()
  (setq spamprod-complain-domains '())
  (mapcar 'spamprod-build-complain-domains-item spamprod-received-hosts)
  (mapcar 'spamprod-build-complain-domains-item-from-emailaddr
          spamprod-senderish-emailaddrs)
  (if spamprod-ignore-unresolvable-domains-p
      (spamprod-weed-out-unresolvable-domains))
  (setq spamprod-complain-domains
        (sort spamprod-complain-domains 'string-lessp)))
  
(defun spamprod-build-complain-domains-item (domain)
  (save-match-data
    (let ((fqdn      "")
          (i         0)
          (keepgoing t)
          (levels    (reverse (spamprod-split-on-char (downcase domain) ?.)))
          (part      nil)
          (tld       nil))
      (while keepgoing
        (if (or (not levels)
                (= i spamprod-max-domain-depth))
            (setq keepgoing nil)
          (setq part (car levels))
          (if (= i 0)
              (if (or (member part spamprod-valid-non2letter-tlds)
                      (string-match "\\`[a-z][a-z]\\'" part))
                  (setq fqdn part
                        tld  part)
                (setq keepgoing nil))
            (setq fqdn (concat part "." fqdn)))
          (if keepgoing
              (if (member fqdn spamprod-exclude-domains)
                  (setq keepgoing nil)
                (if (and (> i 0)
                         (or (> i 1)
                             (not (member tld
                                          spamprod-tlds-with-category-slds)))
                         (not (member fqdn spamprod-overly-general-domains))
                         (not (member fqdn spamprod-complain-domains)))
                    (spamprod-list-prepend-element spamprod-complain-domains
                                                   fqdn))
                (setq i (1+ i))
                (setq levels (cdr levels)))))))))

(defun spamprod-build-complain-domains-item-from-emailaddr (emailaddr)
  (save-match-data
    (if (or (not emailaddr)
            (string-match "\\`[ \t\n]*\\'" emailaddr)
            (member (downcase emailaddr) spamprod-exclude-emailaddrs))
        nil
      (let ((domain (downcase emailaddr)))
        (if (string-match "@\\([^@]*\\)\\'" domain)
            (setq domain (match-string 1 domain)))
        (spamprod-build-complain-domains-item domain)))))

(defun spamprod-build-to ()
  (setq spamprod-to '())
  (mapcar
   (function (lambda (domain)
               (mapcar (function
                        (lambda (account)
                          (spamprod-list-append-element
                           spamprod-to
                           (concat account "@" domain))))
                       spamprod-complaint-accounts)))
   spamprod-complain-domains))

(defun spamprod-domain-resolvable-p (domain)
  ;; Tests (imprecisely) whether an A, CNAME, or MX record can be found for the
  ;; domain.
  (save-excursion
    (let ((output-buf (generate-new-buffer "*spamprod-nslookup*"))
          (found      nil))
      (unwind-protect
          (progn
            (set-buffer output-buf)
            (or (and (eq (call-process
                          spamprod-nslookup-program nil output-buf nil
                          "-retries=1" domain)
                         0)
                     (> (point-max) 2)
                     (not (let ((case-fold-search t))
                            (goto-char (point-min))
                            (re-search-forward
                             (concat "^\\*\\*\\*[^\n]+can't find[^\n]+: "
                                     "Non-existent host/domain[ \t]*$")
                             nil
                             t))))
                (and (progn (delete-region (point-min) (point-max))
                            (eq (call-process
                                 spamprod-nslookup-program nil output-buf nil
                                 "-querytype=MX" "-retries=1" domain)
                                0))
                     (> (point-max) 2)
                     (let ((case-fold-search t))
                       (goto-char (point-min))
                       (re-search-forward ",[ \t]*mail exchanger[ \t]*="
                                          nil t)))))
            ;; unwind-protect cleanup
            (kill-buffer output-buf)))))

(defun spamprod-from-buffer (&optional window-config)
  (interactive)
  (or window-config (setq window-config (current-window-configuration)))
  (spamprod-mail-buf-show (spamprod-mail-buf-prepare window-config)))

(defun spamprod-from-vm ()
  (interactive)
  (let ((window-config (current-window-configuration)))
    ;; Note that the VM-specific code was based on the behavior of VM 6.75.
    ;; Other versions of VM may have somewhat different code patterns for
    ;; getting the raw text of the current message.
    (vm-follow-summary-cursor)
    (eval (macroexpand '(vm-select-folder-buffer)))
    (vm-check-for-killed-summary)
    (vm-error-if-folder-empty)
    (save-restriction
      (save-excursion
        (vm-widen-page)
        (goto-char (point-max))
        (widen)
        (narrow-to-region (point)
                          (eval (macroexpand (list 'vm-start-of
                                                   (car vm-message-pointer)))))
        (spamprod-from-buffer window-config)))))

(defun spamprod-hostname-fix (hostname)
  ;; First-pass hostname cleanup for `spamprod-received-hosts-add'. Returns
  ;; the value of `hostname' massaged to all-downcase, or it returns nil if
  ;; `hostname' looks like an IP address.
  (if hostname
      (save-match-data
        (if (string-match "\\`[\\.0-9]+\\'" hostname)
            nil
          (downcase hostname)))))

(defun spamprod-insert-buf-substr-into (begin end buf)
  (let ((str (buffer-substring-no-properties begin end)))
    (save-excursion
      (set-buffer buf)
      (insert str))))

(defun spamprod-insinuate-vm ()
  (require 'vm)
  (define-key vm-mode-map "$" 'spamprod-from-vm))

(defun spamprod-mail-buf-finish (mail-buf window-config)
  (save-excursion

    ;; Switch to the mail buffer, which should already contain the raw text of
    ;; the spam message.
    (set-buffer mail-buf)

    ;; Insert all the headers and boilerplate above the included spam message,
    ;; and leave the point positioned at the To/BCC header value.
    (let (saved-point)
      (goto-char (point-min))
      (if spamprod-from
          (insert "From: "     spamprod-from "\n"
                  "Reply-To: " spamprod-from "\n"))
      (insert "Subject: " 
              (spamprod-string-remove-excess-whitespace
               (concat spamprod-subject-prefix
                       (or spamprod-orig-subject "")))
              "\n")
      (insert (if spamprod-bcc-p "BCC" "To")
              ": ")
      (setq saved-point (point))
      (insert (mapconcat 'identity spamprod-to ", ")
              "\n")
      (if spamprod-errors-to
          (insert "Errors-To: " spamprod-from "\n"))
      (insert "Precedence: bulk\n")
      (if spamprod-archive-file
          (insert "FCC: " spamprod-archive-file "\n"))
      (let ((start (point)))
        (insert mail-header-separator "\n")
        ;; Note: The text property stuff here is intended to mimic the
        ;; pertinent behavior of the mail buffer preparation code in
        ;; `sendmail.el'.
        (if (get 'mail-header-separator 'rear-nonsticky)
            (put-text-property start
                               (1- (point))
                               'category
                               'mail-header-separator)))
      (insert spamprod-boilerplate "\n")
      (insert "\n-----spam message attached below this line-----\n")
      (goto-char saved-point))

    ;; Reset undo history.
    (buffer-disable-undo)
    (buffer-enable-undo)
     
    ;; Initialize `mail-mode' in this buffer, without hooks.
    (let ((mail-mode-hook nil))
      (mail-mode))
    
    ;; After `mail-mode' is initialized (i.e., after it kills all local
    ;; variables), stash our saved window configuration in a local variable.
    (make-local-variable 'spamprod-saved-window-configuration)
    (setq spamprod-saved-window-configuration window-config)

    ;; Also after `mail-mode' is initialized, interpose our wrapper for
    ;; `sendmail-send-it' (or whatever `send-mail-function' indicates).
    (make-local-variable 'send-mail-function)
    (make-local-variable 'spamprod-saved-send-mail-function)
    (setq spamprod-saved-send-mail-function send-mail-function)
    (setq send-mail-function 'spamprod-send-mail-wrapper)))

(defun spamprod-mail-buf-prepare (window-config)
  (or window-config (error "spamprod-mail-buf-prepare: window-config is nil"))
  (let ((mail-buf (generate-new-buffer "*spamprod-mail*")))
    (spamprod-scan-spam-buf (current-buffer) mail-buf)
    (spamprod-build-complain-domains)
    (spamprod-build-to)
    (spamprod-mail-buf-finish mail-buf window-config)
    mail-buf))

(defun spamprod-mail-buf-show (mail-buf)
  (switch-to-buffer mail-buf)
  (delete-other-windows)
  (or spamprod-to
      (message
       "We couldn't find anyone to whom to complain about the spam.")))

(defun spamprod-received-hosts-add (hostname)
  ;; If `hostname', after being fixed, is non-nil and not already a member of
  ;; `spamprod-received-hosts', then add it to that list.
  (and hostname
       (setq hostname (spamprod-hostname-fix hostname))
       (not (member hostname spamprod-received-hosts))
       (spamprod-list-append-element spamprod-received-hosts hostname)))

(defun spamprod-scan-spam-buf (buf mail-buf)
  ;; Populate `spamprod-senderish-emailaddrs' and `spamprod-received-hosts'
  ;; with email addresses and hostnames from the spam message in the buffer
  ;; specified by `buf', set `spamprod-orig-subject', and insert copy of this
  ;; spam message into `mail-buf' with appropriate edits.  These addresses will
  ;; be used elsewhere to generate a list of email addresses to complain about
  ;; the spam to.
  (setq spamprod-senderish-emailaddrs nil
        spamprod-received-hosts       nil
        spamprod-orig-subject         nil)
  (save-match-data
    (save-excursion
      (set-buffer buf)
      (goto-char (point-min))
      (let ((exclude-headers (mapcar 'downcase spamprod-exclude-headers)))
        (while (progn (beginning-of-line)
                      (not (looking-at "^[ \t]*$")))
          
          ;; Act based on the kind of line.
          (cond
           
           ((spamprod-looking-at-cs "^From ")
            ;; This line is a "^From_" line, which we just ignore.  Note that
            ;; we don't signal an error if "^From_" occurs other than as the
            ;; first line.
            )
           
           ((spamprod-looking-at-cs
             "\\([^ \t\n:]+\\)[ \t]*:[ \t]*\\([^\n]*\\(\n[ \t]+[^\n]+\\)*\\)")
            ;; This line begins a header, so handle it based on name, then
            ;; leave the point at the end of the (possibly multi-line) value so
            ;; that the forward-line at the end of the loop will advance to the
            ;; next header's start line or the header separator line.
            (let ((label    (downcase (match-string 1)))
                  (value    (match-string 2))
                  (endpoint (match-end 0))
                  (text     (match-string 0)))
              (cond ((or (member label '("errors-to"
                                         "reply-to"
                                         "sender"))
                         (and (not spamprod-ignore-from-header-p)
                              (string= label "from"))
                         (and spamprod-extract-from-to-header-p
                              (string= label "to")))
                     (spamprod-scan-header-senderish value))
                    ((string= label "received")
                     (spamprod-scan-header-received value))
                    ((string= label "subject")
                     (setq spamprod-orig-subject value)))
              (goto-char endpoint)
              (if (not (member label exclude-headers))
                  (save-excursion
                    (set-buffer mail-buf)
                    (insert text "\n")))))
           
           (t
            ;; This line was neither "^From_" nor a header start line, so barf.
            (error "spamprod: message has a malformed header line.")))
          
          ;; Advance to next line, which should be the next header or the
          ;; header separator line.
          (if (/= (forward-line 1) 0)
              (error "spamprod: message has no header separator."))))

      ;; We are on the header separator line right now, so insert the
      ;; remainder of the contents into mail-buf.
      (spamprod-insert-buf-substr-into (point) (point-max) mail-buf))))

(defun spamprod-scan-header-received (value)
  ;; Note that some Received headers may contain IP addresses that the mail
  ;; server did or could not reverse-resolve, and it may behoove us to attempt
  ;; to do so.  But for now we will remain unbehooved.
  (cond

   ((spamprod-string-match-ci spamprod-received-header-pat value)
    ;; This Received header matches the usual pattern, so
    ;; extract the hostnames from it.
    (let ((first-host           (match-string 1 value))
          (first-paren-host-opt (match-string 3 value))
          (second-host          (match-string 4 value)))
      (spamprod-received-hosts-add first-host)
      (spamprod-received-hosts-add first-paren-host-opt)
      (spamprod-received-hosts-add second-host)))

   (spamprod-debug-unmatched-received-headers-p
    ;; We did not match the Received header, and debugging is enabled, so barf.
    (error "DEBUG: unmatched Received header: %s" value))))

(defun spamprod-scan-header-senderish (value)
  (let ((extract (mail-extract-address-components value)))
    (and extract
         (setq extract (nth 1 extract))
         (spamprod-list-append-element
          spamprod-senderish-emailaddrs
          extract))))

(defun spamprod-send-mail-wrapper ()
  (interactive)
  ;; Note that we set `user-mail-address' to "<>" for the sole purpose of
  ;; having `sendmail-send-it' call the `sendmail' program with "-f <>".
  (let ((mail-buf          (current-buffer))
        (window-config     spamprod-saved-window-configuration)
        (mail-from-style   'angles)
        (user-mail-address "<>"))
    ;; Call the real mail send function with the overridden `mail-from-style'
    ;; and `user-mail-address' variables.
    (funcall spamprod-saved-send-mail-function)

    ;; Restore saved window configuration from before the mail buffer was
    ;; created.
    (set-window-configuration window-config)

    ;; As an icky kludge around the fact that `mail-send-and-exit' calls
    ;; `mail-bury' after we restore our window configuration, we will now put
    ;; the buffer back in a window here just so that `mail-send-and-exit' can
    ;; bury it again (rather than burying a buffer from the original saved
    ;; window configuration).
    (switch-to-buffer mail-buf)))
    
(defun spamprod-split-on-char (string char)
  ;; Note that this could be more elegant.
  (if (not (and string char))
      nil
    (if (stringp char)
        (if (= (length char) 1)
            (setq char (aref 0 char))
          (error "spamprod-split-on-char: char is a string of length /= 1.")))
    (let* ((start 0)
           (length (length string))
           (i      0)
           (result '()))
      (while (<= i length)
        (if (or (= i length)
                (= (aref string i) char))
            (progn
              (setq result (nconc result (list (substring string start i))))
              (setq start (1+ i))))
        (setq i (1+ i)))
      result)))

(defun spamprod-string-remove-excess-whitespace (str)
  (save-match-data
    (let ((non-whitespace nil)
          (start          nil)
          (substrings     '()))
      (while (string-match "\\([ \t\n\r\v\f]+\\)?\\([^ \t\n\r\v\f]+\\)"
                           str
                           start)
        (setq start (match-end 0))
        (if (setq non-whitespace (match-string 2 str))
            (setq substrings
                  (nconc substrings (if (and (match-beginning 1) substrings)
                                        (list " " non-whitespace)
                                      (list non-whitespace))))))
      (or (apply 'concat substrings) ""))))

(defun spamprod-weed-out-unresolvable-domains ()
  (setq spamprod-unresolvable-domains '())
  (let ((new-complain-domains '()))
    (mapcar (function
             (lambda (domain)
               (if (spamprod-domain-resolvable-p domain)
                   (spamprod-list-append-element new-complain-domains domain)
                 (spamprod-list-append-element spamprod-unresolvable-domains
                                               domain))))
            spamprod-complain-domains)
    (setq spamprod-complain-domains new-complain-domains)))

;; Initialization:

(eval-after-load "vm" '(spamprod-insinuate-vm))

(provide 'spamprod)

;;; spamprod.el ends here
