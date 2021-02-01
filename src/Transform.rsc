module Transform

import Syntax;
import Resolve;
import AST;
import CST2AST;
import ParseTree;

/* 
 * Transforming QL forms
 */
 
 
/* Normalization:
 *  wrt to the semantics of QL the following
 *     q0: "" int; 
 *     if (a) { 
 *        if (b) { 
 *          q1: "" int; 
 *        } 
 *        q2: "" int; 
 *      }
 *
 *  is equivalent to
 *     if (true) q0: "" int;
 *     if (true && a && b) q1: "" int;
 *     if (true && a) q2: "" int;
 *
 * Write a transformation that performs this flattening transformation.
 *
 */
 
AForm flatten(AForm f) {
   f.questions=flatten(f.questions,boolean(true));
   return f;
}

list[AQuestion] flatten(list[AQuestion] aQuestions, AExpr expr){
	return ([] | it + flatten(aQuestion, expr) | /AQuestion aQuestion := aQuestions);
}
list[AQuestion] flatten(AQuestion q, AExpr expr) {
	switch (q) {
		case question(str _, AId _, AType _):
			return  [if_then(expr, [q])];
		case computed_question(str _, AId _, AType _, AExpr _):
			return  [if_then(expr, [q])];
		case block(list[AQuestion] questions):
			return flatten(questions, expr);
		case if_then(AExpr e, list[AQuestion] if_qs):
			return flatten(if_qs, and(e, expr));
		case if_then_else(AExpr condition, list[AQuestion] trueQuestions, list[AQuestion] falseQuestions):
			return   flatten(trueQuestions, and(condition, expr)) + flatten(falseQuestions, and(not(condition), expr));
	}
	return [];
}
/* Rename refactoring:
 *
 * Write a refactoring transformation that consistently renames all occurrences of the same name.
 * Use the results of name resolution to find the equivalence class of a name.
 *
 */
 
start[Form] rename(start[Form] f, loc useOrDef, str newName, UseDef useDef) {
   	set[loc] toRename = {useOrDef} + {l | <useOrDef, loc l> <-useDef} + {u| <loc u, useOrDef> <- useDef};
	
	return visit(f) {
     case (Question)`<Str s> <Id i> : <Type typ>` 
       => (Question)`<Str s> <Id new> : <Type typ>`
         when i@\loc in toRename,
         Id new := [Id]newName
         
     case (Question)`<Str s> <Id i> : <Type typ> = <Expr exp>` 
       => (Question)`<Str s> <Id new> : <Type typ> = <Expr exp>`
         when i@\loc in toRename,
         Id new := [Id]newName
       
     case (Expr)`<Id i>`
       => (Expr)`<Id new>`
         when i@\loc in toRename,
         Id new := [Id]newName  
   }
} 
 
 

