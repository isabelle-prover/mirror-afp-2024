(*
 * Copyright 2020, Data61, CSIRO (ABN 41 687 119 230)
 * Copyright (c) 2022 Apple Inc. All rights reserved.
 *
 * SPDX-License-Identifier: BSD-2-Clause
 *)

theory asm_stmt

imports "AutoCorres2.CTranslation"

begin

declare [[populate_globals=true]]

typedecl machine_state
typedecl cghost_state

install_C_file "asm_stmt.c"
  [machinety=machine_state, ghostty=cghost_state]

context asm_stmt_simpl begin

thm f_body_def
thm f_modifies
thm combine_body_def
thm combine_modifies

end

end
