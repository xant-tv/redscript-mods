// Name: FixOvershield
// Author: fyodorxtv
// Date: 2023-12-07
// Version: 1.4

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

// Our good friends at CDPR have fixed the rest of the problems!