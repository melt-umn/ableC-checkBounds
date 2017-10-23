grammar edu:umn:cs:melt:exts:ableC:checkBounds:abstractsyntax;

imports edu:umn:cs:melt:ableC:abstractsyntax:host;
imports edu:umn:cs:melt:ableC:abstractsyntax:construction;
imports edu:umn:cs:melt:ableC:abstractsyntax:env;
imports edu:umn:cs:melt:ableC:abstractsyntax:injectable as inj;
imports silver:langutil;
imports silver:langutil:pp;

global MODULE_NAME :: String = "edu:umn:cs:melt:exts:ableC:checkBounds";

abstract production checkBoundsQualifier
top::Qualifier ::=
{
  top.pp = pp"check_bounds";
  top.mangledName = "check_bounds";
  top.qualIsPositive = true;
  top.qualIsNegative = false;
  top.qualAppliesWithinRef = true;
  top.qualCompat = \qualToCompare::Qualifier ->
    case qualToCompare of
      checkBoundsQualifier() -> true
    | _ -> false
    end;
  top.qualIsHost = false;
  top.errors :=
    case top.typeToQualify of
      pointerType(_, _) -> []
    | _                 -> [err(top.location, "`check_bounds' cannot qualify a non-pointer")]
    end;
}

aspect production inj:arraySubscriptExpr
top::Expr ::= lhs::Expr rhs::Expr
{
  local lhsDerefTypeName :: TypeName =
    case lhs.typerep of
      pointerType(_, t) -> typeName(t.baseTypeExpr, t.typeModifierExpr)
    | _                 -> error("`check_bounds' cannot qualify a non-pointer")
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
    if containsQualifier(checkBoundsQualifier(location=builtinLoc(MODULE_NAME)), lhs.typerep)
    then [inj:rhsRuntimeMod(inj:runtimeCheck(checkBounds, "ERROR:" ++ rhs.location.unparse ++
          ": array subscript out of range\\n", top.location))]
    else [];
}

