var source = require('fs').readFileSync(require('path').resolve(process.argv[2]), "utf8");

var Reflect = require("../dist/reflect");

console.log(Reflect.compile(source));

