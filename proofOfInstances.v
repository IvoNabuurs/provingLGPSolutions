Require Import String.
Open Scope string_scope.

Require Import List.
Open Scope list_scope.

Require Import Lia.

(* The element is used to make it possible for lists to store natural numbers and strings. *)
Inductive element : Type :=
| nat_ (n : nat)
| str_ (s : string).

(* The Convert class is used to convert one type to another type. *)
Class Convert (A B : Type) := {
  convert : A -> B
}.

Instance NatToElement : Convert nat element := {
  convert (n : nat) := nat_ n 
}.

Instance StrToElement : Convert string element := {
  convert (s : string) := str_ s 
}.

Instance ListToElement : Convert (list element) (list element) := {
  convert (lst : list element) := lst 
}.

Instance ElementToElement : Convert element element := {
  convert (el : element) := match el with 
                            | nat_ n => nat_ n 
                            | str_ s => str_ s 
                            end
}.

(* List need a new notation, so that prefixes do not have to be typed in lists. *)
Notation "[ ]" := nil.
Notation "[ x ]" := (cons (convert x) nil).
Notation "[ x , y , .. , z ]" := (cons (convert x) (cons (convert y) .. (cons (convert z) nil) ..)).

(* Coercion is used, so that prefixes do not have to be typed outside of lists. *)
Definition natToElement (n : nat) := nat_ n.
Coercion natToElement : nat >-> element.

Definition strToElement (s : string) := str_ s.
Coercion strToElement : string >-> element.

(* Defintion of the solution to the logic grid puzzle. *)
Definition solution : list (list element) := 
[[1525, "Yamasaki", "Usui", "rooster"],
 [1585, "Okabe Honzo", "Miyato", "frog"],
 [1645, "Hori Takesi", "Funai", "dragon"],
 [1705, "Amari Michi", "Niwa", "deer"]].

(* Definitions needed for preconditions. *)
Definition uniqueElementsInChain : Prop := 
forall chain : list element, 
    In chain solution 
  -> 
    ~(exists x : element, 
        exists n1 n2 : nat, 
          n1 <> n2 /\ nth_error chain n1 = Some x /\ nth_error chain n2 = Some x).

Definition uniqueElementsOutsideChain : Prop := 
forall n1 n2 : nat, 
    n1 <> n2 
  -> 
    forall chain1 chain2 : list element, 
        chain1 = (nth n1 solution []) /\ chain2 = (nth n2 solution []) 
      -> 
        ~(exists x : element, In x chain1 /\ In x chain2).

Definition sameNrOfElements : Prop := 
exists n : nat, (forall chain : list element, In chain solution -> length chain = n).

Definition preconditions : Prop := 
uniqueElementsInChain /\ uniqueElementsOutsideChain /\ sameNrOfElements.

(* Ltac tactics needed for uniqueElementsInChain. *)
Ltac destructDisjunction hyp tac := destruct hyp as [hyp | hyp];
match type of hyp with 
  | False => contradiction 
  | _ \/ _ => destructDisjunction hyp tac 
  | _ => tac; fail 
end.

Ltac loopOverIndex index rep baseTac endTac := 
match goal with 
  | [ i : nat |- _ ] => match rep with 
                          | O => destruct index; endTac 
                          | S ?n => destruct index; loopOverIndex index n baseTac endTac 
                        end 
  | [ _ : ?i <> ?i |- _ ] => contradiction 
  | _ => baseTac 
end.

Ltac loopOverFirstIndex n1 n2 H3 H4 := 
let len := eval compute in (length (nth 0 solution [])) 
  in loopOverIndex n1 len 
       ltac:(simpl in H3; rewrite <- H3 in H4; 
             loopOverIndex n2 len ltac:(simpl in H4; discriminate) 
                                  ltac:(simpl in H4; discriminate))
       ltac:(simpl in H3; discriminate).

Ltac proveUniqueElementsInChain := 
unfold uniqueElementsInChain; intros chain H1 H2; destruct H2 as [x H2]; 
destruct H2 as [n1 H2]; destruct H2 as [n2 H2]; destruct H2 as [H2 H3]; 
destruct H3 as [H3 H4]; simpl in H1; 
destructDisjunction H1 ltac:(rewrite <- H1 in H3; 
                             rewrite <- H1 in H4;
                             loopOverFirstIndex n1 n2 H3 H4).

