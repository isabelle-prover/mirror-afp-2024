(*
 * Copyright 2020, Data61, CSIRO (ABN 41 687 119 230)
 * Copyright (c) 2022 Apple Inc. All rights reserved.
 *
 * SPDX-License-Identifier: BSD-2-Clause
 *)

theory LemmaBucket_C
imports
  More_Lib
  WordSetup
  TypHeapLib
  ArrayAssertion
begin

declare word_neq_0_conv [simp del]

lemma Ptr_not_null_pointer_not_zero: "(Ptr p \<noteq> NULL)=(p\<noteq>0)"
 by simp

lemma hrs_mem_f: "f (hrs_mem s) = hrs_mem (hrs_mem_update f s)"
  apply (cases s)
  apply (clarsimp simp: hrs_mem_def hrs_mem_update_def)
  done

lemma hrs_mem_heap_update:
     "heap_update p v (hrs_mem s) = hrs_mem (hrs_mem_update (heap_update p v) s)"
  apply (rule hrs_mem_f)
  done

lemma surj_Ptr [simp]:
  "surj Ptr"
  by (rule surjI [where f = ptr_val], simp)

lemma inj_Ptr [simp]:
  "inj Ptr"
  apply (rule injI)
  apply simp
  done

lemma bij_Ptr :
  "bij Ptr"
  by (simp add: bijI)

