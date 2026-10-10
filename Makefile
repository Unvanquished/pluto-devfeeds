.DEFAULT_GOAL := update

.PHONY: build css check page prepare update upgrade

# Use the bundled REXML version to avoid entity-expansion errors with the
# outdated system REXML, and use a Bundler version compatible with this setup.
export RUBYOPT := -I$(CURDIR)/vendor/bundle/ruby/2.7.0/gems/rexml-3.4.4/lib
BUNDLE := $(HOME)/.gem/ruby/2.7.0/bin/bundle _2.4.22_

prepare:
	bundle install --path vendor/bundle

check:
	bundle exec pluto help

upgrade:
	git pull

fetch:
	python3 fetch-feeds -o build
	# sometime it fails but works the next time
	bundle exec pluto update planet.ini \
	|| bundle exec pluto update planet.ini

css:
	# it looks like pluto does not call sass itself
	mkdir -p build/css
	sassc planet-devfeeds/css/page.scss build/css/page.css
	sassc planet-devfeeds/css/news.scss build/css/news.css
	sassc planet-devfeeds/css/github.scss build/css/github.css
	sassc planet-devfeeds/css/gitlab.scss build/css/gitlab.css

page:
	# it automatically finds planet-devfeeds/news.txt
	bundle exec pluto merge -t news -o build planet.ini
	# file was rendered to a temporary file because there can be some race condition
	# between pluto rendering this page and people querying the page from server
	# hence we copy the page when it's ready, which is fast (uses CoW if possible)
	cp -a --reflink=auto build/news.html build/index.html

build: css page

update: fetch build