(* Ltac tactics needed for uniqueElementsOutsideChain *)
Ltac proveUniqueElementsOutsideChain := 
intros n1 n2 H1 chain1 chain2 H2 H4; destruct H2 as [H2 H3];
destruct H4 as [x H4]; destruct H4 as [H4 H5];
let len := eval compute in (length solution) 
  in loopOverIndex n1 len 
       ltac:(simpl in H2; rewrite -> H2 in H4; simpl in H4; 
             loopOverIndex n2 len 
               ltac:(simpl in H3; rewrite -> H3 in H5; simpl in H5;
                     destructDisjunction H4 
                       ltac:(destructDisjunction H5 
                               ltac:(rewrite <- H4 in H5; discriminate))) 
               ltac:(simpl in H3; rewrite -> H3 in H5; simpl in H5; contradiction)) 
       ltac:(simpl in H2; rewrite -> H2 in H4; simpl in H4; contradiction).

(* Ltac tactics needed for sameNrOfElements. *)
Ltac proveSameNrOfElements := 
let len := eval compute in (length (nth 0 solution [])) 
  in exists len;
simpl; intros chain H1; destructDisjunction H1 ltac:(rewrite <- H1; simpl; reflexivity).

(* Ltac tactics needed for preconditions. *)
Ltac provePreconditions := repeat split; 
match goal with 
  | [ |- uniqueElementsInChain ] => proveUniqueElementsInChain 
  | [ |- uniqueElementsOutsideChain ] => proveUniqueElementsOutsideChain 
  | [ |- sameNrOfElements ] => proveSameNrOfElements 
  | _ => fail 
end.

(* Proof of an Instance *)
Example testPreconditions : preconditions.
Proof.
provePreconditions.
Qed.

(* Definitions needed for the Direct Link clue type. *)
Definition directLinkConverted (x y : element) : Prop := 
exists chain : list element, In x chain /\ In y chain /\ In chain solution /\ x <> y.

Definition directLink (x y : element) : Prop := 
directLinkConverted (convert x) (convert y).

(* Ltac tactics needed for the Direct Link clue type. *)
Ltac proveIn := 
match goal with 
| [ |- In _ _ ] => simpl; proveIn
| [ |- ?a = ?a \/ _ ] => left; reflexivity 
| [ |- _ \/ _ ] => right; proveIn 
| _ => fail 
end.

Ltac tryChainsRec index len tactic :=
match goal with 
| [ |- exists _, _ ] => match index with 
                        | S ?n => (exists (nth n solution []); tryChainsRec len len tactic) || tryChainsRec n len tactic 
                        | O => fail 
                        end 
| [ |- _ ] => tactic 
end.

Ltac proveDirectLink := 
unfold directLink; simpl convert; unfold directLinkConverted; 
let len := eval compute in (length solution) 
  in tryChainsRec len len ltac:(repeat split; try proveIn; discriminate).

(* Proof of an Instance *)
Lemma testDirectLink : directLink 1705 "deer".
Proof.
proveDirectLink. 
Qed.

(* Definitions needed for the No Link clue type *)
Definition noLinkConverted (x y : element) : Prop := 
forall chain : list element, In chain solution -> ~(In x chain /\ In y chain).

Definition noLink (x y : element) : Prop := 
noLinkConverted (convert x) (convert y).

Ltac proveNoLink := 
unfold noLink; simpl convert; intros chain H1 H2; destruct H2 as [H2 H3]; simpl in H1; 
destructDisjunction H1 
  ltac:((rewrite <- H1 in H2; simpl in H2; destructDisjunction H2 ltac:(discriminate)) 
        || (rewrite <- H1 in H3; simpl in H3; destructDisjunction H3 ltac:(discriminate))).

(* Proof of an Instance *)
Lemma testNoLink : noLink "Amari Michi" 1525.
Proof.
proveNoLink.
Qed.

