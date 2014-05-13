NODE_MODULES=./node_modules
JSHINT=$(NODE_MODULES)/jshint/bin/jshint
MOCHA=$(NODE_MODULES)/mocha/bin/mocha
MOCHAFLAGS=--compilers coffee:coffee-script/register
UGLIFY=$(NODE_MODULES)/uglify-js/bin/uglifyjs

node_modules: package.json
	npm install .

jshint: | node_modules
	$(JSHINT) *.js

test: node_modules/service.js | node_modules
	$(MOCHA) $(MOCHAFLAGS)

%.min.js: %.js | node_modules
	$(UGLIFY) $^ > $@

node_modules/%.js: %.js
	printf "Q = require('q');\nmodule.exports=" > $@
	cat $^ >> $@

.PHONY: jshint test
