(*
 * Copyright 2020, Data61, CSIRO (ABN 41 687 119 230)
 * Copyright (c) 2022 Apple Inc. All rights reserved.
 *
 * SPDX-License-Identifier: BSD-2-Clause
 *)

signature EXPRESSION_TYPING =
sig

  type 'a ctype = 'a Absyn.ctype
  type expr = Absyn.expr
  (* predicates on classes of C types *)
  val scalar_type : 'a ctype -> bool
  val ptr_type : 'a ctype -> bool
  val integer_type : 'a ctype -> bool
  val assignment_compatible : (int ctype * int ctype * expr) -> bool

  val constant_type : Absyn.literalconstant -> 'a ctype
  val fndes_convert : 'a ctype -> 'a ctype
  val binop_type : Proof.context ->
      SourcePos.t * SourcePos.t * Absyn.binoptype * int ctype * int ctype -> int ctype
  val unop_type : Absyn.unoptype * 'a ctype -> 'a ctype
  val expr_type : Proof.context -> Absyn.ecenv ->
                  (string * (CType.rcd_kind * (string * (int ctype * CType.attribute list)) list * Region.t * CType.attribute list)) list ->
                  (string -> int ctype option) ->
                  Absyn.expr -> int ctype
end


structure ExpressionTyping : EXPRESSION_TYPING =
struct

open Basics Absyn


fun cast_compatible fromty toty = scalar_type fromty andalso scalar_type toty

fun fndes_convert (ty as Function _) = Ptr ty
  | fndes_convert x = x

fun constant_type c =
    case node c of
      NUMCONST i => Absyn.numconst_type i
    | STRING_LIT _ => Ptr PlainChar


fun assign_compatible is_lit0 (newtype (* lhs *), oldtype (* rhs *))  =
  let
    in
      (newtype = oldtype) orelse
      (integer_type newtype andalso integer_type oldtype) orelse
      (newtype = Bool andalso scalar_type oldtype) orelse
      (integer_type oldtype andalso is_lit0 andalso ptr_type newtype) orelse
      (ptr_type newtype andalso oldtype = Ptr Void) orelse
      (ptr_type newtype andalso array_type oldtype) orelse
      (ptr_type oldtype andalso newtype = Ptr Void) orelse
      (fun_ptr_compatible newtype oldtype)
  end
and
  fun_ptr_compatible (Ptr (Function (resT1, params1))) (Ptr (Function (resT2, params2))) =
      assign_compatible false (resT1, resT2) andalso length params1 = length params2 andalso
      forall (assign_compatible false) (params1 ~~ params2)
  | fun_ptr_compatible _ _ = false


fun assignment_compatible (newtype (* lhs *), oldtype (* rhs *), oldexp) = let
    (* need to look at old exp to allow
          ptr = 0;
    *)
  val is_lit0 = case enode oldexp of
                  Constant lc => let
                  in
                    case node lc of
                      NUMCONST i => #value i = IntInf.fromInt 0
                    | _ => false
                  end
                | _ => false
in
  assign_compatible is_lit0 (newtype, oldtype)
end

fun relop Lt = true
  | relop Gt = true
  | relop Leq = true
  | relop Geq = true
  | relop Equals = true
  | relop NotEquals = true
  | relop _ = false


fun binop_type ctxt (l, r, bop, ty1, ty2) = let
  fun badtypemsg () =
      (Feedback.errorStr' ctxt (l,r,
                          "Bad types (" ^ tyname ty1 ^ " and " ^ tyname ty2 ^
                          ") as arguments to "^binopname bop);
       raise Feedback.WantToExit "Can't continue")
in
  case bop of
    LogOr => if scalar_type ty1 andalso scalar_type ty2
             then Signed Int
             else badtypemsg ()
  | LogAnd => if scalar_type ty1 andalso scalar_type ty2 then Signed Int
              else badtypemsg ()
  | _ => if relop bop then
           if ty1 = ty2 andalso scalar_type ty1 then Signed Int
           else if integer_type ty1 andalso integer_type ty2 then Signed Int
           else if ptr_type ty1 andalso ptr_type ty2 andalso
                   (bop = NotEquals orelse bop = Equals) andalso
                   (ty1 = Ptr Void orelse ty2 = Ptr Void) then Signed Int
           else badtypemsg()
         else (* must be arithmetic of some form *)
           if integer_type ty1 andalso integer_type ty2 then
             arithmetic_conversion(ty1, ty2)
           else if ptr_type ty1 andalso integer_type ty2 andalso
                   (bop = Plus orelse bop = Minus) then ty1
           else if array_type ty1 andalso integer_type ty2 andalso
                   bop = Plus then array_to_ptr_decay ty1
           else if ptr_type ty2 andalso integer_type ty1 andalso bop = Plus then ty2
           else if array_type ty2 andalso integer_type ty1 andalso bop = Plus then
              array_to_ptr_decay ty1
           else if ptr_or_array_type ty1 andalso ptr_or_array_type ty2 andalso ty1 = ty2 andalso
                   bop = Minus
           then ImplementationTypes.ptrdiff_t
           else
             (Feedback.errorStr' ctxt (l,r,
                                 "Bad types ("^tyname ty1^" and "^tyname ty2^
                                 ") as arguments to arithmetic op");
              raise Feedback.WantToExit "Can't continue")

