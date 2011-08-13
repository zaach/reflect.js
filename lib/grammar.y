%start Program

%nonassoc IF_WITHOUT_ELSE
%nonassoc ELSE

%%

Pattern
    : OPENBRACE CLOSEBRACE
      { $$ = yy.Node('ObjectPattern', [], yy.loc([@1,@2])); }
    | OPENBRACE FieldList CLOSEBRACE
      { $$ = yy.Node('ObjectPattern', $FieldList, yy.loc([@1,@3])); }
    | OPENBRACE FieldList ',' CLOSEBRACE
      { $$ = yy.Node('ObjectPattern', $FieldList, yy.loc([@1,@4])); }
    | '[' ']'
      { $$ = yy.Node('ArrayPattern', [], yy.loc([@1,@2])); }
    /*| '[' '...' Element ']'*/
    | '[' Elision ']'
      { $$ = yy.Node('ArrayPattern', [,], yy.loc([@1,@3])); }
    /*| '[' Elision '...' Element ']'*/
    | '[' ArrayPatternList ']'
      { $$ = yy.Node('ArrayPattern', $2, yy.loc([@1,@3])); }
    /*| '[' ArrayPatternList '...' Element ']'*/
    | '[' ArrayPatternList ',' ElisionOpt ']'
      { $$ = yy.Node('ArrayPattern', $2.concat($4), yy.loc([@1,@5])); }
    /*| '[' ArrayPatternList ',' ElisionOpt '...' Element ']'*/
    ;

ArrayPatternList
    : Element
      { $$ = [$1]; }
    | Elision Element
      { $$ = $1; $$.push($2); }
    | ArrayPatternList ',' ElisionOpt Element
      { $$ = $1.concat($3); $$.push($4); }
    ;

FieldList
    : Field
      { $$ = [$1]; }
    | FieldList ',' Field
      { $$ = $1; $$.push($3); }
    ;

Field
    : IDENT
      { $$ = {key:yy.Node('Identifier', $1,yy.loc(@1)),value:yy.Node('Identifier', $1,yy.loc(@1)),kind: "init"}; }
    | IDENT ':' Element
      { yy.locComb(@$,@3);$$ = {key:yy.Node('Identifier', $1,yy.loc(@1)),value:$3,kind: "init"}; }
    | STRING ':' Element
      { yy.locComb(@$,@3);$$ = {key:yy.Node('Literal', String($1),yy.loc(@1)),value:$3,kind: "init"}; }
    | NUMBER ':' Element
      { yy.locComb(@$,@3);$$ = {key:yy.Node('Literal', Number($1),yy.loc(@1)),value:$3,kind: "init"}; }
    ;

Element
    : Pattern
    | IDENT
      { $$ = yy.Node('Identifier', $1,yy.loc(@1)) }
    ;

  /* break up keywords to workaround some LALR(1) limitations */
IdentifierName
    : IDENT
    | Keyword
    ;

Keyword
    : NULLTOKEN
    | TRUETOKEN
    | FALSETOKEN
    | BREAK
    | CASE
    | CATCH
    | CONSTTOKEN
    | CONTINUE
    | DEBUGGER
    | DEFAULT
    | DELETETOKEN
    | DO
    | ELSE
    | FINALLY
    | FOR
    | FUNCTION
    | IF
    | INTOKEN
    | INSTANCEOF
    | LET
    | NEW
    | RETURN
    | SWITCH
    | THIS
    | THROW
    | TRY
    | TYPEOF
    | VAR
    | VOIDTOKEN
    | WHILE
    | WITH
    ;

Literal
    : NULLTOKEN
      { $$ = yy.Node('Literal', null, yy.loc(@1)); }
    | TRUETOKEN
      { $$ = yy.Node('Literal', true, yy.loc(@1)); }
    | FALSETOKEN
      { $$ = yy.Node('Literal', false, yy.loc(@1)); }
    | NUMBER
      { $$ = yy.Node('Literal', Number($1), yy.loc(@1)); }
    | STRING
      { $$ = yy.Node('Literal', yy.escapeString(String($1)), yy.loc(@1)); }
    | RegularExpressionLiteralBegin REGEXP_BODY
      {
        var body = yytext.slice(1,yytext.lastIndexOf('/'));
        var flags = yytext.slice(yytext.lastIndexOf('/')+1);
        $$ = yy.Node('Literal', new RegExp(body, flags), yy.loc(yy.locComb(@$,@2)));
        //$$ = yy.Node('RegExpExpression', {body:body,flags:flags});
        yy.inRegex = false;
      }
    ;

RegularExpressionLiteralBegin
    : '/'
      { yy.inRegex = true; yy.lexer.unput($1); $$ = $1; }
    | DIVEQUAL
      { yy.inRegex = true; yy.lexer.unput($1); $$ = $1; }
    ;

Property
    : IDENT /* object shorthand strawman */
      { $$ = {key:yy.Node('Identifier', $1,yy.loc(@1)),value:yy.Node('Identifier', $1,yy.loc(@1)),kind: "init"}; }
    | IDENT ':' AssignmentExpr
      { yy.locComb(@$,@3);$$ = {key:yy.Node('Identifier', $1,yy.loc(@1)),value:$3,kind: "init"}; }
    | Keyword ':' AssignmentExpr
      { yy.locComb(@$,@3);$$ = {key:yy.Node('Identifier', $1,yy.loc(@1)),value:$3,kind: "init"}; }
    | STRING ':' AssignmentExpr
      { yy.locComb(@$,@3);$$ = {key:yy.Node('Literal', String($1),yy.loc(@1)),value:$3,kind: "init"}; }
    | NUMBER ':' AssignmentExpr
      { yy.locComb(@$,@3);$$ = {key:yy.Node('Literal', Number($1),yy.loc(@1)),value:$3,kind: "init"}; }
    | IDENT IdentifierName '(' ')' Block
      {
          if ($1 !== 'get' && $1 !== 'set') throw new Error('Parse error, invalid set/get.'); // TODO: use jison ABORT when supported
          @$ = yy.locComb(@1,@5);
          var fun = yy.Node('FunctionExpression',null,[],$Block, false, false, yy.loc(@$));
          $$ = {key:yy.Node('Identifier', $2,yy.loc(@2)),value:fun,kind: $1};
      }
    | IDENT IdentifierName '(' FormalParameterList ')' Block
      {
          @$ = yy.locComb(@1,@6);
          if ($1 !== 'get' && $1 !== 'set') throw new Error('Parse error, invalid set/get.'); // TODO: use jison ABORT when supported
          var fun = yy.Node('FunctionExpression',null,$FormalParameterList,$Block,false,false,yy.loc(@$));
          $$ = {key:yy.Node('Identifier', $2,yy.loc(@2)),value:fun,kind: $1};
      }
    | IDENT KeyLiteral '(' ')' Block
      {
          if ($1 !== 'get' && $1 !== 'set') throw new Error('Parse error, invalid set/get.'); // TODO: use jison ABORT when supported
          @$ = yy.locComb(@1,@5);
          var fun = yy.Node('FunctionExpression',null,[],$Block, false, false, yy.loc(@$));
          $$ = {key:$2,value:fun,kind: $1};
      }
    | IDENT KeyLiteral '(' FormalParameterList ')' Block
      {
          @$ = yy.locComb(@1,@6);
          if ($1 !== 'get' && $1 !== 'set') throw new Error('Parse error, invalid set/get.'); // TODO: use jison ABORT when supported
          var fun = yy.Node('FunctionExpression',null,$FormalParameterList,$Block,false,false,yy.loc(@$));
          $$ = {key:$2,value:fun,kind: $1};
      }
    ;

