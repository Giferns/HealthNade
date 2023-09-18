#include <amxmodx>
#include <reapi>

new const ACCESS_FLAG[] = "t"
const Float:MAX_HEALTH = 250.0

new g_bitAccessFlag

public plugin_init() {
	register_plugin("Custom MaxHealth", "1.0", "mx?!")

	g_bitAccessFlag = read_flags(ACCESS_FLAG)

	RegisterHookChain(RG_CBasePlayer_Spawn, "CBasePlayer_Spawn_Post", true)
}

public CBasePlayer_Spawn_Post(pPlayer) {
	if((get_user_flags(pPlayer) & g_bitAccessFlag) && is_user_alive(pPlayer)) {
		set_entvar(pPlayer, var_max_health, MAX_HEALTH)
	}
}