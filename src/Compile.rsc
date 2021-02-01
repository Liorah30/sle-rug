module Compile

import AST;
import Resolve;
import IO;
import lang::html5::DOM; // see standard library
import Boolean;
import util::Math;

/*
 * Implement a compiler for QL to HTML and Javascript
 *
 * - assume the form is type- and name-correct
 * - separate the compiler in two parts form2html and form2js producing 2 files
 * - use string templates to generate Javascript
 * - use the HTML5Node type and the `str toString(HTML5Node x)` function to format to string
 * - use any client web framework (e.g. Vue, React, jQuery, whatever) you like for event handling
 * - map booleans to checkboxes, strings to textfields, ints to numeric text fields
 * - be sure to generate uneditable widgets for computed questions!
 * - if needed, use the name analysis to link uses to definitions
 */

void compile(AForm f) {
  writeFile(f.src[extension="js"].top, form2js(f));
  writeFile(f.src[extension="html"].top, toString(form2html(f)));
}

HTML5Node form2html(AForm f) {
  return html(
  		head(
  			title(f.id.name)
  			
  		),
  		body(
  			h1("Fill in the Questionnaire"),
  			div([question2html(question) | \AQuestion question <- f.questions])
  		),
  		footer(
  			script(src("https://code.jquery.com/jquery-3.4.1.min.js")),
  	  		script(src(f.src[extension="js"].file)),
  	  		link(\rel("stylesheet"), src("https://stackpath.bootstrapcdn.com/bootstrap/4.3.1/css/bootstrap.min.css"))
  		)
  );
}


HTML5Node question2html(list[AQuestion] questions, HTML5Node parent) {
  for(AQuestion question <- questions){
	  parent.kids += [question2html(question)];
  }
	
  return parent;
}

HTML5Node question2html(AQuestion q) {
  switch(q) {  
	case question(str _, AId _, AType _): 
		return div(
			class("form-group"),
	  		input2html(q, false)
	  	);
	case computed_question(str _, AId _, AType _, AExpr _): 
		return div(
			class("form-group"),
	  		input2html(q, true)
	  	);
	case block(list[AQuestion] questions):
		return div(
			class("form-group"),
			div([question2html(question) | \AQuestion question <- questions])
		);
	case if_then(AExpr exp, list[AQuestion] if_qs): {
	 parent = div(id("if-" + exp2html(exp)));
	  	return div(
	  	class("form-group"),
	  	question2html(if_qs, parent)
	   );
    }
	case if_then_else(AExpr expr, list[AQuestion] if_qs, list[AQuestion] else_qs):{
	  if_statement = question2html(if_qs, div(id("if-" + exp2html(expr))));
	  else_statement = question2html(else_qs, div(id("else-" + exp2html(expr))));
	  parentt = div();
	  parentt.kids += [if_statement, else_statement];
	  return div(
	  	class("form-group"),
	  	parentt
	  	);
	}
  }
  return div();
}



str exp2html(expr){
  switch (expr) {
    case ref(id(str name)):
    	return "<name>";
    case integer(int n):
    	return toString(n);
    case string(str s):
    	return "<s>";
    case boolean(bool b):
    	return toString(b);
    case brackets(AExpr e):
    	return "("+ exp2html(e) + ")";
    case not(AExpr expr): 					
    	return "!"+ exp2html(expr);
    case multiply(AExpr lhs, AExpr rhs):
    	return exp2html(lhs) + "*" + exp2html(rhs);
    case divide(AExpr lhs, AExpr rhs):
    	return exp2html(lhs) + "/" + exp2html(rhs);
    case addition(AExpr lhs, AExpr rhs):
    	return exp2html(lhs) + "+" + exp2html(rhs);
    case subtraction(AExpr lhs, AExpr rhs):
    	return exp2html(lhs) + "-" + exp2html(rhs);
	case greater(AExpr lhs, AExpr rhs):
		return exp2html(lhs) + "\>" + exp2html(rhs);
	case lesser(AExpr lhs, AExpr rhs):
		return exp2html(lhs) + "\<" + exp2html(rhs);
	case geq(AExpr lhs, AExpr rhs):
		return exp2html(lhs) + "\>=" + exp2html(rhs);
	case leq(AExpr lhs, AExpr rhs):
		return exp2html(lhs) + "\<=" + exp2html(rhs);
	case equate(AExpr lhs, AExpr rhs):
		return exp2html(lhs) + "==" + exp2html(rhs);
	case nequate(AExpr lhs, AExpr rhs):
		return exp2html(lhs) + "!=" + exp2html(rhs);
	case and(AExpr lhs, AExpr rhs):
		return exp2html(lhs) + "&&" + exp2html(rhs);
	case or(AExpr lhs, AExpr rhs):
		return exp2html(lhs) + "||" + exp2html(rhs);	
	    
  }
  return "";
}

HTML5Node input2html(AQuestion q, bool disab) {
  HTML5Attr inptype;
	
  switch(q.typ) {
	case integer() :
	  inptype =  \type("integer"); 
	case boolean() :
	  inptype =  \type("checkbox"); 
	case string() :
	 inptype =  \type("text"); 
  }
  return inpQuestion(q,inptype,disab);
  }
	
  HTML5Node inpQuestion (AQuestion q,HTML5Attr inptype,bool disab){
  	HTML5Node inpQuestion;
  if(disab) {
    inpQuestion = input(inptype, name("<q.id.name>"), id("<q.id.name>"), disabled("disabled"));
  } else {
    inpQuestion = input(inptype, name("<q.id.name>"), id("<q.id.name>"));
  }
  
  return div(
    label(\for("<q.id.name>"), q.label),
    inpQuestion,
    br()
  );
}

