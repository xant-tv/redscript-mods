// Name: RestoreProficiencyPassiveBonuses
// Author: fyodorxtv
// Date: 2023-10-12
// Version: 1.0

@replaceMethod(PlayerDevelopmentData)
private final const func RestoreProficiencyPassiveBonuses(profIndex: Int32, gameInstance: GameInstance) -> Void {  
  let bonusRecord: ref<PassiveProficiencyBonus_Record>;
  let effectorRecord: ref<Effector_Record>;
  let proficiencyRecord: ref<Proficiency_Record> = this.GetProficiencyRecordByIndex(profIndex);
  let effectorSystem: ref<EffectorSystem> = GameInstance.GetEffectorSystem(gameInstance);
  let i: Int32 = 0;
  if proficiencyRecord.GetPassiveBonusesCount() > 0 {
    while i <= this.m_proficiencies[profIndex].currentLevel - 1 { // Change to apply on-level perks properly.
      bonusRecord = proficiencyRecord.GetPassiveBonusesItem(i);
      effectorRecord = bonusRecord.EffectorToTrigger();
      if IsDefined(effectorRecord) && !effectorRecord.IsA(n"gamedataAddDevelopmentPointEffector_Record") {
        effectorSystem.ApplyEffector(this.m_ownerID, this.m_owner, effectorRecord.GetID());
      }
      i += 1;
    };
  };
}

@wrapMethod(PlayerDevelopmentSystem)
private func OnRestored(saveVersion: Int32, gameVersion: Int32) -> Void {
    wrappedMethod(saveVersion, gameVersion);
    // FTLog("RestoringProficiencyPassiveBonuses");
    let game = GetGameInstance();
    let player = GetPlayer(game);
    let playerData = this.GetDevelopmentData(player);
    let profs_to_restore = [
        gamedataProficiencyType.CoolSkill,
        gamedataProficiencyType.IntelligenceSkill,
        gamedataProficiencyType.ReflexesSkill,
        gamedataProficiencyType.StrengthSkill,
        gamedataProficiencyType.TechnicalAbilitySkill
    ];
    for prof in profs_to_restore {
        // FTLog(ToString(prof));
        playerData.RestoreProficiencyPassiveBonuses(
            playerData.GetProficiencyIndexByType(prof), 
            game
        );
    }
}