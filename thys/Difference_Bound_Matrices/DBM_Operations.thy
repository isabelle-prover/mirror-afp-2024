chapter \<open>DBM Operations\<close>

theory DBM_Operations
  imports 
    DBM_Basics
begin

section \<open>Auxiliary\<close>

lemmas [trans] = finite_subset

lemma finite_vimageI2: "finite (h -` F)" if "finite F" "inj_on h {x. h x \<in> F}"
proof -
  have "h -` F = h -` F \<inter> {x. h x \<in> F}"
    by auto
  from that show ?thesis
    by(subst \<open>h -` F = _\<close>) (rule finite_vimage_IntI[of F h "{x. h x \<in> F}"])
qed

lemma gt_swap:
  fixes a b c :: "'t :: time"
  assumes "c < a + b"
  shows "c < b + a"
by (simp add: add.commute assms)

lemma le_swap:
  fixes a b c :: "'t :: time"
  assumes "c \<le> a + b"
  shows "c \<le> b + a"
by (simp add: add.commute assms)

abbreviation clock_numbering :: "('c \<Rightarrow> nat) \<Rightarrow> bool"
where
  "clock_numbering v \<equiv> \<forall> c. v c > 0"

lemma DBM_triv:
  "u \<turnstile>\<^bsub>v,n\<^esub> (\<lambda>i j. \<infinity>)"
  unfolding DBM_val_bounded_def by (auto simp: dbm_le_def)

section \<open>Relaxation\<close>

text \<open>Relaxation of upper bound constraints on all variables.
Used to compute time lapse in timed automata.
\<close>

definition
  up :: "('t::linordered_cancel_ab_semigroup_add) DBM \<Rightarrow> 't DBM"
where
  "up M \<equiv>
    \<lambda> i j. if i > 0 then if j = 0 then \<infinity> else min (dbm_add (M i 0) (M 0 j)) (M i j) else M i j"

lemma dbm_entry_dbm_lt:
  assumes "dbm_entry_val u (Some c1) (Some c2) a" "a \<prec> b"
  shows "dbm_entry_val u (Some c1) (Some c2) b"
  using assms
proof (cases, goal_cases)
  case 1 thus ?case by (cases, auto)
next
  case 2 thus ?case by (cases, auto)
qed auto

lemma dbm_entry_dbm_min2:
  assumes "dbm_entry_val u None (Some c) (min a b)"
  shows "dbm_entry_val u None (Some c) b"
using dbm_entry_val_mono2[folded less_eq, OF assms] by auto

lemma dbm_entry_dbm_min3:
  assumes "dbm_entry_val u (Some c) None (min a b)"
  shows "dbm_entry_val u (Some c) None b"
using dbm_entry_val_mono3[folded less_eq, OF assms] by auto

lemma dbm_entry_dbm_min:
  assumes "dbm_entry_val u (Some c1) (Some c2) (min a b)"
  shows "dbm_entry_val u (Some c1) (Some c2) b"
using dbm_entry_val_mono1[folded less_eq, OF assms] by auto

lemma dbm_entry_dbm_min3':
  assumes "dbm_entry_val u (Some c) None (min a b)"
  shows "dbm_entry_val u (Some c) None a"
using dbm_entry_val_mono3[folded less_eq, OF assms] by auto

lemma dbm_entry_dbm_min2':
  assumes "dbm_entry_val u None (Some c) (min a b)"
  shows "dbm_entry_val u None (Some c) a"
using dbm_entry_val_mono2[folded less_eq, OF assms] by auto

lemma dbm_entry_dbm_min':
  assumes "dbm_entry_val u (Some c1) (Some c2) (min a b)"
  shows "dbm_entry_val u (Some c1) (Some c2) a"
using dbm_entry_val_mono1[folded less_eq, OF assms] by auto

lemma DBM_up_complete': "clock_numbering v \<Longrightarrow> u \<in> ([M]\<^bsub>v,n\<^esub>)\<^sup>\<up> \<Longrightarrow> u \<in> [up M]\<^bsub>v,n\<^esub>"
unfolding up_def DBM_zone_repr_def DBM_val_bounded_def zone_delay_def
proof (safe, goal_cases)
  case prems: (2 u d c)
  hence *: "dbm_entry_val u None (Some c) (M 0 (v c))" by auto
  thus ?case
  proof (cases, goal_cases)
    case (1 d')
    have "- (u c + d) \<le> - u c" using \<open>d \<ge> 0\<close> by simp
    with 1(2) have "- (u c + d)\<le> d'" by (blast intro: order.trans)
    thus ?case unfolding cval_add_def using 1 by fastforce
  next
    case (2 d')
    have "- (u c + d) \<le> - u c" using \<open>d \<ge> 0\<close> by simp
    with 2(2) have "- (u c + d) < d'" by (blast intro: order_le_less_trans)
    thus ?case unfolding cval_add_def using 2 by fastforce
  qed auto
next
  case prems: (4 u d c1 c2)
  then have
    "dbm_entry_val u (Some c1) None (M (v c1) 0)" "dbm_entry_val u None (Some c2) (M 0 (v c2))"
  by auto
  from dbm_entry_val_add_4[OF this] prems have
    "dbm_entry_val u (Some c1) (Some c2) (min (dbm_add (M (v c1) 0) (M 0 (v c2))) (M (v c1) (v c2)))"
  by (auto split: split_min)
  with prems(1) show ?case
  by (cases "min (dbm_add (M (v c1) 0) (M 0 (v c2))) (M (v c1) (v c2))", auto simp: cval_add_def)
qed auto

fun theLe :: "('t::time) DBMEntry \<Rightarrow> 't" where
  "theLe (Le d) = d" |
  "theLe (Lt d) = d" |
  "theLe \<infinity> = 0"

lemma DBM_up_sound':
  assumes "clock_numbering' v n" "u \<in> [up M]\<^bsub>v,n\<^esub>"
  shows "u \<in> ([M]\<^bsub>v,n\<^esub>)\<^sup>\<up>"
proof -
  obtain S_Max_Le where S_Max_Le:
    "S_Max_Le = {d - u c | c d. 0 < v c \<and> v c \<le> n \<and> M (v c) 0 = Le d}"
    by auto
  obtain S_Max_Lt where S_Max_Lt:
    "S_Max_Lt = {d - u c | c d. 0 < v c \<and> v c \<le> n \<and> M (v c) 0 = Lt d}"
    by auto
  obtain S_Min_Le where S_Min_Le:
    "S_Min_Le = {- d - u c| c d. 0 < v c \<and> v c \<le> n \<and> M 0 (v c) = Le d}"
    by auto
  obtain S_Min_Lt where S_Min_Lt:
    "S_Min_Lt = {- d - u c | c d. 0 < v c \<and> v c \<le> n \<and> M 0 (v c) = Lt d}"
    by auto
  have "finite {c. 0 < v c \<and> v c \<le> n}" (is "finite ?S")
  proof -
    have "?S \<subseteq> v -` {1..n}"
      by auto
    also have "finite \<dots>"
      using assms(1) by (auto intro!: finite_vimageI2 inj_onI)
    finally show ?thesis .
  qed
  then have "\<forall> f. finite {(c,b) | c b. 0 < v c \<and> v c \<le> n \<and> f M (v c) = b}" by auto
  moreover have
    "\<forall> f K. {(c,K d) | c d. 0 < v c \<and> v c \<le> n \<and> f M (v c) = K d}
    \<subseteq> {(c,b) | c b. 0 < v c \<and> v c \<le> n \<and> f M (v c) = b}"
    by auto
  ultimately have 1:
    "\<forall> f K. finite {(c,K d) | c d. 0 < v c \<and> v c \<le> n \<and> f M (v c) = K d}" using finite_subset
    by fast
  have "\<forall> f K. theLe o K = id \<longrightarrow> finite {(c,d) | c d. 0 < v c \<and> v c \<le> n \<and> f M (v c) = K d}"
  proof (safe, goal_cases)
    case prems: (1 f K)
    then have "(c, d) = (\<lambda> (c,b). (c, theLe b)) (c, K d)" for c :: 'a and d
      by (simp add: pointfree_idE)
    then have
      "{(c,d) | c d. 0 < v c \<and> v c \<le> n \<and> f M (v c) = K d}
      = (\<lambda> (c,b). (c, theLe b)) ` {(c,K d) | c d. 0 < v c \<and> v c \<le> n \<and> f M (v c) = K d}"
      by (force simp: split_beta)
    moreover from 1 have
      "finite ((\<lambda> (c,b). (c, theLe b)) ` {(c,K d) | c d. 0 < v c \<and> v c \<le> n \<and> f M (v c) = K d})"
      by auto
    ultimately show ?case by auto
  qed
  then have finI:
    "\<And> f g K. theLe o K = id \<Longrightarrow> finite (g ` {(c,d) | c d. 0 < v c \<and> v c \<le> n \<and> f M (v c) = K d})"
    by auto

  have
    "finite ((\<lambda>(c,d). - d - u c) ` {(c,d) | c d. 0 < v c \<and> v c \<le> n \<and> M 0 (v c) = Le d})"
    by (rule finI, auto)
  moreover have
    "S_Min_Le = ((\<lambda>(c,d). - d - u c) ` {(c,d) | c d. 0 < v c \<and> v c \<le> n \<and> M 0 (v c) = Le d})"
    using S_Min_Le by auto
  ultimately have fin_min_le: "finite S_Min_Le" by auto

  have
    "finite ((\<lambda>(c,d). - d - u c) ` {(c,d) | c d. 0 < v c \<and> v c \<le> n \<and> M 0 (v c) = Lt d})"
    by (rule finI, auto)
  moreover have
    "S_Min_Lt = ((\<lambda>(c,d). - d - u c) ` {(c,d) | c d. 0 < v c \<and> v c \<le> n \<and> M 0 (v c) = Lt d})"
    using S_Min_Lt by auto
  ultimately have fin_min_lt: "finite S_Min_Lt" by auto

  have "finite ((\<lambda>(c,d). d - u c) ` {(c,d) | c d. 0 < v c \<and> v c \<le> n \<and> M (v c) 0 = Le d})"
    by (rule finI, auto)
  moreover have
    "S_Max_Le = ((\<lambda>(c,d). d - u c) ` {(c,d) | c d. 0 < v c \<and> v c \<le> n \<and> M (v c) 0 = Le d})"
    using S_Max_Le by auto
  ultimately have fin_max_le: "finite S_Max_Le" by auto

  have
    "finite ((\<lambda>(c,d). d - u c) ` {(c,d) | c d. 0 < v c \<and> v c \<le> n \<and> M (v c) 0 = Lt d})"
    by (rule finI, auto)
  moreover have
    "S_Max_Lt = ((\<lambda>(c,d). d - u c) ` {(c,d) | c d. 0 < v c \<and> v c \<le> n \<and> M (v c) 0 = Lt d})"
    using S_Max_Lt by auto
  ultimately have fin_max_lt: "finite S_Max_Lt" by auto

  { fix x assume "x \<in> S_Min_Le"
    hence "x \<le> 0" unfolding S_Min_Le
    proof (safe, goal_cases)
      case (1 c d)
      with assms have "- u c \<le> d" unfolding DBM_zone_repr_def DBM_val_bounded_def up_def by auto
      thus ?case by (simp add: minus_le_iff)
    qed
  } note Min_Le_le_0 = this
  have Min_Lt_le_0: "x < 0" if "x \<in> S_Min_Lt" for x using that unfolding S_Min_Lt
  proof (safe, goal_cases)
    case (1 c d)
    with assms have "- u c < d" unfolding DBM_zone_repr_def DBM_val_bounded_def up_def by auto
    thus ?case by (simp add: minus_less_iff)
  qed
  text \<open>
    The following basically all use the same proof.
    Only the first is not completely identical but nearly identical.
