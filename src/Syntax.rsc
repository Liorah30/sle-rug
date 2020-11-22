module Syntax

extend lang::std::Layout;
extend lang::std::Id;

/*
 * Concrete syntax of QL
 */

start syntax Form 
  = "form" Id "{" Question* "}"; 


syntax Question
  = question:			Str Id ":" Type
  | computed_question: 	Str Id ":" Type "=" Expr
  | block:				"{" Question* "}"
  | if_then:			"if" "(" Expr ")" Question 
  | if_then_else:		"if" "(" Expr ")" Question "else" Question
  ; 


syntax Expr 
  = Id \ "true" \ "false" // true/false are reserved keywords.
  | integer:		 Int
  | strng:			 Str
  | boolean:		 Bool
  | brackets:   	 "(" Expr ")"
  >right not:   	 "!" Expr
  >left (multiply: 	 Expr lhs "*" Expr rhs|
  		 divide:	 Expr lhs "/" Expr rhs)
  >left (addition:   Expr lhs "+" Expr rhs|
  		 subtraction:Expr lhs "-" Expr rhs)
  >left (greater:	 Expr lhs "\>"Expr rhs|
  		 lesser:	 Expr lhs "\<"Expr rhs|
  		 leq:		 Expr lhs "\<="Expr rhs|
  		 geq:		 Expr lhs "\>="Expr rhs)
  >left (equate:	 Expr lhs "==" Expr rhs|
  		 nequate:    Expr lhs "!=" Expr rhs)
  >left and:		 Expr lhs "&&" Expr rhs
  >left or:			 Expr lhs "||" Expr rhs
  ;
  
syntax Type
  = "boolean"|"integer"|"string";  
  
lexical Str = [\"] ![\"]* [\"];

lexical Int 
  = "-"?[0-9]+;

lexical Bool = "true"|"false";


