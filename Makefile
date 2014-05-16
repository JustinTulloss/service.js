NODE_MODULES=./node_modules
JSHINT=$(NODE_MODULES)/jshint/bin/jshint
MOCHA=$(NODE_MODULES)/mocha/bin/mocha
MOCHAFLAGS=--compilers coffee:coffee-script/register --reporter spec
UGLIFY=$(NODE_MODULES)/uglify-js/bin/uglifyjs
UGLIFYFLAGS=-c -m --source-map build/service.map --source-map-url service.map
HTTPSERVER=$(NODE_MODULES)/http-server/bin/http-server
DOCFILES=service.js README.md
JSDOC=$(NODE_MODULES)/.bin/jsdoc
JSDOCFLAGS=-d docs -c jsdoc-conf.json

node_modules: package.json
	npm install .

jshint: | node_modules
	$(JSHINT) *.js

test: node_modules/service.js | node_modules
	$(MOCHA) $(MOCHAFLAGS)

test-amd: build/service.amd.js | node_modules
	open test/require.html

server: | node_modules
	$(HTTPSERVER)

docs: $(DOCFILES) | node_modules
	$(JSDOC) $(JSDOCFLAGS) $^

build:
	mkdir -p build

build/%.min.js: %.js | node_modules build
	cp $^ build
	$(UGLIFY) $^ $(UGLIFYFLAGS) > $@

build/%.amd.js: build/%.min.js | build
	printf "define(['q'], function(Q) {\n return " > $@
	cat $^ >> $@
	printf "\n});" >> $@

node_modules/%.js: %.js | node_modules
	printf "Q = require('q');\nmodule.exports=" > $@
	cat $^ >> $@

release: jshint node_modules/service.js build/service.min.js build/service.amd.js docs

clean:
	rm -rf docs build

.PHONY: jshint test test-amd server clean release
