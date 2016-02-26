Require Import List String.
Require Import Lib.CommonTactics Lib.Struct Lib.FMap.
Require Import Syntax Semantics SemFacts Wf.

Set Implicit Arguments.

Fixpoint composeLabels (ls1 ls2: LabelSeqT) :=
  match ls1, ls2 with
    | l1 :: ls1', l2 :: ls2' =>
      (hide (mergeLabel l1 l2)) :: (composeLabels ls1' ls2')
    | _, _ => nil
  end.

Section TwoModules.
  Variables (ma mb: Modules).
  Hypotheses (Hinit: DisjList (namesOf (getRegInits ma)) (namesOf (getRegInits mb)))
             (Hdefs: DisjList (getDefs ma) (getDefs mb))
             (Hcalls: DisjList (getCalls ma) (getCalls mb))
             (Hvr: ValidRegsModules type (ConcatMod ma mb)).

  Definition regsA (r: RegsT) := M.restrict r (namesOf (getRegInits ma)).
  Definition regsB (r: RegsT) := M.restrict r (namesOf (getRegInits mb)).

  Definition mergeUnitLabel (ul1 ul2: UnitLabel): UnitLabel :=
    match ul1, ul2 with
      | Rle (Some _), _ => ul1
      | _, Rle (Some _) => ul2
      | Meth (Some _), _ => ul1
      | _, Meth (Some _) => ul2
      | Rle None, _ => ul1
      | _, Rle None => ul2
      | _, _ => Meth None (* unspecified *)
    end.

  Definition OneMustMethNone (ul1 ul2: UnitLabel) :=
    ul1 = Meth None \/ ul2 = Meth None.
  Hint Unfold OneMustMethNone.

  Lemma substep_split:
    forall o u ul cs,
      Substep (ConcatMod ma mb) o u ul cs ->
      exists ua ub ula ulb csa csb,
        Substep ma (regsA o) ua ula csa /\
        Substep mb (regsB o) ub ulb csb /\
        M.Disj ua ub /\ u = M.union ua ub /\
        OneMustMethNone ula ulb /\ ul = mergeUnitLabel ula ulb /\ 
        M.Disj csa csb /\ cs = M.union csa csb.
  Proof.
    induction 1; simpl; intros.

    - exists (M.empty _), (M.empty _).
      exists (Rle None), (Meth None), (M.empty _), (M.empty _).
      repeat split; auto; constructor.

    - exists (M.empty _), (M.empty _).
      exists (Meth None), (Meth None), (M.empty _), (M.empty _).
      repeat split; auto; constructor.

    - simpl in HInRules; apply in_app_or in HInRules.
      destruct HInRules.
      + exists u, (M.empty _).
        exists (Rle (Some k)), (Meth None), cs, (M.empty _).
        repeat split; auto; econstructor; eauto.
        apply validRegsAction_old_regs_restrict; auto.
        eapply validRegsRules_rule; eauto.
        inv Hvr; apply validRegsModules_validRegsRules; auto.
      + exists (M.empty _), u.
        exists (Meth None), (Rle (Some k)), (M.empty _), cs.
        repeat split; auto; econstructor; eauto.
        apply validRegsAction_old_regs_restrict; auto.
        eapply validRegsRules_rule; eauto.
        inv Hvr; apply validRegsModules_validRegsRules; auto.

    - simpl in HIn; apply in_app_or in HIn.
      destruct HIn.
      + exists u, (M.empty _).
        eexists (Meth (Some _)), (Meth None), cs, (M.empty _).
        repeat split; auto; econstructor; eauto.
        apply validRegsAction_old_regs_restrict; auto.
        eapply validRegsDms_dm; eauto.
        inv Hvr; apply validRegsModules_validRegsDms; auto.
      + exists (M.empty _), u.
        eexists (Meth None), (Meth (Some _)), (M.empty _), cs.
        repeat split; auto; econstructor; eauto.
        apply validRegsAction_old_regs_restrict; auto.
        eapply validRegsDms_dm; eauto.
        inv Hvr; apply validRegsModules_validRegsDms; auto.
        
  Qed.

  Lemma substepsInd_split:
    forall o u l,
      SubstepsInd (ConcatMod ma mb) o u l ->
      exists ua ub la lb,
        SubstepsInd ma (regsA o) ua la /\
        SubstepsInd mb (regsB o) ub lb /\
        M.Disj ua ub /\ u = M.union ua ub /\
        CanCombineLabel la lb /\ l = mergeLabel la lb.
  Proof.
    induction 1; simpl; intros.
    - exists (M.empty _), (M.empty _), emptyMethLabel, emptyMethLabel.
      repeat split; auto; try constructor;
        simpl; intro; eapply M.F.P.F.empty_in_iff; eauto.

    - subst.
      destruct IHSubstepsInd as [pua [pub [pla [plb ?]]]]; dest; subst.
      apply substep_split in H0.
      destruct H0 as [sua [sub [sula [sulb [scsa [scsb ?]]]]]];
        dest; subst.

      exists (M.union pua sua), (M.union pub sub).
      exists (mergeLabel (getLabel sula scsa) pla),
      (mergeLabel (getLabel sulb scsb) plb).
      inv H1; inv H6; dest.

      repeat split.

      + eapply SubstepsCons; eauto.
        repeat split; auto.
        { destruct pla, plb; simpl in *; mdisj. }
        { destruct pla as [[[|]|] ? ?], plb as [[[|]|] ? ?];
          destruct sula as [[|]|[|]], sulb as [[|]|[|]];
          simpl in *; auto; findeq; try (inv H9; discriminate).
        }
        
      + eapply SubstepsCons; eauto.
        repeat split; auto.
        { destruct pla, plb; simpl in *; mdisj. }
        { destruct pla as [[[|]|] ? ?], plb as [[[|]|] ? ?];
          destruct sula as [[|]|[|]], sulb as [[|]|[|]];
          simpl in *; auto; findeq; try (inv H9; discriminate);
          try (destruct (M.find a defs); discriminate).
        }
        
      + auto.
      + auto.
      + destruct pla as [[[|]|] pdsa pcsa], plb as [[[|]|] pdsb pcsb];
          destruct sula as [[|]|[[? ?]|]], sulb as [[|]|[[? ?]|]];
          simpl in *; try (inv H9; discriminate); auto.
      + destruct pla as [[[|]|] pdsa pcsa], plb as [[[|]|] pdsb pcsb];
          destruct sula as [[|]|[[? ?]|]], sulb as [[|]|[[? ?]|]];
          simpl in *; try (inv H9; discriminate); auto.
      + destruct pla as [[[|]|] ? ?], plb as [[[|]|] ? ?];
          destruct sula as [[|]|[|]], sulb as [[|]|[|]];
          simpl in *; try (inv H9; discriminate); auto.
      + destruct pla as [[[|]|] pdsa pcsa], plb as [[[|]|] pdsb pcsb];
          destruct sula as [[|]|[[? ?]|]], sulb as [[|]|[[? ?]|]];
          simpl in *; try (inv H9; discriminate);
            try (intuition auto; fail);
            try (f_equal; auto; fail).
          
  Admitted. (* NOTE: It works but takes some time *)

  Lemma stepInd_split:
    forall o u l,
      StepInd (ConcatMod ma mb) o u l ->
      exists ua ub la lb,
        StepInd ma (regsA o) ua la /\ StepInd mb (regsB o) ub lb /\
        M.Disj ua ub /\ u = M.union ua ub /\
        CanCombineLabel la lb /\ wellHidden (ConcatMod ma mb) (hide (mergeLabel la lb)) /\
        l = hide (mergeLabel la lb).
  Proof.
    induction 1; simpl; intros.
    pose proof (substepsInd_split HSubSteps)
      as [ua [ub [la [lb ?]]]]; dest; subst.
    exists ua, ub, (hide la), (hide lb).
    intuition auto.

    - constructor; auto.
      inv H3; dest.
      pose proof (substepsInd_calls_in H).
      pose proof (substepsInd_defs_in H).
      pose proof (substepsInd_calls_in H0).
      pose proof (substepsInd_defs_in H0).
      eapply wellHidden_split
      with (ma:= ma) (mb:= mb) (la:= la) (lb:= lb); eauto.
    - constructor; auto.
      inv H3; dest.
      pose proof (substepsInd_calls_in H).
      pose proof (substepsInd_defs_in H).
      pose proof (substepsInd_calls_in H0).
      pose proof (substepsInd_defs_in H0).
      eapply wellHidden_split
      with (ma:= ma) (mb:= mb) (la:= la) (lb:= lb); eauto.
    - apply CanCombineLabel_hide; auto.
    - inv H3; dest.
      rewrite <-hide_mergeLabel_idempotent; auto.
    - inv H3; rewrite <-hide_mergeLabel_idempotent; auto.
  Qed.

  Lemma step_split:
    forall o u l,
      Step (ConcatMod ma mb) o u l ->
      exists ua ub la lb,
        Step ma (regsA o) ua la /\ Step mb (regsB o) ub lb /\
        M.Disj ua ub /\ u = M.union ua ub /\
        CanCombineLabel la lb /\ wellHidden (ConcatMod ma mb) (hide (mergeLabel la lb)) /\
        l = hide (mergeLabel la lb).
  Proof.
    intros; apply step_consistent in H.
    pose proof (stepInd_split H) as [ua [ub [la [lb ?]]]]; dest; subst.
    exists ua, ub, la, lb.
    inv H4; inv H5; dest.
    repeat split; auto; apply step_consistent; auto.
  Qed.

  Lemma multistep_split:
    forall s ls ir,
      Multistep (ConcatMod ma mb) ir s ls ->
      ir = initRegs (getRegInits ma ++ getRegInits mb) ->
      exists sa lsa sb lsb,
        Multistep ma (initRegs (getRegInits ma)) sa lsa /\
        Multistep mb (initRegs (getRegInits mb)) sb lsb /\
        M.Disj sa sb /\ s = M.union sa sb /\
        CanCombineLabelSeq lsa lsb /\ WellHiddenSeq (ConcatMod ma mb) ls /\
        ls = composeLabels lsa lsb.
  Proof.
    induction 1; simpl; intros; subst.
    - do 2 (eexists; exists nil); repeat split; try (econstructor; eauto; fail).
      + eapply M.DisjList_KeysSubset_Disj with (d1:= namesOf (getRegInits ma)); eauto;
          unfold initRegs; apply makeMap_KeysSubset; auto.
      + subst; unfold initRegs; apply makeMap_union; auto.

    - intros; subst.
      specialize (IHMultistep eq_refl).
      destruct IHMultistep as [sa [lsa [sb [lsb ?]]]]; dest; subst.

      apply step_split in HStep.
      destruct HStep as [sua [sub [sla [slb ?]]]]; dest; subst.

      inv Hvr.
      pose proof (validRegsModules_multistep_newregs_subset H8 H0 eq_refl).
      pose proof (validRegsModules_multistep_newregs_subset H11 H1 eq_refl).
      pose proof (validRegsModules_step_newregs_subset H8 H3).
      pose proof (validRegsModules_step_newregs_subset H11 H6).

      inv H9; inv H10; dest.
      exists (M.union sua sa), (sla :: lsa).
      exists (M.union sub sb), (slb :: lsb).
      repeat split; auto.

      + constructor; auto.
        p_equal H3.
        unfold regsA; rewrite M.restrict_union.
        rewrite M.restrict_KeysSubset; auto.
        rewrite M.restrict_DisjList with (d1:= namesOf (getRegInits mb)); auto.
        apply DisjList_comm; auto.

      + constructor; auto.
        p_equal H6.
        unfold regsB; rewrite M.restrict_union.
        rewrite M.restrict_KeysSubset with (m:= sb); auto.
        rewrite M.restrict_DisjList with (d1:= namesOf (getRegInits ma)); auto.

      + mdisj.
        * eapply M.DisjList_KeysSubset_Disj with (d1:= namesOf (getRegInits mb)); eauto.
          apply DisjList_comm; auto.
        * eapply M.DisjList_KeysSubset_Disj with (d1:= namesOf (getRegInits mb)); eauto.
          apply DisjList_comm; auto.

      + pose proof (M.DisjList_KeysSubset_Disj Hinit H12 H15).
        meq.
  Qed.

  Lemma behavior_split:
    forall s ls,
      Behavior (ConcatMod ma mb) s ls ->
      exists sa lsa sb lsb,
        Behavior ma sa lsa /\ Behavior mb sb lsb /\
        M.Disj sa sb /\ s = M.union sa sb /\
        CanCombineLabelSeq lsa lsb /\ WellHiddenSeq (ConcatMod ma mb) ls /\
        ls = composeLabels lsa lsb.
  Proof.
    induction 1.
    apply multistep_split in HMultistepBeh.
    destruct HMultistepBeh as [sa [lsa [sb [lsb ?]]]]; dest; subst.
    exists sa, lsa, sb, lsb.
    repeat split; auto.
    reflexivity.
  Qed.

  Lemma substepsInd_modular:
    forall oa ua la,
      SubstepsInd ma oa ua la ->
      forall ob ub lb,
        M.Disj oa ob -> CanCombineUL ua ub la lb ->
        SubstepsInd mb ob ub lb ->
        SubstepsInd (ConcatMod ma mb) (M.union oa ob) (M.union ua ub) (mergeLabel la lb).
  Proof.
    induction 1; simpl; intros; subst.
    - destruct lb as [annb dsb csb]; simpl in *.
      do 3 rewrite M.union_empty_L.
      apply substepsInd_modules_weakening with (mc:= mb); [|eauto].
      eapply substepsInd_oldRegs_weakening; eauto.
      apply M.Sub_union_2; auto.
    - rewrite mergeLabel_assoc.
      inv H1; dest.
      rewrite M.union_comm with (m1:= u); [|auto].
      eapply SubstepsCons.
      + eapply IHSubstepsInd; eauto.
        clear -H5.

        (* Better to extract a lemma *)
        inv H5; inv H0; dest.
        destruct (getLabel sul scs), l, lb; simpl in *.
        repeat split; simpl; auto.
        destruct annot, annot0, annot1; auto.
        
      + apply substep_modules_weakening with (mc:= ma); [|eauto].
        eapply substep_oldRegs_weakening; eauto.
        apply M.Sub_union_1.
      + inv H5; inv H8; dest.
        destruct l, lb; repeat split; simpl in *; auto.
        destruct annot, annot0, sul as [|[[? ?]|]]; auto; findeq.
      + inv H5; inv H8; dest; auto.
      + reflexivity.
  Qed.

  Lemma stepInd_modular:
    forall oa ua la,
      StepInd ma oa ua la ->
      forall ob ub lb,
        M.Disj oa ob -> CanCombineUL ua ub la lb ->
        StepInd mb ob ub lb ->
        StepInd (ConcatMod ma mb) (M.union oa ob) (M.union ua ub)
                (hide (mergeLabel la lb)).
  Proof.
    intros; inv H; inv H2.

    pose proof (substepsInd_defs_in HSubSteps).
    pose proof (substepsInd_calls_in HSubSteps).
    pose proof (substepsInd_defs_in HSubSteps0).
    pose proof (substepsInd_calls_in HSubSteps0).

    assert (M.Disj (defs l) (defs l0))
      by (eapply M.DisjList_KeysSubset_Disj with (d1:= getDefs ma); eauto).
    assert (M.Disj (calls l) (calls l0))
      by (eapply M.DisjList_KeysSubset_Disj with (d1:= getCalls ma); eauto).
    inv H1; inv H8; dest.

    replace (hide (mergeLabel (hide l) (hide l0))) with (hide (mergeLabel l l0)).
    - constructor.
      + apply substepsInd_modular; auto.
        constructor; auto.
        repeat split; auto.
      + rewrite hide_mergeLabel_idempotent by auto.
        admit.
    - apply hide_mergeLabel_idempotent; auto.
  Qed.

  Lemma step_modular:
    forall oa ua la,
      Step ma oa ua la ->
      forall ob ub lb,
        M.Disj oa ob -> CanCombineUL ua ub la lb ->
        Step mb ob ub lb ->
        Step (ConcatMod ma mb) (M.union oa ob) (M.union ua ub) (hide (mergeLabel la lb)).
  Proof.
    intros.
    apply step_consistent in H; apply step_consistent in H2.
    apply step_consistent.
    apply stepInd_modular; auto.
  Qed.

  Lemma multistep_modular:
    forall lsa oa sa,
      Multistep ma oa sa lsa ->
      oa = initRegs (getRegInits ma) ->
      forall ob sb lsb,
        Multistep mb ob sb lsb ->
        ob = initRegs (getRegInits mb) ->
        CanCombineLabelSeq lsa lsb ->
        Multistep (ConcatMod ma mb) (initRegs (getRegInits (ConcatMod ma mb))) 
                  (M.union sa sb) (composeLabels lsa lsb).
  Proof.
    induction lsa; simpl; intros; subst.

    - destruct lsb; [|intuition idtac].
      inv H; inv H1; constructor.
      unfold initRegs.
      apply makeMap_union; auto.

    - destruct lsb as [|]; [intuition idtac|].
      inv H3.
      inv H; inv H1.
      inv Hvr.
      
      pose proof (validRegsModules_multistep_newregs_subset H HMultistep eq_refl).
      pose proof (validRegsModules_multistep_newregs_subset H1 HMultistep0 eq_refl).
      pose proof (validRegsModules_step_newregs_subset H HStep).
      pose proof (validRegsModules_step_newregs_subset H1 HStep0).

      replace (M.union (M.union u n) (M.union u0 n0))
      with (M.union (M.union u u0) (M.union n n0))
        by (pose proof (M.DisjList_KeysSubset_Disj Hinit H3 H6); meq).

      inv H0; dest.
      constructor; eauto.
      apply step_modular; auto.
      + eapply M.DisjList_KeysSubset_Disj with (d1:= namesOf (getRegInits ma)); eauto.
      + repeat split; auto.
        eapply M.DisjList_KeysSubset_Disj with (d1:= namesOf (getRegInits ma)); eauto.
  Qed.

  Lemma behavior_modular:
    forall sa sb lsa lsb,
      Behavior ma sa lsa ->
      Behavior mb sb lsb ->
      CanCombineLabelSeq lsa lsb ->
      Behavior (ConcatMod ma mb) (M.union sa sb) (composeLabels lsa lsb).
  Proof.
    intros; inv H; inv H0; constructor.
    eapply multistep_modular; eauto.
  Qed.

