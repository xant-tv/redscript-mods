// Name: FixOvershield
// Author: fyodorxtv
// Date: 2023-10-16
// Version: 1.3

// Reset decay when more juice is added.
@wrapMethod(OvershieldMinValueListener)
public func OnStatPoolValueChanged(oldValue: Float, newValue: Float, percToPoints: Float) -> Void {
    // FTLog(s"StatPoolValueChanged: old=\(oldValue), new=\(newValue), perc=\(percToPoints)");
    wrappedMethod(oldValue, newValue, percToPoints);
    if (newValue > oldValue) {
        // FTLog("OvershieldGainedReset");
        this.m_effector.MarkForReset();
    }
}

// Replace the effector logic to react to remove decay scaling if at threshold.
@replaceMethod(ScaleOvershieldDecayOverTimeEffector)
protected func ContinuousAction(owner: wref<GameObject>, instigator: wref<GameObject>) -> Void {
    let statSys: ref<StatsSystem> = GameInstance.GetStatsSystem(owner.GetGame());
    let statPoolSys: ref<StatPoolsSystem> = GameInstance.GetStatPoolsSystem(owner.GetGame());
    let ownerStats: StatsObjectID = Cast(owner.GetEntityID());
    let threshold: Float = statSys.GetStatValue(ownerStats, gamedataStatType.OvershieldDecayStartThreshold);
    let currentValue: Float = statPoolSys.GetStatPoolValue(ownerStats, gamedataStatPoolType.Overshield);
    // let limit: Float = statPoolSys.GetStatPoolValueCustomLimit(ownerStats, gamedataStatPoolType.Overshield);
    // FTLog(s"Threshold: \(threshold), Value: \(currentValue), Limit: \(limit)");
    if (this.m_markedForReset) {
        // FTLog("OvershieldEffectorMarkedForReset");
        this.ResetDecayModifier();
    }
    if statPoolSys.IsStatPoolModificationDelayed(ownerStats, gamedataStatPoolType.Overshield) {
        // FTLog("OvershieldEffectorStatPoolDelayed");
        return;
    }
    if (this.m_effectApplied) {
        // FTLog("OvershieldEffectorIsApplied");
        if (currentValue <= threshold) {
            // FTLog("BelowThresholdMarkReset");
            this.MarkForReset();
            return;
        }
        if !(this.m_maxValueApplied) {
            // FTLog("OvershieldEffectorAddDelay");
            this.m_elapsedTime += this.m_delayTime;
            this.RemoveModifier();
            this.AddModifier();
        };
        return;
    } 
    // FTLog("OvershieldEffectorNotApplied");
    if (currentValue > threshold) {
        // FTLog("OvershieldEffectorAddNewModifier");
        this.m_elapsedTime = 0.0;
        this.AddModifier();
        this.m_effectApplied = true;
    }
}

// Set custom limit on file load.
@wrapMethod(PlayerDevelopmentSystem)
private func OnRestored(saveVersion: Int32, gameVersion: Int32) -> Void {
    wrappedMethod(saveVersion, gameVersion);
    // FTLog("ResetCustomLimitToOvershieldStatPool");
    let game = GetGameInstance();
    let player = GetPlayer(game);
    let playerStats: StatsObjectID = Cast(player.GetEntityID());
    let statPoolSys: ref<StatPoolsSystem> = GameInstance.GetStatPoolsSystem(game);
    // Reset custom limit and pool on save load.
    statPoolSys.RequestSettingStatPoolValueCustomLimit(playerStats, gamedataStatPoolType.Overshield, 0.0, player); // Fix past mistakes.
    statPoolSys.RequestSettingStatPoolMinValue(playerStats, gamedataStatPoolType.Overshield, player);
}