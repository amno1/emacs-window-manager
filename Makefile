.POSIX:
EM = emacs --batch
EMACS ?= emacs
CASK  ?= cask
ECUKES ?= $(shell find .cask/*/elpa/ecukes-*/bin/ecukes | tail -1)
ECUKES_OPTS ?= --tags ~@known --no-win

SRCS := $(wildcard *.el)
LISPINCL ?= $(addprefix -L ,.)
LISPINCL += $(addprefix -L ,${HOME}/.emacs.d/lisp)
LISPINCL += $(addprefix -L ,${HOME}/.emacs.d/elpa)

EM = emacs --batch

ifeq ($(PREFIX),)
    PREFIX := ${HOME}/.emacs.d/
endif

.PHONY: clean compile native fix-cl uninstall

test: unit-tests ecukes-features

unit-tests: elpa
	${CASK} exec ${EMACS} -Q -batch -L . -l test-e2wm-pst-class.el \
		-f ert-run-tests-batch-and-exit

ecukes-features: elpa
	${CASK} exec ${ECUKES} ${ECUKES_OPTS} features

elpa:
	mkdir -p elpa
	${CASK} install 2> elpa/install.log

fix-cl:
	./bash-fix-old-cl.sh

%.elc: %.el
	$(EM) $(LISPINCL) -f batch-byte-compile $<

%.eln: %.elc
	$(EM) $(LISPINCL) --eval '(native-compile "$<")'

compile: fix-cl ${patsubst %.el, %.elc, $(SRCS)}

native: ${patsubst %.el, %.eln, $(SRCS)}

install: compile
	mkdir -p $(DESTDIR)$(PREFIX)/lisp
	cp *.el $(DESTDIR)$(PREFIX)/lisp
	cp *.elc $(DESTDIR)$(PREFIX)/lisp

install-native: native
	cp eln-*/* $(DESTDIR)$(PREFIX)/lisp/eln-*

install-all: install install-native

uninstall:
	rm -f $(DESTDIR)$(PREFIX)/lisp/e2wm-*
	rm -f $(DESTDIR)$(PREFIX)/lisp/eln-*/e2wm-*

clean-elpa:
	rm -rf elpa

clean-elc:
	rm -f *.elc

clean-eln:
	rm -rf eln-*

clean:
	rm -rf *.elc eln-*


print-deps:
	${EMACS} --version
	@echo CASK=${CASK}
	@echo ECUKES=${ECUKES}

travis-ci: print-deps test
