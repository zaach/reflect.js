// To be part of ES.next
if (!Object.getOwnPropertyDescriptors) {
    Object.getOwnPropertyDescriptors = function (obj) {
        var descriptors = {};
        Object.getOwnPropertyNames(obj).forEach(function (prop) {
            descriptors[prop] = Object.getOwnPropertyDescriptor(obj, prop);
            });
        return descriptors;
    };
}
// end ES.next
