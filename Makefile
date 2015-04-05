SHELL = /bin/bash

DATE ?= $(shell date +%Y-%m-%d)
TITLE ?= "$@"
POST_FILE ?= "_posts/$(DATE)-$(TITLE).md"

.PHONY: help build serve update deploy

help:
	@echo "Usage:"
	@echo "	make \"POST_TITLE\"					- generating a file _posts/YYYY-MM-DD-POST_TITLE.md"
	@echo "	make build						- build the blog source"
	@echo "	make serve						- launch the jekyll serve"
	@echo "	make deploy						- build and deploy to branch gh-pages"
	@echo "	make update						- update current branch source, SHOULD UPDATE AND RESOLVE CONFLICT BEFORE DEPLOY"

build:
	jekyll b
serve:
	jekyll s
update:
	@#git checkout master
	git pull
deploy:
	git checkout master
	jekyll build
	git add -A
	git commit -m "update source"
	cp -r _site/ /tmp/
	git checkout gh-pages
	rm -r ./*
	cp -r /tmp/_site/* ./
	git add -A
	git commit -m "deploy blog"
	git push origin gh-pages
	git checkout master
	echo "deploy succeed"
	git push origin master
	echo "push source"

%:
ifeq ($(POST_FILE),$(wildcard $(POST_FILE)))
	@echo generating $(TITLE)...failure, already exist!
else
	@echo $(POST_FILE)
	@touch _posts/$(DATE)-$@.md
	@echo generating $(TITLE)...success.
endif
