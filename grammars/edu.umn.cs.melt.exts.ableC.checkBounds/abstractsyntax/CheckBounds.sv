grammar edu:umn:cs:melt:exts:ableC:checkBounds:abstractsyntax;

imports edu:umn:cs:melt:ableC:abstractsyntax;
imports edu:umn:cs:melt:ableC:abstractsyntax:construction;
imports edu:umn:cs:melt:ableC:abstractsyntax:env;
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
  top.qualifyErrors =
    case top.typeToQualify of
      pointerType(_, _) -> []
    | _                 -> [err(top.location, "`check_bounds' cannot qualify a non-pointer")]
    end;
}

aspect production arraySubscriptExpr
top::Expr ::= lhs::Expr rhs::Expr
{
  local lhsDerefTypeName :: TypeName =
    case lhs.typerep of
      pointerType(_, t) -> typeName(t.baseTypeExpr, t.typeModifierExpr)
    | _                 -> error("`check_bounds' cannot qualify a non-pointer")
    end;

  local upperBound :: Expr =
    binaryOpExpr(
      directCallExpr(
        name("_boundsmap_find", location=builtinLoc(MODULE_NAME)),
        foldExpr([
          txtExpr("_BOUNDS_MAP", location=builtinLoc(MODULE_NAME)),
          lhs -- TODO: should create tmpLhs
        ]),
        location=builtinLoc(MODULE_NAME)
      ),
      numOp(divOp(location=builtinLoc(MODULE_NAME)), location=builtinLoc(MODULE_NAME)),
      unaryExprOrTypeTraitExpr(
        sizeofOp(location=builtinLoc(MODULE_NAME)),
        typeNameExpr(lhsDerefTypeName),
        location=builtinLoc(MODULE_NAME)
      ),
      location=builtinLoc(MODULE_NAME)
    );

  local checkBounds :: (Expr ::= Expr) =
    \tmpRhs :: Expr ->
      binaryOpExpr(
        upperBound,
        compareOp(lteOp(location=bogusLoc()), location=bogusLoc()),
        tmpRhs,
        location=bogusLoc()
      );

  rhsRuntimeChecks <-
    if containsQualifier(checkBoundsQualifier(location=bogusLoc()), lhs.typerep)
    then [pair(checkBounds, "ERROR:" ++ rhs.location.unparse ++
          ": array subscript out of range\\n")]
    else [];
}