\<close>
  { fix l r assume "l \<in> S_Min_Le" "r \<in> S_Max_Le"
    with S_Min_Le S_Max_Le have "l \<le> r"
    proof (safe, goal_cases)
      case (1 c c' d d')
      note G1 = this
      hence *:"(up M) (v c') (v c) = min (dbm_add (M (v c') 0) (M 0 (v c))) (M (v c') (v c))"
        using assms unfolding up_def by (auto split: split_min)
      have "dbm_entry_val u (Some c') (Some c) ((up M) (v c') (v c))"
        using assms G1 unfolding DBM_zone_repr_def DBM_val_bounded_def by fastforce
      hence "dbm_entry_val u (Some c') (Some c) (dbm_add (M (v c') 0) (M 0 (v c)))"
        using dbm_entry_dbm_min' * by auto
      hence "u c' - u c \<le> d' + d" using G1 by auto
      hence "u c' + (- u c - d) \<le> d'" by (simp add: add_diff_eq diff_le_eq)
      hence "- u c - d \<le> d' - u c'" by (simp add: add.commute le_diff_eq)
      thus ?case by (metis add_uminus_conv_diff uminus_add_conv_diff)
    qed
  } note EE = this
  { fix l r assume "l \<in> S_Min_Le" "r \<in> S_Max_Le"
    with S_Min_Le S_Max_Le have "l \<le> r"
    proof (safe, goal_cases)
      case (1 c c' d d')
      note G1 = this
      hence *:"(up M) (v c') (v c) = min (dbm_add (M (v c') 0) (M 0 (v c))) (M (v c') (v c))"
        using assms unfolding up_def by (auto split: split_min)
      have "dbm_entry_val u (Some c') (Some c) ((up M) (v c') (v c))"
        using assms G1 unfolding DBM_zone_repr_def DBM_val_bounded_def by fastforce
      hence "dbm_entry_val u (Some c') (Some c) (dbm_add (M (v c') 0) (M 0 (v c)))"
        using dbm_entry_dbm_min' * by auto
      hence "u c' - u c \<le> d' + d" using G1 by auto
      hence "u c' + (- u c - d) \<le> d'" by (simp add: add_diff_eq diff_le_eq)
      hence "- u c - d \<le> d' - u c'" by (simp add: add.commute le_diff_eq)
      thus ?case by (metis add_uminus_conv_diff uminus_add_conv_diff)
    qed
  } note EE = this
  { fix l r assume "l \<in> S_Min_Lt" "r \<in> S_Max_Le"
    with S_Min_Lt S_Max_Le have "l < r"
    proof (safe, goal_cases)
      case (1 c c' d d')
      note G1 = this
      hence *:"(up M) (v c') (v c) = min (dbm_add (M (v c') 0) (M 0 (v c))) (M (v c') (v c))"
        using assms unfolding up_def by (auto split: split_min)
      have "dbm_entry_val u (Some c') (Some c) ((up M) (v c') (v c))"
        using assms G1 unfolding DBM_zone_repr_def DBM_val_bounded_def by fastforce
      hence "dbm_entry_val u (Some c') (Some c) (dbm_add (M (v c') 0) (M 0 (v c)))"
        using dbm_entry_dbm_min' * by auto
      hence "u c' - u c < d' + d" using G1 by auto
      hence "u c' + (- u c - d) < d'" by (simp add: add_diff_eq diff_less_eq)
      hence "- u c - d < d' - u c'" by (simp add: add.commute less_diff_eq)
      thus ?case by (metis add_uminus_conv_diff uminus_add_conv_diff)
    qed
  } note LE = this
  { fix l r assume "l \<in> S_Min_Le" "r \<in> S_Max_Lt"
    with S_Min_Le S_Max_Lt have "l < r"
    proof (safe, goal_cases)
      case (1 c c' d d')
      note G1 = this
      hence *:"(up M) (v c') (v c) = min (dbm_add (M (v c') 0) (M 0 (v c))) (M (v c') (v c))"
        using assms unfolding up_def by (auto split: split_min)
      have "dbm_entry_val u (Some c') (Some c) ((up M) (v c') (v c))"
        using assms G1 unfolding DBM_zone_repr_def DBM_val_bounded_def by fastforce
      hence "dbm_entry_val u (Some c') (Some c) (dbm_add (M (v c') 0) (M 0 (v c)))"
        using dbm_entry_dbm_min' * by auto
      hence "u c' - u c < d' + d" using G1 by auto
      hence "u c' + (- u c - d) < d'" by (simp add: add_diff_eq diff_less_eq)
      hence "- u c - d < d' - u c'" by (simp add: add.commute less_diff_eq)
      thus ?case by (metis add_uminus_conv_diff uminus_add_conv_diff)
    qed
  } note EL = this
  { fix l r assume "l \<in> S_Min_Lt" "r \<in> S_Max_Lt"
    with S_Min_Lt S_Max_Lt have "l < r"
    proof (safe, goal_cases)
      case (1 c c' d d')
      note G1 = this
      hence *:"(up M) (v c') (v c) = min (dbm_add (M (v c') 0) (M 0 (v c))) (M (v c') (v c))"
        using assms unfolding up_def by (auto split: split_min)
      have "dbm_entry_val u (Some c') (Some c) ((up M) (v c') (v c))"
        using assms G1 unfolding DBM_zone_repr_def DBM_val_bounded_def by fastforce
      hence "dbm_entry_val u (Some c') (Some c) (dbm_add (M (v c') 0) (M 0 (v c)))"
        using dbm_entry_dbm_min' * by auto
      hence "u c' - u c < d' + d" using G1 by auto
      hence "u c' + (- u c - d) < d'" by (simp add: add_diff_eq diff_less_eq)
      hence "- u c - d < d' - u c'" by (simp add: add.commute less_diff_eq)
      thus ?case by (metis add_uminus_conv_diff uminus_add_conv_diff)
    qed
  } note LL = this
  obtain m where m: "\<forall> t \<in> S_Min_Le. m \<ge> t" "\<forall> t \<in> S_Min_Lt. m > t"
    "\<forall> t \<in> S_Max_Le. m \<le> t" "\<forall> t \<in> S_Max_Lt. m < t" "m \<le> 0"
  proof -
    assume m:"(\<And>m. \<forall>t\<in>S_Min_Le. t \<le> m \<Longrightarrow>
          \<forall>t\<in>S_Min_Lt. t < m \<Longrightarrow> \<forall>t\<in>S_Max_Le. m \<le> t \<Longrightarrow> \<forall>t\<in>S_Max_Lt. m < t \<Longrightarrow> m \<le> 0 \<Longrightarrow> thesis)"
    let ?min_le = "Max S_Min_Le"
    let ?min_lt = "Max S_Min_Lt"
    let ?max_le = "Min S_Max_Le"
    let ?max_lt = "Min S_Max_Lt"
    show thesis
    proof (cases "S_Min_Le = {} \<and> S_Min_Lt = {}")
      case True
      note T = this
      show thesis
      proof (cases "S_Max_Le = {} \<and> S_Max_Lt = {}")
        case True
        let ?d' = "0 :: 't :: time"
        show thesis using True T by (intro m[of ?d']) auto
      next
        case False
        let ?d =
          "if S_Max_Le \<noteq> {}
           then if S_Max_Lt \<noteq> {} then min ?max_lt ?max_le else ?max_le
           else ?max_lt"
        obtain a :: "'b" where a: "a < 0" using non_trivial_neg by auto
        let ?d' = "min 0 (?d + a)"
        { fix x assume "x \<in> S_Max_Le"
          with fin_max_le a have "min 0 (Min S_Max_Le + a) \<le> x"
            by (metis Min_le add_le_same_cancel1 le_less_trans less_imp_le min.cobounded2 not_less)
          then have "min 0 (Min S_Max_Le + a) \<le> x" by auto
        } note 1 = this
        { fix x assume x: "x \<in> S_Max_Lt"
          have "min 0 (min (Min S_Max_Lt) (Min S_Max_Le) + a) < ?max_lt"
            by (meson a add_less_same_cancel1 min.cobounded1 min.strict_coboundedI2 order.strict_trans2)
          also from fin_max_lt x have "\<dots> \<le> x" by auto
          finally have "min 0 (min (Min S_Max_Lt) (Min S_Max_Le) + a) < x" .
        } note 2 = this
        { fix x assume x: "x \<in> S_Max_Le"
          have "min 0 (min (Min S_Max_Lt) (Min S_Max_Le) + a) \<le> ?max_le"
            by (metis le_add_same_cancel1 linear not_le a min_le_iff_disj)
          also from fin_max_le x have "\<dots> \<le> x" by auto
          finally have "min 0 (min (Min S_Max_Lt) (Min S_Max_Le) + a) \<le> x" .
        } note 3 = this
        show thesis using False T a 1 2 3
          apply (intro m[of ?d'])
          apply simp_all
          apply (metis Min.coboundedI add_less_same_cancel1 dual_order.strict_trans2 fin_max_lt
                min.boundedE not_le)
          done
      qed
    next
      case False
      note F = this
      show thesis
      proof (cases "S_Max_Le = {} \<and> S_Max_Lt = {}")
        case True
        let ?d' = "0 :: 't :: time"
        show thesis using True Min_Le_le_0 Min_Lt_le_0 by (intro m[of ?d']) auto
      next
        case False
        let ?r =
          "if S_Max_Le \<noteq> {}
           then if S_Max_Lt \<noteq> {} then min ?max_lt ?max_le else ?max_le
           else ?max_lt"
        let ?l =
          "if S_Min_Le \<noteq> {}
           then if S_Min_Lt \<noteq> {} then max ?min_lt ?min_le else ?min_le
           else ?min_lt"

        have 1: "x \<le> max ?min_lt ?min_le" "x \<le> ?min_le" if "x \<in> S_Min_Le" for x
          using that fin_min_le by (simp add: max.coboundedI2)+

        {
          fix x y assume x: "x \<in> S_Max_Le" "y \<in> S_Min_Lt"
          then have "S_Min_Lt \<noteq> {}" by auto
          from LE[OF Max_in[OF fin_min_lt], OF this, OF x(1)] have "?min_lt \<le> x" by auto
        } note 3 = this

        have 4: "?min_le \<le> x" if "x \<in> S_Max_Le" "y \<in> S_Min_Le" for x y
          using EE[OF Max_in[OF fin_min_le], OF _ that(1)] that by auto

        {
          fix x y assume x: "x \<in> S_Max_Lt" "y \<in> S_Min_Lt"
          then have "S_Min_Lt \<noteq> {}" by auto
          from LL[OF Max_in[OF fin_min_lt], OF this, OF x(1)] have "?min_lt < x" by auto
        } note 5 = this
        {
          fix x y assume x: "x \<in> S_Max_Lt" "y \<in> S_Min_Le"
          then have "S_Min_Le \<noteq> {}" by auto
          from EL[OF Max_in[OF fin_min_le], OF this, OF x(1)] have "?min_le < x" by auto
        } note 6 = this
        {
          fix x y assume x: "y \<in> S_Min_Le"
          then have "S_Min_Le \<noteq> {}" by auto
          from Min_Le_le_0[OF Max_in[OF fin_min_le], OF this] have "?min_le \<le> 0" by auto
        } note 7 = this
        {
          fix x y assume x: "y \<in> S_Min_Lt"
          then have "S_Min_Lt \<noteq> {}" by auto
          from Min_Lt_le_0[OF Max_in[OF fin_min_lt], OF this] have "?min_lt < 0" "?min_lt \<le> 0" by auto
        } note 8 = this
        show thesis
        proof (cases "?l < ?r")
          case False
          then have *: "S_Max_Le \<noteq> {}"
          proof (safe, goal_cases)
            case 1
            with \<open>\<not> (S_Max_Le = {} \<and> S_Max_Lt = {})\<close> obtain y where y:"y \<in> S_Max_Lt" by auto
            note 1 = 1 this
            { fix x y assume A: "x \<in> S_Min_Le" "y \<in> S_Max_Lt"
              with EL[OF Max_in[OF fin_min_le] Min_in[OF fin_max_lt]]
              have "Max S_Min_Le < Min S_Max_Lt" by auto
            } note ** = this
            { fix x y assume A: "x \<in> S_Min_Lt" "y \<in> S_Max_Lt"
              with LL[OF Max_in[OF fin_min_lt] Min_in[OF fin_max_lt]]
              have "Max S_Min_Lt < Min S_Max_Lt" by auto
            } note *** = this
            show ?case
            proof (cases "S_Min_Le \<noteq> {}")
              case True
              note T = this
              show ?thesis
              proof (cases "S_Min_Lt \<noteq> {}")
                case True
                then show False using 1 T True ** *** by auto
              next
                case False with 1 T ** show False by auto
              qed
            next
              case False
              with 1 False *** \<open>\<not> (S_Min_Le = {} \<and> S_Min_Lt = {})\<close> show ?thesis by auto
            qed
          qed
          { fix x y assume A: "x \<in> S_Min_Lt" "y \<in> S_Max_Lt"
            with LL[OF Max_in[OF fin_min_lt] Min_in[OF fin_max_lt]]
            have "Max S_Min_Lt < Min S_Max_Lt" by auto
          } note *** = this
          { fix x y assume A: "x \<in> S_Min_Lt" "y \<in> S_Max_Le"
            with LE[OF Max_in[OF fin_min_lt] Min_in[OF fin_max_le]]
            have "Max S_Min_Lt < Min S_Max_Le" by auto
          } note **** = this
          from F False have **: "S_Min_Le \<noteq> {}"
          proof (safe, goal_cases)
            case (1 x)
            show ?case
            proof (cases "S_Max_Le \<noteq> {}")
              case True
              note T = this
              show ?thesis
              proof (cases "S_Max_Lt \<noteq> {}")
                case True
                then show "x \<in> {}" using 1 T True **** *** by auto
              next
                case False with 1 T **** show "x \<in> {}" by auto
              qed
            next
              case False
              with 1 False *** \<open>\<not> (S_Max_Le = {} \<and> S_Max_Lt = {})\<close> show ?thesis by auto
            qed
          qed
          {
            fix x assume x: "x \<in> S_Min_Lt"
            then have "x \<le> ?min_lt" using fin_min_lt by (simp add: max.coboundedI2)
            also have "?min_lt < ?min_le"
            proof (rule ccontr, goal_cases)
              case 1
              with x ** have 1: "?l = ?min_lt" by auto
              have 2: "?min_lt < ?max_le" using * ****[OF x] by auto
              show False
              proof (cases "S_Max_Lt = {}")
                case False
                then have "?min_lt < ?max_lt" using * ***[OF x] by auto
                with 1 2 have "?l < ?r" by auto
                with \<open>\<not> ?l < ?r\<close> show False by auto
              next
                case True
                with 1 2 have "?l < ?r" by auto
                with \<open>\<not> ?l < ?r\<close> show False by auto
              qed
            qed
            finally have "x < max ?min_lt ?min_le" by (simp add: max.strict_coboundedI2)
          } note 2 = this
          show thesis using F False 1 2 3 4 5 6 7 8 * ** by ((intro m[of ?l]), auto)
        next
          case True
          then obtain d where d: "?l < d" "d < ?r" using dense by auto
          let ?d' = "min 0 d"
          {
            fix t assume "t \<in> S_Min_Le"
            then have "t \<le> ?l" using 1 by auto
            with d have "t \<le> d" by auto
          }
          moreover {
            fix t assume t: "t \<in> S_Min_Lt"
            then have "t \<le> max ?min_lt ?min_le" using fin_min_lt by (simp add: max.coboundedI1)
            with t Min_Lt_le_0 have "t \<le> ?l" using fin_min_lt by auto
            with d have "t < d" by auto
          }
          moreover {
            fix t assume t: "t \<in> S_Max_Le"
            then have "min ?max_lt ?max_le \<le> t" using fin_max_le by (simp add: min.coboundedI2)
            then have "?r \<le> t" using fin_max_le t by auto
            with d have "d \<le> t" by auto
            then have "min 0 d \<le> t" by (simp add: min.coboundedI2)
          }
          moreover {
            fix t assume t: "t \<in> S_Max_Lt"
            then have "min ?max_lt ?max_le \<le> t" using fin_max_lt by (simp add: min.coboundedI1)
            then have "?r \<le> t" using fin_max_lt t by auto
            with d have "d < t" by auto
            then have "min 0 d < t" by (simp add: min.strict_coboundedI2)
          }
          ultimately show thesis using Min_Le_le_0 Min_Lt_le_0 by ((intro m[of ?d']), auto)
        qed
      qed
    qed
  qed
  obtain u' where "u' = (u \<oplus> m)" by blast
  hence u': "u = (u' \<oplus> (-m))" unfolding cval_add_def by force
  have "DBM_val_bounded v u' M n" unfolding DBM_val_bounded_def
  proof (safe, goal_cases)
    case 1 with assms(1,2) show ?case unfolding DBM_zone_repr_def DBM_val_bounded_def up_def by auto
  next
    case (3 c)
    thus ?case
    proof (cases "M (v c) 0", goal_cases)
      case (1 x1)
      hence "m \<le> x1 - u c" using m(3) S_Max_Le assms by auto
      hence "u c + m \<le> x1" by (simp add: add.commute le_diff_eq)
      thus ?case using u' 1(2) unfolding cval_add_def by auto
    next
      case (2 x2)
      hence "m < x2 - u c" using m(4) S_Max_Lt assms by auto
      hence "u c + m < x2" by (metis add_less_cancel_left diff_add_cancel gt_swap)
      thus ?case using u' 2(2) unfolding cval_add_def by auto
    next
      case 3 thus ?case by auto
    qed
  next
    case (2 c) thus ?case
    proof (cases "M 0 (v c)", goal_cases)
      case (1 x1)
      hence "- x1 - u c \<le> m" using m(1) S_Min_Le assms by auto
      hence "- u c - m \<le> x1" using diff_le_eq neg_le_iff_le by fastforce
      thus ?case using u' 1(2) unfolding cval_add_def by auto
    next
      case (2 x2)
      hence "- x2  - u c < m" using m(2) S_Min_Lt assms by auto
      hence "- u c - m < x2" using diff_less_eq neg_less_iff_less by fastforce
      thus ?case using u' 2(2) unfolding cval_add_def by auto
    next
      case 3 thus ?case by auto
    qed
  next
    case (4 c1 c2)
    from assms have "v c1 > 0" "v c2 \<noteq> 0" by auto
    then have B: "(up M) (v c1) (v c2) = min (dbm_add (M (v c1) 0) (M 0 (v c2))) (M (v c1) (v c2))"
      unfolding up_def by simp

    show ?case
    proof (cases "(dbm_add (M (v c1) 0) (M 0 (v c2))) < (M (v c1) (v c2))")
      case False
      with B have "(up M) (v c1) (v c2) = M (v c1) (v c2)" by (auto split: split_min)
      with assms 4 have
        "dbm_entry_val u (Some c1) (Some c2) (M (v c1) (v c2))"
        unfolding DBM_zone_repr_def unfolding DBM_val_bounded_def by fastforce
      thus ?thesis using u' by cases (auto simp add: cval_add_def)
    next
      case True
      with B have "(up M) (v c1) (v c2) = dbm_add (M (v c1) 0) (M 0 (v c2))" by (auto split: split_min)
      with assms 4 have
        "dbm_entry_val u (Some c1) (Some c2) (dbm_add (M (v c1) 0) (M 0 (v c2)))"
        unfolding DBM_zone_repr_def unfolding DBM_val_bounded_def by fastforce
      with True dbm_entry_dbm_lt have
        "dbm_entry_val u (Some c1) (Some c2) (M (v c1) (v c2))"
        unfolding less by fast
      thus ?thesis using u' by cases (auto simp add: cval_add_def)
    qed
  qed
  with m(5) u' show ?thesis
    unfolding DBM_zone_repr_def zone_delay_def by fastforce
qed


section \<open>Intersection\<close>

fun And :: "('t :: {linordered_cancel_ab_monoid_add}) DBM \<Rightarrow> 't DBM \<Rightarrow> 't DBM" where
  "And M1 M2 = (\<lambda> i j. min (M1 i j) (M2 i j))"

lemma DBM_and_complete:
  assumes "DBM_val_bounded v u M1 n" "DBM_val_bounded v u M2 n"
  shows "DBM_val_bounded v u (And M1 M2) n"
  using assms unfolding DBM_val_bounded_def by (auto simp: min_def)

lemma DBM_and_sound1:
  assumes "DBM_val_bounded v u (And M1 M2) n"
  shows "DBM_val_bounded v u M1 n"
  using assms unfolding DBM_val_bounded_def
  apply safe
     apply (simp add: less_eq[symmetric]; fail)
    apply (auto 4 3 intro: dbm_entry_val_mono[folded less_eq])
  done

lemma DBM_and_sound2:
  assumes "DBM_val_bounded v u (And M1 M2) n"
  shows "DBM_val_bounded v u M2 n"
  using assms unfolding DBM_val_bounded_def
  apply safe
     apply (simp add: less_eq[symmetric]; fail)
    apply (auto 4 3 intro: dbm_entry_val_mono[folded less_eq])
  done

lemma And_correct:
  "[M1]\<^bsub>v,n\<^esub> \<inter> [M2]\<^bsub>v,n\<^esub> = [And M1 M2]\<^bsub>v,n\<^esub>"
  using DBM_and_sound1 DBM_and_sound2 DBM_and_complete unfolding DBM_zone_repr_def by blast


section \<open>Variable Reset\<close>

definition
  DBM_reset :: "('t :: time) DBM \<Rightarrow> nat \<Rightarrow> nat \<Rightarrow> 't \<Rightarrow> 't DBM \<Rightarrow> bool"
where
  "DBM_reset M n k d M' \<equiv>
    (\<forall> j \<le> n. 0 < j \<and> k \<noteq> j\<longrightarrow> M' k j =  \<infinity> \<and> M' j k =  \<infinity>) \<and> M' k 0 = Le d \<and> M' 0 k = Le (- d)
    \<and> M' k k = M k k
    \<and> (\<forall>i \<le> n. \<forall>j \<le> n.
        i \<noteq> k \<and> j \<noteq> k \<longrightarrow> M' i j = min (dbm_add (M i k) (M k j)) (M i j))"


lemma DBM_reset_mono:
  assumes "DBM_reset M n k d M'" "i \<le> n" "j \<le> n" "i \<noteq> k" "j \<noteq> k"
  shows "M' i j \<le> M i j"
using assms unfolding DBM_reset_def by auto

lemma DBM_reset_len_mono:
  assumes "DBM_reset M n k d M'" "k \<notin> set xs" "i \<noteq> k" "j \<noteq> k" "set (i # j # xs) \<subseteq> {0..n}"
  shows "len M' i j xs \<le> len M i j xs"
using assms by (induction xs arbitrary: i) (auto intro: add_mono DBM_reset_mono)

lemma DBM_reset_neg_cycle_preservation:
  assumes "DBM_reset M n k d M'" "len M i i xs < Le 0" "set (k # i # xs) \<subseteq> {0..n}"
  shows "\<exists> j. \<exists> ys. set (j # ys) \<subseteq> {0..n} \<and> len M' j j ys < Le 0"
proof (cases "xs = []")
  case Nil: True
  show ?thesis
  proof (cases "k = i")
    case True
    with Nil assms have "len M' i i [] < Le 0" unfolding DBM_reset_def by auto
    moreover from assms have "set (i # []) \<subseteq> {0..n}" by auto
    ultimately show ?thesis by blast
  next
    case False
    with Nil assms DBM_reset_mono have "len M' i i [] < Le 0" by fastforce
    moreover from assms have "set (i # []) \<subseteq> {0..n}" by auto
    ultimately show ?thesis by blast
  qed
next
  case False
  with assms obtain j ys where cycle:
    "len M j j ys < Le 0" "distinct (j # ys)" "j \<in> set (i # xs)" "set ys \<subseteq> set xs"
  by (metis negative_len_shortest neutral)
  show ?thesis
  proof (cases "k \<in> set (j # ys)")
    case False
    with cycle assms have "len M' j j ys \<le> len M j j ys" by - (rule DBM_reset_len_mono, auto)
    moreover from cycle assms have "set (j # ys) \<subseteq> {0..n}" by auto
    ultimately show ?thesis using cycle(1) by fastforce
  next
    case True
    then obtain l where l: "(l, k) \<in> set (arcs j j ys)"
    proof (cases "j = k", goal_cases)
      case True
      show ?thesis
      proof (cases "ys = []")
        case T: True
        with True show ?thesis by (auto intro: that)
      next
        case False
        then obtain z zs where "ys = zs @ [z]" by (metis append_butlast_last_id)
        from arcs_decomp[OF this] True show ?thesis by (auto intro: that)
      qed
    next
      case False
      from arcs_set_elem2[OF False True] show ?thesis by (blast intro: that)
    qed
    show ?thesis
    proof (cases "ys = []")
      case False
      from cycle_rotate_2'[OF False l, of M] cycle(1) obtain zs where rotated:
        "len M l l (k # zs) < Le 0" "set (l # k # zs) = set (j # ys)" "1 + length zs = length ys"
      by auto
      with length_eq_distinct[OF this(2)[symmetric] cycle(2)] have "distinct (l # k # zs)" by auto
      note rotated = rotated(1,2) this
      from this(2) cycle(3,4) assms(3) have n_bound: "set (l # k # zs) \<subseteq> {0..n}" by auto
      then have "l \<le> n" by auto
      show ?thesis
      proof (cases zs)
        case Nil
        with rotated have "M l k + M k l < Le 0" "l \<noteq> k"  by auto
        with assms(1) \<open>l \<le> n\<close> have "M' l l < Le 0" unfolding DBM_reset_def add min_def by auto
        with \<open>l \<le> n\<close> have "len M' l l [] < Le 0" "set [l] \<subseteq> {0..n}" by auto
        then show ?thesis by blast
      next
        case (Cons w ws)
        with n_bound have *: "set (w # l # ws) \<subseteq> {0..n}" by auto
        from Cons n_bound rotated(3) have "w \<le> n" "w \<noteq> k" "l \<noteq> k" by auto
        with assms(1) \<open>l \<le> n\<close> have
          "M' l w \<le> M l k + M k w"
          unfolding DBM_reset_def add min_def by auto
        moreover from Cons rotated assms * have
          "len M' w l ws \<le> len M w l ws"
          by - (rule DBM_reset_len_mono, auto)
        ultimately have
          "len M' l l zs \<le> len M l l (k # zs)"
          using Cons by (auto intro: add_mono simp add: add.assoc[symmetric])
        with n_bound rotated(1) show ?thesis by fastforce
      qed
    next
      case T: True
      with True cycle have "M j j < Le 0" "j = k" by auto
      with assms(1) have "len M' k k [] < Le 0" unfolding DBM_reset_def by simp
      moreover from assms(3) have "set (k # []) \<subseteq> {0..n}" by auto
      ultimately show ?thesis by blast
    qed
  qed
qed

text \<open>Implementation of DBM reset\<close>

definition
  reset :: "('t::{linordered_cancel_ab_semigroup_add,uminus}) DBM \<Rightarrow> nat \<Rightarrow> nat \<Rightarrow> 't \<Rightarrow> 't DBM"
where
  "reset M n k d =
    (\<lambda> i j.
        if i = k \<and> j = 0 then Le d
        else if i = 0 \<and> j = k then Le (-d)
        else if i = k \<and> j \<noteq> k then \<infinity>
        else if i \<noteq> k \<and> j = k then \<infinity>
        else if i = k \<and> j = k then M k k
        else min (dbm_add (M i k) (M k j)) (M i j)
       )"

fun
  reset' ::
  "('t::{linordered_cancel_ab_semigroup_add,uminus}) DBM
  \<Rightarrow> nat \<Rightarrow> 'c list \<Rightarrow> ('c \<Rightarrow> nat) \<Rightarrow> 't \<Rightarrow> 't DBM"
where
  "reset' M n [] v d = M" |
  "reset' M n (c # cs) v d = reset (reset' M n cs v d) n (v c) d"

lemma DBM_reset_reset:
  "0 < k \<Longrightarrow> k \<le> n \<Longrightarrow> DBM_reset M n k d (reset M n k d)"
unfolding DBM_reset_def by (auto simp: reset_def)

lemma DBM_reset_complete:
  assumes "clock_numbering' v n" "v c \<le> n" "DBM_reset M n (v c) d M'" "DBM_val_bounded v u M n"
  shows "DBM_val_bounded v (u(c := d)) M' n"
unfolding DBM_val_bounded_def using assms
proof (safe, goal_cases)
  case 1
  then have *: "M 0 0 \<ge> Le 0" unfolding DBM_val_bounded_def less_eq by auto
  from 1 have **: "M' 0 0 = min (M 0 (v c) + M (v c) 0) (M 0 0)"
    unfolding DBM_reset_def add by auto
  show ?case
  proof (cases "M 0 (v c) + M (v c) 0 \<le> M 0 0")
    case False
    with * ** show ?thesis unfolding min_def less_eq by auto
  next
    case True
    have "dbm_entry_val u (Some c) (Some c) (M (v c) 0 + M 0 (v c))"
      by (metis DBM_val_bounded_def assms(2,4) dbm_entry_val_add_4 add)
    then have "M (v c) 0 + M 0 (v c) \<ge> Le 0"
      unfolding less_eq dbm_le_def by (cases "M (v c) 0 + M 0 (v c)") auto
    with True ** have "M' 0 0 \<ge> Le 0" by (simp add: comm)
    then show ?thesis unfolding less_eq .
  qed
next
  case (2 c')
  show ?case
  proof (cases "c = c'")
    case False
    hence F:"v c' \<noteq> v c" using 2 by metis
    hence *:"M' 0 (v c') = min (dbm_add (M 0 (v c)) (M (v c) (v c'))) (M 0 (v c'))"
    using F 2 unfolding DBM_reset_def by simp
    show ?thesis
    proof (cases "dbm_add (M 0 (v c)) (M (v c) (v c')) < M 0 (v c')")
      case False
      with * have "M' 0 (v c') = M 0 (v c')" by (auto split: split_min)
      hence "dbm_entry_val u None (Some c') (M' 0 (v c'))"
      using 2 unfolding DBM_val_bounded_def by auto
      thus ?thesis using F by cases fastforce+
    next
      case True
      with * have **:"M' 0 (v c') = dbm_add (M 0 (v c)) (M (v c) (v c'))" by (auto split: split_min)
      from 2 have ***:"dbm_entry_val u None (Some c) (M 0 (v c))"
        "dbm_entry_val u (Some c) (Some c') (M (v c) (v c'))"
        unfolding DBM_val_bounded_def by auto
      show ?thesis
      proof -
        note ***
        moreover have "dbm_entry_val (u(c := d)) None (Some c') (dbm_add (Le d1) (M (v c) (v c')))"
          if "M 0 (v c) = Le d1"
            and "dbm_entry_val u (Some c) (Some c') (M (v c) (v c'))"
            and "- u c \<le> d1"
          for d1 :: 'b
        proof -
          note G1 = that
          from G1(2) show ?thesis
          proof (cases, goal_cases)
            case (1 d')
            from \<open>u c - u c' \<le> d'\<close> G1(3) have "- u c' \<le> d1 + d'"
              by (metis diff_minus_eq_add less_diff_eq less_le_trans minus_diff_eq minus_le_iff not_le)
            thus ?case using 1 \<open>c \<noteq> c'\<close> by fastforce
          next
            case (2 d')
            from this(2) G1(3) have "u c - u c' - u c < d1 + d'" using add_le_less_mono by fastforce
            hence "- u c' < d1 + d'" by simp
            thus ?case using 2 \<open>c \<noteq> c'\<close> by fastforce
          next
            case (3) thus ?case by auto
          qed
        qed
        moreover have "dbm_entry_val (u(c := d)) None (Some c') (dbm_add (Lt d2) (M (v c) (v c')))"
          if "M 0 (v c) = Lt d2"
            and "dbm_entry_val u (Some c) (Some c') (M (v c) (v c'))"
            and "- u c < d2"
          for d2 :: 'b
        proof -
          note G2 = that
          from this(2) show ?thesis
          proof (cases, goal_cases)
            case (1 d')
            from this(2) G2(3) have "u c - u c' - u c < d' + d2" using add_le_less_mono by fastforce
            hence "- u c' < d' + d2" by simp
            hence "- u c' < d2 + d'"
            by (metis (no_types) diff_0_right diff_minus_eq_add minus_add_distrib minus_diff_eq)
            thus ?case using 1 \<open>c \<noteq> c'\<close> by fastforce
          next
            case (2 d')
            from this(2) G2(3) have "u c - u c' - u c < d2 + d'" using add_strict_mono by fastforce
            hence "- u c' < d2 + d'" by simp
            thus ?case using 2 \<open>c \<noteq> c'\<close> by fastforce
          next
            case (3) thus ?case by auto
          qed
        qed
        ultimately show ?thesis
          unfolding ** by (cases, auto)
      qed
    qed
  next
    case True
    with 2 show ?thesis unfolding DBM_reset_def by auto
  qed
next
  case (3 c')
  show ?case
  proof (cases "c = c'")
    case False
    hence F:"v c' \<noteq> v c" using 3 by metis
    hence *:"M' (v c') 0 = min (dbm_add (M (v c') (v c)) (M (v c) 0)) (M (v c') 0)"
    using F 3 unfolding DBM_reset_def by simp
    show ?thesis
    proof (cases "dbm_add (M (v c') (v c)) (M (v c) 0) < M (v c') 0")
      case False
      with * have "M' (v c') 0 = M (v c') 0" by (auto split: split_min)
      hence "dbm_entry_val u (Some c') None (M' (v c') 0)"
      using 3 unfolding DBM_val_bounded_def by auto
      thus ?thesis using F by cases fastforce+
    next
      case True
      with * have **:"M' (v c') 0 = dbm_add (M (v c') (v c)) (M (v c) 0)" by (auto split: split_min)
      from 3 have ***:"dbm_entry_val u (Some c') (Some c) (M (v c') (v c))"
        "dbm_entry_val u (Some c) None (M (v c) 0)"
        unfolding DBM_val_bounded_def by auto
    thus ?thesis
    proof -
      note ***
      moreover have "dbm_entry_val (u(c := d)) (Some c') None (dbm_add (Le d1) (M (v c) 0))"
        if "M (v c') (v c) = Le d1"
          and "dbm_entry_val u (Some c) None (M (v c) 0)"
          and "u c' - u c \<le> d1"
        for d1 :: 'b
      proof -
        note G1 = that
        from G1(2) show ?thesis
        proof (cases, goal_cases)
          case (1 d')
          from this(2) G1(3) have "u c' \<le> d1 + d'" using ordered_ab_semigroup_add_class.add_mono
          by fastforce
          thus ?case using 1 \<open>c \<noteq> c'\<close> by fastforce
        next
          case (2 d')
          from this(2) G1(3) have "u c + u c' - u c < d1 + d'" using add_le_less_mono by fastforce
          hence "u c' < d1 + d'" by simp
          thus ?case using 2 \<open>c \<noteq> c'\<close> by fastforce
        next
          case (3) thus ?case by auto
        qed
      qed
      moreover have "dbm_entry_val (u(c := d)) (Some c') None (dbm_add (Lt d1) (M (v c) 0))"
        if "M (v c') (v c) = Lt d1"
          and "dbm_entry_val u (Some c) None (M (v c) 0)"
          and "u c' - u c < d1"
        for d1 :: 'b
      proof -
        note G2 = that
        from that(2) show ?thesis
        proof (cases, goal_cases)
          case (1 d')
          from this(2) G2(3) have "u c + u c' - u c < d' + d1" using add_le_less_mono by fastforce
          hence "u c' < d' + d1" by simp
          hence "u c' < d1 + d'"
          by (metis (no_types) diff_0_right diff_minus_eq_add minus_add_distrib minus_diff_eq)
          thus ?case using 1 \<open>c \<noteq> c'\<close> by fastforce
        next
          case (2 d')
          from this(2) G2(3) have "u c + u c' - u c < d1 + d'" using add_strict_mono by fastforce
          hence "u c' < d1 + d'" by simp
          thus ?case using 2 \<open>c \<noteq> c'\<close> by fastforce
        next
          case 3 thus ?case by auto
        qed
      qed
      ultimately show ?thesis
        unfolding ** by (cases, auto)
      qed
    qed
  next
    case True
    with 3 show ?thesis unfolding DBM_reset_def by auto
  qed
next
  case (4 c1 c2)
  show ?case
  proof (cases "c = c1")
    case False
    note F1 = this
    show ?thesis
    proof (cases "c = c2")
      case False
      with F1 4 have F: "v c \<noteq> v c1" "v c \<noteq> v c2" "v c1 \<noteq> 0" "v c2 \<noteq> 0" by force+
      hence *:"M' (v c1) (v c2) = min (dbm_add (M (v c1) (v c)) (M (v c) (v c2))) (M (v c1) (v c2))"
      using 4 unfolding DBM_reset_def by simp
      show ?thesis
      proof (cases "dbm_add (M (v c1) (v c)) (M (v c) (v c2)) < M (v c1) (v c2)")
        case False
        with * have "M' (v c1) (v c2) = M (v c1) (v c2)" by (auto split: split_min)
        hence "dbm_entry_val u (Some c1) (Some c2) (M' (v c1) (v c2))"
        using 4 unfolding DBM_val_bounded_def by auto
        thus ?thesis using F by cases fastforce+
      next
        case True
        with * have **:"M' (v c1) (v c2) = dbm_add (M (v c1) (v c)) (M (v c) (v c2))" by (auto split: split_min)
        from 4 have ***:"dbm_entry_val u (Some c1) (Some c) (M (v c1) (v c))"
          "dbm_entry_val u (Some c) (Some c2) (M (v c) (v c2))" unfolding DBM_val_bounded_def by auto
        show ?thesis
        proof -
          note ***
          moreover have "dbm_entry_val (u(c := d)) (Some c1) (Some c2) (dbm_add (Le d1) (M (v c) (v c2)))"
            if "M (v c1) (v c) = Le d1"
              and "dbm_entry_val u (Some c) (Some c2) (M (v c) (v c2))"
              and "u c1 - u c \<le> d1"
            for d1 :: 'b
          proof -
            note G1 = that
            from G1(2) show ?thesis
            proof (cases, goal_cases)
              case (1 d')
              from \<open>u c - u c2 \<le> d'\<close> \<open>u c1 - u c \<le> d1\<close> have "u c1 - u c2 \<le> d1 + d'"
                by (metis (no_types) ab_semigroup_add_class.add_ac(1) add_le_cancel_right
                                   add_left_mono diff_add_cancel dual_order.refl dual_order.trans)
              thus ?case using 1(1) \<open>c \<noteq> c1\<close> \<open>c \<noteq> c2\<close> by fastforce
            next
              case (2 d')
              from add_less_le_mono[OF \<open>u c - u c2 < d'\<close> \<open>u c1 - u c \<le> d1\<close>] have
                "- u c2 + u c1 < d' + d1" by simp
              hence "u c1 - u c2 < d1 + d'" by (simp add: add.commute)
              thus ?case using 2 \<open>c \<noteq> c1\<close> \<open>c \<noteq> c2\<close> by fastforce
            next
              case (3) thus ?case by auto
            qed
          qed
          moreover have "dbm_entry_val (u(c := d)) (Some c1) (Some c2) (dbm_add (Lt d2) (M (v c) (v c2)))"
            if "M (v c1) (v c) = Lt d2"
              and "dbm_entry_val u (Some c) (Some c2) (M (v c) (v c2))"
              and "u c1 - u c < d2"
            for d2 :: 'b
          proof -
            note G2 = that
            from G2(2) show ?thesis
            proof (cases, goal_cases)
              case (1 d')
              with add_less_le_mono[OF G2(3) this(2)] \<open>c \<noteq> c1\<close> \<open>c \<noteq> c2\<close> show ?case
                by auto
            next
              case (2 d')
              with add_strict_mono[OF this(2) G2(3)] \<open>c \<noteq> c1\<close> \<open>c \<noteq> c2\<close> show ?case
                by (auto simp: add.commute)
            next
              case (3) thus ?case by auto
            qed
          qed
          ultimately show ?thesis
            unfolding ** by (cases, auto)
        qed
      qed
    next
      case True
      with F1 4 have F: "v c \<noteq> v c1" "v c1 \<noteq> 0" "v c2 \<noteq> 0" by force+
      thus ?thesis using 4 True unfolding DBM_reset_def by auto
    qed
  next
    case True
    note T1 = this
    show ?thesis
    proof (cases "c = c2")
      case False
      with T1 4 have F: "v c \<noteq> v c2" "v c1 \<noteq> 0" "v c2 \<noteq> 0" by force+
      thus ?thesis using 4 True unfolding DBM_reset_def by auto
    next
      case True
      then have *: "M' (v c1) (v c1) = M (v c1) (v c1)"
      using T1 4 unfolding DBM_reset_def by auto
      from 4 True T1 have "dbm_entry_val u (Some c1) (Some c2) (M (v c1) (v c2))"
      unfolding DBM_val_bounded_def by auto
      then show ?thesis by (cases rule: dbm_entry_val.cases, auto simp: * True[symmetric] T1)
    qed
  qed
qed

lemma DBM_reset_sound_empty:
  assumes "clock_numbering' v n" "v c \<le> n" "DBM_reset M n (v c) d M'"
          "\<forall> u . \<not> DBM_val_bounded v u M' n"
  shows "\<not> DBM_val_bounded v u M n"
using assms DBM_reset_complete by metis

lemma DBM_reset_diag_preservation:
  "\<forall>k\<le>n. M' k k \<le> 0" if "\<forall>k\<le>n. M k k \<le> 0" "DBM_reset M n i d M'"
proof safe
  fix k :: nat
  assume "k \<le> n"
  with that show "M' k k \<le> 0"
    by (cases "k = i"; cases "k = 0")
       (auto simp add: DBM_reset_def less[symmetric] neutral split: split_min)
qed

lemma FW_diag_preservation:
  "\<forall>k\<le>n. M k k \<le> 0 \<Longrightarrow> \<forall>k\<le>n. (FW M n) k k \<le> 0"
proof clarify
  fix k assume A: "\<forall>k\<le>n. M k k \<le> 0" "k \<le> n"
  then have "M k k \<le> 0" by auto
  with fw_mono[of k n k M n] A show "FW M n k k \<le> 0" by auto
qed

lemma DBM_reset_not_cyc_free_preservation:
  assumes "\<not> cyc_free M n" "DBM_reset M n k d M'" "k \<le> n"
  shows "\<not> cyc_free M' n"
proof -
  from assms(1) obtain i xs where "i \<le> n" "set xs \<subseteq> {0..n}" "len M i i xs < Le 0"
  unfolding neutral by auto
  with DBM_reset_neg_cycle_preservation[OF assms(2) this(3)] assms(3) obtain j ys where
    "set (j # ys) \<subseteq> {0..n}" "len M' j j ys < Le 0"
  by auto
  then show ?thesis unfolding neutral by force
qed

lemma DBM_reset_complete_empty':
  assumes "\<forall>k\<le>n. k > 0 \<longrightarrow> (\<exists>c. v c = k)" "clock_numbering v" "k \<le> n"
          "DBM_reset M n k d M'" "\<forall> u . \<not> DBM_val_bounded v u M n"
  shows "\<not> DBM_val_bounded v u M' n"
proof -
  from assms(5) have "[M]\<^bsub>v,n\<^esub> = {}" unfolding DBM_zone_repr_def by auto
  from empty_not_cyc_free[OF _ this] have "\<not> cyc_free M n" using assms(2) by auto
  from DBM_reset_not_cyc_free_preservation[OF this assms(4,3)] have "\<not> cyc_free M' n" by auto
  then obtain i xs where "i \<le> n" "set xs \<subseteq> {0..n}" "len M' i i xs < 0" by auto
  from DBM_val_bounded_neg_cycle[OF _ this assms(1)] show ?thesis by fast
qed

lemma DBM_reset_complete_empty:
  assumes "\<forall>k\<le>n. k > 0 \<longrightarrow> (\<exists>c. v c = k)" "clock_numbering v"
          "DBM_reset (FW M n) n (v c) d M'" "\<forall> u . \<not> DBM_val_bounded v u (FW M n) n"
  shows "\<not> DBM_val_bounded v u M' n"
proof -
  note A = assms
  from A(4) have "[FW M n]\<^bsub>v,n\<^esub> = {}" unfolding DBM_zone_repr_def by auto
  with FW_detects_empty_zone[OF A(1), of M] A(2)
  obtain i where i: "i \<le> n" "FW M n i i < Le 0" by blast
  with A(3,4) have "M' i i < Le 0"
  unfolding DBM_reset_def by (cases "i = v c", auto split: split_min)
  with fw_mono[of i n i M' n] i have "FW M' n i i < Le 0" by auto
  with FW_detects_empty_zone[OF A(1), of M'] A(2) i
  have "[FW M' n]\<^bsub>v,n\<^esub> = {}" by auto
  with FW_zone_equiv[OF A(1)] show ?thesis by (auto simp: DBM_zone_repr_def)
qed

lemma DBM_reset_complete_empty1:
  assumes "\<forall>k\<le>n. k > 0 \<longrightarrow> (\<exists>c. v c = k)" "clock_numbering v"
          "DBM_reset (FW M n) n (v c) d M'" "\<forall> u . \<not> DBM_val_bounded v u M n"
  shows "\<not> DBM_val_bounded v u M' n"
proof -
  from assms have "[M]\<^bsub>v,n\<^esub> = {}" unfolding DBM_zone_repr_def by auto
  with FW_zone_equiv[OF assms(1)] have
    "\<forall> u . \<not> DBM_val_bounded v u (FW M n) n"
  unfolding DBM_zone_repr_def by auto
  from DBM_reset_complete_empty[OF assms(1-3) this] show ?thesis by auto
qed

text \<open>
  Lemma \<open>FW_canonical_id\<close> allows us to prove correspondences between reset and canonical,
  like for the two below.
  Can be left out for the rest because of the triviality of the correspondence.
\<close>

lemma DBM_reset_empty'':
  assumes "\<forall>k\<le>n. k > 0 \<longrightarrow> (\<exists>c. v c = k)" "clock_numbering' v n" "v c \<le> n"
          "DBM_reset M n (v c) d M'"
  shows "[M]\<^bsub>v,n\<^esub> = {} \<longleftrightarrow> [M']\<^bsub>v,n\<^esub> = {}"
proof
  assume A: "[M]\<^bsub>v,n\<^esub> = {}"
  hence "\<forall> u . \<not> DBM_val_bounded v u M n" unfolding DBM_zone_repr_def by auto
  hence "\<forall> u . \<not> DBM_val_bounded v u M' n"
  using DBM_reset_complete_empty'[OF assms(1) _ assms(3,4)] assms(2) by auto
  thus "[M']\<^bsub>v,n\<^esub> = {}" unfolding DBM_zone_repr_def by auto
next
  assume "[M']\<^bsub>v,n\<^esub> = {}"
  hence "\<forall> u . \<not> DBM_val_bounded v u M' n" unfolding DBM_zone_repr_def by auto
  hence "\<forall> u . \<not> DBM_val_bounded v u M n" using DBM_reset_sound_empty[OF assms(2-4)] by auto
  thus "[M]\<^bsub>v,n\<^esub> = {}" unfolding DBM_zone_repr_def by auto
qed

lemma DBM_reset_empty:
  assumes "\<forall>k\<le>n. k > 0 \<longrightarrow> (\<exists>c. v c = k)" "clock_numbering' v n" "v c \<le> n"
          "DBM_reset (FW M n) n (v c) d M'"
  shows "[FW M n]\<^bsub>v,n\<^esub> = {} \<longleftrightarrow> [M']\<^bsub>v,n\<^esub> = {}"
proof
  assume A: "[FW M n]\<^bsub>v,n\<^esub> = {}"
  hence "\<forall> u . \<not> DBM_val_bounded v u (FW M n) n" unfolding DBM_zone_repr_def by auto
  hence "\<forall> u . \<not> DBM_val_bounded v u M' n"
  using DBM_reset_complete_empty[of n v M, OF assms(1) _ assms(4)] assms(2,3) by auto
  thus "[M']\<^bsub>v,n\<^esub> = {}" unfolding DBM_zone_repr_def by auto
next
  assume "[M']\<^bsub>v,n\<^esub> = {}"
  hence "\<forall> u . \<not> DBM_val_bounded v u M' n" unfolding DBM_zone_repr_def by auto
  hence "\<forall> u . \<not> DBM_val_bounded v u (FW M n) n" using DBM_reset_sound_empty[OF assms(2-)] by auto
  thus "[FW M n]\<^bsub>v,n\<^esub> = {}" unfolding DBM_zone_repr_def by auto
qed

lemma DBM_reset_empty':
  assumes "canonical M n" "\<forall>k\<le>n. k > 0 \<longrightarrow> (\<exists>c. v c = k)" "clock_numbering' v n" "v c \<le> n"
          "DBM_reset (FW M n) n (v c) d M'"
  shows   "[M]\<^bsub>v,n\<^esub> = {} \<longleftrightarrow> [M']\<^bsub>v,n\<^esub> = {}"
using FW_canonical_id[OF assms(1)] DBM_reset_empty[OF assms(2-)] by simp

lemma DBM_reset_sound':
  assumes "clock_numbering' v n" "v c \<le> n" "DBM_reset M n (v c) d M'" "DBM_val_bounded v u M' n"
          "DBM_val_bounded v u'' M n"
  obtains d' where  "DBM_val_bounded v (u(c := d')) M n"
proof -
  from assms(1) have
    "\<forall>c. 0 < v c"
    and "\<forall>x y. v x \<le> n \<and> v y \<le> n \<and> v x = v y \<longrightarrow> x = y"
    by auto
  note A = that assms(2-) this
  obtain S_Min_Le where S_Min_Le:
  "S_Min_Le = {u c' - d | c' d. 0 < v c' \<and> v c' \<le> n \<and> c \<noteq> c' \<and> M (v c') (v c) = Le d}
               \<union> {-d | d. M 0 (v c) = Le d}" by auto
  obtain S_Min_Lt where S_Min_Lt:
  "S_Min_Lt = {u c' - d | c' d. 0 < v c' \<and> v c' \<le> n \<and> c \<noteq> c' \<and> M (v c') (v c) = Lt d}
              \<union> {-d | d. M 0 (v c) = Lt d}" by auto
  obtain S_Max_Le where S_Max_Le:
  "S_Max_Le = {u c' + d | c' d. 0 < v c' \<and> v c' \<le> n \<and> c \<noteq> c' \<and> M (v c) (v c') = Le d}
              \<union> {d | d. M (v c) 0 = Le d}" by auto
  obtain S_Max_Lt where S_Max_Lt:
  "S_Max_Lt = {u c' + d | c' d. 0 < v c' \<and> v c' \<le> n \<and> c \<noteq> c' \<and> M (v c) (v c') = Lt d}
              \<union> {d | d. M (v c) 0 = Lt d}" by auto

  have "finite {c. 0 < v c \<and> v c \<le> n}" using A(6,7)
  proof (induction n)
    case 0
    then have "{c. 0 < v c \<and> v c \<le> 0} = {}" by auto
    then show ?case by (metis finite.emptyI)
  next
    case (Suc n)
    then have "finite {c. 0 < v c \<and> v c \<le> n}" by auto
    moreover have "{c. 0 < v c \<and> v c \<le> Suc n} = {c. 0 < v c \<and> v c \<le> n} \<union> {c. v c = Suc n}" by auto
    
    moreover have "finite {c. v c = Suc n}"
    proof -
      {fix c assume "v c = Suc n"
       then have "{c. v c = Suc n} = {c}" using Suc.prems(2) by auto
      }
      then show ?thesis by (cases "{c. v c = Suc n} = {}") auto
    qed
    ultimately show ?case by auto
  qed
  then have "\<forall> f. finite {(c,b) | c b. 0 < v c \<and> v c \<le> n \<and> f M (v c) = b}" by auto
  moreover have
    "\<forall> f K. {(c,K d) | c d. 0 < v c \<and> v c \<le> n \<and> f M (v c) = K d}
    \<subseteq> {(c,b) | c b. 0 < v c \<and> v c \<le> n \<and> f M (v c) = b}"
  by auto
  ultimately have B:
    "\<forall> f K. finite {(c,K d) | c d. 0 < v c \<and> v c \<le> n \<and> f M (v c) = K d}"
    using finite_subset by fast
  have "\<forall> f K. theLe o K = id \<longrightarrow> finite {(c,d) | c d. 0 < v c \<and> v c \<le> n \<and> f M (v c) = K d}"
  proof (safe, goal_cases)
    case prems: (1 f K)
    then have "(c, d) = (\<lambda> (c,b). (c, theLe b)) (c, K d)" for c :: 'a and d
      by (simp add: pointfree_idE)
    then have
      "{(c,d) | c d. 0 < v c \<and> v c \<le> n \<and> f M (v c) = K d}
      = (\<lambda> (c,b). (c, theLe b)) ` {(c,K d) | c d. 0 < v c \<and> v c \<le> n \<and> f M (v c) = K d}"
      by (force simp: split_beta)
    moreover from B have
      "finite ((\<lambda> (c,b). (c, theLe b)) ` {(c,K d) | c d. 0 < v c \<and> v c \<le> n \<and> f M (v c) = K d})"
      by auto
    ultimately show ?case by auto
  qed
  then have finI:
    "\<And> f g K. theLe o K = id \<Longrightarrow> finite (g ` {(c',d) | c' d. 0 < v c' \<and> v c' \<le> n \<and> f M (v c') = K d})"
  by auto
  have finI1:
    "\<And> f g K. theLe o K = id \<Longrightarrow> finite (g ` {(c',d) | c' d. 0 < v c' \<and> v c' \<le> n \<and> c \<noteq> c' \<and> f M (v c') = K d})"
  proof goal_cases
    case (1 f g K)
    have
      "g ` {(c',d) | c' d. 0 < v c' \<and> v c' \<le> n \<and> c \<noteq> c' \<and> f M (v c') = K d}
      \<subseteq> g ` {(c',d) | c' d. 0 < v c' \<and> v c' \<le> n \<and> f M (v c') = K d}"
    by auto
    from finite_subset[OF this finI[OF 1, of g f]] show ?case .
  qed
  have "\<forall> f. finite {b. f M (v c) = b}" by auto
  moreover have "\<forall> f K. {K d | d. f M (v c) = K d} \<subseteq> {b. f M (v c) = b}" by auto
  ultimately have B: "\<forall> f K. finite {K d | d. f M (v c) = K d}" using finite_subset by fast

  have "\<forall> f K. theLe o K = id \<longrightarrow> finite {d | d. f M (v c) = K d}"
  proof (safe, goal_cases)
    case prems: (1 f K)
    then have "(c, d) = (\<lambda> (c,b). (c, theLe b)) (c, K d)" for c :: 'a and d
      by (simp add: pointfree_idE)
    then have
      "{d | d. f M (v c) = K d}
      = (\<lambda> b. theLe b) ` {K d | d. f M (v c) = K d}"
      by (force simp: split_beta)
    moreover from B have
      "finite ((\<lambda>b. theLe b) ` {K d | d. f M (v c) = K d})"
      by auto
    ultimately show ?case by auto
  qed
  then have C: "\<forall> f g K. theLe o K = id \<longrightarrow> finite (g ` {d | d. f M (v c) = K d})" by auto
  have finI2: "\<And> f g K. theLe o K = id \<Longrightarrow> finite ({g d | d. f M (v c) = K d})"
  proof goal_cases
    case (1 f g K)
    have "{g d |d. f M (v c) = K d} = g ` {d | d. f M (v c) = K d}" by auto
    with C 1 show ?case by auto
  qed

  { fix K :: "'b \<Rightarrow> 'b DBMEntry" assume A: "theLe o K = id"
    then have
      "finite ((\<lambda>(c,d). u c - d) ` {(c',d) | c' d. 0 < v c' \<and> v c' \<le> n \<and> c \<noteq> c' \<and> M (v c') (v c) = K d})"
    by (intro finI1, auto)
    moreover have
      "{u c' - d |c' d. 0 < v c' \<and> v c' \<le> n \<and> c \<noteq> c' \<and> M (v c') (v c) = K d}
      = ((\<lambda>(c,d). u c - d) ` {(c',d) | c' d. 0 < v c' \<and> v c' \<le> n \<and> c \<noteq> c' \<and> M (v c') (v c) = K d})"
    by auto
    ultimately have "finite {u c' - d |c' d. 0 < v c' \<and> v c' \<le> n \<and> c \<noteq> c' \<and> M (v c') (v c) = K d}"
    by auto
    moreover have "finite {- d |d. M 0 (v c) = K d}" using A by (intro finI2, auto)
    ultimately have
      "finite ({u c' - d |c' d. 0 < v c' \<and> v c' \<le> n \<and> c \<noteq> c' \<and> M (v c') (v c) = K d}
                \<union> {- d |d. M 0 (v c) = K d})"
    by (auto simp: S_Min_Le)
  } note fin1 = this
  have fin_min_le: "finite S_Min_Le" unfolding S_Min_Le by (rule fin1, auto)
  have fin_min_lt: "finite S_Min_Lt" unfolding S_Min_Lt by (rule fin1, auto)

  { fix K :: "'b \<Rightarrow> 'b DBMEntry" assume A: "theLe o K = id"
    then have "finite ((\<lambda>(c,d). u c + d) ` {(c',d) | c' d. 0 < v c' \<and> v c' \<le> n \<and> c \<noteq> c' \<and> M (v c) (v c') = K d})"
    by (intro finI1, auto)
    moreover have
      "{u c' + d |c' d. 0 < v c' \<and> v c' \<le> n \<and> c \<noteq> c' \<and> M (v c) (v c') = K d}
      = ((\<lambda>(c,d). u c + d) ` {(c',d) | c' d. 0 < v c' \<and> v c' \<le> n \<and> c \<noteq> c' \<and> M (v c) (v c') = K d})"
    by auto
    ultimately have "finite {u c' + d |c' d. 0 < v c' \<and> v c' \<le> n \<and> c \<noteq> c' \<and> M (v c) (v c') = K d}"
    by auto
    moreover have "finite {d |d. M (v c) 0 = K d}" using A by (intro finI2, auto)
    ultimately have
      "finite ({u c' + d |c' d. 0 < v c' \<and> v c' \<le> n \<and> c \<noteq> c' \<and> M (v c) (v c') = K d}
               \<union> {d |d. M (v c) 0 = K d})"
    by (auto simp: S_Min_Le)
  } note fin2 = this
  have fin_max_le: "finite S_Max_Le" unfolding S_Max_Le by (rule fin2, auto)
  have fin_max_lt: "finite S_Max_Lt" unfolding S_Max_Lt by (rule fin2, auto)

  { fix l r assume "l \<in> S_Min_Le" "r \<in> S_Max_Le"
    then have "l \<le> r"
      unfolding S_Min_Le S_Max_Le
    proof (safe, goal_cases)
      case (1 c1 d1 c2 d2)
      with A have
        "dbm_entry_val u (Some c1) (Some c2) (M' (v c1) (v c2))"
      unfolding DBM_val_bounded_def by presburger
      moreover have
        "M' (v c1) (v c2) = min (dbm_add (M (v c1) (v c)) (M (v c) (v c2))) (M (v c1) (v c2))"
      using A(3,7) 1 unfolding DBM_reset_def by metis
      ultimately have
        "dbm_entry_val u (Some c1) (Some c2) (dbm_add (M (v c1) (v c)) (M (v c) (v c2)))"
      using dbm_entry_dbm_min' by auto
      with 1 have "u c1 - u c2 \<le> d1 + d2" by auto
      thus ?case
      by (metis (no_types) add_diff_cancel_left diff_0_right diff_add_cancel diff_eq_diff_less_eq)
    next
      case (2 c' d)
      with A have
        "(\<forall>i\<le>n. i \<noteq> v c \<and> i > 0 \<longrightarrow> M' i 0 = min (dbm_add (M i (v c)) (M (v c) 0)) (M i 0))"
        "v c' \<noteq> v c"
      unfolding DBM_reset_def by auto
      hence "(M' (v c') 0 = min (dbm_add (M (v c') (v c)) (M (v c) 0)) (M (v c') 0))"
      using 2 by blast
      moreover from A 2 have "dbm_entry_val u (Some c') None (M' (v c') 0)"
      unfolding DBM_val_bounded_def by presburger
      ultimately have "dbm_entry_val u (Some c') None (dbm_add (M (v c') (v c)) (M (v c) 0))"
      using dbm_entry_dbm_min3' by fastforce
      with 2 have "u c' \<le> d + r" by auto
      thus ?case by (metis add_diff_cancel_left add_le_cancel_right diff_0_right diff_add_cancel)
    next
      case (3 d c' d')
      with A have
        "(\<forall>i\<le>n. i \<noteq> v c \<and> i > 0 \<longrightarrow> M' 0 i = min (dbm_add (M 0 (v c)) (M (v c) i)) (M 0 i))"
        "v c' \<noteq> v c"
      unfolding DBM_reset_def by auto
      hence "(M' 0 (v c') = min (dbm_add (M 0 (v c)) (M (v c) (v c'))) (M 0 (v c')))"
      using 3 by blast
      moreover from A 3 have "dbm_entry_val u None (Some c') (M' 0 (v c'))"
      unfolding DBM_val_bounded_def by presburger
      ultimately have "dbm_entry_val u None (Some c') (dbm_add (M 0 (v c)) (M (v c) (v c')))"
      using dbm_entry_dbm_min2' by fastforce
      with 3 have "-u c' \<le> d + d'" by auto
      thus ?case
      by (metis add_uminus_conv_diff diff_le_eq minus_add_distrib minus_le_iff)
    next
      case (4 d)
      text \<open>
        Here is the reason we need the assumption that the zone was not empty before the reset.
        We cannot deduce anything from the current value of \<open>c\<close> itself because we reset it.
        We can only ensure that we can reset the value of \<open>c\<close> by using the value from the
        alternative assignment.
        This case is only relevant if the tightest bounds for \<open>d\<close> were given by its original
        lower and upper bounds. If they would overlap, the original zone would be empty.
      \<close>
      from A(2,5) have
        "dbm_entry_val u'' None (Some c) (M 0 (v c))"
        "dbm_entry_val u'' (Some c) None (M (v c) 0)"
      unfolding DBM_val_bounded_def by auto
      with 4 have "- u'' c \<le> d" "u'' c \<le> r" by auto
      thus ?case by (metis minus_le_iff order.trans)
    qed
  } note EE = this
  { fix l r assume "l \<in> S_Min_Le" "r \<in> S_Max_Lt"
    then have "l < r"
      unfolding S_Min_Le S_Max_Lt
    proof (safe, goal_cases)
      case (1 c1 d1 c2 d2)
      with A have "dbm_entry_val u (Some c1) (Some c2) (M' (v c1) (v c2))"
      unfolding DBM_val_bounded_def by presburger
      moreover have "M' (v c1) (v c2) = min (dbm_add (M (v c1) (v c)) (M (v c) (v c2))) (M (v c1) (v c2))"
      using A(3,7) 1 unfolding DBM_reset_def by metis
      ultimately have "dbm_entry_val u (Some c1) (Some c2) (dbm_add (M (v c1) (v c)) (M (v c) (v c2)))"
      using dbm_entry_dbm_min' by fastforce
      with 1 have "u c1 - u c2 < d1 + d2" by auto
      then show ?case by (metis add.assoc add.commute diff_less_eq)
    next
      case (2 c' d)
      with A have
        "(\<forall>i\<le>n. i \<noteq> v c \<and> i > 0 \<longrightarrow> M' i 0 = min (dbm_add (M i (v c)) (M (v c) 0)) (M i 0))"
        "v c' \<noteq> v c"
      unfolding DBM_reset_def by auto
      hence "(M' (v c') 0 = min (dbm_add (M (v c') (v c)) (M (v c) 0)) (M (v c') 0))"
      using 2 by blast
      moreover from A 2 have "dbm_entry_val u (Some c') None (M' (v c') 0)"
      unfolding DBM_val_bounded_def by presburger
      ultimately have "dbm_entry_val u (Some c') None (dbm_add (M (v c') (v c)) (M (v c) 0))"
      using dbm_entry_dbm_min3' by fastforce
      with 2 have "u c' < d + r" by auto
      thus ?case by (metis add_less_imp_less_right diff_add_cancel gt_swap)
    next
      case (3 d c' da)
      with A have
        "(\<forall>i\<le>n. i \<noteq> v c \<and> i > 0 \<longrightarrow> M' 0 i = min (dbm_add (M 0 (v c)) (M (v c) i)) (M 0 i))"
        "v c' \<noteq> v c"
      unfolding DBM_reset_def by auto
      hence "(M' 0 (v c') = min (dbm_add (M 0 (v c)) (M (v c) (v c'))) (M 0 (v c')))"
      using 3 by blast
      moreover from A 3 have "dbm_entry_val u None (Some c') (M' 0 (v c'))"
      unfolding DBM_val_bounded_def by presburger
      ultimately have "dbm_entry_val u None (Some c') (dbm_add (M 0 (v c)) (M (v c) (v c')))"
      using dbm_entry_dbm_min2' by fastforce
      with 3 have "-u c' < d + da" by auto
      thus ?case by (metis add.commute diff_less_eq uminus_add_conv_diff)
    next
      case (4 d)
      from A(2,5) have
        "dbm_entry_val u'' None (Some c) (M 0 (v c))"
        "dbm_entry_val u'' (Some c) None (M (v c) 0)"
      unfolding DBM_val_bounded_def by auto
      with 4 have "- u'' c \<le> d" "u'' c < r" by auto
      thus ?case by (metis minus_le_iff neq_iff not_le order.strict_trans)
    qed
  } note EL = this
  { fix l r assume "l \<in> S_Min_Lt" "r \<in> S_Max_Le"
    then have "l < r"
      unfolding S_Min_Lt S_Max_Le
    proof (safe, goal_cases)
      case (1 c1 d1 c2 d2)
      with A have "dbm_entry_val u (Some c1) (Some c2) (M' (v c1) (v c2))"
      unfolding DBM_val_bounded_def by presburger
      moreover have "M' (v c1) (v c2) = min (dbm_add (M (v c1) (v c)) (M (v c) (v c2))) (M (v c1) (v c2))"
      using A(3,7) 1 unfolding DBM_reset_def by metis
      ultimately have "dbm_entry_val u (Some c1) (Some c2) (dbm_add (M (v c1) (v c)) (M (v c) (v c2)))"
      using dbm_entry_dbm_min' by fastforce
      with 1 have "u c1 - u c2 < d1 + d2" by auto
      thus ?case by (metis add.assoc add.commute diff_less_eq)
    next
      case (2 c' d)
      with A have
        "(\<forall>i\<le>n. i \<noteq> v c \<and> i > 0 \<longrightarrow> M' i 0 = min (dbm_add (M i (v c)) (M (v c) 0)) (M i 0))"
        "v c' \<noteq> v c"
      unfolding DBM_reset_def by auto
      hence "(M' (v c') 0 = min (dbm_add (M (v c') (v c)) (M (v c) 0)) (M (v c') 0))"
      using 2 by blast
      moreover from A 2 have "dbm_entry_val u (Some c') None (M' (v c') 0)"
      unfolding DBM_val_bounded_def by presburger
      ultimately have "dbm_entry_val u (Some c') None (dbm_add (M (v c') (v c)) (M (v c) 0))"
      using dbm_entry_dbm_min3' by fastforce
      with 2 have "u c' < d + r" by auto
      thus ?case by (metis add_less_imp_less_right diff_add_cancel gt_swap)
    next
      case (3 d c' da)
      with A have
        "(\<forall>i\<le>n. i \<noteq> v c \<and> i > 0 \<longrightarrow> M' 0 i = min (dbm_add (M 0 (v c)) (M (v c) i)) (M 0 i))"
        "v c' \<noteq> v c"
      unfolding DBM_reset_def by auto
      hence "(M' 0 (v c') = min (dbm_add (M 0 (v c)) (M (v c) (v c'))) (M 0 (v c')))"
      using 3 by blast
      moreover from A 3 have "dbm_entry_val u None (Some c') (M' 0 (v c'))"
      unfolding DBM_val_bounded_def by presburger
      ultimately have "dbm_entry_val u None (Some c') (dbm_add (M 0 (v c)) (M (v c) (v c')))"
      using dbm_entry_dbm_min2' by fastforce
      with 3 have "-u c' < d + da" by auto
      thus ?case by (metis add.commute diff_less_eq uminus_add_conv_diff)
    next
      case (4 d)
      from A(2,5) have
        "dbm_entry_val u'' None (Some c) (M 0 (v c))"
        "dbm_entry_val u'' (Some c) None (M (v c) 0)"
      unfolding DBM_val_bounded_def by auto
      with 4 have "- u'' c < d" "u'' c \<le> r" by auto
      thus ?case by (meson less_le_trans minus_less_iff)
    qed
  } note LE = this
  { fix l r assume "l \<in> S_Min_Lt" "r \<in> S_Max_Lt"
    then have "l < r"
      unfolding S_Min_Lt S_Max_Lt
    proof (safe, goal_cases)
      case (1 c1 d1 c2 d2)
      with A have "dbm_entry_val u (Some c1) (Some c2) (M' (v c1) (v c2))"
      unfolding DBM_val_bounded_def by presburger
      moreover have "M' (v c1) (v c2) = min (dbm_add (M (v c1) (v c)) (M (v c) (v c2))) (M (v c1) (v c2))"
      using A(3,7) 1 unfolding DBM_reset_def by metis
      ultimately have "dbm_entry_val u (Some c1) (Some c2) (dbm_add (M (v c1) (v c)) (M (v c) (v c2)))"
      using dbm_entry_dbm_min' by fastforce
      with 1 have "u c1 - u c2 < d1 + d2" by auto
      then show ?case by (metis add.assoc add.commute diff_less_eq)
    next
      case (2 c' d)
      with A have
        "(\<forall>i\<le>n. i \<noteq> v c \<and> i > 0\<longrightarrow> M' i 0 = min (dbm_add (M i (v c)) (M (v c) 0)) (M i 0))"
        "v c' \<noteq> v c"
      unfolding DBM_reset_def by auto
      hence "(M' (v c') 0 = min (dbm_add (M (v c') (v c)) (M (v c) 0)) (M (v c') 0))"
      using 2 by blast
      moreover from A 2 have "dbm_entry_val u (Some c') None (M' (v c') 0)"
      unfolding DBM_val_bounded_def by presburger
      ultimately have "dbm_entry_val u (Some c') None (dbm_add (M (v c') (v c)) (M (v c) 0))"
      using dbm_entry_dbm_min3' by fastforce
      with 2 have "u c' < d + r" by auto
      thus ?case by (metis add_less_imp_less_right diff_add_cancel gt_swap)
    next
      case (3 d c' da)
      with A have
        "(\<forall>i\<le>n. i \<noteq> v c \<and> i > 0 \<longrightarrow> M' 0 i = min (dbm_add (M 0 (v c)) (M (v c) i)) (M 0 i))"
        "v c' \<noteq> v c"
      unfolding DBM_reset_def by auto
      hence "(M' 0 (v c') = min (dbm_add (M 0 (v c)) (M (v c) (v c'))) (M 0 (v c')))"
      using 3 by blast
      moreover from A 3 have "dbm_entry_val u None (Some c') (M' 0 (v c'))"
      unfolding DBM_val_bounded_def by presburger
      ultimately have "dbm_entry_val u None (Some c') (dbm_add (M 0 (v c)) (M (v c) (v c')))"
      using dbm_entry_dbm_min2' by fastforce
      with 3 have "-u c' < d + da" by auto
      thus ?case by (metis ab_group_add_class.ab_diff_conv_add_uminus add.commute diff_less_eq)
    next
      case (4 d)
      from A(2,5) have
        "dbm_entry_val u'' None (Some c) (M 0 (v c))"
        "dbm_entry_val u'' (Some c) None (M (v c) 0)"
      unfolding DBM_val_bounded_def by auto
      with 4 have "- u'' c \<le> d" "u'' c < r" by auto
      thus ?case by (metis minus_le_iff neq_iff not_le order.strict_trans)
    qed
  } note LL = this

  obtain d' where d':
    "\<forall> t \<in> S_Min_Le. d' \<ge> t" "\<forall> t \<in> S_Min_Lt. d' > t"
    "\<forall> t \<in> S_Max_Le. d' \<le> t" "\<forall> t \<in> S_Max_Lt. d' < t"
  proof -
    assume m:
      "\<And>d'. \<lbrakk>\<forall>t\<in>S_Min_Le. t \<le> d'; \<forall>t\<in>S_Min_Lt. t < d'; \<forall>t\<in>S_Max_Le. d' \<le> t; \<forall>t\<in>S_Max_Lt. d' < t\<rbrakk>
        \<Longrightarrow> thesis"
    let ?min_le = "Max S_Min_Le"
    let ?min_lt = "Max S_Min_Lt"
    let ?max_le = "Min S_Max_Le"
    let ?max_lt = "Min S_Max_Lt"

    show thesis
    proof (cases "S_Min_Le = {} \<and> S_Min_Lt = {}")
      case True
      note T = this
      show thesis
      proof (cases "S_Max_Le = {} \<and> S_Max_Lt = {}")
        case True
        let ?d' = "0 :: 't :: time"
        show thesis using True T by (intro m[of ?d']) auto
      next
        case False
        let ?d =
          "if S_Max_Le \<noteq> {}
           then if S_Max_Lt \<noteq> {} then min ?max_lt ?max_le else ?max_le
           else ?max_lt"
        obtain a :: "'b" where a: "a < 0" using non_trivial_neg by auto
        let ?d' = "min 0 (?d + a)"
        { fix x assume "x \<in> S_Max_Le"
          with fin_max_le a have "min 0 (Min S_Max_Le + a) \<le> x"
          by (metis Min.boundedE add_le_same_cancel1 empty_iff less_imp_le min.coboundedI2)
          then have "min 0 (Min S_Max_Le + a) \<le> x" by auto
        } note 1 = this
        { fix x assume x: "x \<in> S_Max_Lt"
          have "min 0 (min (Min S_Max_Lt) (Min S_Max_Le) + a) < ?max_lt"
          by (meson a add_less_same_cancel1 min.cobounded1 min.strict_coboundedI2 order.strict_trans2)
          also from fin_max_lt x have "\<dots> \<le> x" by auto
          finally have "min 0 (min (Min S_Max_Lt) (Min S_Max_Le) + a) < x" .
        } note 2 = this
        { fix x assume x: "x \<in> S_Max_Le"
          have "min 0 (min (Min S_Max_Lt) (Min S_Max_Le) + a) \<le> ?max_le"
          by (metis le_add_same_cancel1 linear not_le a min_le_iff_disj)
          also from fin_max_le x have "\<dots> \<le> x" by auto
          finally have "min 0 (min (Min S_Max_Lt) (Min S_Max_Le) + a) \<le> x" .
        } note 3 = this
        show thesis using False T a 1 2 3
          by (intro m[of ?d'], auto)
             (metis Min.coboundedI add_less_same_cancel1 fin_max_lt min.boundedE min.orderE
                not_less)
      qed
    next
      case False
      note F = this
      show thesis
      proof (cases "S_Max_Le = {} \<and> S_Max_Lt = {}")
        case True
        let ?l =
          "if S_Min_Le \<noteq> {}
           then if S_Min_Lt \<noteq> {} then max ?min_lt ?min_le else ?min_le
           else ?min_lt"
        obtain a :: "'b" where "a < 0" using non_trivial_neg by blast
        then have a: "-a > 0" using non_trivial_neg by simp
        then obtain a :: "'b" where a: "a > 0" by blast
        let ?d' = "?l + a"
        {
          fix x assume x: "x \<in> S_Min_Le"
          then have "x \<le> max ?min_lt ?min_le" "x \<le> ?min_le" using fin_min_le by (simp add: max.coboundedI2)+
          then have "x \<le> max ?min_lt ?min_le + a" "x \<le> ?min_le + a" using a by (simp add: add_increasing2)+
        } note 1 = this
        {
          fix x assume x: "x \<in> S_Min_Lt"
          then have "x \<le> max ?min_lt ?min_le" "x \<le> ?min_lt" using fin_min_lt by (simp add: max.coboundedI1)+
          then have "x < ?d'" using a x by (auto simp add: add.commute add_strict_increasing)
        } note 2 = this
        show thesis using True F a 1 2 by ((intro m[of ?d']), auto)
      next
        case False
        let ?r =
          "if S_Max_Le \<noteq> {}
           then if S_Max_Lt \<noteq> {} then min ?max_lt ?max_le else ?max_le
           else ?max_lt"
        let ?l =
          "if S_Min_Le \<noteq> {}
           then if S_Min_Lt \<noteq> {} then max ?min_lt ?min_le else ?min_le
           else ?min_lt"
        have 1: "x \<le> max ?min_lt ?min_le" "x \<le> ?min_le" if "x \<in> S_Min_Le" for x
        by (simp add: max.coboundedI2 that fin_min_le)+
        {
          fix x y assume x: "x \<in> S_Max_Le" "y \<in> S_Min_Lt"
          then have "S_Min_Lt \<noteq> {}" by auto
          from LE[OF Max_in[OF fin_min_lt], OF this, OF x(1)] have "?min_lt \<le> x" by auto
        } note 3 = this
        {
          fix x y assume x: "x \<in> S_Max_Le" "y \<in> S_Min_Le"
          with EE[OF Max_in[OF fin_min_le], OF _ x(1)] have "?min_le \<le> x" by auto
        } note 4 = this
        {
          fix x y assume x: "x \<in> S_Max_Lt" "y \<in> S_Min_Lt"
          then have "S_Min_Lt \<noteq> {}" by auto
          from LL[OF Max_in[OF fin_min_lt], OF this, OF x(1)] have "?min_lt < x" by auto
        } note 5 = this
        {
          fix x y assume x: "x \<in> S_Max_Lt" "y \<in> S_Min_Le"
          then have "S_Min_Le \<noteq> {}" by auto
          from EL[OF Max_in[OF fin_min_le], OF this, OF x(1)] have "?min_le < x" by auto
        } note 6 = this

        show thesis
        proof (cases "?l < ?r")
          case False
          then have *: "S_Max_Le \<noteq> {}"
          proof (safe, goal_cases)
            case 1
            with \<open>\<not> (S_Max_Le = {} \<and> S_Max_Lt = {})\<close> obtain y where y:"y \<in> S_Max_Lt" by auto
            note 1 = 1 this
            { fix x y assume A: "x \<in> S_Min_Le" "y \<in> S_Max_Lt"
                  with EL[OF Max_in[OF fin_min_le] Min_in[OF fin_max_lt]]
                  have "Max S_Min_Le < Min S_Max_Lt" by auto
            } note ** = this
            { fix x y assume A: "x \<in> S_Min_Lt" "y \<in> S_Max_Lt"
                with LL[OF Max_in[OF fin_min_lt] Min_in[OF fin_max_lt]]
                have "Max S_Min_Lt < Min S_Max_Lt" by auto
            } note *** = this
            show ?case
            proof (cases "S_Min_Le \<noteq> {}")
              case True
              note T = this
              show ?thesis
              proof (cases "S_Min_Lt \<noteq> {}")
                case True
                then show False using 1 T True ** *** by auto
              next
                case False with 1 T ** show False by auto
              qed
            next
              case False
              with 1 False *** \<open>\<not> (S_Min_Le = {} \<and> S_Min_Lt = {})\<close> show ?thesis by auto
            qed
          qed
          { fix x y assume A: "x \<in> S_Min_Lt" "y \<in> S_Max_Lt"
                with LL[OF Max_in[OF fin_min_lt] Min_in[OF fin_max_lt]]
                have "Max S_Min_Lt < Min S_Max_Lt" by auto
            } note *** = this
          { fix x y assume A: "x \<in> S_Min_Lt" "y \<in> S_Max_Le"
                  with LE[OF Max_in[OF fin_min_lt] Min_in[OF fin_max_le]]
                  have "Max S_Min_Lt < Min S_Max_Le" by auto
          } note **** = this
          from F False have **: "S_Min_Le \<noteq> {}"
          proof (safe, goal_cases)
            case 1
            show ?case
            proof (cases "S_Max_Le \<noteq> {}")
              case True
              note T = this
              show ?thesis
              proof (cases "S_Max_Lt \<noteq> {}")
                case True
                then show ?thesis using 1 T True **** *** by auto
              next
                case False with 1 T **** show ?thesis by auto
              qed
            next
              case False
              with 1 False *** \<open>\<not> (S_Max_Le = {} \<and> S_Max_Lt = {})\<close> show ?thesis by auto
            qed
          qed
          {
            fix x assume x: "x \<in> S_Min_Lt"
            then have "x \<le> ?min_lt" using fin_min_lt by (simp add: max.coboundedI2)
            also have "?min_lt < ?min_le"
            proof (rule ccontr, goal_cases)
              case 1
              with x ** have 1: "?l = ?min_lt" by (auto simp: max.absorb1)
              have 2: "?min_lt < ?max_le" using * ****[OF x] by auto
              show False
              proof (cases "S_Max_Lt = {}")
                case False
                then have "?min_lt < ?max_lt" using * ***[OF x] by auto
                with 1 2 have "?l < ?r" by auto
                with \<open>\<not> ?l < ?r\<close> show False by auto
              next
                case True
                with 1 2 have "?l < ?r" by auto
                with \<open>\<not> ?l < ?r\<close> show False by auto
              qed
            qed
            finally have "x < max ?min_lt ?min_le" by (simp add: max.strict_coboundedI2)
          } note 2 = this
          show thesis using F False 1 2 3 4 5 6 * ** by ((intro m[of ?l]), auto)
        next
          case True
          then obtain d where d: "?l < d" "d < ?r" using dense by auto
          let ?d' = "d"
          {
            fix t assume "t \<in> S_Min_Le"
            then have "t \<le> ?l" using 1 by auto
            with d have "t \<le> d" by auto
          }
          moreover {
            fix t assume t: "t \<in> S_Min_Lt"
            then have "t \<le> max ?min_lt ?min_le" using fin_min_lt by (simp add: max.coboundedI1)
            with t have "t \<le> ?l" using fin_min_lt by auto
            with d have "t < d" by auto
          }
          moreover {
            fix t assume t: "t \<in> S_Max_Le"
            then have "min ?max_lt ?max_le \<le> t" using fin_max_le by (simp add: min.coboundedI2)
            then have "?r \<le> t" using fin_max_le t by auto
            with d have "d \<le> t" by auto
            then have "d \<le> t" by (simp add: min.coboundedI2)
          }
          moreover {
            fix t assume t: "t \<in> S_Max_Lt"
            then have "min ?max_lt ?max_le \<le> t" using fin_max_lt by (simp add: min.coboundedI1)
            then have "?r \<le> t" using fin_max_lt t by auto
            with d have "d < t" by auto
            then have "d < t" by (simp add: min.strict_coboundedI2)
          }
          ultimately show thesis by ((intro m[of ?d']), auto)
        qed
      qed
    qed
  qed
  have "DBM_val_bounded v (u(c := d')) M n" unfolding DBM_val_bounded_def
  proof (safe, goal_cases)
    case 1
    with A show ?case unfolding DBM_reset_def DBM_val_bounded_def by auto
  next
    case (2 c')
    show ?case
    proof (cases "c = c'")
      case False
      with A(2,7) have "v c \<noteq> v c'" by auto
      hence *:"M' 0 (v c') = min (dbm_add (M 0 (v c)) (M (v c) (v c'))) (M 0 (v c'))"
      using A(2,3,6,7) 2 unfolding DBM_reset_def by auto
      from 2 A(2,4) have "dbm_entry_val u None (Some c') (M' 0 (v c'))"
      unfolding DBM_val_bounded_def by auto
      with dbm_entry_dbm_min2 * have "dbm_entry_val u None (Some c') (M 0 (v c'))" by auto
      thus ?thesis using False by cases auto
    next
      case True
      note [simp] = True[symmetric]
      show ?thesis
      proof (cases "M 0 (v c)")
        case (Le t)
        hence "-t \<in> S_Min_Le" unfolding S_Min_Le by force
        hence "d' \<ge> -t" using d' by auto
        thus ?thesis using A Le by (auto simp: minus_le_iff)
      next
        case (Lt t)
        hence "-t \<in> S_Min_Lt" unfolding S_Min_Lt by force
        hence "d' > -t" using d' by auto
        thus ?thesis using 2 Lt by (auto simp: minus_less_iff)
      next
        case INF thus ?thesis by auto
      qed
    qed
  next
    case (3 c')
    show ?case
    proof (cases "c = c'")
      case False
      with A(2,7) have "v c \<noteq> v c'" by auto
      hence *:"M' (v c') 0 = min (dbm_add (M (v c') (v c)) (M (v c) 0)) (M (v c') 0)"
      using A(2,3,6,7) 3 unfolding DBM_reset_def by auto
      from 3 A(2,4) have "dbm_entry_val u (Some c') None (M' (v c') 0)"
      unfolding DBM_val_bounded_def by auto
      with dbm_entry_dbm_min3 * have "dbm_entry_val u (Some c') None (M (v c') 0)" by auto
      thus ?thesis using False by cases auto
    next
      case [symmetric, simp]: True
      show ?thesis
      proof (cases "M (v c) 0", goal_cases)
        case (1 t)
        hence "t \<in> S_Max_Le" unfolding S_Max_Le by force
        hence "d' \<le> t" using d' by auto
        thus ?case using 1 by (auto simp: minus_le_iff)
      next
        case (2 t)
        hence "t \<in> S_Max_Lt" unfolding S_Max_Lt by force
        hence "d' < t" using d' by auto
        thus ?case using 2 by (auto simp: minus_less_iff)
      next
        case 3 thus ?case by auto
      qed
    qed
  next
    case (4 c1 c2)
    show ?case
    proof (cases "c = c1")
      case False
      note F1 = this
      show ?thesis
      proof (cases "c = c2")
        case False
        with A(2,6,7) F1 have "v c \<noteq> v c1" "v c \<noteq> v c2" by auto
        hence *:"M' (v c1) (v c2) = min (dbm_add (M (v c1) (v c)) (M (v c) (v c2))) (M (v c1) (v c2))"
        using A(2,3,6,7) 4 unfolding DBM_reset_def by auto
        from 4 A(2,4) have "dbm_entry_val u (Some c1) (Some c2) (M' (v c1) (v c2))"
        unfolding DBM_val_bounded_def by auto
        with dbm_entry_dbm_min * have "dbm_entry_val u (Some c1) (Some c2) (M (v c1) (v c2))" by auto
        thus ?thesis using F1 False by cases auto
      next
        case [symmetric, simp]: True
        show ?thesis
        proof (cases "M (v c1) (v c)", goal_cases)
          case (1 t)
          hence "u c1 - t \<in> S_Min_Le" unfolding S_Min_Le using A F1 4 by blast
          hence "d' \<ge> u c1 - t" using d' by auto
          hence "t + d' \<ge> u c1" by (metis le_swap add_le_cancel_right diff_add_cancel)
          hence "u c1 - d' \<le> t" by (metis add_le_imp_le_right diff_add_cancel)
          thus ?case using 1 F1 by auto
        next
          case (2 t)
          hence "u c1 - t \<in> S_Min_Lt" unfolding S_Min_Lt using A 4 F1 by blast
          hence "d' > u c1 - t" using d' by auto
          hence "d' + t > u c1" by (metis add_strict_right_mono diff_add_cancel)
          hence "u c1 - d' < t" by (metis gt_swap add_less_cancel_right diff_add_cancel)
          thus ?case using 2 F1 by auto
        next
          case 3 thus ?case by auto
        qed
      qed
    next
      case True
      note T = this
      show ?thesis
      proof (cases "c = c2")
        case False
        show ?thesis
        proof (cases "M (v c) (v c2)", goal_cases)
          case (1 t)
          hence "u c2 + t \<in> S_Max_Le" unfolding S_Max_Le using A 4 False by blast
          hence "d' \<le> u c2 + t" using d' by auto
          hence "d' - u c2 \<le> t"
          by (metis (no_types) add_diff_cancel_left add_ac(1) add_le_cancel_right
              add_right_cancel diff_add_cancel)
          thus ?case using 1 T False by auto
        next
          case (2 t)
          hence "u c2 + t \<in> S_Max_Lt" unfolding S_Max_Lt using A 4 False by blast
          hence "d' < u c2 + t" using d' by auto
          hence "d' - u c2 < t" by (metis gt_swap add_less_cancel_right diff_add_cancel)
          thus ?case using 2 T False by force
        next
          case 3 thus ?case using T by auto
        qed
      next
        case [symmetric, simp]: True
        from A 4 have *:"dbm_entry_val u'' (Some c1) (Some c1) (M (v c1) (v c1))"
        unfolding DBM_val_bounded_def by auto
        show ?thesis using True T
        proof (cases "M (v c1) (v c1)", goal_cases)
          case (1 t)
          with * have "0 \<le> t" by auto
          thus ?case using 1 by auto
        next
          case (2 t)
          with * have "0 < t" by auto
          thus ?case using 2 by auto
        next
          case 3 thus ?case by auto
        qed
      qed
    qed
  qed
  thus ?thesis using A(1) by blast
qed

lemma DBM_reset_sound2:
  assumes "v c \<le> n" "DBM_reset M n (v c) d M'" "DBM_val_bounded v u M' n"
  shows "u c = d"
using assms unfolding DBM_val_bounded_def DBM_reset_def
by fastforce

lemma DBM_reset_sound'':
  fixes M v c n d
  defines "M' \<equiv> reset M n (v c) d"
  assumes "clock_numbering' v n" "v c \<le> n" "DBM_val_bounded v u M' n"
          "DBM_val_bounded v u'' M n"
  obtains d' where  "DBM_val_bounded v (u(c := d')) M n"
proof -
  assume A:"\<And>d'. DBM_val_bounded v (u(c := d')) M n \<Longrightarrow> thesis"
  from assms DBM_reset_reset[of "v c" n M d]
  have *:"DBM_reset M n (v c) d M'" by (auto simp add: M'_def)
  with DBM_reset_sound'[of v n c M d M', OF _ _ this] assms obtain d' where
  "DBM_val_bounded v (u(c := d')) M n" by auto
  with A show thesis by auto
qed

lemma DBM_reset_sound:
  fixes M v c n d
  defines "M' \<equiv> reset M n (v c) d"
  assumes "\<forall>k\<le>n. k > 0 \<longrightarrow> (\<exists>c. v c = k)" "clock_numbering' v n" "v c \<le> n"
          "u \<in> [M']\<^bsub>v,n\<^esub>"
  obtains d' where  "u(c := d') \<in>[M]\<^bsub>v,n\<^esub>"
proof (cases "[M]\<^bsub>v,n\<^esub> = {}")
  case False
  then obtain u' where "DBM_val_bounded v u' M n" unfolding DBM_zone_repr_def by auto
  from DBM_reset_sound''[OF assms(3-4) _ this] assms(1,5) that show ?thesis
  unfolding DBM_zone_repr_def by auto
next
  case True
  with DBM_reset_complete_empty'[OF assms(2) _ _ DBM_reset_reset, of "v c" M u d] assms show ?thesis
  unfolding DBM_zone_repr_def by simp
qed

lemma DBM_reset'_complete':
  assumes "DBM_val_bounded v u M n" "clock_numbering' v n" "\<forall> c \<in> set cs. v c \<le> n"
  shows "\<exists> u'. DBM_val_bounded v u' (reset' M n cs v d) n"
using assms
proof (induction cs)
  case Nil thus ?case by auto
next
  case (Cons c cs)
  let ?M' = "reset' M n cs v d"
  let ?M'' = "reset ?M' n (v c) d"
  from Cons obtain u' where u': "DBM_val_bounded v u' ?M' n" by fastforce
  from Cons(3,4) have "0 < v c" "v c \<le> n" by auto
  from DBM_reset_reset[OF this] have **: "DBM_reset ?M' n (v c) d ?M''" by fast
  from Cons(4) have "v c \<le> n" by auto
  from DBM_reset_complete[of v n c ?M' d ?M'', OF Cons(3) this ** u']
  have "DBM_val_bounded v (u'(c := d)) (reset (reset' M n cs v d) n (v c) d) n" by fast
  thus ?case by auto
qed

lemma DBM_reset'_complete:
  assumes "DBM_val_bounded v u M n" "clock_numbering' v n" "\<forall> c \<in> set cs. v c \<le> n"
  shows "DBM_val_bounded v ([cs \<rightarrow> d]u) (reset' M n cs v d) n"
using assms
proof (induction cs)
  case Nil thus ?case by auto
next
  case (Cons c cs)
  let ?M' = "reset' M n cs v d"
  let ?M'' = "reset ?M' n (v c) d"
  from Cons have *: "DBM_val_bounded v ([cs\<rightarrow>d]u) (reset' M n cs v d) n" by fastforce
  from Cons(3,4) have "0 < v c" "v c \<le> n" by auto
  from DBM_reset_reset[OF this] have **: "DBM_reset ?M' n (v c) d ?M''" by fast
  from Cons(4) have "v c \<le> n" by auto
  from DBM_reset_complete[of v n c ?M' d ?M'', OF Cons(3) this ** *]
  have ***:"DBM_val_bounded v ([c#cs\<rightarrow>d]u) (reset (reset' M n cs v d) n (v c) d) n" by simp
  have "reset' M n (c#cs) v d = reset (reset' M n cs v d) n (v c) d" by auto
  with *** show ?case by presburger
qed

lemma DBM_reset'_sound_empty:
  assumes "clock_numbering' v n" "\<forall>c \<in> set cs. v c \<le> n"
          "\<forall> u . \<not> DBM_val_bounded v u (reset' M n cs v d) n"
  shows "\<not> DBM_val_bounded v u M n"
using assms DBM_reset'_complete by metis

fun set_clocks :: "'c list \<Rightarrow> 't::time list\<Rightarrow> ('c,'t) cval \<Rightarrow> ('c,'t) cval"
where
  "set_clocks [] _ u = u" |
  "set_clocks _ [] u = u" |
  "set_clocks (c#cs) (t#ts) u = (set_clocks cs ts (u(c:=t)))"

lemma DBM_reset'_sound':
  fixes M v c n d cs
  assumes "clock_numbering' v n" "\<forall> c \<in> set cs. v c \<le> n"
          "DBM_val_bounded v u (reset' M n cs v d) n" "DBM_val_bounded v u'' M n"
  shows "\<exists>ts. DBM_val_bounded v (set_clocks cs ts u) M n"
using assms
proof (induction cs arbitrary: M u)
  case Nil
  hence "DBM_val_bounded v (set_clocks [] [] u) M n" by auto
  thus ?case by blast
next
  case (Cons c' cs)
  let ?M' = "reset' M n (c' # cs) v d"
  let ?M'' = "reset' M n cs v d"
  from DBM_reset'_complete[OF Cons(5) Cons(2)] Cons(3)
  have u'': "DBM_val_bounded v ([cs\<rightarrow>d]u'') ?M'' n" by fastforce
  from Cons(3,4) have "v c' \<le> n" "DBM_val_bounded v u (reset ?M'' n (v c') d) n" by auto
  from DBM_reset_sound''[OF Cons(2) this u'']
  obtain d' where **:"DBM_val_bounded v (u(c' := d')) ?M'' n" by blast
  from Cons.IH[OF Cons.prems(1) _ ** Cons.prems(4)] Cons.prems(2)
  obtain ts where ts:"DBM_val_bounded v (set_clocks cs ts (u(c' := d'))) M n" by fastforce
  hence "DBM_val_bounded v (set_clocks (c' # cs) (d'#ts) u) M n" by auto
  thus ?case by fast
qed

lemma DBM_reset'_resets:
  fixes M v c n d cs
  assumes "\<forall>k\<le>n. k > 0 \<longrightarrow> (\<exists>c. v c = k)" "clock_numbering' v n" "\<forall> c \<in> set cs. v c \<le> n"
          "DBM_val_bounded v u (reset' M n cs v d) n"
  shows "\<forall>c \<in> set cs. u c = d"
using assms
proof (induction cs arbitrary: M u)
  case Nil thus ?case by auto
next
  case (Cons c' cs)
  let ?M' = "reset' M n (c' # cs) v d"
  let ?M'' = "reset' M n cs v d"
  from Cons(4,5) have "v c' \<le> n" "DBM_val_bounded v u (reset ?M'' n (v c') d) n" by auto
  from DBM_reset_sound2[OF this(1) _ Cons(5), of ?M'' d] DBM_reset_reset[OF _ this(1), of ?M'' d] Cons(3)
  have c':"u c' = d" by auto
  from Cons(4,5) have "v c' \<le> n" "DBM_val_bounded v u (reset ?M'' n (v c') d) n" by auto
  with DBM_reset_sound[OF Cons.prems(1,2) this(1)]
  obtain d' where **:"DBM_val_bounded v (u(c' := d')) ?M'' n" unfolding DBM_zone_repr_def by blast
  from Cons.IH[OF Cons.prems(1,2) _ **] Cons.prems(3) have "\<forall>c\<in>set cs. (u(c' := d')) c = d" by auto
  thus ?case using c'
    by (auto split: if_split_asm)
qed

lemma DBM_reset'_resets':
  fixes M :: "('t :: time) DBM" and v c n d cs
  assumes "clock_numbering' v n" "\<forall> c \<in> set cs. v c \<le> n" "DBM_val_bounded v u (reset' M n cs v d) n"
          "DBM_val_bounded v u'' M n"
  shows "\<forall>c \<in> set cs. u c = d"
using assms
proof (induction cs arbitrary: M u)
  case Nil thus ?case by auto
next
  case (Cons c' cs)
  let ?M' = "reset' M n (c' # cs) v d"
  let ?M'' = "reset' M n cs v d"
  from DBM_reset'_complete[OF Cons(5) Cons(2)] Cons(3)
  have u'': "DBM_val_bounded v ([cs\<rightarrow>d]u'') ?M'' n" by fastforce
  from Cons(3,4) have "v c' \<le> n" "DBM_val_bounded v u (reset ?M'' n (v c') d) n" by auto
  from DBM_reset_sound2[OF this(1) _ Cons(4), of ?M'' d] DBM_reset_reset[OF _ this(1), of ?M'' d] Cons(2)
  have c':"u c' = d" by auto
  from Cons(3,4) have "v c' \<le> n" "DBM_val_bounded v u (reset ?M'' n (v c') d) n" by auto
  from DBM_reset_sound''[OF Cons(2) this u'']
  obtain d' where **:"DBM_val_bounded v (u(c' := d')) ?M'' n" by blast
  from Cons.IH[OF Cons.prems(1) _ ** Cons.prems(4)] Cons.prems(2)
  have "\<forall>c\<in>set cs. (u(c' := d')) c = d" by auto
  thus ?case using c'
    by (auto split: if_split_asm)
qed

lemma DBM_reset'_neg_diag_preservation':
  fixes M :: "('t :: time) DBM"
  assumes "k\<le>n" "M k k < 0" "clock_numbering v" "\<forall> c \<in> set cs. v c \<le> n"
  shows "reset' M n cs v d k k < 0" using assms
proof (induction cs)
  case Nil thus ?case by auto
next
  case (Cons c cs)
  then have IH: "reset' M n cs v d k k < 0" by auto
  from Cons.prems have "v c > 0" "v c \<le> n" by auto
  from DBM_reset_reset[OF this, of "reset' M n cs v d" d] \<open>k \<le> n\<close>
  have "reset (reset' M n cs v d) n (v c) d k k \<le> reset' M n cs v d k k" unfolding DBM_reset_def
    by (cases "v c = k", cases "k = 0", auto simp: less[symmetric])
  with IH show ?case by auto
qed

lemma DBM_reset'_complete_empty':
  assumes "\<forall>k\<le>n. k > 0 \<longrightarrow> (\<exists>c. v c = k)" "clock_numbering' v n"
          "\<forall> c \<in> set cs. v c \<le> n" "\<forall> u . \<not> DBM_val_bounded v u M n"
  shows "\<forall> u . \<not> DBM_val_bounded v u (reset' M n cs v d) n" using assms
proof (induction cs)
  case Nil then show ?case by simp
next
  case (Cons c cs)
  then have "\<forall>u. \<not> DBM_val_bounded v u (reset' M n cs v d) n" by auto
  from Cons.prems(2,3) DBM_reset_complete_empty'[OF Cons.prems(1) _ _ DBM_reset_reset this]
  show ?case by auto
qed

lemma DBM_reset'_complete_empty:
  assumes "\<forall>k\<le>n. k > 0 \<longrightarrow> (\<exists>c. v c = k)" "clock_numbering' v n"
          "\<forall> c \<in> set cs. v c \<le> n" "\<forall> u . \<not> DBM_val_bounded v u M n"
  shows "\<forall> u . \<not> DBM_val_bounded v u (reset' (FW M n) n cs v d) n" using assms
proof -
  note A = assms
  from A(4) have "[M]\<^bsub>v,n\<^esub> = {}" unfolding DBM_zone_repr_def by auto
  with FW_zone_equiv[OF A(1)] have "[FW M n]\<^bsub>v,n\<^esub> = {}" by auto
  with FW_detects_empty_zone[OF A(1)] A(2) obtain i where i: "i \<le> n" "FW M n i i < Le 0" by blast
  with DBM_reset'_neg_diag_preservation' A(2,3) have
    "reset' (FW M n) n cs v d i i < Le 0"
  by (auto simp: neutral)
  with fw_mono[of i n i "reset' (FW M n) n cs v d" n] i
  have "FW (reset' (FW M n) n cs v d) n i i < Le 0" by auto
  with FW_detects_empty_zone[OF A(1), of "reset' (FW M n) n cs v d"] A(2,3) i
  have "[FW (reset' (FW M n) n cs v d) n]\<^bsub>v,n\<^esub> = {}" by auto
  with FW_zone_equiv[OF A(1), of "reset' (FW M n) n cs v d"] A(3,4)
  show ?thesis by (auto simp: DBM_zone_repr_def)
qed

lemma DBM_reset'_empty':
  assumes "\<forall>k\<le>n. k > 0 \<longrightarrow> (\<exists>c. v c = k)" "clock_numbering' v n" "\<forall> c \<in> set cs. v c \<le> n"
  shows "[M]\<^bsub>v,n\<^esub> = {} \<longleftrightarrow> [reset' (FW M n) n cs v d]\<^bsub>v,n\<^esub> = {}"
proof
  let ?M' = "reset' (FW M n) n cs v d"
  assume A: "[M]\<^bsub>v,n\<^esub> = {}"
  hence "\<forall> u . \<not> DBM_val_bounded v u M n" unfolding DBM_zone_repr_def by auto
  with DBM_reset'_complete_empty[OF assms] show "[?M']\<^bsub>v,n\<^esub> = {}" unfolding DBM_zone_repr_def by auto
next
  let ?M' = "reset' (FW M n) n cs v d"
  assume A: "[?M']\<^bsub>v,n\<^esub> = {}"
  hence "\<forall> u . \<not> DBM_val_bounded v u ?M' n" unfolding DBM_zone_repr_def by auto
  from DBM_reset'_sound_empty[OF assms(2,3) this] have "\<forall> u. \<not> DBM_val_bounded v u (FW M n) n" by auto
  with FW_zone_equiv[OF assms(1)] show "[M]\<^bsub>v,n\<^esub> = {}" unfolding DBM_zone_repr_def by auto
qed

lemma DBM_reset'_empty:
  assumes "\<forall>k\<le>n. k > 0 \<longrightarrow> (\<exists>c. v c = k)" "clock_numbering' v n" "\<forall> c \<in> set cs. v c \<le> n"
  shows "[M]\<^bsub>v,n\<^esub> = {} \<longleftrightarrow> [reset' M n cs v d]\<^bsub>v,n\<^esub> = {}"
proof
  let ?M' = "reset' M n cs v d"
  assume A: "[M]\<^bsub>v,n\<^esub> = {}"
  hence "\<forall> u . \<not> DBM_val_bounded v u M n" unfolding DBM_zone_repr_def by auto
  with DBM_reset'_complete_empty'[OF assms] show "[?M']\<^bsub>v,n\<^esub> = {}" unfolding DBM_zone_repr_def by auto
next
  let ?M' = "reset' M n cs v d"
  assume A: "[?M']\<^bsub>v,n\<^esub> = {}"
  hence "\<forall> u . \<not> DBM_val_bounded v u ?M' n" unfolding DBM_zone_repr_def by auto
  from DBM_reset'_sound_empty[OF assms(2,3) this] have "\<forall> u. \<not> DBM_val_bounded v u M n" by auto
  with FW_zone_equiv[OF assms(1)] show "[M]\<^bsub>v,n\<^esub> = {}" unfolding DBM_zone_repr_def by auto
qed

lemma DBM_reset'_sound:
  assumes "\<forall>k\<le>n. k > 0 \<longrightarrow> (\<exists>c. v c = k)" "clock_numbering' v n"
    and "\<forall>c\<in>set cs. v c \<le> n"
    and "u \<in> [reset' M n cs v d]\<^bsub>v,n\<^esub>"
  shows "\<exists>ts. set_clocks cs ts u \<in> [M]\<^bsub>v,n\<^esub>"
proof -
  from DBM_reset'_empty[OF assms(1-3)] assms(4) obtain u' where "u' \<in> [M]\<^bsub>v,n\<^esub>" by blast
  with DBM_reset'_sound'[OF assms(2,3)] assms(4) show ?thesis unfolding DBM_zone_repr_def by blast
qed

section \<open>Misc Preservation Lemmas\<close>

lemma get_const_sum[simp]:
  "a \<noteq> \<infinity> \<Longrightarrow> b \<noteq> \<infinity> \<Longrightarrow> get_const a \<in> \<int> \<Longrightarrow> get_const b \<in> \<int> \<Longrightarrow> get_const (a + b) \<in> \<int>"
by (cases a) (cases b, auto simp: add)+

lemma sum_not_inf_dest:
  assumes "a + b \<noteq> (\<infinity> :: _ DBMEntry)"
  shows "a \<noteq> (\<infinity> :: _ DBMEntry) \<and> b \<noteq> (\<infinity> :: _ DBMEntry)"
using assms by (cases a; cases b; simp add: add)

lemma sum_not_inf_int:
  assumes "a + b \<noteq> (\<infinity> :: _ DBMEntry)" "get_const a \<in> \<int>" "get_const b \<in> \<int>"
  shows "get_const (a + b) \<in> \<int>"
using assms sum_not_inf_dest by fastforce

lemma int_fw_upd:
  "\<forall> i \<le> n. \<forall> j \<le> n. m i j \<noteq> \<infinity> \<longrightarrow> get_const (m i j) \<in> \<int> \<Longrightarrow> k \<le> n \<Longrightarrow> i \<le> n \<Longrightarrow> j \<le> n
  \<Longrightarrow> i' \<le> n \<Longrightarrow> j' \<le> n \<Longrightarrow> (fw_upd m k i j i' j') \<noteq> \<infinity>
  \<Longrightarrow> get_const (fw_upd m k i j i' j') \<in> \<int>"
proof (goal_cases)
  case 1
  show ?thesis
  proof (cases "i = i' \<and> j = j'")
    case True
    with 1 show ?thesis by (fastforce simp: fw_upd_def upd_def min_def dest: sum_not_inf_dest)
  next
    case False
    with 1 show ?thesis by (auto simp : fw_upd_def upd_def)
  qed
qed

abbreviation "dbm_int M n \<equiv> \<forall> i\<le>n. \<forall> j\<le>n. M i j \<noteq> \<infinity> \<longrightarrow> get_const (M i j) \<in> \<int>"

abbreviation "dbm_int_all M \<equiv> \<forall> i. \<forall> j. M i j \<noteq> \<infinity> \<longrightarrow> get_const (M i j) \<in> \<int>"

lemma dbm_intI:
  "dbm_int_all M \<Longrightarrow> dbm_int M n"
by auto

lemma fwi_int_preservation:
  "dbm_int (fwi M n k i j) n" if "dbm_int M n" "k \<le> n"
  apply (induction _ "(i, j)" arbitrary: i j rule: wf_induct[of "less_than <*lex*> less_than"])
   apply force
  subgoal for i j
    using that
    by (cases i; cases j) (auto 4 3 dest: sum_not_inf_dest simp:  min_def fw_upd_def upd_def)
  done

lemma fw_int_preservation:
  "dbm_int (fw M n k) n" if "dbm_int M n" "k \<le> n"
  using \<open>k \<le> n\<close> apply (induction k)
  using that apply simp
   apply (rule fwi_int_preservation; auto)
  using that by (simp) (rule fwi_int_preservation; auto)

lemma FW_int_preservation:
  assumes "dbm_int M n"
  shows "dbm_int (FW M n) n"
  using fw_int_preservation[OF assms(1)] by auto

lemma FW_int_all_preservation:
  assumes "dbm_int_all M"
  shows "dbm_int_all (FW M n)"
using assms
 apply clarify
 subgoal for i j
 apply (cases "i \<le> n")
 apply (cases "j \<le> n")
 by (auto simp: FW_int_preservation[OF dbm_intI[OF assms(1)]] FW_out_of_bounds1 FW_out_of_bounds2)
done

lemma And_int_all_preservation[intro]:
  assumes "dbm_int_all M1" "dbm_int_all M2"
  shows "dbm_int_all (And M1 M2)"
using assms by (auto simp: min_def)

lemma And_int_preservation:
  assumes "dbm_int M1 n" "dbm_int M2 n"
  shows "dbm_int (And M1 M2) n"
using assms by (auto simp: min_def)

lemma up_int_all_preservation:
  "dbm_int_all (M :: (('t :: {time, ring_1}) DBM)) \<Longrightarrow> dbm_int_all (up M)"
  unfolding up_def min_def add[symmetric] by (auto dest: sum_not_inf_dest split: if_split_asm)

lemma up_int_preservation:
  "dbm_int (M :: (('t :: {time, ring_1}) DBM)) n \<Longrightarrow> dbm_int (up M) n"
  unfolding up_def min_def add[symmetric] by (auto dest: sum_not_inf_dest split: if_split_asm)

(* Definitely a candidate for cleaning *)
lemma DBM_reset_int_preservation':
  assumes "dbm_int M n" "DBM_reset M n k d M'" "d \<in> \<int>" "k \<le> n"
  shows "dbm_int M' n"
proof clarify
  fix i j
  assume A: "i \<le> n" "j \<le> n" "M' i j \<noteq> \<infinity>"
  from assms(2) show "get_const (M' i j) \<in> \<int>" unfolding DBM_reset_def
    apply (cases "i = k"; cases "j = k")
       apply simp
    subgoal using A assms(1,4) by presburger
      apply (cases "j = 0")
    subgoal using assms(3) by simp
    subgoal using A by simp
     apply simp
     apply (cases "i = 0")
    subgoal using assms(3) by simp
    subgoal using A by simp
    using A apply simp
    apply (simp split: split_min, safe)
    subgoal
    proof goal_cases
      case 1
      then have *: "M i k + M k j \<noteq> \<infinity>" unfolding add min_def by meson
      with sum_not_inf_dest have "M i k \<noteq> \<infinity>" "M k j \<noteq> \<infinity>" by auto
      with 1(3,4) assms(1,4) have "get_const (M i k) \<in> \<int>" "get_const (M k j) \<in> \<int>" by auto
      with sum_not_inf_int[folded add, OF *] show ?case unfolding add by auto
    qed
    subgoal
    proof goal_cases
      case 1
      then have *: "M i j \<noteq> \<infinity>" unfolding add min_def by meson
      with 1(3,4) assms(1,4) show ?case by auto
    qed
  done
qed

lemma DBM_reset_int_preservation:
  fixes M :: "('t :: {time,ring_1}) DBM"
  assumes "dbm_int M n" "d \<in> \<int>" "0 < k" "k \<le> n"
  shows "dbm_int (reset M n k d) n"
using assms(3-) DBM_reset_int_preservation'[OF assms(1) DBM_reset_reset assms(2)] by blast

lemma DBM_reset_int_all_preservation:
  fixes M :: "('t :: {time,ring_1}) DBM"
  assumes "dbm_int_all M" "d \<in> \<int>"
  shows "dbm_int_all (reset M n k d)"
using assms
 apply clarify
 subgoal for i j
   by (cases "i = k"; cases "j = k";
       auto simp: reset_def min_def add[symmetric] dest!: sum_not_inf_dest
       )
done

lemma DBM_reset'_int_all_preservation:
  fixes M :: "('t :: {time, ring_1}) DBM"
  assumes "dbm_int_all M" "d \<in> \<int>"
  shows "dbm_int_all (reset' M n cs v d)" using assms
by (induction cs) (simp | rule DBM_reset_int_all_preservation)+

lemma DBM_reset'_int_preservation:
  fixes M :: "('t :: {time, ring_1}) DBM"
  assumes "dbm_int M n" "d \<in> \<int>" "\<forall>c. v c > 0" "\<forall> c \<in> set cs. v c \<le> n"
  shows "dbm_int (reset' M n cs v d) n" using assms
proof (induction cs)
  case Nil then show ?case by simp
next
  case (Cons c cs)
  from Cons.IH[OF Cons.prems(1,2,3)] Cons.prems(4) have "dbm_int (reset' M n cs v d) n"
    by fastforce
  from DBM_reset_int_preservation[OF this Cons.prems(2), of "v c"] Cons.prems(3,4) show ?case
    by auto
qed

lemma reset_set1:
  "\<forall>c \<in> set cs. ([cs\<rightarrow>d]u) c = d"
by (induction cs) auto

lemma reset_set11:
  "\<forall>c. c \<notin> set cs \<longrightarrow> ([cs\<rightarrow>d]u) c = u c"
by (induction cs) auto

lemma reset_set2:
  "\<forall>c. c \<notin> set cs \<longrightarrow> (set_clocks cs ts u)c = u c"
proof (induction cs arbitrary: ts u)
  case Nil then show ?case by auto
next
  case Cons then show ?case
  proof (cases ts, goal_cases)
   case Nil then show ?thesis by simp
  next
    case (2 a') then show ?case by auto
  qed
qed

lemma reset_set:
  assumes "\<forall> c \<in> set cs. u c = d"
  shows "[cs\<rightarrow>d](set_clocks cs ts u) = u"
proof
  fix c
  show "([cs\<rightarrow>d]set_clocks cs ts u) c = u c"
  proof (cases "c \<in> set cs")
    case True
    hence "([cs\<rightarrow>d]set_clocks cs ts u) c = d" using reset_set1 by fast
    also have "d = u c" using assms True by auto
    finally show ?thesis by auto
  next
    case False
    hence "([cs\<rightarrow>d]set_clocks cs ts u) c = set_clocks cs ts u c" by (simp add: reset_set11)
    also  with False have "\<dots> = u c" by (simp add: reset_set2)
    finally show ?thesis by auto
  qed
qed


subsection \<open>Unused theorems\<close>

lemma canonical_cyc_free:
  "canonical M n \<Longrightarrow> \<forall>i \<le> n. M i i \<ge> 0 \<Longrightarrow> cyc_free M n"
  by (auto dest!: canonical_len)

lemma canonical_cyc_free2:
  "canonical M n \<Longrightarrow> cyc_free M n \<longleftrightarrow> (\<forall>i \<le> n. M i i \<ge> 0)"
  apply safe
  apply (simp add: cyc_free_diag_dest')
  using canonical_cyc_free by blast

lemma DBM_reset'_diag_preservation:
  fixes M :: "('t :: time) DBM"
  assumes "\<forall>k\<le>n. M k k \<le> 0" "clock_numbering v" "\<forall> c \<in> set cs. v c \<le> n"
  shows "\<forall>k\<le>n. reset' M n cs v d k k \<le> 0" using assms
proof (induction cs)
  case Nil thus ?case by auto
next
  case (Cons c cs)
  then have IH: "\<forall>k\<le>n. reset' M n cs v d k k \<le> 0" by auto
  from Cons.prems have "v c > 0" "v c \<le> n" by auto
  from DBM_reset_diag_preservation[of n "reset' M n cs v d", OF IH DBM_reset_reset, of "v c", OF this]
  show ?case by simp
qed

end
