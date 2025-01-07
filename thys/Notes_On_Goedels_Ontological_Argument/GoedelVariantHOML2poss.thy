subsection\<open>GoedelVariantHOML2poss.thy (Figure 17 of \cite{J75})\<close>
text\<open>After an appropriate modification of the definition of essence, the inconsistency revealed in
Figure 16 is avoided, and the argument can be successfully verified in modal logic S5 (indeed, as shown,
only the modal schema B is actually needed). In contrast to Figure 7 we here use only possibilist
quantifiers to obtain these results.\<close>
theory GoedelVariantHOML2poss imports HOMLinHOL ModalFilter
begin 

consts PositiveProperty::"(e\<Rightarrow>\<sigma>)\<Rightarrow>\<sigma>" ("P") 

axiomatization where Ax1: "\<lfloor>P \<phi> \<^bold>\<and> P \<psi> \<^bold>\<supset> P (\<phi> \<^bold>. \<psi>)\<rfloor>"

axiomatization where Ax2a: "\<lfloor>P \<phi> \<^bold>\<or>\<^sup>e P \<^bold>~\<phi>\<rfloor>"

definition God ("G") where "G x \<equiv> \<^bold>\<forall>\<phi>. P \<phi> \<^bold>\<supset> \<phi> x"

abbreviation PropertyInclusion ("_\<^bold>\<supset>\<^sub>N_") where "\<phi> \<^bold>\<supset>\<^sub>N \<psi> \<equiv> \<^bold>\<box>(\<^bold>\<forall>y::e. \<phi> y \<^bold>\<supset> \<psi> y)"

definition Essence ("_Ess._") where "\<phi> Ess. x \<equiv> \<phi> x \<^bold>\<and> (\<^bold>\<forall>\<psi>. \<psi> x \<^bold>\<supset> (\<phi> \<^bold>\<supset>\<^sub>N \<psi>))"

axiomatization where Ax2b: "\<lfloor>P \<phi> \<^bold>\<supset> \<^bold>\<box> P \<phi>\<rfloor>"

lemma Ax2b': "\<lfloor>\<^bold>\<not>P \<phi> \<^bold>\<supset> \<^bold>\<box>(\<^bold>\<not>P \<phi>)\<rfloor>" using Ax2a Ax2b by blast

theorem Th1: "\<lfloor>G x \<^bold>\<supset> G Ess. x\<rfloor>" using Ax2a Ax2b Essence_def God_def by (smt (verit))

definition NecExist ("E") where "E x \<equiv> \<^bold>\<forall>\<phi>. \<phi> Ess. x \<^bold>\<supset> \<^bold>\<box>(\<^bold>\<exists>x. \<phi> x)"

axiomatization where Ax3: "\<lfloor>P E\<rfloor>"

theorem Th2: "\<lfloor>G x \<^bold>\<supset> \<^bold>\<box>(\<^bold>\<exists>y. G y)\<rfloor>" using Ax3 Th1 God_def NecExist_def by smt

theorem Th3: "\<lfloor>\<^bold>\<diamond>(\<^bold>\<exists>x. G x) \<^bold>\<supset> \<^bold>\<box>(\<^bold>\<exists>y. G y)\<rfloor>" 
  \<comment>\<open>sledgehammer(Th2 Rsymm)\<close> \<comment>\<open>Proof found\<close>
  proof -
    have 1: "\<lfloor>(\<^bold>\<exists>x. G x) \<^bold>\<supset> \<^bold>\<box>(\<^bold>\<exists>y. G y)\<rfloor>" using Th2 by blast
    have 2: "\<lfloor>\<^bold>\<diamond>(\<^bold>\<exists>x. G x) \<^bold>\<supset> \<^bold>\<diamond>\<^bold>\<box>(\<^bold>\<exists>y. G y)\<rfloor>" using 1 by blast
    have 3: "\<lfloor>\<^bold>\<diamond>(\<^bold>\<exists>x. G x) \<^bold>\<supset> \<^bold>\<box>(\<^bold>\<exists>y. G y)\<rfloor>" using 2 Rsymm by blast
    thus ?thesis by blast
  qed

axiomatization where Ax4: "\<lfloor>P \<phi> \<^bold>\<and> (\<phi> \<^bold>\<supset>\<^sub>N \<psi>) \<^bold>\<supset> P \<psi>\<rfloor>"

