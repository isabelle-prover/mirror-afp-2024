(*
 * Copyright 2020, Data61, CSIRO (ABN 41 687 119 230)
 * Copyright (c) 2022 Apple Inc. All rights reserved.
 *
 * SPDX-License-Identifier: BSD-2-Clause
 *)

theory phantom_mstate
imports "AutoCorres2.CTranslation"
begin

install_C_file "phantom_mstate.c" [machinety=bool]

context phantom_mstate_simpl
begin

  thm machine_proto_body_def
  thm proto2_body_def

  thm f_body_def
  thm g_body_def

  thm f_modifies
  thm g_modifies
  thm machine_proto_modifies
  thm proto2_modifies

  term phantom_machine_state_'
end

end
