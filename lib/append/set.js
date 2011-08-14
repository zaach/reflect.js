
// appended utils
function __extend (a, b) {
    Object.defineProperties(a, Object.getOwnPropertyDescriptors(b));
    return a;
}

function __prototypeForObject (proto, obj) {
    return Object.create(proto, Object.getOwnPropertyDescriptors(obj));
}

function __prototypeForLiteral (proto, obj) {
    obj.__proto__ = proto;
    return obj;
}

function __prototypeForFunction (proto, obj) {
    obj.__proto__ = proto;
    obj.prototype = {
        __proto__: proto.prototype,
        constructor: obj
    };
    return obj;
}

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