(* Definitions needed for the Either clue type. *)
Definition eitherConverted (x y z : element) : Prop := 
exists chain, 
  In x chain /\ (In y chain \/ In z chain) /\ ~(In y chain /\ In z chain) /\ 
  In chain solution /\ x <> y /\ x <> z.

Definition either (x y z : element) : Prop := 
eitherConverted (convert x) (convert y) (convert z).

(* Ltac tactics needed for the Either clue type. *)
Ltac tryChain := repeat split;
match goal with 
  | [ |- In _ _ ] => proveIn
  | [ |- _ \/ _ ] => (left; proveIn) || (right; proveIn)
  | [ |- _ <> _ ] => discriminate 
  | [ |- ~(_ /\ _) ] => simpl; intros H1; destruct H1 as [H1 H2]; 
                        (destructDisjunction H1 ltac:(discriminate) 
                         || destructDisjunction H2 ltac:(discriminate))
  | _ => fail 
end.

Ltac proveEither := 
unfold either; simpl convert; unfold eitherConverted; 
let len := eval compute in (length solution) 
  in tryChainsRec len len ltac:(tryChain).

(* Proof of an Instance *)
Lemma testEither : either "rooster" "Amari Michi" 1525.
Proof.
Time proveEither.
Qed.

(* Definitions needed for the alternative definition of the Either clue type. *)
Definition eitherAltConverted (x y z : element) := 
(directLinkConverted x y \/ directLinkConverted x z) /\ noLinkConverted y z.

Definition eitherAlt (x y z : element) := 
eitherAltConverted (convert x) (convert y) (convert z).

(* Ltac tactics needed for the alternative definition of the Either clue type. *)
Ltac proveEitherAlt := 
unfold eitherAlt; simpl convert; split; 
try ((left; proveDirectLink) || (right; proveDirectLink)); proveNoLink.

(* Proof of an Instance *)
Lemma testEitherAlt : eitherAlt "rooster" "Amari Michi" 1525.
Proof.
Time proveEitherAlt.
Qed.

(* Definition needed for the All Different clue type. *)
Definition allDifferent (lst : list element) : Prop := 
  ~(exists x : element, 
      exists n1 n2 : nat, 
        n1 <> n2 /\ nth_error lst n1 = Some x /\ nth_error lst n2 = Some x) 
/\
  forall el : element, 
    forall chain : list element, 
        In chain solution /\ In el lst /\ In el chain 
      -> 
        forall el2 : element, 
          In el2 lst /\ el <> el2 -> ~(In el2 chain).

(* Ltac tactics needed for the All Different clue type. *)
Ltac contradictionInH3OrH6 chainH elOrEl2H contradictionH := 
rewrite <- chainH in contradictionH; rewrite <- elOrEl2H in contradictionH; 
simpl in contradictionH; destructDisjunction contradictionH ltac:(discriminate).

Ltac contradictionInH5 H2 H4 H5 := 
rewrite <- H2 in H5; rewrite <- H4 in H5; contradiction.

Ltac tryAllDifferent el el2 chain H1 H2 H3 H4 H5 H6 :=
match goal with 
  | [ _ : False |- _ ] => contradiction 
  | [ _ : _ = chain \/ _ |- _ ] => destruct H1 as [H1 | H1]; 
                                   tryAllDifferent el el2 chain H1 H2 H3 H4 H5 H6 
  | [ _ : _ = el \/ _ |- _ ] => destruct H2 as [H2 | H2]; 
                                tryAllDifferent el el2 chain H1 H2 H3 H4 H5 H6 
  | [ _ : _ = el, _ : _ = el2 \/ _ |- _ ] => contradictionInH3OrH6 H1 H2 H3 
  | [ _ : _ = el2 \/ _ |- _ ] => repeat destruct H4 as [H4 | H4]; 
                                 tryAllDifferent el el2 chain H1 H2 H3 H4 H5 H6 
  | [ _ : ?e = el, _ : ?e = el2 |- _ ] => contradictionInH5 H2 H4 H5 
  | [ _ : _ = el, _ : _ = el2 |- _ ] => contradictionInH3OrH6 H1 H4 H6 
  | _ => fail 
end.

