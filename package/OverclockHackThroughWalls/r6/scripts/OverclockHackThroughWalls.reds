// Name: OverclockHackThroughWalls
// Author: fyodorxtv
// Date: 2023-10-16
// Version: 1.1

// Players can save in the middle of Overclock and it will _permanently_ give them the status effect. :facepalm:
// This needs to be checked for on file load and removed.
@wrapMethod(PlayerDevelopmentSystem)
private func OnRestored(saveVersion: Int32, gameVersion: Int32) -> Void {
    wrappedMethod(saveVersion, gameVersion);
    // FTLog("RemoveExistingAutoRevealModifiersOnPlayerRestore");
    let game = GetGameInstance();
    let statusEffectSys: ref<StatusEffectSystem> = GameInstance.GetStatusEffectSystem(game);
    let player = GetPlayer(game);
    statusEffectSys.RemoveStatusEffect(player.GetEntityID(), t"BaseStatusEffect.Intelligence_60_Ping_Aura");
}

// This method sets a scripted puppet as scannable.
// Vanilla code checks for the puppet owner to have any status effects with the "Int60_Ping" tag.
// This tag _should_ be applied by the "Intelligence_60_Ping" PingMarkStatusEffect.
// The ping effect is _meant_ to be applied by an "Intelligence_60_Ping_Aura" PropagateStatusEffectInAreaEffector but that doesn't seem to work...
@replaceMethod(ScanningComponent)
public func SetScannableThroughWallsIfPossible() -> Void {
    // FTLog(s"SetScannableThroughWallsIfPossible: owner=\(this.GetOwner()) playercan=\(this.GetOwner().CanPlayerScanThroughWalls())");
    let scriptedPuppet: ref<ScriptedPuppet> = this.GetOwner() as ScriptedPuppet;
    let isNetRunnerNPC: Bool = IsDefined(scriptedPuppet) && scriptedPuppet.IsNetrunnerPuppet();
    let isEnemy: Bool = IsDefined(scriptedPuppet) && scriptedPuppet.IsEnemy();
    let isHighlighted: Bool = IsDefined(scriptedPuppet) && scriptedPuppet.IsHighlightedInFocusMode();
    let game = GetGameInstance();
    let statusEffectSys: ref<StatusEffectSystem> = GameInstance.GetStatusEffectSystem(game);
    if (this.GetOwner().CanPlayerScanThroughWalls()) {
        let effectApplied: Bool = false;
        let hasAura: Bool = StatusEffectSystem.ObjectHasStatusEffect(GetPlayer(game), t"BaseStatusEffect.Intelligence_60_Ping_Aura");
        // Status effect just isn't being applied.
        // The player has the correct aura but nearby enemies do not hold the mark.
        // Let's just utilise cyberware detection for this instead.
        // FTLog(s"PlayerHasStatusEffect: \(hasAura)");
        if (isEnemy && isHighlighted && hasAura) {
            // This effect inherits from the Ping quickhack and thus makes the same noise.
            // Useful for debugging but probably annoying for regular gameplay.
            effectApplied = statusEffectSys.ApplyStatusEffect(this.GetOwner().GetEntityID(), t"BaseStatusEffect.Intelligence_60_Ping");
        }
        // let hasPingStatus: Bool = StatusEffectSystem.ObjectHasStatusEffectWithTag(this.GetOwner(), n"Int60_Ping");
        // FTLog(s"ObjectHasStatusEffect: \(hasPingStatus)");
        if ((this.GetOwner().IsDevice() || isNetRunnerNPC) || (isEnemy && effectApplied)) {
            this.SetScannableThroughWalls(true);
        }
        else {
            this.SetScannableThroughWalls(false);
        }
    }
}

// This class is initialised when Overclock is initiated due to the "Intelligence_60_Ping_Aura" status effect.
// Initialisation happens multiple times because the aura is set to ping repeatedly every ~3 seconds.
// The actual ping debuff is meant to then be propagated onto enemies near to the player via the `ProcessAction` method.
// The method appears to work correctly and construct the correct effect and run it but...
// I have not been able to see _any_ effects propagated via this class actually apply to nearby enemies.
@replaceMethod(PropagateStatusEffectInAreaEffector)
protected func Initialize(record: TweakDBID, game: GameInstance, parentRecord: TweakDBID) -> Void {
    // Looks like some of the initialisation is messed up.
    // This would actually fix the on-dismemberment debuff strength perk, except that status effect doesn't apply either.
    this.m_statusEffect = TweakDBInterface.GetForeignKey(record + t".statusEffect", t"");
    this.m_range = TweakDBInterface.GetFloat(record + t".range", 2.0);
    this.m_duration = TweakDBInterface.GetFloat(record + t".duration", 0.0);
    this.m_applicationTarget = TweakDBInterface.GetCName(record + t".applicationTarget", n""); // Missing "." before "applicationTarget" in source code.
    this.m_propagateToInstigator = TweakDBInterface.GetBool(record + t".propagateToInstigator", true);
}