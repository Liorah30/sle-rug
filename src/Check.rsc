module Check

import AST;
import Resolve;
import Message; // see standard library
import Set;

data Type
  = tint()
  | tbool()
  | tstr()
  | tunknown()
  ;
  

//pattern matching abstract and mapping to the data Type
Type mapTypes(AType t) {
  switch (t) {
    case integer(): return tint();
    case boolean(): return tbool();
    case string():  return tstr();
    default:        return tunknown();
  }
}


//the type environment consisting of defined questions in the form 
alias TEnv = rel[loc def, str name, str label, Type \type];

// To avoid recursively traversing the form, use the `visit` construct
// or deep match (e.g., `for (/question(...) := f) {...}` ) 



//return type env 
TEnv collect(AForm f) {
		TEnv t_env = {};
	visit(f){
		case question(str label, id(name), AType typ, src = loc location) :
			t_env += {<location, name, label, mapTypes(typ)>};	
		case computed_question(str label, id(name), AType typ, AExpr _, src = loc location) :
			t_env += {<location, name, label, mapTypes(typ)>};
	}
  	return t_env; 
}


//check form for type correctneess
set[Message] check(AForm f, TEnv tenv, UseDef useDef) 
	 = ({} | it + check(question, tenv, useDef) | /AQuestion question <- f.questions);
	 //+ ({} | it + check(expr,tenv,useDef)|/AExpr expr := f);


// - produce an error if there are declared questions with the same name but different types.
// - duplicate labels should trigger a warning 
// - the declared type computed questions should match the type of the expression.
/*set[Message] check(AQuestion q, TEnv tenv, UseDef useDef){
	set[Message] msg ={};
	switch(q){
		case question(str _,AId id , AType _,src=loc location):
			msg += {warning("Duplicate label ",location)|size((tenv<2,0>)[q.label])>1}
			+ {error("Question name has been declared with different types",location)|size((tenv<1,3>)[id.name])>1};
		case computed_question(str _, AId id, AType typ,AExpr expr,src=loc location):
			msg += {warning("Duplicate label ",location)|size((tenv<2,0>)[q.label])>1}
			+ {error("Question name has been declared with different types",location)|size((tenv<1,3>)[id.name])>1}
			+{error("Declared type of computed question dooes not match the type of expression",location)|mapTypes(typ)!=typeOf(expr,tenv,useDef)};
		case block(list[AQuestion] qs ,  src =loc _):
			msg +=({}|it+ check(question,tenv,useDef)|/AQuestion question<-qs);	
		case if_then(AExpr e,list[AQuestion] if_qs,src =loc location):
			msg+={error("Conditon must always be boolean",location)|typeOf(e,tenv,useDef)!=tbool()}
			+check(e,tenv,useDef)
			+({}|it+check(qs,tenv,useDef)|/AQuestion qs<-if_qs);	
		case if_then_else(AExpr e,list[AQuestion] if_qs,list[AQuestion] else_qs,src =loc location):	
			msg+={error("Conditon must always be boolean",location)|typeOf(e,tenv,useDef)!=tbool()}
			+check(e,tenv,useDef)
			+({}|it+check(qs,tenv,useDef)|/AQuestion qs<-if_qs)
			+({}|it+check(qss,tenv,useDef)|/AQuestion qss<-else_qs);
	}
	return msg;
}
*/

set[Message] check(AQuestion q, TEnv tenv, UseDef useDef) {
	set[Message] msgs = {};
	switch(q){
		case question(str _, AId id, AType _, src = loc l):
			msgs += {error("Duplicate question with different type", l) | (size((tenv<1,3>)[id.name]) > 1)} 
			+ {warning("Same label for different questions", l) | (size((tenv<2,0>)[q.label]) > 1)}
			+ {warning("Different label for occurences of same question", l) | (size((tenv<1,2>)[q.id.name]) > 1) };
		case computed_question(str _, AId id, AType _, AExpr expr, src = loc l):
			msgs += {error("Duplicate question with different type", l) | (size((tenv<1,3>)[id.name]) > 1)}
			+ {warning("Same label for different questions", l) | (size((tenv<2,0>)[q.label]) > 1)}
			+ {warning("Different label for occurences of same question", l) | (size((tenv<1,2>)[q.id.name]) > 1)}
			+ check(expr, tenv, useDef);
		case block(list[AQuestion] questions, src = loc _):
			msgs += ({} | it + check(question, tenv, useDef) | /AQuestion question <- questions);
		case if_then_else(AExpr condition, list[AQuestion] trueQuestions, list[AQuestion] falseQuestions, src = loc l):
			msgs += {error("Condition is not boolean", l) | (typeOf(condition, tenv, useDef) != tbool())}
			+ check(condition, tenv, useDef)
			+ ({} | it + check(tQuestion, tenv, useDef) | /AQuestion tQuestion <- trueQuestions)
			+ ({} | it + check(fQuestion, tenv, useDef) | /AQuestion fQuestion <- falseQuestions);
		case if_then(AExpr condition, list[AQuestion] trueQuestions, src = loc l): 
			msgs += {error("Condition is not boolean", l) | (typeOf(condition, tenv, useDef) != tbool())}
			+ check(condition, tenv, useDef)
			+ ({} | it + check(tQuestion, tenv, useDef) | /AQuestion tQuestion <- trueQuestions);
	}
	return msgs;
}

