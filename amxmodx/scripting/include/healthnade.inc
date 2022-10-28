#if defined __healthnade_included
    #endinput
#endif
#define __healthnade_included

#define HN_NULLENT -1

// Blow radius for throwed nade
#define var_HealthNade_Radius var_fuser1

// Healing amount for throwed nade
#define var_HealthNade_ThrowHealingAmount var_fuser2

// Healing amount for drunk nade
#define var_HealthNade_DrinkHealingAmount var_fuser3

/**
 * Give health nade with specified parameters to specified player.
 * 
 * @param id    Player`s index.
 * 
 * @return      HealthNade item index or HN_NULLENT if operation fails.
 */
native HealthNade_GiveNade(const id);
