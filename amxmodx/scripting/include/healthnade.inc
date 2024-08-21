#if defined __healthnade_included
    #endinput
#endif
#define __healthnade_included

#define HN_NULLENT -1

#define MAX_PROP_STRING_LEN 128

// Blow radius for throwed nade
#define var_HealthNade_Radius var_fuser1

// Healing amount for throwed nade
#define var_HealthNade_ThrowHealingAmount var_fuser2

// Healing amount for drunk nade
#define var_HealthNade_DrinkHealingAmount var_fuser3

// Prop types for HealthNade_GetProp() forward
enum _:HnPropertiesEnum {
	HnProp_DrinkHealingAmount,
    HnProp_ThrowHealingAmount,
    HnProp_ExplodeRadius
}

// ET_STOP, return > 0 to block internal spawnequip
forward HealthNade_CanEquip(const id);

// ET_STOP, you must return > 0 if you write new prop
// For iPropType see HnPropertiesEnum
// int/float values stored in PropValue, strings/arrays stored in PropString
forward HealthNade_GetProp(const id, const iPropType, &any:PropValue, PropString[MAX_PROP_STRING_LEN]);

/**
 * Give health nade with specified parameters to specified player.
 *
 * @param id    Player`s index.
 * @param count     Count of health grenades to give
 * @param maximum   Maximum number of health grenades player can have at once
 *
 * @return      HealthNade item index or HN_NULLENT if operation fails.
 */
native HealthNade_GiveNade(const id, count = 1, maximum = 1);

/**
 * Checks if the player has HealthNade.
 *
 * @param id    Player`s index.
 *
 * @return      True if the player has a HealthNade, false otherwise.
 */
native bool:HealthNade_HasNade(const id);
