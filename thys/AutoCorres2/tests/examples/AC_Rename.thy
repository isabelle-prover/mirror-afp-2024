(*
 * Copyright 2020, Data61, CSIRO (ABN 41 687 119 230)
 * Copyright (c) 2022 Apple Inc. All rights reserved.
 *
 * SPDX-License-Identifier: BSD-2-Clause
 *)

(*
 * AutoCorres allows you to change how names are generated for
 * functions and globals.
 *)
theory AC_Rename imports
  "AutoCorres2_Main.AutoCorres_Main"
begin


declare [[allow_underscore_idents]]
install_C_file "rename.c"

autocorres [
  (* Prefix function names with "ac_". *)
  function_name_prefix="ac_",

  (* Prefix AutoCorres global variable names with "my_". *)
  lifted_globals_field_prefix="my_",

  (* These are the default suffixes for names. *)
  function_name_suffix="'",
  lifted_globals_field_suffix="_''"
  ] "rename.c"


context rename_all_corres begin

(* Names of C-parser function definitions *)
thm StrictC'__get_real_var___body_def
thm StrictC'__set_real_var___body_def

(* Names of AutoCorres function definitions *)
thm ac_StrictC'__get_real_var__'_def
thm ac_StrictC'__set_real_var__'_def
(* Intermediate function definitions *)
thm l1_ac_StrictC'__get_real_var__'_def
    l2_ac_StrictC'__get_real_var__'_def
    hl_ac_StrictC'__get_real_var__'_def
    wa_ac_StrictC'__get_real_var__'_def
thm l1_ac_StrictC'__set_real_var__'_def
    l2_ac_StrictC'__set_real_var__'_def
    hl_ac_StrictC'__set_real_var__'_def
    wa_ac_StrictC'__set_real_var__'_def

(* Name of C-parser global variable *)
term "globals.StrictC'__real_var___'"

(* Name of AutoCorres lifted global variable *)
term lifted_globals.my_StrictC'__real_var___''

(* Note that AutoCorres currently doesn't strip the "StrictC'" prefix
 * generated by allow_underscore_idents. *)

end

end