KeyLiteral
    : NUMBER
      { $$ = yy.Node('Literal', Number($1), yy.loc(@1)); }
    | STRING
      { $$ = yy.Node('Literal', yy.escapeString(String($1)), yy.loc(@1)); }
    ;

PropertyList
    : Property
      { $$ = [$1]; }
    | PropertyList ',' Property
      { $$ = $1; $$.push($3); }
    ;

PrimaryExpr
    : PrimaryExprNoBrace
    | OPENBRACE CLOSEBRACE
      { $$ = yy.Node('ObjectExpression',[],yy.loc([@$,@2])); }
    | OPENBRACE PropertyList CLOSEBRACE
      { $$ = yy.Node('ObjectExpression',$2,yy.loc([@$,@3])); }
    | OPENBRACE PropertyList ',' CLOSEBRACE
      { $$ = yy.Node('ObjectExpression',$2,yy.loc([@$,@4])); }
    ;

PrimaryExprNoBrace
    : THISTOKEN
      { $$ = yy.Node('ThisExpression'); }
    | SUPER
      { $$ = yy.Node('SuperExpression'); }
    | Literal
    | ArrayLiteral
    | IDENT
      { $$ = yy.Node('Identifier', String($1), yy.loc(@1)); }
    | '(' Expr ')'
      { $$ = $Expr; $$.parens = true; yy.locComb(@$,@3) }
    ;

ArrayLiteral
    : '[' ']'
      { $$ = yy.Node('ArrayExpression',[],yy.loc([@$,@2])); }
    | '[' Elision ']'
      { $$ = yy.Node('ArrayExpression',$2,yy.loc([@$,@3])); }
    | '[' ElementList ']'
      { $$ = yy.Node('ArrayExpression',$2,yy.loc([@$,@3])); }
    | '[' ElementList ',' ElisionOpt ']'
      { $$ = yy.Node('ArrayExpression',$2.concat($4),yy.loc([@$,@5]));}
    ;

ElementList
    : AssignmentExpr
      { $$ = [$1]; }
    | Elision AssignmentExpr
      { $$ = $1; $$.push($2); }
    | ElementList ',' ElisionOpt AssignmentExpr
      { $$ = $1.concat($3); $$.push($4); }
    ;

ElisionOpt
    :
      { $$ = []; }
    | Elision
    ;

Elision
    : ','
      { $$ = [,]; }
    | Elision ','
      { $$ = $1; $$.length = $$.length+1; }
    ;

MemberExpr
    : PrimaryExpr
    | FunctionExpr
    | MemberExpr '[' Expr ']'
      { $$ = yy.Node('MemberExpression',$1,$3,true,yy.loc([@$,@4])); }
    | MemberExpr '.' IdentifierName
      { $$ = yy.Node('MemberExpression',$1,yy.Node('Identifier', String($3)),false,yy.loc([@$,@3])); }
    | NEW MemberExpr Arguments
      { $$ = yy.Node('NewExpression',$MemberExpr,$Arguments,yy.loc([@$,@3])); }
    | MemberExpr '.' ObjectLiteral
      { $$ = yy.Node('MemberExpression',$1,$3,false,yy.loc([@$,@3])); }
    | MemberExpr PROTOTYPEFOR ObjectLiteral
      { $$ = yy.Node('PrototypeForExpression',$1,$3,yy.loc([@$,@3])); }
    | MemberExpr PROTOTYPEFOR FunctionExpr
      { $$ = yy.Node('PrototypeForExpression',$1,$3,yy.loc([@$,@3])); }
    ;

ObjectLiteral
    : OPENBRACE PropertyList CLOSEBRACE
      { $$ = yy.Node('ObjectExpression',$2,yy.loc([@$,@3])); }
    | OPENBRACE PropertyList ',' CLOSEBRACE
      { $$ = yy.Node('ObjectExpression',$2,yy.loc([@$,@4])); }
    ;

MemberExprNoBF
    : PrimaryExprNoBrace
    | MemberExprNoBF '[' Expr ']'
      { $$ = yy.Node('MemberExpression',$1,$3,true,yy.loc([@$,@4])); }
    | MemberExprNoBF '.' IdentifierName
      { $$ = yy.Node('MemberExpression',$1,yy.Node('Identifier', String($3)),false,yy.loc([@$,@3])); }
    | NEW MemberExpr Arguments
      { $$ = yy.Node('NewExpression',$MemberExpr,$Arguments,yy.loc([@$,@3])); }
    | MemberExprNoBF '.' ObjectLiteral
      { $$ = yy.Node('MemberExpression',$1,$3,false,yy.loc([@$,@3])); }
    | MemberExprNoBF PROTOTYPEFOR ObjectLiteral
      { $$ = yy.Node('PrototypeForExpression',$1,$3,yy.loc([@$,@3])); }
    | MemberExprNoBF PROTOTYPEFOR FunctionExpr
      { $$ = yy.Node('PrototypeForExpression',$1,$3,yy.loc([@$,@3])); }
    ;

NewExpr
    : MemberExpr
    | NEW NewExpr
      { $$ = yy.Node('NewExpression',$2,[],yy.loc([@$,@2])); }
    ;

NewExprNoBF
    : MemberExprNoBF
    | NEW NewExpr
      { $$ = yy.Node('NewExpression',$2,[],yy.loc([@$,@2])); }
    ;

CallExpr
    : MemberExpr Arguments
      { $$ = yy.Node('CallExpression',$1,$2,yy.loc([@$,@2])); }
    | CallExpr Arguments
      { $$ = yy.Node('CallExpression',$1,$2,yy.loc([@$,@2])); }
    | CallExpr '[' Expr ']'
      { $$ = yy.Node('MemberExpression',$1,$3,true,yy.loc([@$,@4])); }
    | CallExpr '.' IdentifierName
      { $$ = yy.Node('MemberExpression',$1,yy.Node('Identifier', String($3)),false,yy.loc([@$,@3])); }
    ;

