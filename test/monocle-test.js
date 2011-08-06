var fs = require("fs");
var path = require("path");
var source = fs.readFileSync(path.resolve(path.join(__dirname, "monocle.js")), "utf8");

var Reflect = require("../dist/reflect");
var b = require("reflect-tree-builder");
var transform = require("../dist/transform").transform;

var ast = Reflect.parse(source, {builder: b});

transform(ast, b);

console.log(Reflect.stringify(ast));

Object.extend = function (a, b) {
    Object.getOwnPropertyNames(b).forEach(function (name) {
        var desc = Object.getOwnPropertyDescriptor(b, name);
        Object.defineProperty(a, name, desc);
    });
    return a;
};

eval(Reflect.stringify(ast));

