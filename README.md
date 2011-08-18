This is an experitmental ES.next->ES5 transpiler.

What works:

* the <| operator -- defines the [[Prototype]] of a literal (uses `__proto__`)
* the .{ operator -- extends the LHS object with properties from an object literal
* object literal property shorthand -- `{x, y}` -> `{x: x, y: y}`

What sort of works:

* let and const declarations: no block scope for let
* super propertry references: no early syntax errors

Install
==
    npm install reflect-next

CLI
==
    reflect-next example/person.js > compiled.js
    node compiled.js