CallExprNoBF
    : MemberExprNoBF Arguments
      { $$ = yy.Node('CallExpression',$1,$2,yy.loc([@$,@2])); }
    | CallExprNoBF Arguments
      { $$ = yy.Node('CallExpression',$1,$2,yy.loc([@$,@2])); }
    | CallExprNoBF '[' Expr ']'
      { $$ = yy.Node('MemberExpression',$1,$3,true,yy.loc([@$,@4])); }
    | CallExprNoBF '.' IdentifierName
      { $$ = yy.Node('MemberExpression',$1,yy.Node('Identifier', String($3)),false,yy.loc([@$,@3])); }
    ;

Arguments
    : '(' ')'
      { $$ = []; }
    | '(' ArgumentList ')'
      { $$ = $ArgumentList; }
    ;

ArgumentList
    : AssignmentExpr
      { $$ = [$1]; }
    | ArgumentList ',' AssignmentExpr
      { $$ = $1; $$.push($3); }
    ;

LeftHandSideExpr
    : NewExpr
    | CallExpr
    ;

LeftHandSideExprNoBF
    : NewExprNoBF
    | CallExprNoBF
    ;

PostfixExpr
    : LeftHandSideExpr
    | LeftHandSideExpr PLUSPLUS
      { $$ = yy.Node('UpdateExpression','++',$1,false,yy.loc([@$,@2])); }
    | LeftHandSideExpr MINUSMINUS
      { $$ = yy.Node('UpdateExpression','--',$1,false,yy.loc([@$,@2])); }
    ;

PostfixExprNoBF
    : LeftHandSideExprNoBF
    | LeftHandSideExprNoBF PLUSPLUS
      { $$ = yy.Node('UpdateExpression','++',$1,false,yy.loc([@$,@2])); }
    | LeftHandSideExprNoBF MINUSMINUS
      { $$ = yy.Node('UpdateExpression','--',$1,false,yy.loc([@$,@2])); }
    ;

UnaryExprCommon
    : DELETETOKEN UnaryExpr
      { $$ = yy.Node('UnaryExpression','delete',$2,true,yy.loc([@$,@2])); }
    | VOIDTOKEN UnaryExpr
      { $$ = yy.Node('UnaryExpression','void',$2,true,yy.loc([@$,@2])); }
    | TYPEOF UnaryExpr
      { $$ = yy.Node('UnaryExpression','typeof',$2,true,yy.loc([@$,@2])); }
    | PLUSPLUS UnaryExpr
      { $$ = yy.Node('UpdateExpression','++',$2,true,yy.loc([@$,@2])); }
    | MINUSMINUS UnaryExpr
      { $$ = yy.Node('UpdateExpression','--',$2,true,yy.loc([@$,@2])); }
    | '+' UnaryExpr
      { $$ = yy.Node('UnaryExpression','+',$2,true,yy.loc([@$,@2])); }
    | '-' UnaryExpr
      { $$ = yy.Node('UnaryExpression','-',$2,true,yy.loc([@$,@2])); }
    | '~' UnaryExpr
      { $$ = yy.Node('UnaryExpression','~',$2,true,yy.loc([@$,@2])); }
    | '!' UnaryExpr
      { $$ = yy.Node('UnaryExpression','!',$2,true,yy.loc([@$,@2])); }
    ;

UnaryExpr
    : PostfixExpr
    | UnaryExprCommon
    ;

UnaryExprNoBF
    : PostfixExprNoBF
    | UnaryExprCommon
    ;

MultiplicativeExpr
    : UnaryExpr
    | MultiplicativeExpr '*' UnaryExpr
      { $$ = yy.Node('BinaryExpression', '*', $1, $3, yy.loc([@$,@3])); }
    | MultiplicativeExpr '/' UnaryExpr
      { $$ = yy.Node('BinaryExpression', '/', $1, $3,yy.loc([@$,@3])); }
    | MultiplicativeExpr '%' UnaryExpr
      { $$ = yy.Node('BinaryExpression', '%', $1, $3,yy.loc([@$,@3])); }
    ;

MultiplicativeExprNoBF
    : UnaryExprNoBF
    | MultiplicativeExprNoBF '*' UnaryExpr
      { $$ = yy.Node('BinaryExpression',  '*', $1, $3,yy.loc([@$,@3])); }
    | MultiplicativeExprNoBF '/' UnaryExpr
      { $$ = yy.Node('BinaryExpression', '/', $1, $3,yy.loc([@$,@3])); }
    | MultiplicativeExprNoBF '%' UnaryExpr
      { $$ = yy.Node('BinaryExpression', '%', $1, $3,yy.loc([@$,@3])); }
    ;

AdditiveExpr
    : MultiplicativeExpr
    | AdditiveExpr '+' MultiplicativeExpr
      { $$ = yy.Node('BinaryExpression', '+', $1, $3,yy.loc([@$,@3])); }
    | AdditiveExpr '-' MultiplicativeExpr
      { $$ = yy.Node('BinaryExpression', '-', $1, $3,yy.loc([@$,@3])); }
    ;

AdditiveExprNoBF
    : MultiplicativeExprNoBF
    | AdditiveExprNoBF '+' MultiplicativeExpr
      { @$ = yy.locComb(@1,@3);
        $$ = yy.Node('BinaryExpression', '+', $1, $3, yy.loc(@$)); }
    | AdditiveExprNoBF '-' MultiplicativeExpr
      { @$ = yy.locComb(@1,@3);
        $$ = yy.Node('BinaryExpression', '-', $1, $3, yy.loc(@$)); }
    ;

ShiftExpr
    : AdditiveExpr
    | ShiftExpr LSHIFT AdditiveExpr
      { $$ = yy.Node('BinaryExpression', '<<', $1, $3,yy.loc([@$,@3])); }
    | ShiftExpr RSHIFT AdditiveExpr
      { $$ = yy.Node('BinaryExpression', '>>', $1, $3,yy.loc([@$,@3])); }
    | ShiftExpr URSHIFT AdditiveExpr
      { $$ = yy.Node('BinaryExpression', '>>>', $1, $3,yy.loc([@$,@3])); }
    ;

ShiftExprNoBF
    : AdditiveExprNoBF
    | ShiftExprNoBF LSHIFT AdditiveExpr
      { $$ = yy.Node('BinaryExpression', '<<', $1, $3,yy.loc([@$,@3])); }
    | ShiftExprNoBF RSHIFT AdditiveExpr
      { $$ = yy.Node('BinaryExpression', '>>', $1, $3,yy.loc([@$,@3])); }
    | ShiftExprNoBF URSHIFT AdditiveExpr
      { $$ = yy.Node('BinaryExpression', '>>>', $1, $3,yy.loc([@$,@3])); }
    ;