lemma True nitpick[satisfy,card=1,eval="\<lfloor>P (\<lambda>x.\<^bold>\<bottom>)\<rfloor>"] oops \<comment>\<open>One model found of cardinality one\<close>

abbreviation "PosProps \<Phi> \<equiv> \<^bold>\<forall>\<phi>. \<Phi> \<phi> \<^bold>\<supset> P \<phi>"
abbreviation "ConjOfPropsFrom \<phi> \<Phi> \<equiv> \<^bold>\<box>(\<^bold>\<forall>z. \<phi> z \<^bold>\<leftrightarrow> (\<^bold>\<forall>\<psi>. \<Phi> \<psi> \<^bold>\<supset> \<psi> z))"
axiomatization where Ax1Gen: "\<lfloor>(PosProps \<Phi> \<^bold>\<and> ConjOfPropsFrom \<phi> \<Phi>) \<^bold>\<supset> P \<phi>\<rfloor>" 

lemma L: "\<lfloor>P G\<rfloor>" using Ax1Gen God_def by smt

theorem Th4: "\<lfloor>\<^bold>\<diamond>(\<^bold>\<exists>x. G x)\<rfloor>" using Ax2a Ax4 L by blast

theorem Th5: "\<lfloor>\<^bold>\<box>(\<^bold>\<exists>x. G x)\<rfloor>" using Th3 Th4 by blast

lemma MC: "\<lfloor>\<phi> \<^bold>\<supset> \<^bold>\<box>\<phi>\<rfloor>" 
  \<comment>\<open>sledgehammer(Ax2a Ax2b Th5 God\_def Rsymm)\<close> \<comment>\<open>Proof found\<close>
  proof - {fix w fix Q
    have 1: "\<forall>x.(G x w \<longrightarrow> (\<^bold>\<forall>Z. Z x \<^bold>\<supset> \<^bold>\<box>(\<^bold>\<forall>z. G z \<^bold>\<supset> Z z)) w)" using Ax2a Ax2b God_def by smt
    have 2: "(\<exists>x. G x w)\<longrightarrow>((Q \<^bold>\<supset> \<^bold>\<box>(\<^bold>\<forall>z. G z \<^bold>\<supset> Q)) w)" using 1 by force
    have 3: "(Q \<^bold>\<supset> \<^bold>\<box>Q) w"using 2 Th5 Rsymm by blast} 
   thus ?thesis by auto 
 qed

lemma PosProps: "\<lfloor>P (\<lambda>x.\<^bold>\<top>) \<^bold>\<and> P (\<lambda>x. x \<^bold>= x)\<rfloor>" using Ax2a Ax4 by blast
lemma NegProps: "\<lfloor>\<^bold>\<not>P(\<lambda>x.\<^bold>\<bottom>) \<^bold>\<and> \<^bold>\<not>P(\<lambda>x. x \<^bold>\<noteq> x)\<rfloor>" using Ax2a Ax4 by blast
lemma UniqueEss1: "\<lfloor>\<phi> Ess. x \<^bold>\<and> \<psi> Ess. x \<^bold>\<supset> \<^bold>\<box>(\<^bold>\<forall>y. \<phi> y \<^bold>\<leftrightarrow> \<psi> y)\<rfloor>" using Essence_def by smt
lemma UniqueEss2: "\<lfloor>\<phi> Ess. x \<^bold>\<and> \<psi> Ess. x \<^bold>\<supset> \<^bold>\<box>(\<phi> \<^bold>\<equiv> \<psi>)\<rfloor>" nitpick[card i=2] oops \<comment>\<open>Countermodel found\<close>
lemma UniqueEss3: "\<lfloor>\<phi> Ess. x \<^bold>\<supset> \<^bold>\<box>(\<^bold>\<forall>y. \<phi> y \<^bold>\<supset> y \<^bold>\<equiv> x)\<rfloor>" using Essence_def MC by auto
lemma Monotheism: "\<lfloor>G x \<^bold>\<and> G y \<^bold>\<supset> x \<^bold>\<equiv> y\<rfloor>" using Ax2a God_def by smt
lemma Filter: "\<lfloor>FilterP P\<rfloor>" using Ax1 Ax4 MC NegProps PosProps Rsymm by smt
lemma UltraFilter: "\<lfloor>UFilterP P\<rfloor>" using Ax2a Filter by smt 
lemma True nitpick[satisfy,card=1,eval="\<lfloor>P (\<lambda>x.\<^bold>\<bottom>)\<rfloor>"] oops \<comment>\<open>One model found of cardinality one\<close>

end