str form2js(AForm f) {
  return hideFunction() + allVariables2js(f.questions) + transformAllQuestions2js(f.questions);
}

str hideFunction() {
  return "function hideDiv(divId, hide) {
		    var x = document.getElementById(divId);
			if (!hide) {
			  x.style.display = \"block\";
	        } else {
			  x.style.display = \"none\";
			}
    	  }\n" ;
}


//everytime theres a change the form updates
str transformAllQuestions2js(list[AQuestion] questions) {
  str new = "$(function(){
   	   		       $(\':input\').change(function(e){
   					 changedValues();
   				   });
				 });
				 function changedValues(){\n";
				   new += transformQuestions2js(questions);
				   new += "}
				 $( document ).ready(function() {
				  changedValues();
    			   console.log(\"ready!\" );
  				 });\n";
  return new;
}

str transformQuestions2js(list[AQuestion] questions) {
  str new = "";
  for(AQuestion q <- questions){
	new += question2js(q);
  }
  return new;
}

str question2js(AQuestion q) {
  switch(q) {
  	case question(str _, AId id, AType typ):
  	  return id.name + " = document.getElementById(\'"+ id.name +"\')." + type2jsInput(typ) + ";\n";
	case computed_question(str _, AId id, AType typ, AExpr exp): 
	  return id.name + " = "+ exp2js(exp) + ";
	    document.getElementById(\'"+ id.name +"\')." + type2jsInput(typ) + " = " + id.name + ";\n";
	case block(list[AQuestion] questions):
		return transformQuestions2js(questions);
	case if_then(AExpr exp, list[AQuestion] if_qs): {
	  if_statement = transformQuestions2js(if_qs);
		  parent =  "hideDiv(\'if-"+ exp2js(exp)+"\',!("+ exp2js(exp) +"));\n";
		return parent + if_statement; 
	  }
	case if_then_else(AExpr exp, list[AQuestion] if_qs, list[AQuestion] else_qs):{
	  if_statement = transformQuestions2js(if_qs);
	  else_statement= transformQuestions2js(else_qs);
	  parent = "hideDiv(\'if-"+ exp2js(exp)+"\',!("+ exp2js(exp) +"));
	  hideDiv(\'else-"+ exp2js(exp)+"\',("+ exp2js(exp) +"));\n";
	  return parent + if_statement + else_statement;
	}
	default: 
		return "";
  }
}

str allVariables2js(list[AQuestion] questions) {
  str new = "";
  for(AQuestion question <- questions){
	new += variables2js(question);
  }
  return new;
}

str variables2js(AQuestion q) {
  switch(q) {
  	case question(str _, AId id, AType typ): 
	  return "var " + id.name + " = " + type2js(typ) + ";\n";
	case computed_question(str _, AId id, AType typ, AExpr _): 
	  return "var " + id.name + " = " + type2js(typ) + ";\n";
	case block(list[AQuestion] questions):
		return allVariables2js(questions);
	case if_then(AExpr _, list[AQuestion] if_qs): {
	  return allVariables2js(if_qs); 
	}
	case if_then_else(AExpr _, list[AQuestion] if_qs, list[AQuestion] else_qs):{
	  if_statement = allVariables2js(if_qs);
	  else_statement = allVariables2js(else_qs);
	  return if_statement + else_statement;
	}
	default: 
	  return "";
  }
  
}

str type2js(AType t) {
  switch(t){
	case integer(): return "0";
	case boolean(): return "false";
	case string(): return "";
	default: return "";
  }
}

str type2jsInput(AType t){
  switch(t){
	case integer(): return "value";
	case boolean(): return "checked";
	case string(): return "value";
	default: return "";
  }
}

str exp2js(expr){
  switch (expr) {
    case ref(id(str name)):
    	return "<name>";
    case integer(int n):
    	return toString(n);
    case string(str s):
    	return "<s>";
    case boolean(bool b):
    	return toString(b);
    case brackets(AExpr e):
    	return "("+ exp2js(e) + ")";
    case not(AExpr expr): 					
    	return "!"+ exp2js(expr);
    case multiply(AExpr lhs, AExpr rhs):
    	return exp2js(lhs) + "*" + exp2js(rhs);
    case divide(AExpr lhs, AExpr rhs):
    	return exp2js(lhs) + "/" + exp2js(rhs);
    case addition(AExpr lhs, AExpr rhs):
    	return exp2js(lhs) + "+" + exp2js(rhs);
    case subtraction(AExpr lhs, AExpr rhs):
    	return exp2js(lhs) + "-" + exp2js(rhs);
	case greater(AExpr lhs, AExpr rhs):
		return exp2js(lhs) + "\>" + exp2js(rhs);
	case lesser(AExpr lhs, AExpr rhs):
		return exp2js(lhs) + "\<" + exp2js(rhs);
	case geq(AExpr lhs, AExpr rhs):
		return exp2js(lhs) + "\>=" + exp2js(rhs);
	case leq(AExpr lhs, AExpr rhs):
		return exp2js(lhs) + "\<=" + exp2js(rhs);
	case equate(AExpr lhs, AExpr rhs):
		return exp2js(lhs) + "==" + exp2js(rhs);
	case nequate(AExpr lhs, AExpr rhs):
		return exp2js(lhs) + "!=" + exp2js(rhs);
	case and(AExpr lhs, AExpr rhs):
		return exp2js(lhs) + "&&" + exp2js(rhs);
	case or(AExpr lhs, AExpr rhs):
		return exp2js(lhs) + "||" + exp2js(rhs);	
	    
  }
  return "";
}