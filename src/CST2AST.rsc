module CST2AST

import Syntax;
import AST;

import ParseTree;
import String;
import Boolean;

/*
 * Implement a mapping from concrete syntax trees (CSTs) to abstract syntax trees (ASTs)
 *
 * - Use switch to do case distinction with concrete patterns (like in Hack your JS) 
 * - Map regular CST arguments (e.g., *, +, ?) to lists 
 *   (NB: you can iterate over * / + arguments using `<-` in comprehensions or for-loops).
 * - Map lexical nodes to Rascal primitive types (bool, int, str)
 * - See the ref example on how to obtain and propagate source locations.
 */

AForm cst2ast(start[Form] sf) {
 
  return cst2ast(sf.top);
}

AForm cst2ast(f: (Form) `form <Id i> { <Question* qs> }`) {
  return form(id("<i>", src=i@\loc), [cst2ast(q) | Question q <- qs], src=f@\loc);
}

AQuestion cst2ast(Question q) {
  switch (q) {
    case (Question) `<Str l> <Id i>: <Type typ>`:
      return question("<l>",id("<i>"),cst2ast(typ),src=q@\loc);
    case (Question) `<Str l> <Id i>: <Type typ> = <Expr e>`:
      return computed_question("<l>", id("<i>"),cst2ast(typ), cst2ast(e), src=q@\loc);
    case (Question) `if ( <Expr e> ) { <Question* if_qs> }`:
      return if_then(cst2ast(e), [cst2ast(q) | Question q <- if_qs], src=q@\loc);
    case (Question) `if ( <Expr e> ) { <Question* if_qs> } else { <Question* else_qs> }`:
      return if_then_else(cst2ast(e), [cst2ast(q) | Question q <- if_qs], [cst2ast(q) | Question q <- else_qs], src=q@\loc);
    case (Question) `{ <Question* qs> }`:
      return block([cst2ast(q) | Question q <- qs], src=q@\loc);
    default:
      throw "Unhandled question <q>";
  }
}

AExpr cst2ast(Expr e) {
  switch (e) {
    case (Expr) `<Id x>`: 
      return ref(id("<x>", src=x@\loc), src=e@\loc);
    case (Expr) `<Str x>`: 
      return string("<x>", src=e@\loc);
    case (Expr) `<Int x>`: 
      return integer(toInt("<x>"), src=e@\loc);
    case (Expr) `<Bool x>`: 
      return boolean(fromString("<x>"), src=e@\loc);
    case (Expr) `(<Expr expr>)`: 
      return brackets(cst2ast(expr), src=e@\loc);
    case (Expr) `! <Expr expr>`: 
      return not(cst2ast(expr), src=e@\loc);
    case (Expr) `<Expr e1> * <Expr e2>`: 
      return multiply(cst2ast(e1), cst2ast(e2), src=e@\loc);
    case (Expr) `<Expr e1> / <Expr e2>`: 
      return divide(cst2ast(e1), cst2ast(e2), src=e@\loc);
    case (Expr) `<Expr e1> + <Expr e2>`: 
      return addition(cst2ast(e1), cst2ast(e2), src=e@\loc);
    case (Expr) `<Expr e1> - <Expr e2>`: 
      return subtraction(cst2ast(e1), cst2ast(e2), src=e@\loc);
    case (Expr) `<Expr e1> \< <Expr e2>`: 
      return lesser(cst2ast(e1), cst2ast(e2), src=e@\loc);
    case (Expr) `<Expr e1> \<= <Expr e2>`: 
      return leq(cst2ast(e1), cst2ast(e2), src=e@\loc);
    case (Expr) `<Expr e1> \> <Expr e2>`: 
      return greater(cst2ast(e1), cst2ast(e2), src=e@\loc);
    case (Expr) `<Expr e1> \>= <Expr e2>`: 
      return geq(cst2ast(e1), cst2ast(e2), src=e@\loc);
    case (Expr) `<Expr e1> == <Expr e2>`: 
      return equate(cst2ast(e1), cst2ast(e2), src=e@\loc);
    case (Expr) `<Expr e1> != <Expr e2>`: 
      return nequate(cst2ast(e1), cst2ast(e2), src=e@\loc);
    case (Expr) `<Expr e1> && <Expr e2>`: 
      return and(cst2ast(e1), cst2ast(e2), src=e@\loc);
    case (Expr) `<Expr e1> || <Expr e2>`: 
      return or(cst2ast(e1), cst2ast(e2), src=e@\loc);
    default: 
      throw "Unhandled expression: <e>";
  }
}

AType cst2ast(Type t) {
  switch (t) {
    case (Type) `boolean`: return boolean();
    case (Type) `string`: return string();
    case (Type) `integer`: return integer();
    default: throw "Unhandled type: <t>";
  }
}