RelationalExpr
    : ShiftExpr
    | RelationalExpr '<' ShiftExpr
      { $$ = yy.Node('BinaryExpression', '<', $1, $3,yy.loc([@$,@3])); }
    | RelationalExpr '>' ShiftExpr
      { $$ = yy.Node('BinaryExpression', '>', $1, $3,yy.loc([@$,@3])); }
    | RelationalExpr LE ShiftExpr
      { $$ = yy.Node('BinaryExpression', '<=', $1, $3,yy.loc([@$,@3])); }
    | RelationalExpr GE ShiftExpr
      { $$ = yy.Node('BinaryExpression', '>=', $1, $3,yy.loc([@$,@3])); }
    | RelationalExpr INSTANCEOF ShiftExpr
      { $$ = yy.Node('BinaryExpression', 'instanceof', $1, $3,yy.loc([@$,@3])); }
    | RelationalExpr INTOKEN ShiftExpr
      { $$ = yy.Node('BinaryExpression', 'in', $1, $3,yy.loc([@$,@3])); }
    ;

RelationalExprNoIn
    : ShiftExpr
    | RelationalExprNoIn '<' ShiftExpr
      { $$ = yy.Node('BinaryExpression', '<', $1, $3,yy.loc([@$,@3])); }
    | RelationalExprNoIn '>' ShiftExpr
      { $$ = yy.Node('BinaryExpression', '>', $1, $3,yy.loc([@$,@3])); }
    | RelationalExprNoIn LE ShiftExpr
      { $$ = yy.Node('BinaryExpression', '<=', $1, $3,yy.loc([@$,@3])); }
    | RelationalExprNoIn GE ShiftExpr
      { $$ = yy.Node('BinaryExpression', '>=', $1, $3,yy.loc([@$,@3])); }
    | RelationalExprNoIn INSTANCEOF ShiftExpr
      { $$ = yy.Node('BinaryExpression', 'instanceof', $1, $3,yy.loc([@$,@3])); }
    ;

RelationalExprNoBF
    : ShiftExprNoBF
    | RelationalExprNoBF '<' ShiftExpr
      { $$ = yy.Node('BinaryExpression', '<', $1, $3,yy.loc([@$,@3])); }
    | RelationalExprNoBF '>' ShiftExpr
      { $$ = yy.Node('BinaryExpression', '>', $1, $3,yy.loc([@$,@3])); }
    | RelationalExprNoBF LE ShiftExpr
      { $$ = yy.Node('BinaryExpression', '<=', $1, $3,yy.loc([@$,@3])); }
    | RelationalExprNoBF GE ShiftExpr
      { $$ = yy.Node('BinaryExpression', '>=', $1, $3,yy.loc([@$,@3])); }
    | RelationalExprNoBF INSTANCEOF ShiftExpr
      { $$ = yy.Node('BinaryExpression', 'instanceof', $1, $3,yy.loc([@$,@3])); }
    | RelationalExprNoBF INTOKEN ShiftExpr
      { $$ = yy.Node('BinaryExpression', 'in', $1, $3,yy.loc([@$,@3])); }
    ;

EqualityExpr
    : RelationalExpr
    | EqualityExpr EQEQ RelationalExpr
      { $$ = yy.Node('BinaryExpression', '==', $1, $3,yy.loc([@$,@3])); }
    | EqualityExpr NE RelationalExpr
      { $$ = yy.Node('BinaryExpression', '!=', $1, $3,yy.loc([@$,@3])); }
    | EqualityExpr STREQ RelationalExpr
      { $$ = yy.Node('BinaryExpression', '===', $1, $3,yy.loc([@$,@3])); }
    | EqualityExpr STRNEQ RelationalExpr
      { $$ = yy.Node('BinaryExpression', '!==', $1, $3,yy.loc([@$,@3])); }
    ;

EqualityExprNoIn
    : RelationalExprNoIn
    | EqualityExprNoIn EQEQ RelationalExprNoIn
      { $$ = yy.Node('BinaryExpression', '==', $1, $3,yy.loc([@$,@3])); }
    | EqualityExprNoIn NE RelationalExprNoIn
      { $$ = yy.Node('BinaryExpression', '!=', $1, $3,yy.loc([@$,@3])); }
    | EqualityExprNoIn STREQ RelationalExprNoIn
      { $$ = yy.Node('BinaryExpression', '===', $1, $3,yy.loc([@$,@3])); }
    | EqualityExprNoIn STRNEQ RelationalExprNoIn
      { $$ = yy.Node('BinaryExpression', '!==', $1, $3,yy.loc([@$,@3])); }
    ;

EqualityExprNoBF
    : RelationalExprNoBF
    | EqualityExprNoBF EQEQ RelationalExpr
      { $$ = yy.Node('BinaryExpression', '==', $1, $3,yy.loc([@$,@3])); }
    | EqualityExprNoBF NE RelationalExpr
      { $$ = yy.Node('BinaryExpression', '!=', $1, $3,yy.loc([@$,@3])); }
    | EqualityExprNoBF STREQ RelationalExpr
      { $$ = yy.Node('BinaryExpression', '===', $1, $3,yy.loc([@$,@3])); }
    | EqualityExprNoBF STRNEQ RelationalExpr
      { $$ = yy.Node('BinaryExpression', '!==', $1, $3,yy.loc([@$,@3])); }
    ;

BitwiseANDExpr
    : EqualityExpr
    | BitwiseANDExpr '&' EqualityExpr
      { $$ = yy.Node('BinaryExpression', '&', $1, $3,yy.loc([@$,@3])); }
    ;

BitwiseANDExprNoIn
    : EqualityExprNoIn
    | BitwiseANDExprNoIn '&' EqualityExprNoIn
      { $$ = yy.Node('BinaryExpression', '&', $1, $3,yy.loc([@$,@3])); }
    ;

BitwiseANDExprNoBF
    : EqualityExprNoBF
    | BitwiseANDExprNoBF '&' EqualityExpr
      { $$ = yy.Node('BinaryExpression', '&', $1, $3,yy.loc([@$,@3])); }
    ;

BitwiseXORExpr
    : BitwiseANDExpr
    | BitwiseXORExpr '^' BitwiseANDExpr
      { $$ = yy.Node('BinaryExpression', '^', $1, $3,yy.loc([@$,@3])); }
    ;

BitwiseXORExprNoIn
    : BitwiseANDExprNoIn
    | BitwiseXORExprNoIn '^' BitwiseANDExprNoIn
      { $$ = yy.Node('BinaryExpression', '^', $1, $3,yy.loc([@$,@3])); }
    ;

BitwiseXORExprNoBF
    : BitwiseANDExprNoBF
    | BitwiseXORExprNoBF '^' BitwiseANDExpr
      { $$ = yy.Node('BinaryExpression', '^', $1, $3,yy.loc([@$,@3])); }
    ;