// Check operand compatibility with operators.
// E.g. for an addition node add(lhs, rhs), 
//   the requirement is that typeOf(lhs) == typeOf(rhs) == tint()
set[Message] check(AExpr e, TEnv tenv, UseDef useDef) {
  set[Message] msgs = {};
  
  switch (e) {
    case ref(AId id):
    	msgs += { error("Undeclared question", id.src) | useDef[id.src] == {} };
    case brackets(AExpr expr):
    	msgs += check(expr , tenv,useDef);
    case not(AExpr expr):
    	msgs += {error("Invalid negation",expr.src)| typeOf(expr,tenv,useDef)!=tbool()};
    case multiply(AExpr lhs,AExpr rhs):
    	msgs+={error("Invalid multiplication",e.src)|typeOf(lhs, tenv, useDef) != tint() || typeOf(rhs, tenv, useDef) != tint()}
    	+check(lhs,tenv,useDef)+check(rhs,tenv,useDef);
    case divide(AExpr lhs, AExpr rhs):
    	msgs+={error("Invalid divisions",e.src)|typeOf(lhs, tenv, useDef) != tint() || typeOf(rhs, tenv, useDef) != tint()}
    	+check(lhs,tenv,useDef)+check(rhs,tenv,useDef);
    case addition (AExpr lhs, AExpr rhs):
    	msgs+={error("Invalid addition",e.src)|typeOf(lhs, tenv, useDef) != tint() || typeOf(rhs, tenv, useDef) != tint()}
    	+check(lhs,tenv,useDef)+check(rhs,tenv,useDef);
     case subtraction(AExpr lhs, AExpr rhs):
    	msgs+={error("Invalid subtraction",e.src)|typeOf(lhs, tenv, useDef) != tint() || typeOf(rhs, tenv, useDef) != tint()}
    	+check(lhs,tenv,useDef)+check(rhs,tenv,useDef);
     case lesser(AExpr lhs, AExpr rhs):
    	msgs+={error("Invalid comparision",e.src)|typeOf(lhs, tenv, useDef) != tint() || typeOf(rhs, tenv, useDef) != tint()}
    	+check(lhs,tenv,useDef)+check(rhs,tenv,useDef);
     case lesser(AExpr lhs, AExpr rhs):
    	msgs+={error("Invalid comparision",e.src)|typeOf(lhs, tenv, useDef) != tint() || typeOf(rhs, tenv, useDef) != tint()}
    	+check(lhs,tenv,useDef)+check(rhs,tenv,useDef);
    case leq(AExpr lhs, AExpr rhs):
    	msgs+={error("Invalid comparision",e.src)|typeOf(lhs, tenv, useDef) != tint() || typeOf(rhs, tenv, useDef) != tint()}
    	+check(lhs,tenv,useDef)+check(rhs,tenv,useDef);
    case greater(AExpr lhs, AExpr rhs):
    	msgs+={error("Invalid comparision",e.src)|typeOf(lhs, tenv, useDef) != tint() || typeOf(rhs, tenv, useDef) != tint()}
    	+check(lhs,tenv,useDef)+check(rhs,tenv,useDef);
    case geq(AExpr lhs, AExpr rhs):
    	msgs+={error("Invalid comparision",e.src)|typeOf(lhs, tenv, useDef) != tint() || typeOf(rhs, tenv, useDef) != tint()}
    	+check(lhs,tenv,useDef)+check(rhs,tenv,useDef);
    case equate(AExpr lhs, AExpr rhs):
      msgs += { error("Invalid equality comparison", e.src) | typeOf(lhs, tenv, useDef) != tint() || typeOf(rhs, tenv, useDef) != tint()}
      	+check(lhs,tenv,useDef)+check(rhs,tenv,useDef);
     
     case nequate(AExpr lhs, AExpr rhs):
      msgs += { error("Invalid equality comparison", e.src) | typeOf(lhs, tenv, useDef) != tint() || typeOf(rhs, tenv, useDef) != tint()}
      	+check(lhs,tenv,useDef)+check(rhs,tenv,useDef);	
    
    case and(AExpr lhs, AExpr rhs):
      msgs += { error("Invalid equality comparison", e.src) | typeOf(lhs, tenv, useDef) != tbool() || typeOf(rhs, tenv, useDef) != tbool()}
      	+check(lhs,tenv,useDef)+check(rhs,tenv,useDef);	
      	
     case or(AExpr lhs, AExpr rhs):
      msgs += { error("Invalid equality comparison", e.src) | typeOf(lhs, tenv, useDef) != tbool() || typeOf(rhs, tenv, useDef) != tbool()}
      	+check(lhs,tenv,useDef)+check(rhs,tenv,useDef);	
  }
  
  return msgs; 
}

