(*
 * Copyright 2020, Data61, CSIRO (ABN 41 687 119 230)
 * Copyright (c) 2022 Apple Inc. All rights reserved.
 *
 * SPDX-License-Identifier: BSD-2-Clause
 *)

theory ArchArraysMemInstance
imports "ArraysMemInstance"
begin

(* Showing arrays are in xmem_contained_type requires maximum sizes for objects,
   and maximum counts for elements *)
class array_outer_max_size = xmem_contained_type +
  assumes array_outer_max_size_ax: "size_of TYPE('a) < 2 ^ array_outer_max_size_exponent"

class array_max_count = finite +
  assumes array_max_count_ax: "CARD ('a) <= 2 ^ array_outer_max_count_exponent"

instance array :: (array_outer_max_size, array_max_count) mem_type
apply intro_classes
apply simp
apply (subgoal_tac "addr_card = 2 ^ (addr_bitsize - array_outer_max_size_exponent) * 2 ^ array_outer_max_size_exponent")
  apply (erule ssubst)
  apply (rule less_le_trans[where y = "card (UNIV::'b set) * 2 ^ array_outer_max_size_exponent"])
    apply (rule mult_less_mono2)
      apply (rule array_outer_max_size_ax)
    apply simp
  apply (rule mult_le_mono1)
    apply (rule le_trans[where j = "2 ^ array_outer_max_count_exponent"])
      apply (rule array_max_count_ax)
    apply simp
  apply simp
apply (simp add: addr_card)
done


instance array :: (array_outer_max_size, array_max_count) xmem_contained_type
  apply intro_classes
      apply (rule wf_component_descs_array)
     apply (rule component_descs_independent_array)
    apply (rule wf_field_descs_array)
   apply (rule wf_padding_array)
  apply (rule contained_field_descs_array)
  done


class array_inner_max_size = array_outer_max_size +
  assumes array_inner_max_size_ax: "size_of TYPE('a) < 2 ^ array_inner_max_size_exponent"

instance array :: (array_inner_max_size, array_max_count) array_outer_max_size
apply intro_classes
apply simp
  apply (rule order_less_le_trans)
   apply (rule mult_le_less_imp_less)
    apply (rule array_max_count_ax)
   apply (rule array_inner_max_size_ax)
  apply simp
   apply simp
  apply simp
  done

instance word :: (len8) array_outer_max_size
apply intro_classes
apply(simp add: size_of_def)
apply(subgoal_tac "len_of TYPE('a) \<le> 128")
 apply simp
apply(rule len8_width)
done

instance word :: (len8) array_inner_max_size
apply intro_classes
apply(simp add: size_of_def)
apply(subgoal_tac "len_of TYPE('a) \<le> 128")
 apply simp
apply(rule len8_width)
done

instance ptr :: (c_type) array_outer_max_size
apply intro_classes
apply (simp add: size_of_def)
done

instance ptr :: (c_type) array_inner_max_size
apply intro_classes
apply (simp add: size_of_def)
done

class lt19 = finite +
  assumes lt19_ax: "CARD ('a) < 2 ^ 19"
class lt18 = lt19 +
  assumes lt18_ax: "CARD ('a) < 2 ^ 18"
class lt17 = lt18 +
  assumes lt17_ax: "CARD ('a) < 2 ^ 17"
class lt16 = lt17 +
  assumes lt16_ax: "CARD ('a) < 2 ^ 16"
class lt15 = lt16 +
  assumes lt15_ax: "CARD ('a) < 2 ^ 15"
class lt14 = lt15 +
  assumes lt14_ax: "CARD ('a) < 2 ^ 14"
class lt13 = lt14 +
  assumes lt13_ax: "CARD ('a) < 2 ^ 13"
class lt12 = lt13 +
  assumes lt12_ax: "CARD ('a) < 2 ^ 12"
class lt11 = lt12 +
  assumes lt11_ax: "CARD ('a) < 2 ^ 11"
class lt10 = lt11 +
  assumes lt10_ax: "CARD ('a) < 2 ^ 10"
class lt9 = lt10 +
  assumes lt9_ax: "CARD ('a) < 2 ^ 9"
class lt8 = lt9 +
  assumes lt8_ax: "CARD ('a) < 2 ^ 8"
class lt7 = lt8 +
  assumes lt7_ax: "CARD ('a) < 2 ^ 7"
class lt6 = lt7 +
  assumes lt6_ax: "CARD ('a) < 2 ^ 6"
class lt5 = lt6 +
  assumes lt5_ax: "CARD ('a) < 2 ^ 5"
class lt4 = lt5 +
  assumes lt4_ax: "CARD ('a) < 2 ^ 4"
class lt3 = lt4 +
  assumes lt3_ax: "CARD ('a) < 2 ^ 3"
class lt2 = lt3 +
  assumes lt2_ax: "CARD ('a) < 2 ^ 2"
class lt1 = lt2 +
  assumes lt1_ax: "CARD ('a) < 2 ^ 1"


instance bit0 :: (lt19) array_max_count
  using lt19_ax[where 'a='a] if_architecture_by (ARM64, RISCV64, X64) intro_classes simp

instance bit1 :: (lt19) array_max_count
  using lt19_ax[where 'a='a] if_architecture_by (ARM64, RISCV64, X64) intro_classes simp