end

fun unop_type (unop, ty) =
    case unop of
      Negate => if integer_type ty then ty
                else raise Fail "Bad type to unary negation"
    | Not => if scalar_type ty then Signed Int
             else raise Fail "Bad type to boolean negation"
    | Addr => Ptr ty
    | BitNegate => if integer_type ty then ty
                   else raise Fail "Bad type to bitwise complement"

fun expr_type ctxt ecenv senv varinfo e = let
  val expr_type = expr_type ctxt ecenv senv varinfo
  fun Fail s = (Feedback.errorStr' ctxt (eleft e, eright e, "expr-typing: " ^ s);
                raise Feedback.WantToExit "Can't continue")
  fun get_varinfo s = 
      case varinfo s of
        NONE => let
        in
          case eclookup ecenv s of
            NONE => Fail ("Bad variable reference: "^s)
          | SOME _ => Signed Int
        end
      | SOME ty => ty
in
  case enode e of
    BinOp(binop, e1, e2) => binop_type ctxt (eleft e, eright e, binop,
                                       expr_type e1, expr_type e2)
  | UnOp(unop, e0) => unop_type (unop, expr_type e0)
  | Constant c => constant_type c
  | Var (s, Unsynchronized.ref NONE) => get_varinfo s
  | Var (_, Unsynchronized.ref (SOME (cty, _))) => cty
  | StructDot (e0, fld) => let
     fun sel name = 
       let
          val sinfo = (#2 (the (AList.lookup (op =) senv name)))
          val fld_type =
              #1 (the (AList.lookup (op =) sinfo fld))
              handle Option =>
                       Fail ("Field \""^fld^"\" invalid fieldname")
       in
         fld_type
       end
    in
      case expr_type e0 of
        StructTy sname => sel sname
      | UnionTy uname => sel uname
      | _ => Fail "Attempt to field-dereference non-struct value"
    end
  | ArrayDeref(e1, e2) => let
    in
      case expr_type e1 of
        Array (ty1, _) => let
        in
          case expr_type e2 of
            Signed _ => ty1
          | Unsigned _ => ty1
          | EnumTy _ => ty1
          | badty => Fail ("Non-integer type "^tyname badty^
                           " used to dereference array")
        end
      | Ptr ty0 => let (* don't allow i[array] though C does *)
        in
          if integer_type (expr_type e2) then ty0
          else Fail "Non-integer type used to dereference array"
        end
      | _ => Fail "Attempt to array-index non-array value"
    end
  | Deref e0 => let
    in
      case fndes_convert (expr_type e0) of
        Ptr ty => ty
      | Array (ty, _) => ty
      | _ => Fail "Attempt to dereference non-pointer value"
    end
  | TypeCast(ty, e0) => let
      val ty0 = expr_type e0
      val ty' = Absyn.constify_abtype true ctxt ecenv (node ty)
    in
      if cast_compatible ty0 ty' then ty'
      else Fail ("Illegal cast - from: "^tyname ty0^" to: "^tyname ty')
    end
  | CondExp(_,t,_) => expr_type t (* bit bogus really *)
  | Sizeof _ => ImplementationTypes.size_t
  | SizeofTy _ => ImplementationTypes.size_t
  | CompLiteral(ty, _) => Absyn.constify_abtype true ctxt ecenv ty
  | EFnCall(fn_e, args) => let
      val fty = fndes_convert (expr_type fn_e)
      val (rettype, parameter_types) =
          case fty of
            Ptr (Function(r, ps)) => (r,ps)
          | _ => (Feedback.errorStr' ctxt (eleft e, eright e,
                                     "Function not of function type");
                  raise Feedback.WantToExit "Can't continue")
      val argtypes = List.map (fndes_convert o expr_type) args
      fun recurse [] _ _ = rettype
        | recurse (pty::prest) (aty::arest) (arg::erest) =
            if assignment_compatible(pty, aty, arg) then
              recurse prest arest erest
            else
              (Feedback.errorStr' ctxt (eleft arg, eright arg,
                                  "Argument with type "^tyname aty^
                                  " not compatible with parameter of type "^
                                  tyname pty);
               raise Feedback.WantToExit "Can't continue")
        | recurse _ _ _ = raise Fail "Invariant failure in expr_type"
    in
      recurse parameter_types argtypes args
    end
  | MKBOOL e => let
      val ty = expr_type e
    in
      if scalar_type ty then Signed Int
      else Fail "Expression can't be boolean"
    end
  | _ => Fail ("expr_type: encountered unexpected expression form("
               ^expr_string e^ ")")
end

end; (* struct *)
