theory DNEList imports
  "$AFP/Applicative_Lifting/Applicative_List"
  "~~/src/HOL/Library/Dlist"
begin

lemma bind_eq_Nil_iff [simp]: "List.bind xs f = [] \<longleftrightarrow> (\<forall>x\<in>set xs. f x = [])"
by(simp add: List.bind_def)

lemma zip_eq_Nil_iff [simp]: "zip xs ys = [] \<longleftrightarrow> xs = [] \<or> ys = []"
by(cases xs ys rule: list.exhaust[case_product list.exhaust]) simp_all

lemma fst_swap [simp]: "fst (prod.swap x) = snd x"
by(cases x) simp

lemma snd_swap [simp]: "snd (prod.swap x) = fst x"
by(cases x) simp

lemma remdups_append1: "remdups (remdups xs @ ys) = remdups (xs @ ys)"
by(induction xs) simp_all

lemma remdups_append2: "remdups (xs @ remdups ys) = remdups (xs @ ys)"
by(induction xs) simp_all

lemma remdups_append1_drop: "set xs \<subseteq> set ys \<Longrightarrow> remdups (xs @ ys) = remdups ys"
by(induction xs) auto

lemma remdups_concat_map: "remdups (concat (map remdups xss)) = remdups (concat xss)"
by(induction xss)(simp_all add: remdups_append1, metis remdups_append2)

lemma remdups_concat_remdups: "remdups (concat (remdups xss)) = remdups (concat xss)"
apply(induction xss)
apply(auto simp add: remdups_append1_drop)
 apply(subst remdups_append1_drop; auto)
apply(metis remdups_append2)
done

lemma remdups_replicate: "remdups (replicate n x) = (if n = 0 then [] else [x])"
by(induction n) simp_all


typedef 'a dnelist = "{xs::'a list. distinct xs \<and> xs \<noteq> []}"
  morphisms list_of_dnelist Abs_dnelist
proof
  show "[x] \<in> ?dnelist" for x by simp
qed

setup_lifting type_definition_dnelist

lemma dnelist_subtype_dlist:
  "type_definition (\<lambda>x. Dlist (list_of_dnelist x)) (\<lambda>x. Abs_dnelist (list_of_dlist x)) {xs. xs \<noteq> Dlist.empty}"
apply unfold_locales
subgoal by(transfer; auto simp add: dlist_eq_iff)
subgoal by(simp add: distinct_remdups_id dnelist.list_of_dnelist[simplified] list_of_dnelist_inverse)
subgoal by(simp add: dlist_eq_iff Abs_dnelist_inverse)
done

lift_bnf 'a dnelist via dnelist_subtype_dlist for map: map by(simp_all add: dlist_eq_iff)
hide_const (open) map

context begin
qualified lemma map_def: "DNEList.map = map_fun id (map_fun list_of_dnelist Abs_dnelist) (\<lambda>f xs. remdups (list.map f xs))"
unfolding map_def by(simp add: fun_eq_iff distinct_remdups_id list_of_dnelist[simplified])

qualified lemma map_transfer [transfer_rule]:
  "rel_fun op = (rel_fun (pcr_dnelist op =) (pcr_dnelist op =)) (\<lambda>f xs. remdups (map f xs)) DNEList.map"
by(simp add: map_def rel_fun_def dnelist.pcr_cr_eq cr_dnelist_def list_of_dnelist[simplified] Abs_dnelist_inverse)

qualified lift_definition single :: "'a \<Rightarrow> 'a dnelist" is "\<lambda>x. [x]" by simp
qualified lift_definition insert :: "'a \<Rightarrow> 'a dnelist \<Rightarrow> 'a dnelist" is "\<lambda>x xs. if x \<in> set xs then xs else x # xs" by auto
qualified lift_definition append :: "'a dnelist \<Rightarrow> 'a dnelist \<Rightarrow> 'a dnelist" is "\<lambda>xs ys. remdups (xs @ ys)" by auto
qualified lift_definition bind :: "'a dnelist \<Rightarrow> ('a \<Rightarrow> 'b dnelist) \<Rightarrow> 'b dnelist" is "\<lambda>xs f. remdups (List.bind xs f)" by auto