BitwiseORExpr
    : BitwiseXORExpr
    | BitwiseORExpr '|' BitwiseXORExpr
      { $$ = yy.Node('BinaryExpression', '|', $1, $3,yy.loc([@$,@3])); }
    ;

BitwiseORExprNoIn
    : BitwiseXORExprNoIn
    | BitwiseORExprNoIn '|' BitwiseXORExprNoIn
      { $$ = yy.Node('BinaryExpression', '|', $1, $3,yy.loc([@$,@3])); }
    ;

BitwiseORExprNoBF
    : BitwiseXORExprNoBF
    | BitwiseORExprNoBF '|' BitwiseXORExpr
      { $$ = yy.Node('BinaryExpression', '|', $1, $3,yy.loc([@$,@3])); }
    ;

LogicalANDExpr
    : BitwiseORExpr
    | LogicalANDExpr AND BitwiseORExpr
      { $$ = yy.Node('LogicalExpression', '&&', $1, $3,yy.loc([@$,@3])); }
    ;

LogicalANDExprNoIn
    : BitwiseORExprNoIn
    | LogicalANDExprNoIn AND BitwiseORExprNoIn
      { $$ = yy.Node('LogicalExpression', '&&', $1, $3,yy.loc([@$,@3])); }
    ;

LogicalANDExprNoBF
    : BitwiseORExprNoBF
    | LogicalANDExprNoBF AND BitwiseORExpr
      { $$ = yy.Node('LogicalExpression', '&&', $1, $3,yy.loc([@$,@3])); }
    ;

LogicalORExpr
    : LogicalANDExpr
    | LogicalORExpr OR LogicalANDExpr
      { $$ = yy.Node('LogicalExpression', '||', $1, $3,yy.loc([@$,@3])); }
    ;

LogicalORExprNoIn
    : LogicalANDExprNoIn
    | LogicalORExprNoIn OR LogicalANDExprNoIn
      { $$ = yy.Node('LogicalExpression', '||', $1, $3,yy.loc([@$,@3])); }
    ;

LogicalORExprNoBF
    : LogicalANDExprNoBF
    | LogicalORExprNoBF OR LogicalANDExpr
      { $$ = yy.Node('LogicalExpression', '||', $1, $3,yy.loc([@$,@3])); }
    ;

ConditionalExpr
    : LogicalORExpr
    | LogicalORExpr '?' AssignmentExpr ':' AssignmentExpr
      { $$ = yy.Node('ConditionalExpression', $1, $3, $5,yy.loc([@$,@5])); }
    ;

ConditionalExprNoIn
    : LogicalORExprNoIn
    | LogicalORExprNoIn '?' AssignmentExprNoIn ':' AssignmentExprNoIn
      { $$ = yy.Node('ConditionalExpression', $1, $3, $5,yy.loc([@$,@5])); }
    ;

ConditionalExprNoBF
    : LogicalORExprNoBF
    | LogicalORExprNoBF '?' AssignmentExpr ':' AssignmentExpr
      { $$ = yy.Node('ConditionalExpression', $1, $3, $5,yy.loc([@$,@5])); }
    ;

AssignmentExpr
    : ConditionalExpr
    | LeftHandSideExpr AssignmentOperator AssignmentExpr
      { $$ = yy.Node('AssignmentExpression', $2, $1, $3,yy.loc([@$,@3])); }
    ;

AssignmentExprNoIn
    : ConditionalExprNoIn
    | LeftHandSideExpr AssignmentOperator AssignmentExprNoIn
      { $$ = yy.Node('AssignmentExpression', $2, $1, $3,yy.loc([@$,@3])); }
    ;

AssignmentExprNoBF
    : ConditionalExprNoBF
    | LeftHandSideExprNoBF AssignmentOperator AssignmentExpr
      { $$ = yy.Node('AssignmentExpression', $2, $1, $3,yy.loc([@$,@3])); }
    ;

AssignmentOperator
    : '='
    | PLUSEQUAL
    | MINUSEQUAL
    | MULTEQUAL
    | DIVEQUAL
    | LSHIFTEQUAL
    | RSHIFTEQUAL
    | URSHIFTEQUAL
    | ANDEQUAL
    | XOREQUAL
    | OREQUAL
    | MODEQUAL
    ;

Expr
    : AssignmentExpr
    | Expr ',' AssignmentExpr
      {
        if ($1.type == 'SequenceExpression') {
          $1.expressions.push($3);
          $1.loc = yy.loc([@$,@3]);
          $$ = $1;
        } else
          $$ = yy.Node('SequenceExpression',[$1, $3],yy.loc([@$,@3]));
      }
    ;

ExprNoIn
    : AssignmentExprNoIn
    | ExprNoIn ',' AssignmentExprNoIn
      {
        if ($1.type == 'SequenceExpression') {
          $1.expressions.push($3);
          $1.loc = yy.loc([@$,@3]);
          $$ = $1;
        } else
          $$ = yy.Node('SequenceExpression',[$1, $3],yy.loc([@$,@3]));
      }
    ;

ExprNoBF
    : AssignmentExprNoBF
    | ExprNoBF ',' AssignmentExpr
      {
        if ($1.type == 'SequenceExpression') {
          $1.expressions.push($3);
          $1.loc = yy.loc([@$,@3]);
          $$ = $1;
        } else
          $$ = yy.Node('SequenceExpression',[$1, $3],yy.loc([@$,@3]));
      }
    ;

Statement
    : Block
    | VariableStatement
    | FunctionDeclaration
    | EmptyStatement
    | ExprStatement
    | IfStatement
    | IterationStatement
    | ContinueStatement
    | BreakStatement
    | ReturnStatement
    | WithStatement
    | SwitchStatement
    | LabeledStatement
    | ThrowStatement
    | TryStatement
    | DebuggerStatement
    ;

Block
    : OPENBRACE CLOSEBRACE
      { $$ = yy.Node('BlockStatement',[],yy.loc([@$,@2])); }
    | OPENBRACE SourceElements CLOSEBRACE
      { $$ = yy.Node('BlockStatement',$2,yy.loc([@$,@3])); }
    ;

ConstStatement
    : CONSTTOKEN ConstDecralarionList ';'
      { $$ = yy.Node('VariableDeclaration',"const",$2,yy.loc([@$,@3])) }
    | CONSTTOKEN ConstDecralarionList error
      { $$ = yy.Node('VariableDeclaration',"const",$2,yy.loc([@$,@2])) }
    ;