instance bit0 :: (lt18) lt19
  using lt18_ax[where 'a='a] if_architecture_by (ARM64, RISCV64, X64) intro_classes simp

instance bit1 :: (lt18) lt19
  using lt18_ax[where 'a='a] if_architecture_by (ARM64, RISCV64, X64) intro_classes simp

instance bit0 :: (lt17) lt18
  using lt17_ax[where 'a='a] if_architecture_by (ARM64, RISCV64, X64) intro_classes simp

instance bit1 :: (lt17) lt18
  using lt17_ax[where 'a='a] if_architecture_by (ARM64, RISCV64, X64) intro_classes simp

instance bit0 :: (lt16) lt17
  using lt16_ax[where 'a='a] if_architecture_by (ARM64, RISCV64, X64) intro_classes simp

instance bit1 :: (lt16) lt17
  using lt16_ax[where 'a='a] if_architecture_by (ARM64, RISCV64, X64) intro_classes simp

instance bit0 :: (lt15) lt16
  using lt15_ax[where 'a='a] if_architecture_by (ARM64, RISCV64, X64) intro_classes simp

instance bit1 :: (lt15) lt16
  using lt15_ax[where 'a='a] if_architecture_by (ARM64, RISCV64, X64) intro_classes simp

instance bit0 :: (lt14) lt15
  using lt14_ax[where 'a='a] if_architecture_by (ARM64, RISCV64, X64) intro_classes simp

instance bit1 :: (lt14) lt15
  using lt14_ax[where 'a='a] if_architecture_by (ARM64, RISCV64, X64) intro_classes simp

instance bit0 :: (lt13) lt14
  using lt13_ax[where 'a='a] if_architecture_by (ARM64, RISCV64, X64) intro_classes simp

instance bit1 :: (lt13) lt14
  using lt13_ax[where 'a='a] if_architecture_by (ARM64, RISCV64, X64) intro_classes simp

instance bit0 :: (lt12) lt13
  using lt12_ax[where 'a='a] if_architecture_by (ARM64, RISCV64, X64) intro_classes simp

instance bit1 :: (lt12) lt13
  using lt12_ax[where 'a='a] if_architecture_by (ARM64, RISCV64, X64) intro_classes simp

(*
ML \<open>
val _ = Thm.consolidate_theory @{theory}
\<close>
*)
instance bit0 :: (lt12) array_max_count
  using lt12_ax[where 'a='a] if_architecture_by (ARM, ARM_HYP) intro_classes simp

instance bit1 :: (lt12) array_max_count
  using lt12_ax[where 'a='a] if_architecture_by (ARM, ARM_HYP)  intro_classes simp

instance bit0 :: (lt11) lt12
  using lt11_ax[where 'a='a] by intro_classes simp_all

instance bit1 :: (lt11) lt12
  using lt11_ax[where 'a='a] by intro_classes simp_all

instance bit0 :: (lt10) lt11
  using lt10_ax[where 'a='a] by intro_classes simp_all

instance bit1 :: (lt10) lt11
  using lt10_ax[where 'a='a] by intro_classes simp_all

instance bit0 :: (lt9) lt10
  using lt9_ax[where 'a='a] by intro_classes simp_all

instance bit1 :: (lt9) lt10
  using lt9_ax[where 'a='a] by intro_classes simp_all

instance bit0 :: (lt8) lt9
  using lt8_ax[where 'a='a] by intro_classes simp_all

instance bit1 :: (lt8) lt9
  using lt8_ax[where 'a='a] by intro_classes simp_all

instance bit0 :: (lt7) lt8
  using lt7_ax[where 'a='a] by intro_classes simp_all

instance bit1 :: (lt7) lt8
  using lt7_ax[where 'a='a] by intro_classes simp_all

instance bit0 :: (lt6) lt7
  using lt6_ax[where 'a='a] by intro_classes simp_all

instance bit1 :: (lt6) lt7
  using lt6_ax[where 'a='a] by intro_classes simp_all

instance bit0 :: (lt5) lt6
  using lt5_ax[where 'a='a] by intro_classes simp_all

instance bit1 :: (lt5) lt6
  using lt5_ax[where 'a='a] by intro_classes simp_all

instance bit0 :: (lt4) lt5
  using lt4_ax[where 'a='a] by intro_classes simp_all

instance bit1 :: (lt4) lt5
  using lt4_ax[where 'a='a] by intro_classes simp_all

instance bit0 :: (lt3) lt4
  using lt3_ax[where 'a='a] by intro_classes simp_all

instance bit1 :: (lt3) lt4
  using lt3_ax[where 'a='a] by intro_classes simp_all

instance bit0 :: (lt2) lt3
  using lt2_ax[where 'a='a] by intro_classes simp_all

instance bit1 :: (lt2) lt3
  using lt2_ax[where 'a='a] by intro_classes simp_all

instance bit0 :: (lt1) lt2
  using lt1_ax[where 'a='a] by intro_classes simp_all

instance bit1 :: (lt1) lt2
  using lt1_ax[where 'a='a] by intro_classes simp_all

instance num1 :: lt1
  by (intro_classes, simp_all)

(* don't understand why this also seems to be necessary *)

instance num1 :: array_max_count
  by (intro_classes, simp)

end
