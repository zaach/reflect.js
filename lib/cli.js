#!/usr/bin/env node

var sys = require("sys");
var path = require("path");
var Reflect = require("./reflect");

var source = read(process.argv[2]);
var target = Reflect.compile(source, true);

sys.puts(target);

function read (path) {
    return require("fs").readFileSync(require("path").resolve(path), "utf8");
}
