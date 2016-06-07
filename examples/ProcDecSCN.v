Require Import Bool String List.
Require Import Lib.CommonTactics Lib.ilist Lib.Word.
Require Import Lib.Struct Lib.StringBound Lib.FMap Lib.StringEq.
Require Import Lts.Syntax Lts.ParametricSyntax Lts.Semantics Lts.SemFacts.
Require Import Lts.Equiv Lts.Refinement Lts.Renaming Lts.Wf.
Require Import Lts.Renaming Lts.Specialize Lts.Tactics Lts.Duplicate Lts.ModuleBound.
Require Import Ex.SC Ex.Fifo Ex.MemAtomic.
Require Import Ex.ProcDec Ex.ProcDecInl Ex.ProcDecInv Ex.ProcDecSC.

Set Implicit Arguments.

Section ProcDecSCN.
  Variables addrSize lgDataBytes rfIdx: nat.

  Variable dec: DecT 2 addrSize lgDataBytes rfIdx.
  Variable execState: ExecStateT 2 addrSize lgDataBytes rfIdx.
  Variable execNextPc: ExecNextPcT 2 addrSize lgDataBytes rfIdx.

  Variable n: nat.
  
  Definition pdecN := procDecM dec execState execNextPc n.
  Definition scN := sc dec execState execNextPc opLd opSt opHt n.

  Lemma pdecN_refines_scN: pdecN <<== scN.
  Proof. (* SKIP_PROOF_ON
    simple kmodular.
    - kequiv.
    - kequiv.
    - kequiv.
    - kequiv.
    - disj_module_tac.
    - disj_module_tac.
    - split.
      + apply duplicate_validRegsModules; auto.
      + constructor; [constructor|].
        simpl; rewrite app_nil_r.
        induction n; simpl; [repeat constructor|].
        repeat constructor; auto.
    - split.
      + apply duplicate_validRegsModules; auto.
      + constructor; [constructor|].
        simpl; rewrite app_nil_r.
        induction n; simpl; [repeat constructor|].
        repeat constructor; auto.
    - disj_module_tac.
    - disj_module_tac.
    - disj_module_tac.
    - disj_module_tac.
    - auto.
    - auto.
    - auto.
    - kduplicated.
      + kequiv.
      + kequiv.
      + apply pdec_refines_pinst.
    - krefl.
      END_SKIP_PROOF_ON *) admit.
  Qed.

  Definition procDecN := pdecs dec execState execNextPc n.
  Definition memAtomic := memAtomic addrSize lgDataBytes n.
  Definition pdecAN := (procDecN ++ memAtomic)%kami.

  Lemma pdecN_memAtomic_refines_scN: pdecAN <<== scN.
  Proof. (* SKIP_PROOF_ON
    ktrans pdecN; [|unfold MethsT; rewrite <-idElementwiseId; apply pdecN_refines_scN].
    ktrans ((pdecs dec execState execNextPc n ++ ioms addrSize lgDataBytes n)
              ++ minst addrSize lgDataBytes n)%kami; [apply traceRefines_assoc_2|].

    kmodular_sim_l.
    - simpl; unfold namesOf; rewrite map_app; apply NoDup_DisjList.
      + apply duplicate_regs_NoDup; auto.
      + apply duplicate_regs_NoDup; auto.
      + apply duplicate_disj_regs; auto.
    - apply duplicate_regs_NoDup; auto.
    - auto.
    - simpl; unfold namesOf; rewrite map_app; apply DisjList_app_4.
      + clear; induction n; simpl; [auto|].
        assert (forall s, ~ (In s (spDom (ProcDec.pdec dec execState execNextPc)) /\
                             In s (spImg (ProcDec.pdec dec execState execNextPc) (S n0)))).
        { apply specializable_disj_dom_img; auto. }
        repeat (rewrite specializer_dom; [|auto|vm_compute; tauto]).
        repeat (apply DisjList_string_cons; [intro Hx; CommonTactics.dest_in; discriminate|]).
        auto.
      + clear; induction n; simpl; [auto|].
        assert (forall s, ~ (In s (spDom (iom addrSize lgDataBytes)) /\
                             In s (spImg (iom addrSize lgDataBytes) (S n0)))).
        { apply specializable_disj_dom_img; auto. }
        repeat (rewrite specializer_dom; [|auto|vm_compute; tauto]).
        repeat (apply DisjList_string_cons; [intro Hx; CommonTactics.dest_in; discriminate|]).
        auto.
    - clear; induction n; simpl; [auto|].
      assert (forall s, ~ (In s (spDom (pdecf dec execState execNextPc)) /\
                           In s (spImg (pdecf dec execState execNextPc) (S n0)))).
      { apply specializable_disj_dom_img; auto. }
      repeat (rewrite specializer_dom; [|auto|vm_compute; tauto]).
      repeat (apply DisjList_string_cons; [intro Hx; CommonTactics.dest_in; discriminate|]).
      auto.
      
    - apply duplicate_regs_ConcatMod_2; auto; kequiv.
    - apply duplicate_regs_ConcatMod_1; auto; kequiv.
    - apply duplicate_rules_ConcatMod_2; auto; kequiv.
    - apply duplicate_rules_ConcatMod_1; auto; kequiv.
    - apply duplicate_defs_ConcatMod_2; auto; kequiv.
    - apply duplicate_defs_ConcatMod_1; auto; kequiv.
      END_SKIP_PROOF_ON *) admit.
  Qed.
  
End ProcDecSCN.

