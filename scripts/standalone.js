// Bundles the built code base as a standalone javascript file

var bundler = require("./cjs-bundler");

function read (path) {
    return require("fs").readFileSync(path, "utf8");
}

function loadPackage (path) {
    return JSON.parse(read(path+'/package.json'));
}

function normalizeModules (mods, path) {
    var modArray = [];
    for (var mod in mods) {
        modArray.push({id: mod, path: path+'/'+mods[mod]});
    }
    return modArray;
}

function generate (path) {
    var pkg = loadPackage(path),
        modules = normalizeModules(pkg.modules, path),
        script = bundler.bundle(modules);

    var out = "var Reflect = (function() {\n" + script + ";\nreturn require('reflect').Reflect;\n})();";
    require("sys").puts(out);
}

var cwd = process.cwd();
generate(cwd);
