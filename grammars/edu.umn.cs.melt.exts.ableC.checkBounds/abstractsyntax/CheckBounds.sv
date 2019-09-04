grammar edu:umn:cs:melt:exts:ableC:checkBounds:abstractsyntax;

imports edu:umn:cs:melt:exts:ableC:check:abstractsyntax;
imports edu:umn:cs:melt:ableC:abstractsyntax:host;
imports edu:umn:cs:melt:ableC:abstractsyntax:construction;
imports edu:umn:cs:melt:ableC:abstractsyntax:env;
imports edu:umn:cs:melt:ableC:abstractsyntax:injectable as inj;
imports silver:langutil;
imports silver:langutil:pp;

global MODULE_NAME :: String = "edu:umn:cs:melt:exts:ableC:checkBounds";

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
        name("_boundsmap_find", location=builtinLoc(MODULE_NAME)),
        foldExpr([
          txtExpr("_BOUNDS_MAP", location=builtinLoc(MODULE_NAME)),
          lhs -- TODO: should create tmpLhs
        ]),
        location=builtinLoc(MODULE_NAME)
      ),
      sizeofExpr(
        typeNameExpr(lhsDerefTypeName),
        location=builtinLoc(MODULE_NAME)
      ),
      location=builtinLoc(MODULE_NAME)
    );

  local checkBounds :: (Expr ::= Expr) =
    \tmpRhs :: Expr -> lteExpr(upperBound, tmpRhs, location=builtinLoc(MODULE_NAME));

  runtimeMods <-
    if containsQualifier(checkQualifier(location=builtinLoc(MODULE_NAME)), lhs.typerep)
    then [inj:rhsRuntimeMod(inj:runtimeCheck(checkBounds, "ERROR:" ++ rhs.location.unparse ++
          ": array subscript out of range\\n", top.location))]
    else [];
}