ConstDecralarionList
    : IDENT
      { $$ = [yy.Node('VariableDeclarator', yy.Node('Identifier', $1,yy.loc(@1)), null)]; }
    | IDENT Initializer
      { yy.locComb(@$,@2);$$ = [yy.Node('VariableDeclarator', yy.Node('Identifier', $1,yy.loc(@1)), $2)]; }
    | Pattern Initializer
      { yy.locComb(@$,@2);$$ = [yy.Node('VariableDeclarator', $1, $2)]; }
    | ConstDecralarionList ',' IDENT
      { yy.locComb(@$,@3);$$ = $1; $1.push(yy.Node('VariableDeclarator', yy.Node('Identifier', $3,yy.loc(@3)), null)); }
    | ConstDecralarionList ',' IDENT Initializer
      { yy.locComb(@$,@4);$$ = $1; $1.push(yy.Node('VariableDeclarator', yy.Node('Identifier', $3,yy.loc(@3)), $4)); }
    | ConstDecralarionList ',' Pattern Initializer
      { yy.locComb(@$,@4);$$ = $1; $1.push(yy.Node('VariableDeclarator', $3, $4)); }
    ;

ConstDecralarionListNoIn
    : IDENT
      { $$ = [yy.Node('VariableDeclarator', yy.Node('Identifier', $1,yy.loc(@1)), null)]; }
    | IDENT InitializerNoIn
      { yy.locComb(@$,@2);$$ = [yy.Node('VariableDeclarator', yy.Node('Identifier', $1,yy.loc(@1)), $2)]; }
    | Pattern InitializerNoIn
      { yy.locComb(@$,@2);$$ = [yy.Node('VariableDeclarator', $1, $2)]; }
    | ConstDecralarionListNoIn ',' IDENT
      { yy.locComb(@$,@3);$$ = $1; $1.push(yy.Node('VariableDeclarator', yy.Node('Identifier', $3,yy.loc(@3)), null)); }
    | ConstDecralarionListNoIn ',' IDENT InitializerNoIn
      { yy.locComb(@$,@4);$$ = $1; $1.push(yy.Node('VariableDeclarator', yy.Node('Identifier', $3,yy.loc(@3)), $4)); }
    | ConstDecralarionListNoIn ',' Pattern InitializerNoIn
      { yy.locComb(@$,@4);$$ = $1; $1.push(yy.Node('VariableDeclarator', $3, $4)); }
    ;

VariableStatement
    : VAR VariableDeclarationList ';'
      { $$ = yy.Node('VariableDeclaration',"var",$2,yy.loc([@$,@3])) }
    | VAR VariableDeclarationList error
      { $$ = yy.Node('VariableDeclaration',"var",$2,yy.loc([@$,@2])) }
    ;

VariableDeclarationList
    : IDENT
      { $$ = [yy.Node('VariableDeclarator', yy.Node('Identifier', $1,yy.loc(@1)), null)]; }
    | IDENT Initializer
      { yy.locComb(@$,@2);$$ = [yy.Node('VariableDeclarator', yy.Node('Identifier', $1,yy.loc(@1)), $2)]; }
    | Pattern Initializer
      { yy.locComb(@$,@2);$$ = [yy.Node('VariableDeclarator', $1, $2)]; }
    | VariableDeclarationList ',' IDENT
      { yy.locComb(@$,@3);$$ = $1; $1.push(yy.Node('VariableDeclarator', yy.Node('Identifier', $3,yy.loc(@3)), null)); }
    | VariableDeclarationList ',' IDENT Initializer
      { yy.locComb(@$,@4);$$ = $1; $1.push(yy.Node('VariableDeclarator', yy.Node('Identifier', $3,yy.loc(@3)), $4)); }
    | VariableDeclarationList ',' Pattern Initializer
      { yy.locComb(@$,@4);$$ = $1; $1.push(yy.Node('VariableDeclarator', $3, $4)); }
    ;

VariableDeclarationListNoIn
    : IDENT
      { $$ = [yy.Node('VariableDeclarator', yy.Node('Identifier', $1,yy.loc(@1)), null)]; }
    | IDENT InitializerNoIn
      { yy.locComb(@$,@2);
        $$ = [yy.Node('VariableDeclarator', yy.Node('Identifier', $1,yy.loc(@1)), $2)]; }
    | Pattern InitializerNoIn
      { yy.locComb(@$,@2);$$ = [yy.Node('VariableDeclarator', $1, $2)]; }
    | VariableDeclarationListNoIn ',' IDENT
      { yy.locComb(@$,@3);
        $$ = $1; $1.push(yy.Node('VariableDeclarator', yy.Node('Identifier', $3,yy.loc(@3)), null)); }
    | VariableDeclarationListNoIn ',' IDENT InitializerNoIn
      { yy.locComb(@$,@4);
        $$ = $1; $1.push(yy.Node('VariableDeclarator', yy.Node('Identifier', $3,yy.loc(@3)), $4)); }
    | VariableDeclarationListNoIn ',' Pattern InitializerNoIn
      { yy.locComb(@$,@4);$$ = $1; $1.push(yy.Node('VariableDeclarator', $3, $4)); }
    ;

LetStatement
    : LET LetDeclarationList ';'
      { $$ = yy.Node('VariableDeclaration',"let",$2,yy.loc([@$,@3])) }
    | LET LetDeclarationList error
      { $$ = yy.Node('VariableDeclaration',"let",$2,yy.loc([@$,@2])) }
    ;

LetDeclarationList
    : IDENT
      { $$ = [yy.Node('VariableDeclarator', yy.Node('Identifier', $1,yy.loc(@1)), null)]; }
    | IDENT Initializer
      { yy.locComb(@$,@2);$$ = [yy.Node('VariableDeclarator', yy.Node('Identifier', $1,yy.loc(@1)), $2)]; }
    | Pattern Initializer
      { yy.locComb(@$,@2);$$ = [yy.Node('VariableDeclarator', $1, $2)]; }
    | LetDeclarationList ',' IDENT
      { yy.locComb(@$,@3);$$ = $1; $1.push(yy.Node('VariableDeclarator', yy.Node('Identifier', $3,yy.loc(@3)), null)); }
    | LetDeclarationList ',' IDENT Initializer
      { yy.locComb(@$,@4);$$ = $1; $1.push(yy.Node('VariableDeclarator', yy.Node('Identifier', $3,yy.loc(@3)), $4)); }
    | LetDeclarationList ',' Pattern Initializer
      { yy.locComb(@$,@4);$$ = $1; $1.push(yy.Node('VariableDeclarator', $3, $4)); }
    ;

LetDeclarationListNoIn
    : IDENT
      { $$ = [yy.Node('VariableDeclarator', yy.Node('Identifier', $1,yy.loc(@1)), null)]; }
    | IDENT InitializerNoIn
      { yy.locComb(@$,@2);
        $$ = [yy.Node('VariableDeclarator', yy.Node('Identifier', $1,yy.loc(@1)), $2)]; }
    | Pattern InitializerNoIn
      { yy.locComb(@$,@2);$$ = [yy.Node('VariableDeclarator', $1, $2)]; }
    | LetDeclarationListNoIn ',' IDENT
      { yy.locComb(@$,@3);
        $$ = $1; $1.push(yy.Node('VariableDeclarator', yy.Node('Identifier', $3,yy.loc(@3)), null)); }
    | LetDeclarationListNoIn ',' IDENT InitializerNoIn
      { yy.locComb(@$,@4);
        $$ = $1; $1.push(yy.Node('VariableDeclarator', yy.Node('Identifier', $3,yy.loc(@3)), $4)); }
    | LetDeclarationListNoIn ',' Pattern InitializerNoIn
      { yy.locComb(@$,@4);$$ = $1; $1.push(yy.Node('VariableDeclarator', $3, $4)); }
    ;

