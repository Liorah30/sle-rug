module AST

/*
 * Define Abstract Syntax for QL
 *
 * - complete the following data types
 * - make sure there is an almost one-to-one correspondence with the grammar
 */

data AForm(loc src = |tmp:///|)
  = form(AId id, list[AQuestion] questions)
  ; 

data AQuestion(loc src = |tmp:///|)
	= question(str label,AId id,AType typ)
	| computed_question(str label,AId id,AType typ,AExpr e)
	| block (list[AQuestion] questions)
	| if_then(AExpr e,list[AQuestion] if_qs)
	| if_then_else(AExpr e,list[AQuestion] if_qs,list[AQuestion] else_qs)
  ; 

data AExpr(loc src = |tmp:///|)
  = ref(AId id)
  |integer(int i)
  |string (str s)
  |boolean (bool b)
  |brackets(AExpr e)
  |not(AExpr e)
  |multiply(AExpr lhs,AExpr rhs)
  |divide(AExpr lhs,AExpr rhs)
  |addition(AExpr lhs, AExpr rhs)
  |subtraction(AExpr lhs, AExpr rhs)
  |greater(AExpr lhs, AExpr rhs)
  |lesser(AExpr lhs, AExpr rhs)
  |leq(AExpr lhs, AExpr rhs)
  |geq(AExpr lhs, AExpr rhs)
  |equate(AExpr lhs, AExpr rhs)
  |nequate(AExpr lhs, AExpr rhs)
  |and(AExpr lhs, AExpr rhs)
  |or(AExpr lhs, AExpr rhs)
  ;

data AId(loc src = |tmp:///|)
  = id(str name);

data AType(loc src = |tmp:///|)
	= integer()
	| string()
	| boolean()
	;

