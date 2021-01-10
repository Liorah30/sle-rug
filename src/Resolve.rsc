module Resolve

import AST;

/*
 * Name resolution for QL
 
 */ 


// modeling declaring occurrences of names
alias Def = rel[str name, loc def];

// modeling use occurrences of names
alias Use = rel[loc use, str name];

alias UseDef = rel[loc use, loc def];

// the reference graph
alias RefGraph = tuple[
  Use uses, 
  Def defs, 
  UseDef useDef
]; 

RefGraph resolve(AForm f) = <us, ds, us o ds>
  when Use us := uses(f), Def ds := defs(f);

// Visit all nodes that have ref(AId id), i.e. all AExpr nodes.
Use uses(AForm f) {
  return {<id.src, id.name> | /ref(AId id) := f}; 
}
// Visit all questions, either computed or non-computed to find variable definations
Def defs(AForm f) {
 return {<id.name,id.src> | /question(_, AId id, _) := f || /computed_question(_, AId id, _,_) := f};
  }