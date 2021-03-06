theory Find_First imports Main begin

fun plus :: "'a option \<Rightarrow> 'a option \<Rightarrow> 'a option"
where
  "plus None r = r"
| "plus l r = l"

lemma plus_assoc [simp]: "plus (plus x y) z = plus x (plus y z)"
by(cases x) simp_all

lemma plus_None [simp]: "plus x None = x"
by(cases x) simp_all

type_synonym ('a, 'b) af = "'a option \<times> 'b"

definition pure :: "'b \<Rightarrow> ('a, 'b) af"
where "pure x = (None, x)"

fun ap :: "('a, 'b \<Rightarrow> 'c) af \<Rightarrow> ('a, 'b) af \<Rightarrow> ('a, 'c) af" (infixl "\<diamond>" 60)
where "ap (u, f) (v, x) = (plus u v, f x)"

lemma af_identity: "pure id \<diamond> x = x"
unfolding pure_def by(cases x) simp

lemma af_homomorphism: "pure f \<diamond> pure x = pure (f x)"
unfolding pure_def by simp

lemma af_composition: "\<And>g f x. pure comp \<diamond> g \<diamond> f \<diamond> x = g \<diamond> (f \<diamond> x)"
unfolding pure_def by(clarsimp)

lemma af_interchange: "f \<diamond> pure x = pure (\<lambda>g. g x) \<diamond> f"
unfolding pure_def by(cases f) simp

definition H :: "('x, ('a \<Rightarrow> 'b \<Rightarrow> 'a \<Rightarrow> 'c) \<Rightarrow> 'a \<Rightarrow> 'b \<Rightarrow> 'c) af"
where "H = pure (\<lambda>f x y. f x y x)"

lemma ap_H: "H \<diamond> f \<diamond> x \<diamond> y = f \<diamond> x \<diamond> y \<diamond> x"
unfolding H_def pure_def
apply(cases f)
apply(cases x)
apply(cases y)
apply(rename_tac u f' v g' w x')
apply(case_tac u)
 apply(case_tac v)
  apply(case_tac w)
 apply simp_all
done

end