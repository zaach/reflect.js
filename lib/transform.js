var JSONSelect = require("JSONSelect");

exports.transform = function (ast, b /*builder*/) {

    var superSelector = JSONSelect.compile(':has(:root > .type:val("SuperExpression"))');

    // object extend .{ operator
    JSONSelect.forEach(':has(:root > .property .type:val("ObjectExpression"))', ast,
        function (match) {
            var parent = match.parent;
            var hasSuper = 0;
            superSelector.forEach(match.property, function (sup) {
                hasSuper++;
                superExpr(sup);
            });

            if (hasSuper) {
                var wrapExp = buildExtend(b.identifier("__Extendee__"), match.property);
                var exp = wrapSuper(match.object, wrapExp, superExtender());
            } else {
                var exp = buildExtend(match.object, match.property);
            }

            parent.replace(match, exp);
        }
    );

    // prototype for <| operator
    JSONSelect.forEach(':has(:root > .type:val("PrototypeForExpression"))', ast,
        function (match) {
            var parent = match.parent;

            var hasSuper = 0;
            superSelector.forEach(match.object, function (sup) {
                hasSuper++;
                superExpr(sup);
            });

            var isFun = match.object.type === 'FunctionExpression';

            if (hasSuper) {
                var wrapExp = buildPrototypeFor(b.identifier(isFun ? "__Proto__" : "__Super__"), match.object);
                var exp = wrapSuper(match.proto, wrapExp, isFun ? superProto() : []);
            } else {
                var exp = buildPrototypeFor(match.proto, match.object);
            }
            parent.replace(match, exp);
        }
    );

    function superExpr (sup) {
        var parent = sup.parent;
        var grandparent = parent.parent;

        if (grandparent.type == 'CallExpression' &&
            grandparent.callee === parent) {
            superCall(sup);
        } else if (parent.type       == 'ExpressionStatement' ||
                parent.type          == 'AssignmentExpression' ||
                parent.type          == 'UpdateExpression' ||
                grandparent.operator == 'delete') {
            sup.parent.replace(sup, b.thisExpression());
        } else if (grandparent.type  == 'AssignmentExpression') {
            //superSet(sup);
            if (grandparent.operator == '=') {
                sup.parent.parent.parent.replace(sup.parent.parent, getSetCall("set", sup, sup.parent.parent.right));
            } else {
                sup.parent.replace(sup, b.thisExpression());
            }
        } else {
            //superGet(sup);
            sup.parent.parent.replace(sup.parent, getSetCall("get", sup));
        }
    }

    // replace super.meth() with __Super__.meth.call(this)
    function superCall (sup) {
        var mem = sup.parent;
        var call = mem.parent;
        mem.replace(sup, b.identifier("__Super__"));
        call.replace(mem,
            b.memberExpression(mem, b.identifier("call"), false));
        call.arguments.unshift(b.thisExpression());
    }

    function getSetCall (getset, sup, val) {
        return b.callExpression(
          b.identifier("__"+getset),
          [ b.identifier("__Super__"), propName(sup.parent), b.thisExpression() ].concat(val ? [val] : [])
        )
    }

    function propName (member) {
        return member.computed ? member.property : b.literal(member.property.name);
    }



    // for inline getter checks
    function superGet (sup) {
        var member = sup.parent;
        member.parent.replace(member, b.conditionalExpression(
            b.memberExpression(
              getProp(member.property),
              b.identifier("get"),
              false
            ),
            getSetPropCall("get", member.property),
            b.memberExpression(b.identifier("__Super__"), member.property, member.computed)
          ));
    }

    // for inline setter checks
    function superSet (sup) {
        var member = sup.parent;
        var assign = member.parent;
        var val = assign.right;
        var key = member.property;
        assign.parent.replace(assign, b.conditionalExpression(
            b.memberExpression(
              getProp(key),
              b.identifier("get"),
              false
            ),
            getSetPropCall("set", key, val),
            (member.replace(sup,b.thisExpression()),assign)
          ));
    }

    // used for inlining getter/setter checks
    function getProp (prop) {
        return b.callExpression(
          b.memberExpression(
            b.identifier("Object"),
            b.identifier("getOwnPropertyDescriptor"),
            false
          ),
          [ b.identifier("__Super__"), prop.name ? b.literal(prop.name) : prop ]
        )
    }
    // used for inlining getter/setter checks
    function getSetPropCall (getset, prop, val) {
        return b.callExpression(
          b.memberExpression(
            b.memberExpression(
              getProp(prop),
              b.identifier(getset),
              false
            ),
            b.identifier("call"),
            false
          ),
          [ b.thisExpression() ].concat(val ? [val] : [])
        )
    }

    function superProto () {
      return [b.variableDeclaration(
          "var",
          [ b.variableDeclarator(
            b.identifier("__Proto__"),
            b.identifier("__Super__")
          ) ]
        ),b.expressionStatement(
          b.assignmentExpression("=",
            b.identifier("__Super__"),
            b.memberExpression(
              b.identifier("__Super__"),
              b.identifier("prototype"),
              false)
            )
          )];
    }

    function superExtender () {
        return [b.variableDeclaration(
          "var",
          [ b.variableDeclarator(
            b.identifier("__Extendee__"),
            b.identifier("__Super__")
          ) ]
        ), b.expressionStatement(b.assignmentExpression(
            "=",
            b.identifier("__Super__"),
            b.callExpression(
              b.memberExpression(
                b.identifier("Object"),
                b.identifier("getPrototypeOf"),
                false
              ),
              [ b.identifier("__Super__") ]
            )
        ))]
    }

    function wrapSuper (super, exp, pre) {
      return b.callExpression(
          b.functionExpression(
            null,
            [ b.identifier("__Super__") ],
            b.blockStatement(
              (pre||[]).concat([b.returnStatement(exp)])
            ),
            false, false),
          [super]
        );
    }

    function expStmt (expr) {
        return b.expressionStatement(expr);
    }

    function buildExtend (obj, extension) {
        return b.callExpression(
            b.identifier("extend"),
            [obj, extension]
        );
    }

    function buildPrototypeFor (proto, obj) {
        return b.callExpression(
            b.identifier("prototypeFor"),
            [proto, obj]
        );
    }
};

