var assert = require("assert");
var a = {};

a.{
  foo: "bar",
  hello: "world"
};

assert.equal(a.foo, "bar");

var b = {foo: "bar"}.{extras: "yes please"};

assert.equal(b.extras, "yes please");

a.{
  2: "computed",
  "$$": "cache money"
};

assert.equal(a["$$"], "cache money");

var c = {foo: "bar"}.{extras: "yes please"}.{more: "wow"};

assert.equal(c.more, "wow");

c.{
  get dynamic () {return this.foo},
  set name (val) { this.more = val; }
};

assert.equal(c.dynamic, "bar");

c.name = "setter";
assert.equal(c.more, "setter");

