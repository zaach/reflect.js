var fs = require("fs");
var path = require("path");
var source = read(path.join(__dirname, "es.next.js"));

var Reflect = require("../dist/reflect");
var b = require("reflect-tree-builder");
var transform = require("../dist/transform").transform;

var ast = Reflect.parse(source, {builder: b});

var dependencies = transform(ast, b);

var newSource = Reflect.stringify(ast);
console.log(newSource);

var target = read(path.join(__dirname, "..", "dist", "es6.js")) +
             newSource;

Object.keys(dependencies).forEach(function (dep) {
    target += read(path.join(__dirname, "..", "dist", "append", dep+".js"));
});

//var Script=process.binding("evals").Script; 
//var js = "var a=0;\nvarb=1;\nthrow new Error("lol");"; 
//try { 
  //Script.runInThisContext(js, "eval"); 
  //console.log("no exception"); 
//} catch (err) { 

  //console.log(err.stack); 
/*} */

eval(target);

function read (path) {
    return require("fs").readFileSync(require("path").resolve(path), "utf8");
}
