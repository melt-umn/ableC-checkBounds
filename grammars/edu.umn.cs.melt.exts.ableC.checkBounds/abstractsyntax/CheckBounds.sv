grammar edu:umn:cs:melt:exts:ableC:checkBounds:abstractsyntax;

imports edu:umn:cs:melt:exts:ableC:check:abstractsyntax;
imports edu:umn:cs:melt:ableC:abstractsyntax:host;
imports edu:umn:cs:melt:ableC:abstractsyntax:construction;
imports edu:umn:cs:melt:ableC:abstractsyntax:env;
imports edu:umn:cs:melt:ableC:abstractsyntax:injectable as inj;
imports silver:langutil;
imports silver:langutil:pp;

aspect production inj:arraySubscriptExpr
top::Expr ::= lhs::Expr rhs::Expr
{
  local lhsDerefTypeName :: TypeName =
    case lhs.typerep of
      pointerType(_, t) -> typeName(t.baseTypeExpr, t.typeModifierExpr)
    | _                 -> error("`check' aspect on subscript of non-pointer")
    end;

  local upperBound :: Expr =
    divExpr(
      directCallExpr(
        name("_boundsmap_find"),
        foldExpr([
          txtExpr("_BOUNDS_MAP"),
          lhs -- TODO: should create tmpLhs
        ])
      ),
      sizeofExpr(
        typeNameExpr(lhsDerefTypeName)
      )
    );

  local checkBounds :: (Expr ::= Expr) =
    \tmpRhs :: Expr -> lteExpr(upperBound, tmpRhs);

  runtimeMods <-
    if containsQualifier(checkQualifier(), lhs.typerep)
    then [inj:rhsRuntimeMod(inj:runtimeCheck(checkBounds, "ERROR:" ++ getParsedOriginLocationOrFallback(rhs).unparse ++
          ": array subscript out of range\\n"))]
    else [];
}