Initializer
    : '=' AssignmentExpr
      { $$ = $2; yy.locComb(@$,@2) }
    ;

InitializerNoIn
    : '=' AssignmentExprNoIn
      { $$ = $2; yy.locComb(@$,@2) }
    ;

EmptyStatement
    : ';'
      { $$ = yy.Node('EmptyStatement',yy.loc(@1)); }
    ;

ExprStatement
    : ExprNoBF ';'
      { $$ = yy.Node('ExpressionStatement', $1,yy.loc([@$,@2])); }
    | ExprNoBF error
      { $$ = yy.Node('ExpressionStatement', $1,yy.loc(@1)); }
    ;

IfStatement
    : IF '(' Expr ')' Statement %prec IF_WITHOUT_ELSE
      { $$ = yy.Node('IfStatement', $Expr, $Statement, null, yy.loc([@$,@5])); }
    | IF '(' Expr ')' Statement ELSE Statement
      { $$ = yy.Node('IfStatement', $Expr, $Statement1, $Statement2, yy.loc([@$,@7])); }
    ;

IterationStatement
    : DO Statement WHILE '(' Expr ')' ';'
      { $$ = yy.Node('DoWhileStatement', $Statement, $Expr,yy.loc([@$,@7])); }
    | DO Statement WHILE '(' Expr ')' error
      { $$ = yy.Node('DoWhileStatement', $Statement, $Expr,yy.loc([@$,@6])); }
    | WHILE '(' Expr ')' Statement
      { $$ = yy.Node('WhileStatement', $Expr, $Statement,yy.loc([@$,@5])); }
    | FOR '(' ExprNoInOpt ';' ExprOpt ';' ExprOpt ')' Statement
      { $$ = yy.Node('ForStatement', $ExprNoInOpt, $ExprOpt1, $ExprOpt2, $Statement,yy.loc([@$,@9])); }
    | FOR '(' VAR VariableDeclarationListNoIn ';' ExprOpt ';' ExprOpt ')' Statement
      { $$ = yy.Node('ForStatement',
                yy.Node('VariableDeclaration',"var", $4, yy.loc([@3,@4])),
                $ExprOpt1, $ExprOpt2, $Statement, yy.loc([@$,@10])); }
    | FOR '(' LET LetDeclarationListNoIn ';' ExprOpt ';' ExprOpt ')' Statement
      { $$ = yy.Node('ForStatement',
                yy.Node('VariableDeclaration',"let", $4, yy.loc([@3,@4])),
                $ExprOpt1, $ExprOpt2, $Statement, yy.loc([@$,@10])); }
    | FOR '(' CONSTTOKEN ConstDecralarionListNoIn ';' ExprOpt ';' ExprOpt ')' Statement
      { $$ = yy.Node('ForStatement',
                yy.Node('VariableDeclaration',"const", $4, yy.loc([@3,@4])),
                $ExprOpt1, $ExprOpt2, $Statement, yy.loc([@$,@10])); }
    | FOR '(' LeftHandSideExpr INTOKEN Expr ')' Statement
      { $$ = yy.Node('ForInStatement', $LeftHandSideExpr, $Expr, $Statement, false, yy.loc([@$,@7])); }
    | FOR '(' VarOrLet Expr ')' Statement
      { $$ = yy.Node('ForInStatement', $3,
                  $Expr, $Statement, false, yy.loc([@$,@6])); }
    | FOR '(' VarOrLetInitNoIn Expr ')' Statement
      { $$ = yy.Node('ForInStatement', $3,
                  $Expr, $Statement, false, yy.loc([@$,@6])); }
    ;

VarOrLet
    : VAR IDENT INTOKEN
      { $$ = yy.Node('VariableDeclaration',"var",
          [yy.Node('VariableDeclarator',yy.Node('Identifier', $2,yy.loc(@2)), null)],
          yy.loc([@1,@2])) }
    | VAR Pattern INTOKEN
      { $$ = yy.Node('VariableDeclaration',"var",
          [yy.Node('VariableDeclarator',$2, null)],
          yy.loc([@1,@2])) }
    | LET IDENT INTOKEN
      { $$ = yy.Node('VariableDeclaration',"let",
          [yy.Node('VariableDeclarator',yy.Node('Identifier', $2,yy.loc(@2)), null)],
          yy.loc([@1,@2])) }
    | LET Pattern INTOKEN
      { $$ = yy.Node('VariableDeclaration',"let",
          [yy.Node('VariableDeclarator',$2, null)],
          yy.loc([@1,@2])) }
    ;

VarOrLetInitNoIn
    : VAR IDENT InitializerNoIn INTOKEN
      { $$ = yy.Node('VariableDeclaration',"var",
          [yy.Node('VariableDeclarator',yy.Node('Identifier', $2,yy.loc(@2)), $3)],
          yy.loc([@1,@3])) }
    | VAR Pattern InitializerNoIn INTOKEN
      { $$ = yy.Node('VariableDeclaration',"var",
          [yy.Node('VariableDeclarator',$2, $3)],
          yy.loc([@1,@3])) }
    | LET IDENT InitializerNoIn INTOKEN
      { $$ = yy.Node('VariableDeclaration',"let",
          [yy.Node('VariableDeclarator',yy.Node('Identifier', $2,yy.loc(@2)), $3)],
          yy.loc([@1,@3])) }
    | LET Pattern InitializerNoIn INTOKEN
      { $$ = yy.Node('VariableDeclaration',"let",
          [yy.Node('VariableDeclarator',$2, $3)],
          yy.loc([@1,@3])) }
    ;

ExprOpt
    :
      { $$ = null }
    | Expr
    ;

ExprNoInOpt
    :
      { $$ = null }
    | ExprNoIn
    ;

ContinueStatement
    : CONTINUE ';'
      { $$ = yy.Node('ContinueStatement',null,yy.loc([@$,@2])); }
    | CONTINUE error
      { $$ = yy.Node('ContinueStatement',null,yy.loc(@$)); }
    | CONTINUE IDENT ';'
      { $$ = yy.Node('ContinueStatement',yy.Node('Identifier', $2,yy.loc(@2)),yy.loc([@$,@3])); }
    | CONTINUE IDENT error
      { $$ = yy.Node('ContinueStatement',yy.Node('Identifier', $2,yy.loc(@2)),yy.loc([@$,@2])); }
    ;

