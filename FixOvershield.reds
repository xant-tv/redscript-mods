// Name: FixOvershield
// Author: fyodorxtv
// Date: 2023-10-13
// Version: 1.1

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
    let statSys: ref<StatsSystem> = GameInstance.GetStatsSystem(owner.GetGame());
    let statPoolSys: ref<StatPoolsSystem> = GameInstance.GetStatPoolsSystem(owner.GetGame());
    let ownerStats: StatsObjectID = Cast(owner.GetEntityID());
    let threshold: Float = statSys.GetStatValue(ownerStats, gamedataStatType.OvershieldDecayStartThreshold);
    let limit: Float = statPoolSys.GetStatPoolValueCustomLimit(ownerStats, gamedataStatPoolType.Overshield);
    // let value: Float = statPoolSys.GetStatPoolValue(ownerStats, gamedataStatPoolType.Overshield);
    // FTLog(s"Threshold: \(threshold), Limit: \(limit), Value: \(value)");
    // Fail-safe in case the stat pool ever becomes de-synced from the limit.
    if (limit != threshold) {
        // FTLog("SyncStatPoolWithThreshold");
        statPoolSys.RequestSettingStatPoolValueCustomLimit(ownerStats, gamedataStatPoolType.Overshield, threshold, owner);
    }
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
    let playerStats: StatsObjectID = Cast(player.GetEntityID());
    let statSys: ref<StatsSystem> = GameInstance.GetStatsSystem(game);
    let statPoolSys: ref<StatPoolsSystem> = GameInstance.GetStatPoolsSystem(game);
    let threshold = statSys.GetStatValue(playerStats, gamedataStatType.OvershieldDecayStartThreshold);
    // FTLog(s"Threshold: \(threshold)");
    statPoolSys.RequestSettingStatPoolValueCustomLimit(playerStats, gamedataStatPoolType.Overshield, threshold, player);
}

// Set custom limit on player reaching required proficiency.
@wrapMethod(PlayerDevelopmentData)
private func ProcessProficiencyPassiveBonus(profIndex: Int32) -> Void {
    wrappedMethod(profIndex);
    // FTLog("ProcessCustomLimitToOvershieldStatPool");
    let game = GetGameInstance();
    let player = GetPlayer(game);
    let playerStats: StatsObjectID = Cast(player.GetEntityID());
    let statSys: ref<StatsSystem> = GameInstance.GetStatsSystem(game);
    let statPoolSys: ref<StatPoolsSystem> = GameInstance.GetStatPoolsSystem(game);
    let strengthIndex = this.GetProficiencyIndexByType(gamedataProficiencyType.StrengthSkill);
    if (profIndex != strengthIndex) {
        return;
    };
    let threshold = statSys.GetStatValue(playerStats, gamedataStatType.OvershieldDecayStartThreshold);
    // FTLog(s"Threshold: \(threshold)");
    statPoolSys.RequestSettingStatPoolValueCustomLimit(playerStats, gamedataStatPoolType.Overshield, threshold, player);
}