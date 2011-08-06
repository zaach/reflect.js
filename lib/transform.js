var JSONSelect = require("JSONSelect");

exports.transform = function (ast, b /*builder*/) {

    JSONSelect.forEach(':has(:root > .property .type:val("ObjectExpression"))', ast,
      function (match) {
        var parent = match.parent;
        var name = match.object.type == 'Identifier' ?
                                        match.object.name :
                                        '$IIFEparam';
        //var exp = b.callExpression(
            //buildFunction(name, match.property),
            //[match.object]
        //);
        var exp = buildExtend(match.object, match.property);

        parent.replace(match, exp);
      }
    );

    function buildFunction (name, property) {
        return b.functionExpression(
          null,
          [b.identifier(name)],
          b.blockStatement(
            buildBody(name, property.properties)
              .concat(b.returnStatement(b.identifier(name)))
          ),
          false, false
        );
    }

    function buildBody (name, properties) {
        return properties.map(function (prop) {
            return expStmt(b.assignmentExpression(
                "=",
                b.memberExpression(b.identifier(name), prop.key, prop.key.type === 'Literal'),
                prop.value
            ));
        });
    }

    function buildGetSet (name, prop) {
    }

    function expStmt (expr) {
        return b.expressionStatement(expr);
    }

    function buildExtend (obj, extension) {
        return b.callExpression(
            b.memberExpression(
                b.identifier("Object"),
                b.identifier("extend")),
            [obj, extension]
        );
    }
};