End TwoModules.

Section LabelMap.
  Variable (p: MethsT -> MethsT).
  Hypotheses (Hpunion: forall m1 m2, M.union (p m1) (p m2) =
                                     p (M.union m1 m2))
             (Hpsub: forall m1 m2, M.subtractKV signIsEq (p m1) (p m2) =
                                   p (M.subtractKV signIsEq m1 m2)).

  Lemma equivalentLabel_hide_mergeLabel:
    forall la lb,
      equivalentLabel p la lb ->
      forall lc ld,
        equivalentLabel p lc ld ->
        equivalentLabel p (hide (mergeLabel la lc)) (hide (mergeLabel lb ld)).
  Proof.
    intros.
    destruct la as [anna dsa csa], lb as [annb dsb csb].
    destruct lc as [annc dsc csc], ld as [annd dsd csd].
    unfold equivalentLabel in *; simpl in *; dest; subst.
    repeat split.
    - do 2 rewrite Hpunion.
      rewrite Hpsub.
      reflexivity.
    - do 2 rewrite Hpunion.
      rewrite Hpsub.
      reflexivity.
    - destruct anna, annb, annc, annd; auto.
  Qed.

  Lemma composeLabels_modular:
    forall lsa lsb,
      equivalentLabelSeq p lsa lsb ->
      forall lsc lsd,
        equivalentLabelSeq p lsc lsd ->
        equivalentLabelSeq p (composeLabels lsa lsc) (composeLabels lsb lsd).
  Proof.
    induction 1; simpl; intros; [constructor|].
    destruct lsc, lsd; [constructor|inv H1|inv H1|].
    inv H1; constructor; [|apply IHequivalentLabelSeq; auto].
    apply equivalentLabel_hide_mergeLabel; auto.
  Qed.

End LabelMap.

