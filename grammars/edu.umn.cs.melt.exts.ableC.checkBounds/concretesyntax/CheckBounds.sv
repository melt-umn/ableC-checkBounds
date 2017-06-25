grammar edu:umn:cs:melt:exts:ableC:checkBounds:concretesyntax;

imports edu:umn:cs:melt:ableC:concretesyntax;
imports edu:umn:cs:melt:ableC:abstractsyntax as abs;
imports edu:umn:cs:melt:ableC:abstractsyntax:construction as abs;
imports silver:langutil only ast; 

imports edu:umn:cs:melt:exts:ableC:checkBounds:abstractsyntax;

marking terminal CheckBounds_t 'check_bounds' lexer classes {Ckeyword};

concrete production CheckBoundsTypeQualifier_c
top::TypeQualifier_c ::= 'check_bounds'
{
  top.typeQualifiers = abs:foldQualifier([checkBoundsQualifier(location=top.location)]);
  top.mutateTypeSpecifiers = [];
}