Type typeOf(AExpr e, TEnv tenv, UseDef useDef) {
  switch (e) {
    case ref(id(_, src = loc u)):  
      if (<u, loc d> <- useDef, <d, _, _, Type t> <- tenv) {
        return t;
      }
    case string(str _,src=loc _):
   		return tstr();
   	case boolean(bool _,src=loc _):
   		return tbool();
   	case integer(int _,src=loc _):
   		return tint();
   	case brackets(AExpr expr,src = loc _):
   		return typeOf(expr,tenv,useDef);
   	case not (AExpr expr,src = loc _):
   		return typeOf(expr, tenv, useDef) == tbool() ? tbool() : tunknown();
   	case multiply(AExpr lhs ,AExpr rhs , src = loc _):
   		return typeOf(lhs,tenv,useDef)==tint() && typeOf(rhs,tenv,useDef)==tint()?tint() : tunknown();
   	case divide(AExpr lhs,AExpr rhs,src=loc _):
   		return typeOf(lhs,tenv,useDef)==tint() && typeOf(rhs,tenv,useDef)==tint()?tint() : tunknown();
   	case addition(AExpr lhs,AExpr rhs,src=loc _):
   		return typeOf(lhs,tenv,useDef)==tint() && typeOf(rhs,tenv,useDef)==tint()?tint() : tunknown();
   	case subtraction(AExpr lhs,AExpr rhs,src=loc _):
   		return typeOf(lhs,tenv,useDef)==tint() && typeOf(rhs,tenv,useDef)==tint()?tint() : tunknown();
   	case lesser(AExpr lhs,AExpr rhs,src=loc _):
   		return typeOf(lhs,tenv,useDef)==tint() && typeOf(rhs,tenv,useDef)==tint()?tbool() : tunknown();
   	case leq(AExpr lhs,AExpr rhs,src=loc _):
   		return typeOf(lhs,tenv,useDef)==tint() && typeOf(rhs,tenv,useDef)==tint()?tbool() : tunknown();
   	case greater(AExpr lhs,AExpr rhs,src=loc _):
   		return typeOf(lhs,tenv,useDef)==tint() && typeOf(rhs,tenv,useDef)==tint()?tbool() : tunknown();
   	case geq(AExpr lhs,AExpr rhs,src=loc _):
   		return typeOf(lhs,tenv,useDef)==tint() && typeOf(rhs,tenv,useDef)==tint()?tbool() : tunknown();
   	case equate(AExpr lhs,AExpr rhs,src=loc _):
   		return typeOf(lhs,tenv,useDef)==tint() && typeOf(rhs,tenv,useDef)==tint()?tbool() : tunknown();
   	case nequate(AExpr lhs,AExpr rhs,src=loc _):
   		return typeOf(lhs,tenv,useDef)==tint() && typeOf(rhs,tenv,useDef)==tint()?tbool() : tunknown();
   	case and(AExpr lhs,AExpr rhs,src=loc _):
   		typeOf(lhs,tenv,useDef)==tbool() && typeOf(rhs,tenv,useDef)==tbool()?tbool() : tunknown();
   	case or(AExpr lhs,AExpr rhs,src=loc _):
   		typeOf(lhs,tenv,useDef)==tbool() && typeOf(rhs,tenv,useDef)==tbool()?tbool() : tunknown();			
  }
  return tunknown(); 
}

/* 
 * Pattern-based dispatch style:
 * 
 * Type typeOf(ref(id(_, src = loc u)), TEnv tenv, UseDef useDef) = t
 *   when <u, loc d> <- useDef, <d, x, _, Type t> <- tenv
 *
 * ... etc.
 * 
 * default Type typeOf(AExpr _, TEnv _, UseDef _) = tunknown();
 *
 */
 
 