BreakStatement
    : BREAK ';'
      { $$ = yy.Node('BreakStatement',null,yy.loc([@$,@2])); }
    | BREAK error
      { $$ = yy.Node('BreakStatement',null,yy.loc(@$)); }
    | BREAK IDENT ';'
      { $$ = yy.Node('BreakStatement',yy.Node('Identifier', $2,yy.loc(@$)),yy.loc([@$,@3])); }
    | BREAK IDENT error
      { $$ = yy.Node('BreakStatement',yy.Node('Identifier', $2,yy.loc(@$)),yy.loc([@$,@2])); }
    ;

ReturnStatement
    : RETURN ';'
      { $$ = yy.Node('ReturnStatement',null,yy.loc([@$,@2])); }
    | RETURN error
      { $$ = yy.Node('ReturnStatement',null,yy.loc(@$)); }
    | RETURN Expr ';'
      { $$ = yy.Node('ReturnStatement',$2,yy.loc([@$,@3])); }
    | RETURN Expr error
      { $$ = yy.Node('ReturnStatement',$2,yy.loc([@$,@2])); }
    ;

WithStatement
    : WITH '(' Expr ')' Statement
      { $$ = yy.Node('WithStatement',$Expr,$Statement,yy.loc([@$,@5])); }
    ;

SwitchStatement
    : SWITCH '(' Expr ')' CaseBlock
      { $$ = yy.Node('SwitchStatement',$Expr,$CaseBlock,yy.loc([@$,@5])); }
    ;

CaseBlock
    : OPENBRACE CaseClausesOpt CLOSEBRACE
      { $$ = $2; yy.locComb(@$,@3) }
    | OPENBRACE CaseClausesOpt DefaultClause CaseClausesOpt CLOSEBRACE
      { $2.push($DefaultClause); $$ = $2.concat($CaseClausesOpt2); yy.locComb(@$,@5) }
    ;

CaseClausesOpt
    :
      { $$ = []; }
    | CaseClauses
    ;

CaseClauses
    : CaseClause
      { $$ = [$1]; }
    | CaseClauses CaseClause
      { $1.push($2); $$ = $1; }
    ;

CaseClause
    : CASE Expr ':'
      { $$ = yy.Node('SwitchCase',$Expr,[], yy.loc([@$,@3])); }
    | CASE Expr ':' SourceElements
      { $$ = yy.Node('SwitchCase',$Expr,$4, yy.loc([@$,@4])); }
    ;

DefaultClause
    : DEFAULT ':'
      { $$ = yy.Node('SwitchCase',null,[], yy.loc([@$,@2])); }
    | DEFAULT ':' SourceElements
      { $$ = yy.Node('SwitchCase',null,$3, yy.loc([@$,@3])); }
    ;

LabeledStatement
    : IDENT ':' Statement
      { $$ = yy.Node('LabeledStatement',yy.Node('Identifier', $1,yy.loc(@1)),$3, yy.loc([@$,@3])); }
    ;

ThrowStatement
    : THROW Expr ';'
      { $$ = yy.Node('ThrowStatement', $Expr, @2, yy.loc([@$,@3])); }
    | THROW Expr error
      { $$ = yy.Node('ThrowStatement', $Expr, @2, yy.loc([@$,@2])); }
    ;

TryStatement
    : TRY Block FINALLY Block
      { $$ = yy.Node('TryStatement', $Block1, null, $Block2, yy.loc([@$,@4])); }
    | TRY Block CATCH '(' IDENT ')' Block
      { $$ = yy.Node('TryStatement', $Block1,
                yy.Node('CatchClause',yy.Node('Identifier', $5,yy.loc(@5)),null, $Block2, yy.loc([@3,@7])), null, yy.loc([@$,@7])); }
    | TRY Block CATCH '(' IDENT ')' Block FINALLY Block
      { $$ = yy.Node('TryStatement', $Block1,
                yy.Node('CatchClause',yy.Node('Identifier', $5,yy.loc(@5)),null, $Block2, yy.loc([@3,@7])),
                $Block3, yy.loc([@$,@9])); }
    ;

DebuggerStatement
    : DEBUGGER ';'
      { $$ = yy.Node('DebuggerStatement', yy.loc([@$,@2])); }
    | DEBUGGER error
      { $$ = yy.Node('DebuggerStatement', yy.loc(@1)); }
    ;

FunctionDeclaration
    : FUNCTION IDENT '(' ')' Block
      { $$ = yy.Node('FunctionDeclaration',
                yy.Node('Identifier', $2,yy.loc(@2)), [], $Block, false, false, yy.loc([@$,@5]))
      }
    | FUNCTION IDENT '(' FormalParameterList ')' Block
      { $$ = yy.Node('FunctionDeclaration',
                yy.Node('Identifier', $2,yy.loc(@2)),
                $FormalParameterList, $Block, false, false, yy.loc([@$,@6]))
      }
    ;

FunctionExpr
    : FUNCTION '(' ')' Block
      { $$ = yy.Node('FunctionExpression', null, [], $Block, false, false, yy.loc([@$,@4])); }
    | FUNCTION '(' FormalParameterList ')' Block
      { $$ = yy.Node('FunctionExpression', null,
           $FormalParameterList, $Block, false, false, yy.loc([@$,@5])); }

    | FUNCTION IDENT '(' ')' Block
      { $$ = yy.Node('FunctionExpression',
                yy.Node('Identifier', $2,yy.loc(@2)),
                [], $Block, false, false, yy.loc([@$,@5])); }
    | FUNCTION IDENT '(' FormalParameterList ')' Block
      { $$ = yy.Node('FunctionExpression',
                yy.Node('Identifier', $2,yy.loc(@2)),
                $FormalParameterList, $Block, false, false, yy.loc([@$,@6])); }
    ;

FormalParameterList
    : IDENT
      { $$ = [yy.Node('Identifier', $1)]; }
    | Pattern
      { $$ = [$1]; }
    | FormalParameterList ',' IDENT
      { $$ = $1; $$.push(yy.Node('Identifier', $3,yy.loc(@3))); }
    | FormalParameterList ',' Pattern
      { $$ = $1; $$.push($3); }
    ;

FunctionBody
    :
      { $$ = []; }
    | SourceElements
    ;

Program
    :
      { return yy.Node('Program',[],yy.loc(@$)); }
    | SourceElements
      { return yy.Node('Program',$1,yy.loc(@1)); }
    ;

SourceElements
    : SourceElement
      { $$ = [$1]; }
    | SourceElements SourceElement
      { yy.locComb(@$,@2);
      $$ = $1;$1.push($2); }
    ;

SourceElement
    : LetStatement
    | ConstStatement
    | Statement
    ;
