(*
 * Copyright 2020, Data61, CSIRO (ABN 41 687 119 230)
 *
 * SPDX-License-Identifier: BSD-2-Clause
 *)

theory modifies_speed
imports "AutoCorres2.CTranslation"
begin

text \<open>Speed test for modifies proofs.\<close>

ML \<open>

local
fun filename_relative thy name =
    Path.append (Resources.master_directory thy) (Path.explode name)
    |> File.standard_path

val fN =  filename_relative @{theory} "modifies_speed.c"
val file_exists = is_some (try (TextIO.closeIn o TextIO.openIn) fN)
in

fun write_speed_test_file n_globs n_funcs = if file_exists then () else let
    val f = fN
      |> TextIO.openOut
    fun write_global n = TextIO.output (f, "int global" ^ string_of_int n
      ^ ";\n")
    fun write_func_h n = TextIO.output (f, "int\nfoo" ^ string_of_int n
      ^ " (int x) {\n\n")
    fun write_upd_global n = TextIO.output (f, "  global" ^ string_of_int n
      ^ " = x;\n")
    fun write_fun_call n = TextIO.output (f, "  foo" ^ string_of_int n
      ^ " (x);\n")
    fun write_func_t () = TextIO.output (f, "\n  return x;\n}\n")
    fun write_func n = let
        val globs = filter
          (fn y => IntInf.andb (n, IntInf.<< (1, Word.fromInt y)) = 0)
          (1 upto n_globs)
        val funs = filter (fn y => n mod y = 0) (3 upto (n - 1))
      in write_func_h n; List.app write_upd_global globs;
        List.app write_fun_call funs; write_func_t () end
  in
    List.app write_global (1 upto n_globs);
    List.app write_func (1 upto n_funcs);
    TextIO.closeOut f
  end
end
\<close>

ML \<open>
write_speed_test_file 10 40
\<close>

declare [[sorry_modifies_proofs = false]]

install_C_file "modifies_speed.c"

end
