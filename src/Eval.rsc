module Eval

import AST;
import Resolve;

/*
 * Implement big-step semantics for QL
 */
 
// NB: Eval may assume the form is type- and name-correct.


// Semantic domain for expressions (values)
data Value
  = vint(int n)
  | vbool(bool b)
  | vstr(str s)
  ;

// The value environment
alias VEnv = map[str name, Value \value];

// Modeling user input
data Input
  = input(str question, Value \value); 
 
//standard values   for all different types for initialzation
Value initialValue (AType t){
	switch(t){
		case integer(): return vint(0);
		case string():  return vstr("");
		case boolean(): return vbool(false);
		default:        throw "Unsupported type: <t>";
	}
}

// produce an environment which for each question has a default value
// (e.g. 0 for int, "" for str etc.)
VEnv initialEnv(AForm f) {
  VEnv venv = ();
  for(/AQuestion qs :=f.questions){
  	switch(qs){
  		case question(str _, AId id,AType typ):
  			venv+=(id.name:initialValue(typ));
  		case computed_question(str _,AId id, AType typ,AExpr _):
  			venv+=(id.name:initialValue(typ));
  		}
  	}
  	return venv;
}


// Because of out-of-order use and declaration of questions
// we use the solve primitive in Rascal to find the fixpoint of venv.
VEnv eval(AForm f, Input inp, VEnv venv) {
  return solve (venv) {
    venv = evalOnce(f, inp, venv);
  }
}

// evaluate new answer once for each question
VEnv evalOnce(AForm f, Input inp, VEnv venv) {
	for(/AQuestion q:=f.questions){
		venv = eval(q,inp,venv);
	}
  return venv; 
}

VEnv eval(AQuestion q, Input inp, VEnv venv) {
  // evaluate conditions for branching,
  // evaluate inp and computed questions to return updated VEnv
  
  switch(q){
  case question(str _,AId id, AType _):
        if(inp.question == id.name) { venv[id.name] = inp.\value; }
    case computed_question(str _, AId id, AType _ ,AExpr expr):
    	venv[id.name] = eval(expr, venv);
    case block(list[AQuestion] questions):
      for(AQuestion qs <- questions) { 
      	venv = eval(qs, inp, venv); 
      }

    case if_then(AExpr expr, list[AQuestion] if_qs):
        if(eval(expr, venv) == vbool(true)) { 
        	for(/AQuestion qs<-if_qs){
    			venv = eval(qs,inp,venv);
    			}
    		}
    case if_then_else(AExpr expr,list[ AQuestion] if_qs, list[AQuestion] else_qs):
    	if (eval(expr, venv) == vbool(true)){
    		for(/AQuestion qs<-if_qs){
    			venv = eval(qs,inp,venv);
    		}
    	}else{
    		for(/AQuestion qqs<-else_qs){
    			venv = eval(qqs,inp,venv);
    		}
    	}
    }
    
  return venv; 
}

Value eval(AExpr e, VEnv venv) {
  switch (e) {
    case ref(AId id): return venv[id.name];
    case integer(int x):return vint(x);
    case string(str s):return vstr(s);
    case boolean(bool b):return vbool(b);
    case brackets(AExpr _): return eval(e, venv);
    case not(AExpr expr): return vbool(!eval(expr, venv).b);
    case multiply(AExpr lhs, AExpr rhs): return vint(eval(lhs, venv).n * eval(rhs, venv).n);
    case divide(AExpr lhs, AExpr rhs): return vint(eval(lhs, venv).n / eval(rhs, venv).n);
    case addition(AExpr lhs, AExpr rhs): return vint(eval(lhs, venv).n + eval(rhs, venv).n);
    case subtraction(AExpr lhs, AExpr rhs): return vint(eval(lhs, venv).n - eval(rhs, venv).n);
    case greater(AExpr lhs, AExpr rhs): return vbool(eval(lhs, venv).n > eval(rhs, venv).n);
    case lesser(AExpr lhs, AExpr rhs): return vbool(eval(lhs, venv).n < eval(rhs, venv).n);
    case leq(AExpr lhs, AExpr rhs): return vbool(eval(lhs, venv).n <= eval(rhs, venv).n);
    case geq(AExpr lhs, AExpr rhs): return vbool(eval(lhs, venv).n >= eval(rhs, venv).n);
    case equate(AExpr lhs, AExpr rhs): return vbool(eval(lhs, venv) == eval(rhs, venv)); 
    case nequate(AExpr lhs, AExpr rhs): return vbool(eval(lhs, venv) != eval(rhs, venv));
    case and(AExpr lhs, AExpr rhs): return vbool(eval(lhs, venv).b && eval(rhs, venv).b);
    case or(AExpr lhs, AExpr rhs): return vbool(eval(lhs, venv).b || eval(rhs, venv).b);
    default: throw "Unsupported expression <e>";

  }
}