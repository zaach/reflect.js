![Reflect.js](https://github.com/zaach/reflect.js/raw/master/reflectjs.png "Reflect.js")

Reflect.js is a JavaScript (ES3 compatible) implementation of [Mozilla's Parser API](https://developer.mozilla.org/en/SpiderMonkey/Parser_API). It does not currently support some of Mozilla's extensions, such as generators, list comprehensions, `for each`, E4X, etc. but may eventually support ones that are, or become Harmony proposals.
Builders are also supported.

Parsing large files can be slow, for reasons [articulated](http://www.andychu.net/ecmascript/RegExp-Enhancements.html) by Andy Chu.


Download
========
You can download a standalone version of reflect.js to embed in web pages [here](https://github.com/downloads/zaach/reflect.js/standalone-0.0.1.zip).

Install
=======
Reflect.js is available as a CommonJS module for Node.js. Simply install it with npm:

    npm install reflect

License
=======
MIT X Licensed.
