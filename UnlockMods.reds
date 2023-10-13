// Name: UnlockMods
// Author: fyodorxtv
// Date: 2023-10-12
// Version: 1.0

@replaceMethod(RPGManager)
public final static func CanPartBeUnequipped(data: InventoryItemData, slotId: TweakDBID) -> Bool {
    let itemID: ItemID = data.ID;
    let type: gamedataItemType = RPGManager.GetItemType(itemID);
    if RPGManager.IsWeaponMod(type) || RPGManager.IsClothingMod(type) {
      return true;
    };
    if Equals(type, gamedataItemType.Prt_Fragment) {
      return !RPGManager.IsNonModifableSlot(slotId);
    };
    if Equals(type, gamedataItemType.Prt_ShortScope) || Equals(type, gamedataItemType.Prt_LongScope) || Equals(type, gamedataItemType.Prt_TechSniperScope) || Equals(type, gamedataItemType.Prt_PowerSniperScope) || Equals(type, gamedataItemType.Prt_Muzzle) || Equals(type, gamedataItemType.Prt_HandgunMuzzle) || Equals(type, gamedataItemType.Prt_RifleMuzzle) || Equals(type, gamedataItemType.Prt_Program) {
      return true;
    };
    return false;
}