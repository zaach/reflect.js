
// appended utils
function __extend (a, b) {
    Object.defineProperties(a, Object.getOwnPropertyDescriptors(b));
    return a;
};

function __prototypeFor (proto, obj) {
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
