function __extend (a, b) {
    Object.defineProperties(a, Object.getOwnPropertyDescriptors(b));
    return a;
}
