NODE_MODULES=./node_modules
JSHINT=$(NODE_MODULES)/jshint/bin/jshint
MOCHA=$(NODE_MODULES)/mocha/bin/mocha
MOCHAFLAGS=--compilers coffee:coffee-script/register --reporter spec
UGLIFY=$(NODE_MODULES)/uglify-js/bin/uglifyjs
UGLIFYFLAGS=-c -m
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

server: | node_modules
	$(HTTPSERVER)

docs: $(DOCFILES) | node_modules
	$(JSDOC) $(JSDOCFLAGS) $^

%.min.js: %.js | node_modules
	$(UGLIFY) $^ $(UGLIFYFLAGS) > $@

node_modules/%.js: %.js | node_modules
	printf "Q = require('q');\nmodule.exports=" > $@
	cat $^ >> $@

clean:
	rm -rf docs
	rm -f *.min.js

.PHONY: jshint test server clean
