/**module Compile

import AST;
import Resolve;
import IO;
import lang::html5::DOM; // see standard library
import List;
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


/*
 * Map the type of the expression to an HTML5 input type such as checkboxes, text-fields or integer inputs
 */
 
HTML5Attr type2html(boolean()) = \type("checkbox");
HTML5Attr type2html(string()) = \type("text");
HTML5Attr type2html(integer()) = \type("number");


void compile(AForm f) {
  writeFile(f.src[extension="js"].top, form2js(f));
  writeFile(f.src[extension="html"].top, toString(form2html(f)));
}

HTML5Node form2html(AForm f) {
  return html(
  head(
  	title("A Query Language")
  ),
  body (
  	div([question2html(q)|AQuestion q <-f.questions]),
  	script(src("https://code.jquery.com/jquery-3.4.1.min.js"))
  	)
  	
  );
}

HTML5Node question2html(AQuestin q){
	switch(q){
		case question(str label,AId id,AType typ):
			return 
	}
	
}
str form2js(AForm f) {
  return "";
}
