(*
 * Copyright 2020, Data61, CSIRO (ABN 41 687 119 230)
 * Copyright (c) 2022 Apple Inc. All rights reserved.
 *
 * SPDX-License-Identifier: BSD-2-Clause
 *)

theory longlong
imports "AutoCorres2.CTranslation"
begin

install_C_file "longlong.c"


context longlong_simpl
begin

thm f_body_def
thm shifts1_body_def
thm shifts2_body_def

end (* context *)

lemma "(ucast :: 16 word \<Rightarrow> 8 word) 32768 = 0"
apply simp
done

lemma "(scast :: 16 word \<Rightarrow> 8 word) 32768 = 0"
by simp

lemma "(scast :: 16 word \<Rightarrow> 8 word) 65535 = 255"
by simp

lemma "(ucast :: 16 word \<Rightarrow> 8 word) 65535 = 255"
by simp

lemma "(ucast :: 16 word \<Rightarrow> 8 word) 32767 = 255" by simp
lemma "(scast :: 16 word \<Rightarrow> 8 word) 32767 = 255" by simp

lemma "(scast :: 8 word \<Rightarrow> 16 word) 255 = 65535" by simp
lemma "(ucast :: 8 word \<Rightarrow> 16 word) 255 = 255" by simp


lemma (in callg_impl) g_result:
  "\<Gamma> \<turnstile> \<lbrace> True \<rbrace> \<acute>ret' :== CALL callg() \<lbrace> \<acute>ret' = 0 \<rbrace>"
  apply vcg
  apply (simp add: mask_def )
done


lemma (in literals_impl) literals_result:
  "\<Gamma> \<turnstile> \<lbrace> True \<rbrace> \<acute>ret' :== CALL literals() \<lbrace> \<acute>ret' = 31 \<rbrace>"
apply vcg
apply simp
done



end (* theory *)