Ltac uniqueList := 
intros H1; destruct H1 as [x H1]; destruct H1 as [n1 H1];
destruct H1 as [n2 H1]; destruct H1 as [H1 H2]; destruct H2 as [H2 H3];
match type of H2 with 
  | nth_error ?lst _ = _ => let len := eval compute in (length lst) 
                              in loopOverIndex n1 len 
                                   ltac:(simpl in H2; rewrite <- H2 in H3; 
                                         loopOverIndex n2 len ltac:(simpl in H3; discriminate) 
                                                              ltac:(simpl in H3; discriminate))
                                   ltac:(simpl in H2; discriminate) 
  | _ => fail 
end.

Ltac proveAllDifferent :=
split;
match goal with 
  | [ |- ~(exists _, _) ] => uniqueList 
  | [ |- forall _, _ ] => intros el chain H1 el2 H4 H6; destruct H1 as [H1 H2];
                          destruct H2 as [H2 H3]; destruct H4 as [H4 H5]; 
                          simpl in H1, H2, H4; tryAllDifferent el el2 chain H1 H2 H3 H4 H5 H6 
  | _ => fail 
end.

(* Proof of an Instance *)
Lemma testAllDifferent : allDifferent ["Okabe Honzo", "Usui", "Niwa"].
Proof. 
proveAllDifferent.
Qed.

(* Definitions needed for the Two Pairs clue type. *)
Definition twoPairsConverted (x1 x2 y1 y2 : element) := 
x1 <> x2 /\ x1 <> y1 /\ x1 <> y2 /\ x2 <> y1 /\ x2 <> y2 /\ y1 <> y2 /\ 
(exists chain : list element, 
   In x1 chain /\ ~(In x2 chain) /\ (In y1 chain \/ In y2 chain) /\ In chain solution) /\ 
(exists chain : list element, 
   In x2 chain /\ (In y1 chain \/ In y2 chain) /\ In chain solution).

Definition twoPairs (x1 x2 y1 y2 : element) := twoPairsConverted (convert x1) (convert x2) (convert y1) (convert y2).

(* Ltac tactics needed for the Two Pairs clue type. *)
Ltac proveTwoPairsForOneChain := repeat split; 
match goal with 
  | [ |- In _ _ ] => proveIn 
  | [ |- _ \/ _ ] => (left; proveIn) || (right; proveIn) 
  | [ |- ~(In _ _) ] => simpl; intros H1; destructDisjunction H1 ltac:(discriminate) 
  | _ => fail 
end. 

Ltac proveTwoPairs := unfold twoPairs; simpl convert; 
repeat split; 
match goal with 
  | [ |- _ <> _ ] => discriminate
  | [ |- exists _, _ ] => let len := eval compute in (length solution) 
                            in tryChainsRec len len ltac:(proveTwoPairsForOneChain) 
  | _ => fail 
end.

(* Proof of an Instance *)
Lemma testTwoPairs : twoPairs "Funai" "rooster" "Hori Takesi" 1525.
Proof. 
proveTwoPairs.
Qed.

(* Definitions needed for the Comparison clue type. *)
Definition comparisonConverted (x y : element) (cat : nat) (compFun : element -> element -> Prop) :=
exists chain1 chain2 : list element, 
  In x chain1 /\ In y chain2 /\ chain1 <> chain2 /\ cat < length chain1 /\ 
  compFun (nth cat chain1 (nat_ 0)) (nth cat chain2 (nat_ 0)) /\ In chain1 solution /\ 
  In chain2 solution.

Definition comparison (x y : element) (cat : nat) (compFun : element -> element -> Prop) := comparisonConverted (convert x) (convert y) cat compFun.

(* Functions needed for the comparison functions. *)
Definition elementToNat (el : element) : nat := 
match el with 
  | nat_ n => n 
  | str_ s => 0
end.

Definition elementToString (el : element) : string := 
match el with 
  | nat_ n => ""
  | str_ s => s 
end.

(* The comparison functions meant for natural numbers. *)
Definition before (x y : element) : Prop := 
(elementToNat x) < (elementToNat y).

Definition after (x y : element) : Prop := 
(elementToNat x) > (elementToNat y). 

Definition beforeFixed (n : nat) (x y : element) : Prop := 
(elementToNat x) = (elementToNat y) - n.

