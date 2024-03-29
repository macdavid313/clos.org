## author: Tianyu Gu
# CLOS.org
#

.PHONY: build
build:
	emacs -Q --script publish.el

.PHONY: server
server: build
	python -m http.server --directory public

.PHONY: clean
clean:
	rm -rf public/

.DEFAULT_GOAL := build

# end
