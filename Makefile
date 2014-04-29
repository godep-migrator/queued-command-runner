SHELL := /bin/bash
SUDO ?= sudo
DOCKER ?= docker
Q := github.com/modcloth/queued-command-runner
TARGETS := $(Q)/qcr

GINKGO_PATH ?= "."
GOPATH := $(PWD)/Godeps/_workspace
GOBIN := $(GOPATH)/bin
PATH := $(GOPATH):$(PATH)

export GINKGO_PATH
export GOPATH
export GOBIN
export PATH

default: test

.PHONY: all
all: clean build test

.PHONY: clean
clean:
	go clean -i -r $(TARGETS) || true
	rm -rf $${GOPATH%%:*}/src/github.com/modcloth/queued-command-runner
	rm -rf Godeps/_workspace/*

.PHONY: build
build: linkthis deps

.PHONY: test
test: build fmtpolice ginkgo

.PHONY: linkthis
linkthis:
	@echo "gvm linkthis'ing this..."
	@if which gvm >/dev/null && \
	  [[ ! -d $${GOPATH%%:*}/src/github.com/modcloth/queued-command-runner ]] ; then \
	  gvm linkthis github.com/modcloth/queued-command-runner ; \
	  fi

.PHONY: godep
godep:
	go get github.com/tools/godep

.PHONY: deps
deps: godep
	@echo "godep restoring..."
	$(GOBIN)/godep restore
	go get github.com/golang/lint/golint
	go get github.com/onsi/ginkgo/ginkgo
	go get github.com/onsi/gomega

.PHONY: fmtpolice
fmtpolice: deps fmt lint

.PHONY: fmt
fmt:
	@echo "----------"
	@echo "checking fmt"
	@set -e ; \
	  for f in $(shell git ls-files '*.go'); do \
	  gofmt $$f | diff -u $$f - ; \
	  done

.PHONY: linter
linter:
	go get github.com/golang/lint/golint

.PHONY: lint
lint: linter
	@echo "----------"
	@echo "checking lint"
	@for file in $(shell git ls-files '*.go') ; do \
	  if [[ "$$($(GOBIN)/golint $$file)" =~ ^[[:blank:]]*$$ ]] ; then \
	  echo yayyy >/dev/null ; \
	  else $(MAKE) lintv && exit 1 ; fi \
	  done

.PHONY: lintv
lintv:
	@echo "----------"
	@for file in $(shell git ls-files '*.go') ; do $(GOBIN)/golint $$file ; done

.PHONY: ginkgo
ginkgo:
	@echo "----------"
	@if [[ "$(GINKGO_PATH)" == "." ]] ; then \
	  echo "$(GOBIN)/ginkgo -nodes=10 -noisyPendings -race -r ." && \
	  $(GOBIN)/ginkgo -nodes=10 -noisyPendings -race -r . ; \
	  else echo "$(GOBIN)/ginkgo -nodes=10 -noisyPendings -race --v $(GINKGO_PATH)" && \
	  $(GOBIN)/ginkgo -nodes=10 -noisyPendings -race --v $(GINKGO_PATH) ; \
	  fi
