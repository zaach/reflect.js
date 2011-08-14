
var assert = require("assert");
var a = {};

a.{
  foo: "bar",
  hello: "world"
};

assert.equal(a.foo, "bar");
assert.equal(a.hello, "world");

var b = {foo: "bar"}.{extras: "yes please"};

assert.equal(b.extras, "yes please");

a.{
  2: "computed",
  "$$": "cache money"
};

assert.equal(a[2], "computed");
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

var simple = {fe: "fo"} <| {
    foo: "bar"
};

assert.equal(simple.fe, "fo");

var sup = {method: function () { return "sup"; }};

var sub = sup <| {
  method: function () {
    return super.method()+"sub";
  }
};

assert.equal(Object.getPrototypeOf(sub), sup);
assert.equal(sub.method(), "supsub");

function A () { this.init = "A"; }
A.prototype.{
    method: function () { return "blah"; }
};

var B = A <| function () {
                super.constructor();
                this.initB = "B";
             }.prototype.{
                method: function () {
                  return super.method() + " blah";
                }
             }.constructor;

var b = new B;

assert.equal(b.init, "A");
assert.equal(b.initB, "B");
assert.equal(Object.getPrototypeOf(b), B.prototype);
assert.equal(Object.getPrototypeOf(B), A);
assert.equal(Object.getPrototypeOf(Object.getPrototypeOf(b)), A.prototype);
assert.equal(b.method(), "blah blah");

var sup2 = {k: 1};

var sub2 = sup2 <| {
   setK: function setK () {
      assert.equal(super.k, 1);
      assert.equal(this.k, 1);
      super.k = super.k + 1;
      assert.equal(super.k, 1);
      assert.equal(this.k, 2);
      return super.k;
   }
}
var f = 1;
var sup3 = {
   get f() {return f},
   get ff() {return f}
};

var sub3 = sup3 <| {
   set f(v) {f=v},
   get f() {return super.f},
   set ff(v) {f=v}
};
assert.equal(sub3.f, 1);
sub3.f=2;
assert.equal(sup3.f, 2);
assert.equal(sub3.f, 2);
assert.equal(sub3.ff);

var arr = {} <| [0,1,2,3,4,5];
var p = {foo: "bar"} <| /[a-m][3-7]/;

assert.equal(arr.length, 6);
assert.equal(p.foo, "bar");

