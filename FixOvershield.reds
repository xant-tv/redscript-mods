// Adds a callback for the custom limit to the overshield listener.
@addMethod(OvershieldMinValueListener)
protected cb func OnStatPoolCustomLimitReached(const value: Float) -> Void {
    // FTLog("OvershieldStatPoolCustomLimitReached");
    if IsDefined(this.m_effector) {
        this.m_effector.MarkForReset();
    };
}

// Replace the effector logic to react to custom limit appropriately.
@replaceMethod(ScaleOvershieldDecayOverTimeEffector)
protected func ContinuousAction(owner: wref<GameObject>, instigator: wref<GameObject>) -> Void {
    let statPoolSys: ref<StatPoolsSystem> = GameInstance.GetStatPoolsSystem(owner.GetGame());
    let ownerStats: StatsObjectID = Cast(owner.GetEntityID());
    if (this.m_markedForReset) {
        // FTLog("OvershieldEffectorMarkedForReset");
        this.ResetDecayModifier();
    };
    if statPoolSys.IsStatPoolModificationDelayed(ownerStats, gamedataStatPoolType.Overshield) {
        // FTLog("OvershieldEffectorStatPoolDelayed");
        return;
    };
    if (this.m_effectApplied) {
        // FTLog("OvershieldEffectorIsApplied");
        if !(this.m_maxValueApplied) {
            // FTLog("OvershieldEffectorAddDelay");
            this.m_elapsedTime += this.m_delayTime;
            this.RemoveModifier();
            this.AddModifier();
        };
        return;
    } 
    // FTLog("OvershieldEffectorNotApplied");
    let threshold: Float = 0.0;
    let customThreshold: Float = statPoolSys.GetStatPoolValueCustomLimit(ownerStats, gamedataStatPoolType.Overshield);
    // let value: Float = statPoolSys.GetStatPoolValue(ownerStats, gamedataStatPoolType.Overshield);
    // FTLog(s"Default: \(threshold), Custom: \(customThreshold), Value: \(value)");
    if (customThreshold > threshold) {
        // FTLog("OvershieldEffectorUpdateThreshold");
        threshold = customThreshold;
    };
    if (statPoolSys.GetStatPoolValue(ownerStats, gamedataStatPoolType.Overshield) > threshold) {
        // FTLog("OvershieldEffectorAddNewModifier");
        this.m_elapsedTime = 0.0;
        this.AddModifier();
        this.m_effectApplied = true;
    };
}

// Set custom limit on file load.
@wrapMethod(PlayerDevelopmentSystem)
private func OnRestored(saveVersion: Int32, gameVersion: Int32) -> Void {
    wrappedMethod(saveVersion, gameVersion);
    // FTLog("ApplyCustomLimitToOvershieldStatPool");
    let game = GetGameInstance();
    let player = GetPlayer(game);
    let playerData = this.GetDevelopmentData(player);
    let playerStats: StatsObjectID = Cast(player.GetEntityID());
    let statPoolSys: ref<StatPoolsSystem> = GameInstance.GetStatPoolsSystem(game);
    let profLevel = playerData.m_proficiencies[playerData.GetProficiencyIndexByType(gamedataProficiencyType.StrengthSkill)].currentLevel;
    // FTLog(s"Proficiency: \(ToString(profLevel))");
    if (profLevel >= 55) {
        // FTLog("HasPassiveApplyLimit: 10");
        statPoolSys.RequestSettingStatPoolValueCustomLimit(playerStats, gamedataStatPoolType.Overshield, 10, player);
        return;
    };
    // FTLog("NoPassiveApplyLimit: 0");
    statPoolSys.RequestSettingStatPoolValueCustomLimit(playerStats, gamedataStatPoolType.Overshield, 0, player);
}

// Set custom limit on player reaching required proficiency.
@wrapMethod(PlayerDevelopmentData)
private func ProcessProficiencyPassiveBonus(profIndex: Int32) -> Void {
    wrappedMethod(profIndex);
    // FTLog("ProcessCustomLimitToOvershieldStatPool");
    let game = GetGameInstance();
    let player = GetPlayer(game);
    let playerStats: StatsObjectID = Cast(player.GetEntityID());
    let statPoolSys: ref<StatPoolsSystem> = GameInstance.GetStatPoolsSystem(game);
    let strengthIndex = this.GetProficiencyIndexByType(gamedataProficiencyType.StrengthSkill);
    if (profIndex != strengthIndex) {
        return;
    };
    if (this.m_proficiencies[profIndex].currentLevel >= 55) {
        // FTLog("HasPassiveApplyLimit: 10");
        statPoolSys.RequestSettingStatPoolValueCustomLimit(playerStats, gamedataStatPoolType.Overshield, 10, player);
    };
}