(*
 * Copyright 2020, Data61, CSIRO (ABN 41 687 119 230)
 * Copyright (c) 2022 Apple Inc. All rights reserved.
 *
 * SPDX-License-Identifier: BSD-2-Clause
 *)

(*
  Transitional theory for collecting all the map and disj lemmas in one spot
*)

theory MapExtraTrans
imports MapExtra
begin

(* TRANSLATIONS:
lemmas heap_disj_com = map_disj_com
lemmas heap_disj_dom = map_disjD
lemmas heap_merge_com = map_add_com
lemmas heap_merge_ac = map_add_left_commute
lemmas heap_merge = map_ac_simps
lemmas heap_merge_disj = map_add_disj
lemmas heap_disj_map_le = map_disj_map_le
lemmas heap_merge_dom_exact = map_disj_add_eq_dom_right_eq
lemmas map_restrict_empty = restrict_map_empty
XXX: assumption other way round  "P \<inter> dom s = {} \<Longrightarrow> s |` P = empty"
lemmas map_add_restrict_sub_add = subset_map_restrict_sub_add
lemmas restrict_neg_un_map = restrict_map_sub_union
restrict_map_dom \<rightarrow> restrict_map_subdom
*)

(* XXX: in Misc of map_sep *)
lemma case_option_None_Some [simp]:
  "case_option None Some P = P"
  by (simp split: option.splits)

(* XXX: when I redefine a lemma using lemmas, it doesn't show up in
        the theorem searcher anymore \<dots> GRRR *)

(* fixme: no direct equivalent in MapExtra *)
lemma heap_merge_dom_exact2:
  "\<lbrakk> a ++ b = c ++ d; dom a = dom c; a \<bottom> b; c \<bottom> d \<rbrakk> \<Longrightarrow> a=c \<and> b=d"
  apply (rule conjI)
   apply (erule (3) map_add_left_dom_eq)
  apply (erule (3) map_disj_add_eq_dom_right_eq)
  done

(* fixme: no equivalent in MapExtras, but this is too specific to shove in there *)
lemma map_add_restrict_sub:
  "\<lbrakk> dom s = X; dom t = X - Y \<rbrakk> \<Longrightarrow>
      s ++ (t |` (X - Y - Z)) = s ++ t ++ s |` Z"
apply(rule ext)
apply(auto simp: restrict_map_def map_add_def split: option.splits)
done

(* fixme: no equivalent in MapExtras, but this is too specific to shove in there *)
lemma map_add_restrict_UNIV:
  "\<lbrakk> dom g \<inter> X = {}; dom f = dom h \<rbrakk> \<Longrightarrow> f ++ g = f |` (UNIV - X) ++ h |` X ++ g ++ f |` X"
apply(rule ext)
apply(force simp: restrict_map_def map_add_def split: option.splits)
done

end
