chapter {* Generated by Lem from \<open>semantics/ast.lem\<close>. *}

theory "AstAuxiliary" 

imports 
 	 Main
	 "LEM.Lem_pervasives" 
	 "Lib" 
	 "Namespace" 
	 "FpSem" 
	 "Ast" 

begin 


(****************************************************)
(*                                                  *)
(* Termination Proofs                               *)
(*                                                  *)
(****************************************************)

termination pat_bindings by lexicographic_order



end