Definition afterFixed (n : nat) (x y : element) : Prop := 
(elementToNat x) = (elementToNat y) + n.

Definition beforeAtLeast (n : nat) (x y : element) : Prop := 
(elementToNat x) <= (elementToNat y) - n.

Definition afterAtLeast (n : nat) (x y : element) : Prop := 
(elementToNat x) >= (elementToNat y) + n.

Definition distance (n : nat) (x y : element) : Prop := 
(elementToNat x) = (elementToNat y) - n \/ (elementToNat x) = (elementToNat y) + n.

(* The comparison functions meant for strings. *)
Definition lexicographicalOrder (x y : element) : Prop := 
match compare (elementToString x) (elementToString y) with 
  | Lt => True 
  | Eq => True 
  | Gt => False 
end.

Definition reverseLexicographicalOrder (x y : element) : Prop := 
match compare (elementToString x) (elementToString y) with 
  | Lt => False 
  | Eq => True 
  | Gt => True 
end.

(* Ltac tactics needed for the Comparison clue type. *)
Ltac findFunction func := 
match func with 
  | ?x _ => findFunction x 
  | _ => unfold func 
end. 

Ltac unfoldFunction :=  
match goal with 
  | [ |- ?x ] => findFunction x 
end.

Ltac proveConjunctionClauses := split;
match goal with 
  | [ |- _ /\ _ ] => proveConjunctionClauses
  | [ |- In _ _ ] => proveIn  
  | [ |- _ <> _ ] => discriminate 
  | [ |- _ < _ ] => simpl; lia 
  | _ => simpl; unfoldFunction; simpl; (lia || auto); fail 
end.

Ltac proveComparison := 
unfold comparison; simpl convert; unfold comparisonConverted; 
let len := eval compute in (length solution) 
  in tryChainsRec len len ltac:(proveConjunctionClauses).

(* Proof of an Instance *)
Lemma testComparison : comparison "frog" "Hori Takesi" 0 (beforeFixed 60).
Proof.
proveComparison.
Qed.

(* Ltac tactics needed for the Disjunction clue type. *)
Ltac checkClauses form := 
match form with 
  | ?c1 \/ ?c2 => checkClauses c1; checkClauses c2 
  | noLink _ _ => idtac 
  | directLink _ _ => idtac 
  | _ => fail 
end.

Ltac checkDisjunction :=
match goal with 
  | [ |- ?g ] => checkClauses g
  | _ => fail 
end.

Ltac proveDisjunction := checkDisjunction; 
match goal with 
| [ |- _ \/ _ ] => (left; proveDisjunction) || (right; proveDisjunction) 
| [ |- noLink _ _ ] => proveNoLink 
| [ |- directLink _ _ ] => proveDirectLink 
| _ => fail 
end. 

(* Proof of an Instance *)
Lemma testDisjunction : noLink "rooster" 1525 \/ directLink "Amari Michi" "Niwa".
Proof. 
proveDisjunction.
Qed.

(* The proof tactic that automates proving the clue types. *)
Ltac autoProve := 
match goal with 
| [ |- _ /\ _ ] => split; autoProve 
| [ |- preconditions ] => provePreconditions 
| [ |- directLink _ _ ] => proveDirectLink 
| [ |- noLink _ _ ] => proveNoLink 
| [ |- either _ _ _ ] => proveEither 
| [ |- allDifferent _ ] => proveAllDifferent 
| [ |- twoPairs _ _ _ _ ] => proveTwoPairs 
| [ |- comparison _ _ _ _ ] => proveComparison 
| [ |- _ \/ _ ] => proveDisjunction
| _ => fail 
end.

(* The complete logic grid puzzle formalized and proven. *)
Theorem testSolution : 
preconditions /\ directLink 1705 "deer" /\ either "rooster" "Amari Michi" 1525 /\
directLink 1705 "Niwa" /\ allDifferent ["Okabe Honzo", "Usui", "Niwa"] /\ 
twoPairs "Funai" "rooster" "Hori Takesi" 1525 /\ 
comparison "frog" "Hori Takesi" 0 (beforeFixed 60) /\
comparison "Okabe Honzo" "rooster" 0 (afterFixed 60).
Proof.
autoProve.
Qed.