abbreviation (input) pure_dnelist :: "'a \<Rightarrow> 'a dnelist"
where "pure_dnelist \<equiv> single"

end

lift_definition ap_dnelist :: "('a \<Rightarrow> 'b) dnelist \<Rightarrow> 'a dnelist \<Rightarrow> 'b dnelist"
is "\<lambda>f x. remdups (ap_list f x)"
by(auto simp add: ap_list_def)

adhoc_overloading Applicative.ap ap_dnelist

lemma ap_pure_list [simp]: "ap_list [f] xs = map f xs"
by(simp add: ap_list_def List.bind_def)

context begin interpretation applicative_syntax .

lemma ap_pure_dlist: "pure_dnelist f \<diamondop> x = DNEList.map f x"
by transfer simp

applicative dnelist (K)
for pure: pure_dnelist
    ap: ap_dnelist
proof -
  show "pure_dnelist (\<lambda>x. x) \<diamondop> x = x" for x :: "'a dnelist"
    by transfer simp
  show "pure_dnelist (\<lambda>g f x. g (f x)) \<diamondop> g \<diamondop> f \<diamondop> x = g \<diamondop> (f \<diamondop> x)"
    for g :: "('c \<Rightarrow> 'b) dnelist" and f :: "('a \<Rightarrow> 'c) dnelist" and x
    apply transfer
    apply(simp add: ap_list_def List.bind_def)
    apply(subst (2) remdups_concat_remdups[symmetric])
    apply(subst remdups_map_remdups)
    apply simp
    apply(subst remdups_concat_remdups)
    apply(subst (1) remdups_concat_remdups[symmetric])
    apply(subst remdups_map_remdups)
    apply(subst remdups_concat_remdups)
    apply(subst (2) remdups_concat_map[symmetric])
    apply(simp add: o_def)
    apply(subst remdups_map_remdups)
    apply(subst (5) list.map_comp[symmetric, unfolded o_def]) back back back back
    apply(subst remdups_concat_map)
    subgoal for g f x using list.afun_comp[of g f x]
      by(simp add: ap_list_def List.bind_def o_def)
    done
  show "pure_dnelist f \<diamondop> pure_dnelist x = pure_dnelist (f x)" for f :: "'a \<Rightarrow> 'b" and x
    by transfer simp
  show "f \<diamondop> pure_dnelist x = pure_dnelist (\<lambda>f. f x) \<diamondop> f" for f :: "('a \<Rightarrow> 'b) dnelist" and x
    by transfer(simp add: list.afun_ichng)
  show "pure_dnelist (\<lambda>x y. x) \<diamondop> x \<diamondop> y = x" 
    for x :: "'b dnelist" and y :: "'a dnelist"
    apply transfer
    apply(simp add: ap_list_def List.bind_def)
    apply(subst (2) distinct_remdups_id)
    apply(simp add: distinct_map)
    apply(rule inj_onI)
    apply(simp add: fun_eq_iff)
    apply(simp add: o_def map_replicate_const)
    apply(subst remdups_concat_map[symmetric])
    apply(simp add: o_def remdups_replicate)
    done
qed


text \<open>@{typ "_ dnelist"} does not have combinator C, so it cannot have W either.\<close>

context begin 
private lift_definition x :: "int dnelist" is "[2,3]" by simp
private lift_definition y :: "int dnelist" is "[5,7]" by simp
private lemma "pure_dnelist (\<lambda>f x y. f y x) \<diamondop> pure_dnelist (op *) \<diamondop> x \<diamondop> y \<noteq> pure_dnelist (op *) \<diamondop> y \<diamondop> x"
  by transfer(simp add: ap_list_def fun_eq_iff)
end

end

end