lemma exec_Guard:
  "(G \<turnstile> \<langle>Guard Err S c, Normal s\<rangle> \<Rightarrow> s')
       = (if s \<in> S then G \<turnstile> \<langle>c, Normal s\<rangle> \<Rightarrow> s'
                else s' = Fault Err)"
  by (auto split: if_split elim!: exec_elim_cases intro: exec.intros)

lemma byte_ptr_guarded:"ptr_val (x::8 word ptr) \<noteq> 0 \<Longrightarrow> c_guard x"
  unfolding c_guard_def c_null_guard_def ptr_aligned_def
  by (clarsimp simp: intvl_Suc)

lemma intvl_aligned_bottom_eq:
  fixes p :: "'a::len word"
  assumes al1: "is_aligned x n"
  and     al2: "is_aligned p bits"
  and      nb: "\<not> n < bits"
  and     off: "off \<le> 2 ^ bits" "off \<noteq> 0"
  shows  "(x \<in> {p ..+ off}) = (x = p)"
proof (rule iffI)
  assume "x = p"
  thus "x \<in> {p ..+ off}" using off
    by (simp add: intvl_self)
next
  assume x_in_intvl: "x \<in> {p ..+ off}"

  show "x = p"
  proof cases
    assume wb: "bits < len_of TYPE('a)"

    from x_in_intvl obtain kp where xp: "x = p + of_nat kp" and kp: "kp < off"
      by (clarsimp dest!: intvlD)

    hence "is_aligned (p + of_nat kp) n" using al1 by simp
    hence "2 ^ n dvd unat (p + of_nat kp)" unfolding is_aligned_def .
    hence "2 ^ n dvd unat p + kp" using kp off wb
      apply -
      apply (subst (asm) iffD1 [OF unat_plus_simple])
       apply (rule is_aligned_no_wrap' [OF al2])
       apply (rule of_nat_power)
        apply simp_all[2]
      apply (subst (asm) unat_of_nat)
      apply (subst (asm) mod_less)
       apply (erule order_less_le_trans)
       apply (erule order_trans)
       apply simp
      apply simp
      done

  moreover from al2 obtain q2 where pbits: "p = 2 ^ bits * of_nat q2"
                                and q2: "q2 < 2 ^ (len_of TYPE('a) - bits)"
    by (rule is_alignedE)

  moreover from nb obtain kn where nbits: "n = bits + kn"
    by (clarsimp simp: linorder_not_less le_iff_add)

  ultimately have "2 ^ bits dvd 2 ^ bits * q2 + kp"
    apply (simp add: power_add)
    apply (simp add: unat_mult_power_lem [OF q2])
    apply (erule dvd_mult_left)
    done

  hence "2 ^ bits dvd kp" by (simp add: dvd_reduce_multiple)
  with kp have "kp = 0"
    apply -
    apply (erule contrapos_pp)
    apply (simp add: linorder_not_less)
    apply (drule (1) dvd_imp_le)
    apply (erule order_trans [OF off(1)])
    done

  thus ?thesis using xp by simp
  next
    assume wb: "\<not> bits < len_of TYPE('a)"
    with assms
    show ?thesis by (simp add: is_aligned_mask mask_def power_overflow)
  qed
qed

lemma intvl_mem_weaken: "x \<in> {p..+a - n} \<Longrightarrow> x \<in> {p..+a}"
  apply -
  apply (drule intvlD)
  apply clarsimp
  apply (rule intvlI)
  apply simp
  done


lemma upto_intvl_eq:
  fixes x :: "'a::len word"
  assumes al: "is_aligned x n"
  shows "{x..+2 ^ n} = {x .. x + 2 ^ n - 1}"
proof cases
  assume "n < len_of TYPE('a)"
  with assms show ?thesis
  unfolding intvl_def
  apply simp
  apply standard
   apply clarsimp
   apply (subgoal_tac "of_nat k < (2 :: 'a word) ^ n")
    apply (intro conjI)
     apply (erule (1) is_aligned_no_wrap')
    apply (subst p_assoc_help)
    apply (rule word_plus_mono_right)
     apply (simp add: word_less_sub_1)
    apply (simp add: field_simps is_aligned_no_overflow)
   apply (simp add: of_nat_power)
  apply clarsimp
  subgoal for xa
    apply (rule exI[where x = "unat (xa - x)"])
    apply clarsimp
    apply (rule unat_less_power, assumption)
    apply (subst word_less_sub_le [symmetric])
     apply assumption
    apply (rule word_diff_ls'(4))
     apply (simp add: field_simps)
    apply assumption
    done
  done
next
  assume "\<not> n < len_of TYPE('a)"
  with assms show ?thesis
    apply (simp add: is_aligned_mask mask_def power_overflow intvl_def)
    apply (rule set_eqI)
    apply clarsimp
     by (metis (no_types, opaque_lifting) le_less_trans nat_power_less_imp_less not_le power_eq_0_iff 
   power_zero_numeral unat_lt2p word_unat.Rep_inverse)
qed


lemma upto_intvl_eq':
  fixes x :: "'a :: len word"
  shows "\<lbrakk> x \<le> x + (of_nat b - 1); b \<noteq> 0; b \<le> 2 ^ len_of TYPE('a)\<rbrakk> \<Longrightarrow> {x..+b} = {x .. x + of_nat b - 1}"
  unfolding intvl_def
  supply unsigned_of_nat  
  apply standard
   apply clarsimp
   apply (subgoal_tac "of_nat k \<le> (of_nat (b - 1) :: 'a word)")
    apply (intro conjI)
     apply (erule word_random)
     apply simp
    apply (subst field_simps [symmetric], rule word_plus_mono_right)
     apply simp
    apply assumption
   apply (subst More_Word.of_nat_mono_maybe_le [symmetric])
     apply simp
    apply simp
   apply simp
  apply clarsimp
  subgoal for xa
    apply (rule exI[where x = "unat (xa - x)"])
    apply simp
    apply (simp add: unat_sub)
    apply (rule nat_diff_less)
     apply (subst (asm) word_le_nat_alt, erule order_le_less_trans)
     apply (subst add_diff_eq[symmetric], subst unat_plus_if')
     apply (simp add: no_olen_add_nat)
     apply (simp add: le_eq_less_or_eq)
     apply (erule disjE)
      apply (subst unat_minus_one)
       apply (erule (1) of_nat_neq_0)
      apply (simp add: unat_of_nat)
     apply (erule ssubst, rule unat_lt2p)
    apply (simp add: word_le_nat_alt)
    done
  done

lemma intvl_aligned_top:
  fixes x :: "'a::len word"
  assumes al1: "is_aligned x n"
  and     al2: "is_aligned p bits"
  and      nb: "n \<le> bits"
  and    offn: "off < 2 ^ n"
  and      wb: "bits < len_of TYPE('a)"
  shows  "(x \<in> {p ..+ 2 ^ bits - off}) = (x \<in> {p ..+ 2 ^ bits})"
proof (rule iffI)
  assume "x \<in> {p..+2 ^ bits - off}"
  thus "x \<in> {p..+2 ^ bits}" by (rule intvl_mem_weaken)
next
  assume asm: "x \<in> {p..+2 ^ bits}"

  show "x \<in> {p..+2 ^ bits - off}"
  proof (cases "n = 0")
    case True
    with offn asm show ?thesis by simp
  next
    case False

    from asm have "x \<in> {p .. p + 2 ^ bits - 1}"
      by (simp add: upto_intvl_eq [OF al2])
    then obtain q where xp: "x = p + of_nat (q * 2 ^ n)" and qb: "q < 2 ^ (bits - n)" using False nb
      by (fastforce dest!: is_aligned_diff[OF al1 al2 wb,simplified field_simps])

    have "q * 2 ^ n < 2 ^ bits - off"
    proof -
      show ?thesis using offn qb nb
        apply (simp add: less_diff_conv)
        apply (erule (1) nat_add_offset_less)
        apply arith
        done
    qed

    with xp show ?thesis
      apply -
      apply (erule ssubst)
      apply (erule intvlI)
      done
  qed
qed



lemma heap_update_list_update:
  fixes v :: word8
  shows "x \<noteq> y \<Longrightarrow> heap_update_list s xs (hp(y := v)) x = heap_update_list s xs hp x"
  apply (induct xs rule: rev_induct)
   apply simp
  apply (simp add: heap_update_list_append cong: if_cong)
  done

(* FIXME: generalise *)
lemma heap_update_list_append2:
  "length xs + length ys < 2 ^ word_bits \<Longrightarrow>
    heap_update_list s (xs @ ys) hp
      = heap_update_list s xs (heap_update_list (s + of_nat (length xs)) ys hp)"
proof (induct xs arbitrary: hp s)
  case Nil
  show ?case by simp
next
  case (Cons v' vs')

  have "(1 :: addr) + of_nat (length vs') = of_nat (length (v' # vs'))"
    by simp
  also have "\<dots> \<noteq> 0" using Cons.prems
    apply -
    apply (rule of_nat_neq_0)
    apply simp
    apply (simp add: word_bits_conv)
    done
  finally have neq0: "(1 :: addr) + of_nat (length vs') \<noteq> 0" .

  have "(1 :: addr) + of_nat (length vs') = of_nat (length (v' # vs'))"
    by simp
  also have "unat \<dots> + length ys < 2 ^ word_bits" using Cons.prems
    apply (subst unat_of_nat)
    apply (simp add: word_bits_conv)
    done
  finally have lt: "unat ((1 :: addr) + of_nat (length vs')) + length ys < 2 ^ word_bits" .

  from Cons.prems have "length vs' + length ys < 2 ^ word_bits" by simp
  thus ?case
    apply simp
    apply (subst Cons.hyps, assumption)
    apply (rule arg_cong [where f = "heap_update_list (s + 1) vs'"])
    apply (rule ext)
    subgoal for x
      apply (cases "x = s")
       apply simp
       apply (subst heap_update_nmem_same)
        apply (subst add.assoc)
        apply (rule intvl_nowrap[OF neq0 order_less_imp_le
            [OF lt[unfolded word_bits_def]]])
       apply simp
      apply (clarsimp simp: heap_update_list_update field_simps)
      done
    done
qed

lemma heap_update_word8:
  "heap_update p (v :: word8) hp = hp(ptr_val p := v)"
  unfolding heap_update_def by (simp add: to_bytes_word8)

lemma index_foldr_update2:
  "\<lbrakk> n \<le> i; i < CARD('b::finite) \<rbrakk> \<Longrightarrow> index (foldr (\<lambda>n arr. Arrays.update arr n m) [0..<n] (x :: ('a,'b) array)) i = index x i"
  apply (induct n arbitrary: x)
   apply simp
  apply simp
  done

lemma index_foldr_update:
  "\<lbrakk> i < n; n \<le> CARD('b::finite) \<rbrakk> \<Longrightarrow> index (foldr (\<lambda>n arr. Arrays.update arr n m) [0..<n]  (x :: ('a,'b) array)) i = m"
  apply (induct n arbitrary: x)
   apply simp
  apply simp
  apply (erule less_SucE)
   apply simp
  apply simp
  apply (subst index_foldr_update2)
    apply simp
   apply simp
  apply simp
  done

lemma intvl_disjoint1:
  fixes a :: "'a :: len word"
  assumes abc: "a + of_nat b \<le> c"
  and     alb: "a \<le> a + of_nat b"
  and     cld: "c \<le> c + of_nat d"
  and     blt: "b < 2 ^ len_of TYPE('a)"
  and     dlt: "d < 2 ^ len_of TYPE('a)"
  shows   "{a..+b} \<inter> {c..+d} = {}"
proof (rule disjointI, rule notI)
  fix x y
  assume x: "x \<in> {a..+b}" and y: "y \<in> {c..+d}" and xy: "x = y"

  from x obtain kx where "x = a + of_nat kx" and kx: "kx < b"
    by (clarsimp dest!: intvlD)

  moreover from y obtain ky where "y = c + of_nat ky" and ky: "ky < d"
    by (clarsimp dest!: intvlD)

  ultimately have ac: "a + of_nat kx = c + of_nat ky" using xy by simp

  have "of_nat kx < (of_nat b :: 'a word)" using blt kx
    by (rule of_nat_mono_maybe)
  hence "a + of_nat kx < a + of_nat b" using alb
    by (rule word_plus_strict_mono_right)

  also have "\<dots> \<le> c" by (rule abc)
  also have "\<dots> \<le> c + of_nat ky" using cld dlt ky
    by - (rule word_random [OF _ iffD1 [OF More_Word.of_nat_mono_maybe_le]], simp+ )
  finally show False using ac by simp
qed

lemma intvl_disjoint2:
  fixes a :: "'a :: len word"
  assumes abc: "a + of_nat b \<le> c"
  and     alb: "a \<le> a + of_nat b"
  and     cld: "c \<le> c + of_nat d"
  and     blt: "b < 2 ^ len_of TYPE('a)"
  and     dlt: "d < 2 ^ len_of TYPE('a)"
  shows   "{c..+d} \<inter> {a..+b} = {}"
  using abc alb cld blt dlt
  by (subst Int_commute, rule intvl_disjoint1)

lemma typ_slice_t_self:
  "td \<in> fst ` set (typ_slice_t td m)"
  apply (cases td)
  apply (simp split: if_split)
  done

lemma index_fold_update:
  "\<lbrakk> distinct xs; set xs \<subseteq> {..< card (UNIV :: 'b set)}; n < card (UNIV :: 'b set) \<rbrakk> \<Longrightarrow>
   index (foldr (\<lambda>n (arr :: 'a['b :: finite]). Arrays.update arr n (f n (index arr n))) xs v) n
     = (if n \<in> set xs then f n (index v n) else index v n)"
  apply (induct xs)
   apply simp
  subgoal for x xs by (cases "x = n", auto)
  done


(*
lemma size_td_list_map2: "\<And>f adjs. \<lbrakk> \<And>a. size_td_pair (f a) = size_td_pair a \<rbrakk>
                           \<Longrightarrow> size_td_list (map f adjs) = size_td_list adjs"
  by (induct_tac adjs, simp_all)
*)
lemma hrs_mem_update_cong:
  "\<lbrakk> \<And>x. f x = f' x \<rbrakk> \<Longrightarrow> hrs_mem_update f = hrs_mem_update f'"
  by (simp add: hrs_mem_update_def)

lemma Guard_no_cong:
  "\<lbrakk> A=A'; c=c' \<rbrakk> \<Longrightarrow> Guard A P c = Guard A' P c'"
  by simp


lemma coerce_heap_update_to_heap_updates:
  assumes n: "n = chunk * m" and len: "length xs = n"
  shows "heap_update_list x xs
      = (\<lambda>s. foldl (\<lambda>s n. heap_update_list (x + (of_nat n * of_nat chunk))
                                      (take chunk (drop (n * chunk) xs)) s)
                     s [0 ..< m])"
  using len[simplified n]
  apply (induct m arbitrary: x xs)
   apply (rule ext, simp)
  apply (rule ext)
  subgoal for m x xs s
    apply (simp only: upt_conv_Cons map_Suc_upt[symmetric])
    apply (subgoal_tac "\<exists>ys zs. length ys = chunk \<and> xs = ys @ zs")
     apply (clarsimp simp: heap_update_list_concat_unfold foldl_map
        field_simps)
    apply (rule exI[where x="take chunk xs"])
    apply (rule exI[where x="drop chunk xs"])
    apply simp
    done
  done

lemma update_ti_list_array':
  "\<lbrakk> update_ti_list_t (map f [0 ..< n]) xs v = y;
     \<forall>n. size_td_tuple (f n) = v3; length xs = v3 * n;
     \<forall>m xs v'. length xs = v3 \<and> m < n \<longrightarrow>
       update_ti_tuple_t (f m) xs v' = Arrays.update v' m (update_ti_t (g m) xs (index v' m)) \<rbrakk>
    \<Longrightarrow> y = foldr (\<lambda>n arr. Arrays.update arr n (update_ti_t (g n) (take v3 (drop (v3 * n) xs)) (index arr n))) [0 ..< n] v"
  apply (subgoal_tac "\<forall>ys. size_td_list (map f ys) = v3 * length ys")
   prefer 2
  apply (rule allI)
  subgoal for ys by (induct ys) auto
  apply (induct n arbitrary: xs y v)
   apply simp
  apply (simp add: access_ti_append)
  apply (elim meta_allE, drule(1) meta_mp)
  apply simp
  apply (rule foldr_cong, (rule refl)+)
  apply (simp add: take_drop)
  apply (subst min.absorb1)
   apply (fold mult_Suc_right, rule mult_le_mono2)
   apply simp
  apply simp
  done

lemma update_ti_list_array:
  "\<lbrakk> update_ti_list_t (map f [0 ..< n]) xs v = (y :: 'a['b :: finite]);
     \<forall>n. size_td_tuple (f n) = v3; length xs = v3 * n;
     \<forall>m xs v'. length xs = v3 \<and> m < n \<longrightarrow>
       update_ti_tuple_t (f m) xs v' = Arrays.update v' m (update_ti_t (g m) xs (index v' m));
      n \<le> card (UNIV :: 'b set) \<rbrakk>
    \<Longrightarrow> \<forall>m < n. update_ti_t (g m) (take v3 (drop (v3 * m) xs)) (index v m) = index y m"
  apply (subst update_ti_list_array'[where y=y], assumption+)
  apply clarsimp
  apply (subst index_fold_update)
     apply clarsimp+
  done

lemma access_in_array:
  fixes y :: "('a :: c_type)['b :: finite]"
  assumes assms: "h_val hp x = y"
                 "n < card (UNIV :: 'b set)"
     and subst: "\<forall>xs v. length xs = size_of TYPE('a)
                     \<longrightarrow> update_ti_t (typ_info_t TYPE('a)) xs v = f xs"
  shows "h_val hp
           (Ptr (ptr_val x + of_nat (n * size_of TYPE('a)))) = index y n"
  using assms
  apply (simp add: h_val_def drop_heap_list_le2 del: of_nat_mult)
  apply (subst take_heap_list_le[symmetric, where n="card (UNIV :: 'b set) * size_of TYPE ('a)"])
   apply (fold mult_Suc, rule mult_le_mono1)
   apply simp
  apply (simp add: from_bytes_def typ_info_array')
  apply (drule update_ti_list_array, simp+)
     apply (simp add: size_of_def)
    apply (clarsimp simp: update_ti_s_adjust_ti)
    apply (rule refl)
   apply simp
  apply (drule spec, drule(1) mp)
  apply (simp add: size_of_def ac_simps drop_take)
  apply (subgoal_tac "length v = size_of TYPE('a)" for v)
   apply (subst subst, assumption)
   apply (subst(asm) subst, assumption)
   apply simp
  apply (simp add: size_of_def)
  apply (subst le_diff_conv2)
   apply simp
  apply (fold mult_Suc, rule mult_le_mono1)
  apply simp
  done

lemma access_ti_list_array:
  "\<lbrakk> \<forall>n. size_td_tuple (f n) = v3; length xs = v3 * n;
     \<forall>m. m < n \<and> v3 \<le> length (drop (v3 * m) xs)
        \<longrightarrow> access_ti_tuple (f m) (FCP g) (take v3 (drop (v3 * m) xs)) = (h m)
          \<rbrakk> \<Longrightarrow>
   access_ti_list (map f [0 ..< n]) (FCP g) xs
     = foldl (@) [] (map h [0 ..< n])"
  apply (subgoal_tac "\<forall>ys. size_td_list (map f ys) = v3 * length ys")
   prefer 2
   apply (rule allI)
  subgoal for ys by (induct ys, simp+)
  apply (induct n arbitrary: xs)
   apply simp
  apply (simp add: access_ti_append)
  apply (erule_tac x="take (v3 * n) xs" in meta_allE)
  apply simp
  apply (frule spec, drule mp, rule conjI, rule lessI)
   apply simp
  apply simp
  apply (erule meta_mp)
  apply (auto simp add: drop_take)
  done

lemma take_drop_foldl_concat:
  "\<lbrakk> \<And>y. y < m \<Longrightarrow> length (f y) = n; x < m \<rbrakk>
      \<Longrightarrow> take n (drop (x * n) (foldl (@) [] (map f [0 ..< m]))) = f x"
  apply (subst split_upt_on_n, assumption)
  apply (simp only: foldl_concat_concat map_append)
  apply (subst drop_append_miracle)
   apply (induct x, simp_all)[1]
  apply simp
  done


lemma heap_update_Array:
  "heap_update (p ::('a::packed_type['b::finite]) ptr) arr
     = (\<lambda>s. foldl (\<lambda>s n. heap_update (array_ptr_index p False n)
                                     (Arrays.index arr n) s) s [0 ..< card (UNIV :: 'b set)])"
  apply (rule ext, simp add: heap_update_def)
  apply (subst coerce_heap_update_to_heap_updates
      [OF _ refl, where chunk="size_of TYPE('a)" and m="card (UNIV :: 'b set)"])
   apply (simp)
  apply (rule foldl_cong[OF refl refl])
  apply (simp add: array_ptr_index_def CTypesDefs.ptr_add_def)
  subgoal for s a x
    apply (rule arg_cong[where f="\<lambda>xs. heap_update_list p xs s" for p s])
    apply (simp add: to_bytes_def size_of_def
        packed_type_access_ti)
    apply (simp add: typ_info_array')
    apply (subst fcp_eta[symmetric], subst access_ti_list_array)
       apply simp
      apply simp
     apply (simp add: packed_type_access_ti size_of_def)
     apply fastforce
    apply (rule take_drop_foldl_concat)
     apply (simp add: size_of_def)
    apply simp
    done
  done

lemma from_bytes_Array_element:
  fixes p :: "('a::mem_type['b::finite]) ptr"
  assumes less: "of_nat n < card (UNIV :: 'b set)"
  assumes len: "length bs = size_of TYPE('a) * CARD('b)"
  shows
  "index (from_bytes bs :: 'a['b]) n
      = from_bytes (take (size_of TYPE('a)) (drop (n * size_of TYPE('a)) bs))"
  using less
  apply (simp add: from_bytes_def size_of_def typ_info_array')
  apply (subst update_ti_list_array'[OF refl])
     apply simp
    apply (simp add: len size_of_def)
   apply (clarsimp simp: update_ti_s_adjust_ti)
   apply (rule refl)
  apply (simp add: split_upt_on_n[OF less])
  apply (rule trans, rule foldr_does_nothing_to_xf[where xf="\<lambda>s. index s n"])
   apply simp+
  apply (subst foldr_does_nothing_to_xf[where xf="\<lambda>s. index s n"])
   apply simp
  apply (simp add: mult.commute)
  apply (frule Suc_leI)
  apply (drule_tac k="size_of TYPE('a)" in mult_le_mono2)
  apply (rule upd_rf)
  apply (simp add: size_of_def len mult.commute)
  done


lemma heap_access_Array_element':
  fixes p :: "('a::mem_type['b::finite]) ptr"
  assumes less: "of_nat n < card (UNIV :: 'b set)"
  shows
  "index (h_val hp p) n
      = h_val hp (array_ptr_index p False n)"
  using less
  apply (simp add: array_ptr_index_def CTypesDefs.ptr_add_def h_val_def)
  apply (simp add: from_bytes_Array_element)
  apply (simp add: drop_heap_list_le take_heap_list_le)
  apply (subst take_heap_list_le)
   apply (simp add: le_diff_conv2)
   apply (drule Suc_leI)
   apply (drule_tac k="size_of TYPE('a)" in mult_le_mono2)
   apply (simp add: mult.commute)
  apply simp
  done

lemmas heap_access_Array_element
    = heap_access_Array_element'[simplified array_ptr_index_simps]

lemma heap_update_id:
  "h_val hp ptr = (v :: 'a :: packed_type)
      \<Longrightarrow> heap_update ptr v hp = hp"
  apply (simp add: h_val_def heap_update_def)
  apply (rule heap_update_list_id'[where n="size_of TYPE('a)"])
  apply clarsimp
  apply (simp add: from_bytes_def to_bytes_def update_ti_t_def
                   size_of_def field_access_update_same
                   td_fafu_idem)
  done


lemma heap_update_Array_update:
  assumes n: "n < CARD('b :: finite)"
  assumes size: "CARD('b) * size_of TYPE('a :: packed_type) < 2 ^ addr_bitsize"
  shows "heap_update p (Arrays.update (arr :: 'a['b]) n v) hp
       = heap_update (array_ptr_index p False n) v (heap_update p arr hp)"
proof -

  have P: "\<And>x k. \<lbrakk> x < CARD('b); k < size_of TYPE('a) \<rbrakk>
         \<Longrightarrow> unat (of_nat x * of_nat (size_of TYPE('a)) + (of_nat k :: addr))
                 = x * size_of TYPE('a) + k"
    using size
    supply unsigned_of_nat
    apply (cases "size_of TYPE('a)", simp_all)
    apply (cases "CARD('b)", simp_all)
    apply (subst unat_add_lem[THEN iffD1])
     apply (simp add: unat_word_ariths unat_of_nat less_Suc_eq_le)
     apply (subgoal_tac "Suc x * size_of TYPE('a) < 2 ^ addr_bitsize", simp_all)
     apply (erule order_le_less_trans[rotated], simp add: add_mono)
    apply (subst unat_mult_lem[THEN iffD1])
     apply (simp add: unat_of_nat unat_add_lem[THEN iffD1])
     apply (rule order_less_le_trans, erule order_le_less_trans[rotated],
            rule add_mono, simp+)
      apply (simp add: less_Suc_eq_le trans_le_add2)
     apply simp
    apply (simp add: unat_of_nat unat_add_lem[THEN iffD1])
    done

  let ?key_upd = "heap_update (array_ptr_index p False n) v"
  note commute = fold_commute_apply[where h="?key_upd"
      and xs="[Suc n ..< CARD('b)]", where g=f' and f=f' for f']

  show ?thesis using n
    apply (simp add: heap_update_Array split_upt_on_n[OF n]
                     foldl_conv_fold)
    apply (subst commute)
     apply (simp_all add: packed_heap_update_collapse
                    cong: fold_cong')
    apply (rule ext, simp)
    subgoal for x
      apply (rule heap_update_commute, simp_all add: ptr_add_def)
      apply (simp add: array_ptr_index_def CTypesDefs.ptr_add_def intvl_def Suc_le_eq)
      apply (rule set_eqI, clarsimp)
      apply (drule word_unat.Rep_inject[THEN iffD2])
      apply (clarsimp simp: P nat_eq_add_iff1)
      apply (cases x, simp_all add: less_Suc_eq_le Suc_diff_le)
      done
    done
qed

lemma heap_update_id_Array:
  fixes arr :: "('a :: packed_type)['b :: finite]"
  shows "arr = h_val hp p
    \<Longrightarrow> heap_update p arr hp = hp"
  apply (simp add: heap_update_Array)
  apply (rule foldl_does_nothing[where s=hp])
  apply (simp add: heap_access_Array_element' heap_update_id)
  done

lemma heap_update_Array_element'':
  fixes p' :: "(('a :: packed_type)['b::finite]) ptr"
  fixes p :: "('a :: packed_type) ptr"
  fixes hp w
  assumes p: "p = array_ptr_index p' False n"
  assumes n: "n < CARD('b)"
  assumes size: "CARD('b) * size_of TYPE('a) < 2 ^ addr_bitsize"
  shows "heap_update p' (Arrays.update (h_val hp p') n w) hp
       = heap_update p w hp"
  apply (subst heap_update_Array_update[OF n size])
  apply (simp add: heap_update_id_Array p)
  done

lemmas heap_update_Array_element'
    = heap_update_Array_element''[simplified array_ptr_index_simps]

lemma array_count_size:
  "CARD('b :: array_max_count) * size_of TYPE('a :: array_outer_max_size) < 2 ^ addr_bitsize"
  using array_outer_max_size_ax[where 'a='a] array_max_count_ax[where 'a='b]
  apply (clarsimp dest!: nat_le_Suc_less_imp)
  apply (drule(1) mult_mono, simp+)
  done

lemmas heap_update_Array_element
    = heap_update_Array_element'[OF refl _ array_count_size]

lemma typ_slice_list_cut:
  "\<lbrakk> (\<forall>x \<in> set xs. size_td (dt_fst x) = m); m \<noteq> 0; n < (length xs * m) \<rbrakk>
    \<Longrightarrow> typ_slice_list xs n =
      typ_slice_tuple (xs ! (n div m)) (n mod m)"
  apply (induct xs arbitrary: n, simp_all)
  subgoal for x1 xs n
    apply (intro conjI impI)
     apply simp
    apply (subgoal_tac "\<exists>n'. n = n' + m")
     apply clarsimp
     apply (metis (no_types, opaque_lifting) add.commute add.left_neutral cancel_comm_monoid_add_class.diff_cancel 
        div_add1_eq div_mult_self_is_m mod_div_trivial modulo_nat_def mult.left_neutral nth_Cons_Suc plus_1_eq_Suc)
    apply (rule exI[where x="n - m"])
    apply simp
    done
  done

lemma typ_slice_t_array:
  "\<lbrakk> n < CARD('b); y < size_of TYPE('a) \<rbrakk>
   \<Longrightarrow> typ_slice_t (export_uinfo (typ_info_t TYPE('a))) y \<le>
   typ_slice_t (export_uinfo (array_tag TYPE('a['b :: finite])))
              (y + size_of TYPE('a :: mem_type) * n)"
  apply (simp add: array_tag_def array_tag_n_eq
               split del: if_split)
  apply (rule disjI2)
  apply (subgoal_tac "y + (size_of TYPE('a) * n) < CARD('b) * size_of TYPE('a)")
   apply (simp add: typ_slice_list_cut[where m="size_of TYPE('a)"]
                    map_td_list_map o_def size_of_def
                    sz_nzero[unfolded size_of_def])
   apply (simp flip: export_uinfo_def)
  apply (rule order_less_le_trans[where y="Suc n * size_of TYPE('a)"])
   apply (simp add: size_of_def)
  apply (simp only: size_of_def mult_le_mono1)
  done

lemma h_t_valid_Array_element':
  "\<lbrakk> htd \<Turnstile>\<^sub>t (p :: (('a :: mem_type)['b :: finite]) ptr); coerce \<or> n < CARD('b) \<rbrakk>
    \<Longrightarrow> htd \<Turnstile>\<^sub>t array_ptr_index p coerce n" for coerce
  apply (clarsimp simp only: h_t_valid_def valid_footprint_def Let_def
      c_guard_def c_null_guard_def)
  apply (subgoal_tac "\<exists>offs. array_ptr_index p coerce n = CTypesDefs.ptr_add (ptr_coerce p) (of_nat offs)
        \<and> offs < CARD ('b)")
   apply (clarsimp simp: size_td_array size_of_def typ_uinfo_t_def
      typ_info_array array_tag_def)
  subgoal for offs
    apply (intro conjI)
      apply (clarsimp simp: CTypesDefs.ptr_add_def
        field_simps)
      apply (rename_tac y) 
      apply (drule_tac x="offs * size_of TYPE('a) + y" in spec)
      apply (drule mp)
       apply (rule order_less_le_trans[where y="Suc offs * size_of TYPE('a)"])
        apply (simp add: size_of_def)
       apply (simp only: size_of_def mult_le_mono1)
      apply (clarsimp simp: field_simps)
      apply (erule map_le_trans[rotated])
      apply (rule list_map_mono)
      apply (subst mult.commute, rule typ_slice_t_array[unfolded array_tag_def])
       apply assumption
      apply (simp add: size_of_def)
     apply (simp add: ptr_aligned_def align_of_def align_td_array
        array_ptr_index_def
        CTypesDefs.ptr_add_def unat_word_ariths unat_of_nat)
    using align_size_of[where 'a='a] align[where 'a='a]
     apply (simp add: align_of_def size_of_def addr_card_def card_word)
     apply (simp add: dvd_mod)
    apply (thin_tac "\<forall>x. P x" for P)
    apply (clarsimp simp: intvl_def)
    apply (rename_tac k)
    apply (drule_tac x="offs * size_of TYPE('a) + k" in spec)
    apply (drule mp)
     apply (simp add: array_ptr_index_def CTypesDefs.ptr_add_def field_simps)
    apply (erule notE)
    apply (rule order_less_le_trans[where y="Suc offs * size_of TYPE('a)"])
     apply (simp add: size_of_def)
    apply (simp only: size_of_def mult_le_mono1)
    done
  subgoal by (auto simp add: array_ptr_index_def intro: exI[where x=0])
  done

lemma h_t_valid_Array_element:
  "\<lbrakk> htd \<Turnstile>\<^sub>t (p :: (('a :: mem_type)['b :: finite]) ptr); 0 \<le> n; n < int CARD('b) \<rbrakk>
    \<Longrightarrow> htd \<Turnstile>\<^sub>t ((ptr_coerce p :: 'a ptr) +\<^sub>p n)"
  apply (drule_tac n="nat n" and coerce=False in h_t_valid_Array_element')
   apply simp
  apply (simp add: array_ptr_index_def)
  done

lemma ptr_safe_Array_element:
  "\<lbrakk> ptr_safe (p :: (('a :: mem_type)['b :: finite]) ptr) htd; coerce \<or> n < CARD('b) \<rbrakk>
    \<Longrightarrow> ptr_safe (array_ptr_index p coerce n) htd" for coerce
  apply (simp add: ptr_safe_def)
  apply (erule order_trans[rotated])
  apply (subgoal_tac "\<exists>offs. array_ptr_index p coerce n = CTypesDefs.ptr_add (ptr_coerce p) (of_nat offs)
        \<and> offs < CARD ('b)")
   prefer 2
  subgoal by (auto simp: array_ptr_index_def intro: exI[where x=0])[1]
  apply (clarsimp simp: s_footprint_def s_footprint_untyped_def
      CTypesDefs.ptr_add_def
      size_td_array size_of_def)
  subgoal for offs x k
    apply (rule exI[where x="offs * size_of TYPE('a) + x"])
    apply (simp add: size_of_def)
    apply (rule conjI)
     apply (rule order_less_le_trans[where y="Suc offs * size_of TYPE('a)"])
      apply (simp add: size_of_def)
     apply (simp only: size_of_def)
     apply (rule mult_le_mono1)
     apply simp
    apply (thin_tac "coerce \<or> P" for P)
    apply (elim disjE exE conjE, simp_all add: typ_uinfo_t_def)
    apply (erule order_less_le_trans)
    apply (rule prefix_length_le)
    apply (rule order_trans, erule typ_slice_t_array)
     apply (simp add: size_of_def)
    apply (simp add: size_of_def field_simps typ_info_array)
    done
  done

lemma from_bytes_eq:
  "from_bytes [x] = x"
  apply (clarsimp simp:from_bytes_def update_ti_t_def typ_info_word)
  apply (simp add:word_rcat_def)
  done

lemma bytes_disjoint:"(x::('a::c_type) ptr) \<noteq> y \<Longrightarrow> {ptr_val x + a ..+ 1} \<inter> {ptr_val y + a ..+ 1} = {}"
  by (clarsimp simp:intvl_def)

lemma byte_ptrs_disjoint:"(x::('a::c_type) ptr) \<noteq> y \<Longrightarrow> \<forall>i < of_nat (size_of TYPE('a)). ptr_val x + i \<noteq> ptr_val y + i"
  by force

lemma le_step:"\<lbrakk>(x::('a::len) word) < y + 1; x \<noteq> y\<rbrakk> \<Longrightarrow> x < y"
  by (metis less_x_plus_1 max_word_max order_less_le)

lemma ptr_add_disjoint:
  "\<lbrakk> ptr_val y \<notin> {ptr_val x ..+ size_of TYPE('a)};
     ptr_val (x::('a::c_type) ptr) < ptr_val (y::('b::c_type) ptr);
     a < of_nat (size_of TYPE('a)) \<rbrakk> \<Longrightarrow>
   ptr_val x + a < ptr_val y"
  apply (erule swap)
  apply (rule intvl_inter_le [where k=0 and ka="unat (ptr_val y - ptr_val x)"])
    apply clarsimp
   apply (metis (opaque_lifting, mono_tags) add_diff_cancel2 add_diff_inverse diff_add_cancel
              trans_less_add1 unat_less_helper word_le_less_eq word_less_add_right
              word_of_nat_less word_unat.Rep_inverse)
  apply simp
  done

lemma ptr_add_disjoint2:
  "\<lbrakk> ptr_val x \<notin> {ptr_val y ..+ size_of TYPE('a)};
     ptr_val (y::('b::c_type) ptr) < ptr_val (x::('a::c_type) ptr);
     a < of_nat (size_of TYPE('a)) \<rbrakk> \<Longrightarrow>
   ptr_val y + a < ptr_val x"
  apply (erule swap)
  apply (rule intvl_inter_le[where k=0 and ka="unat (ptr_val x - ptr_val y)"])
    apply clarsimp
   apply (metis (no_types, opaque_lifting) add.commute less_imp_le less_le_trans not_le unat_less_helper
                word_diff_ls'(4))
  apply simp
  done

lemma ptr_aligned_is_aligned:"\<lbrakk>ptr_aligned (x::('a::c_type) ptr); align_of TYPE('a) = 2 ^ n\<rbrakk> \<Longrightarrow> is_aligned (ptr_val x) n"
  by (clarsimp simp: ptr_aligned_def is_aligned_def)

lemma intvl_no_overflow:
  assumes no_overflow: "unat a + b < 2 ^ len_of TYPE('a::len)"
  shows "(x \<in> {(a :: 'a word) ..+ b}) = (a \<le> x \<and> x < (a + of_nat b))"
proof -
  obtain "sk" :: "'a word \<Rightarrow> 'a word \<Rightarrow> nat \<Rightarrow> nat"
      where f1: "\<And>x y z. x \<notin> {y..+z} \<or> x = y + of_nat (sk x y z) \<and> sk x y z < z"
    using [[metis_new_skolem]] by (metis intvlD)

  have f2: "\<And>x. a + x < a + of_nat b \<or> \<not> x < of_nat b"
    using no_overflow
    by (metis PackedTypes.of_nat_mono_maybe_le add_lessD1 le_add1
            add.commute olen_add_eqv unat_of_nat_eq word_arith_nat_add
            word_plus_strict_mono_right)

  have f3: "\<forall>x y. y \<notin> {x..+b} \<or> of_nat (sk y x b) < (of_nat b :: 'a word)"
    using no_overflow f1
    by (metis add_lessD1 add.commute of_nat_mono_maybe)

  have "x < a + of_nat b \<or> \<not> of_nat (sk x a b) < (of_nat b :: 'a word) \<or> ?thesis"
    using f1 f2 by metis

  hence "x < a + of_nat b \<or> ?thesis"
    using f3 by metis

  thus "?thesis"
    apply (rule disjE)
     apply (rule iffI)
      apply (clarsimp simp: intvl_def)
      apply (rename_tac k)
      apply (clarsimp simp: unat_sub_if_size word_le_nat_alt word_less_nat_alt)
      apply (cut_tac no_overflow)
      apply (subgoal_tac "k + (b + unat a) < 2 ^ len_of (TYPE('a)) + b")
       apply (subgoal_tac "k + unat a < 2 ^ len_of (TYPE('a))")
        apply (metis add_lessD1 le_def less_not_refl2 add.commute unat_eq_of_nat word_arith_nat_add)
       apply clarsimp
      apply clarsimp
     apply (clarsimp simp: intvl_def)
     apply (rule exI [where x="unat (x  - a)"])
     apply (clarsimp simp: unat_sub_if_size word_le_nat_alt word_less_nat_alt)
     apply (cut_tac no_overflow)
     apply (metis diff_le_self le_add_diff_inverse le_diff_conv le_eq_less_or_eq le_unat_uoi add.commute nat_neq_iff unat_of_nat_eq word_arith_nat_add)
    apply simp
    done
qed




(* arg_cong specified for FCP because it does not apply as is. *)
lemma FCP_arg_cong:"f = g \<Longrightarrow> FCP f = FCP g"
  by simp

lemma h_val_id:
    "h_val (hrs_mem (hrs_mem_update (heap_update x y) s)) x = (y::'a::mem_type)"
  apply (subst hrs_mem_update)
  apply (rule h_val_heap_update)
  done

lemma h_val_id_padding:
    "length bs = size_of TYPE('a) \<Longrightarrow> h_val (hrs_mem (hrs_mem_update (heap_update_padding x y bs) s)) x = (y::'a::mem_type)"
  apply (subst hrs_mem_update)
  apply (simp add: h_val_heap_update_padding)
  done

lemma heap_update_id2:
    "hrs_mem_update (heap_update p ((h_val (hrs_mem s) p)::'a::packed_type)) s = s"
  apply (clarsimp simp:hrs_mem_update_def case_prod_beta)
  apply (subst heap_update_id)
   apply (simp add:hrs_mem_def)+
  done

lemma intvlI_unat:"unat b < unat c \<Longrightarrow> a + b \<in> {a ..+ unat c}"
  by (metis intvlI word_unat.Rep_inverse)

lemma neq_imp_bytes_disjoint:
  "\<lbrakk> c_guard (x::'a::c_type ptr); c_guard y; unat j < align_of TYPE('a);
        unat i < align_of TYPE('a); x \<noteq> y; 2 ^ n = align_of TYPE('a); n < 32\<rbrakk> \<Longrightarrow>
    ptr_val x + j \<noteq> ptr_val y + i"
  apply (rule ccontr)
  apply (subgoal_tac "is_aligned (ptr_val x) n")
   apply (subgoal_tac "is_aligned (ptr_val y) n")
    apply (subgoal_tac "(ptr_val x + j && ~~ mask n) = (ptr_val y + i && ~~ mask n)")
     apply (subst (asm) neg_mask_add_aligned, simp, simp add: word_less_nat_alt)
     apply (subst (asm) neg_mask_add_aligned, simp, simp add: word_less_nat_alt)
     apply clarsimp
    apply simp
   apply (clarsimp simp: c_guard_def ptr_aligned_def is_aligned_def)
  apply (clarsimp simp: c_guard_def ptr_aligned_def is_aligned_def)
  done

lemma heap_update_list_base':"heap_update_list p [] = id"
  by (rule ext, simp)

lemma hrs_mem_update_id3: "hrs_mem_update id = id"
  unfolding hrs_mem_update_def by simp

lemma h_t_valid_ptr_retyp_inside_eq:
  fixes p :: "'a :: mem_type ptr" and p' :: "'a :: mem_type ptr"
  assumes inside: "ptr_val p' \<in> {ptr_val p ..+ size_of TYPE('a)}"
  and         ht: "ptr_retyp p td, g \<Turnstile>\<^sub>t p'"
  shows   "p = p'"
  using ptr_retyp_same_cleared_region[OF ht] inside mem_type_self[where p=p']
  by blast

lemma typ_slice_t_self_nth:
  "\<exists>n < length (typ_slice_t td m). \<exists>b. typ_slice_t td m ! n = (td, b)"
  using typ_slice_t_self [where td = td and m = m]
  by (fastforce simp add: in_set_conv_nth)

lemma ptr_retyp_other_cleared_region:
  fixes p :: "'a :: mem_type ptr" and p' :: "'b :: mem_type ptr"
  assumes  ht: "ptr_retyp p td, g \<Turnstile>\<^sub>t p'"
  and   tdisj: "typ_uinfo_t TYPE('a) \<bottom>\<^sub>t typ_uinfo_t TYPE('b :: mem_type)"
  and   clear: "\<forall>x \<in> {ptr_val p ..+ size_of TYPE('a)}. \<forall>n b. snd (td x) n \<noteq> Some (typ_uinfo_t TYPE('b), b)"
  shows "{ptr_val p'..+ size_of TYPE('b)} \<inter> {ptr_val p ..+ size_of TYPE('a)} = {}"
proof (rule classical)
  assume asm: "{ptr_val p'..+ size_of TYPE('b)} \<inter> {ptr_val p ..+ size_of TYPE('a)} \<noteq> {}"
  then obtain mv where mvp: "mv \<in> {ptr_val p..+size_of TYPE('a)}"
    and mvp': "mv \<in> {ptr_val p'..+size_of TYPE('b)}"
      by blast

  then obtain k' where mv: "mv = ptr_val p' + of_nat k'" and klt: "k' < size_td (typ_info_t TYPE('b))"
    by (clarsimp dest!: intvlD simp: size_of_def)

  let ?mv = "ptr_val p' + of_nat k'"

  obtain n b where nl: "n < length (typ_slice_t (typ_uinfo_t TYPE('b)) k')"
    and tseq: "typ_slice_t (typ_uinfo_t TYPE('b)) k' ! n = (typ_uinfo_t TYPE('b), b)"
    using typ_slice_t_self_nth [where td = "typ_uinfo_t TYPE('b)" and m = k']
    by clarsimp

  with ht have "snd (ptr_retyp p td ?mv) n = Some (typ_uinfo_t TYPE('b), b)"
    unfolding h_t_valid_def
    apply -
    apply (clarsimp simp: valid_footprint_def Let_def)
    apply (drule spec, drule mp [OF _ klt])
    apply (clarsimp simp: map_le_def)
    apply (drule bspec)
    apply simp
    apply simp
    done

  moreover {
    assume "snd (ptr_retyp p empty_htd ?mv) n = Some (typ_uinfo_t TYPE('b), b)"
    hence "(typ_uinfo_t TYPE('b)) \<in> fst ` set (typ_slice_t (typ_uinfo_t TYPE('a))
                                                 (unat (ptr_val p' + of_nat k' - ptr_val p)))"
      using asm mv mvp
      apply -
      apply (rule image_eqI[where x = "(typ_uinfo_t TYPE('b), b)"])
       apply simp
      apply (fastforce simp add: ptr_retyp_footprint list_map_eq in_set_conv_nth split: if_split_asm)
      done

    with typ_slice_set have "(typ_uinfo_t TYPE('b)) \<in> fst ` td_set (typ_uinfo_t TYPE('a)) 0"
      by (rule subsetD)

    hence False using tdisj by (clarsimp simp: tag_disj_def typ_tag_le_def)
  } ultimately show ?thesis using mvp mvp' mv unfolding h_t_valid_def valid_footprint_def
    apply -
    apply (subst (asm) ptr_retyp_d_eq_snd)
    apply (auto simp add: map_add_Some_iff clear)
    done
qed

end
