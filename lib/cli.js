#!/usr/bin/env node

var source = read(process.argv[2]);
var sys = require('sys');
var path = require('path');

var Reflect = require("./reflect");

var target = read(path.join(__dirname,'es6.js'))+
             Reflect.compile(source)+
             read(path.join(__dirname,'append.js'));

sys.puts(target);

function read (path) {
    return require('fs').readFileSync(require('path').resolve(path), "utf8");
}
