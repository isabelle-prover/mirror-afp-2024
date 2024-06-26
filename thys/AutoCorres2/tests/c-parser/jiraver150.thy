(*
 * Copyright 2020, Data61, CSIRO (ABN 41 687 119 230)
 * Copyright (c) 2022 Apple Inc. All rights reserved.
 *
 * SPDX-License-Identifier: BSD-2-Clause
 *)

theory jiraver150
imports "AutoCorres2.CTranslation"
begin


declare [[use_anonymous_local_variables=true]]
  install_C_file "jiraver150.c"

context jiraver150_simpl
begin



  thm f_body_def
  thm f2_body_def
  thm g_body_def
  thm h_body_def

  lemma (in f_impl) "\<Gamma> \<turnstile> \<lbrace> True \<rbrace> \<acute>unsigned'local0 :== CALL f(1) \<lbrace> \<acute>unsigned'local0 = 2 \<rbrace>"
  apply vcg
  apply (simp add: scast_id)
  done

  end

end
