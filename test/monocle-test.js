var fs = require("fs");
var path = require("path");
var source = fs.readFileSync(path.resolve(path.join(__dirname, "monocle.js")), "utf8");

var Reflect = require("../dist/reflect");
var b = require("reflect-tree-builder");
var transform = require("../dist/transform").transform;

var ast = Reflect.parse(source, {builder: b});

transform(ast, b);

//console.log(ast.body[0].type);
console.log(ast.body[0].toSource('b', ''));

console.log(Reflect.stringify(ast));

// To be part of ECMAScript.next
if (!Object.getOwnPropertyDescriptors) {
    Object.getOwnPropertyDescriptors = function (obj) {
        var descriptors = {};
        Object.getOwnPropertyNames(obj).forEach(function (prop) {
            descriptors[prop] = Object.getOwnPropertyDescriptor(obj, prop);
            });
        return descriptors;
    };
}

function extend (a, b) {
    Object.defineProperties(a, Object.getOwnPropertyDescriptors(b));
    return a;
};

function prototypeFor (proto, obj) {
    obj.__proto__ = proto;
    if (typeof obj === "function") {
        obj.prototype = {
            __proto__: proto.prototype,
            constructor: obj
        };
    }
    return obj;
};

function __get (sup, prop, that) {
    var desc = Object.getOwnPropertyDescriptor(sup, prop);
    return desc.get ?
        desc.get.call(that) :
        desc.value;
}

function __set (sup, prop, that, val) {
    var desc = Object.getOwnPropertyDescriptor(sup, prop);
    return desc.get ?
        desc.set.call(that, val) :
        that[prop] = val;
}

//var Script=process.binding('evals').Script; 
//var js = "var a=0;\nvarb=1;\nthrow new Error('lol');"; 
//try { 
  //Script.runInThisContext(js, 'eval'); 
  //console.log('no exception'); 
//} catch (err) { 

  //console.log(err.stack); 
/*} */

eval(Reflect.stringify(ast));

