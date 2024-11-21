/*
	1.0 (19.11.2024 by mx?!):
		* Первый релиз
*/

new const PLUGIN_VERSION[] = "1.0"

#include <amxmodx>
#include <amxmisc>
#include <reapi>
#tryinclude <gamecms5>
#include <healthnade>

// Имя файла основного конфига в 'amxmodx/configs'
new const FLAGS_CFG_FILENAME[] = "plugins/hn_spawnequip_gamecms.cfg"

// Имя логфайла отладки в 'amxmodx/logs', в рабочей версии должен быть закомментирован
//#define DEBUG "hn_gamecms_debug.log"

/* ------------------------------------------------------------------ */

#if !defined _gamecms5_included
	native Array:cmsapi_get_user_services(const index, const szAuth[] = "", const szService[] = "", serviceID = 0, bool:part = false);
#endif

#define rg_get_current_round() (get_member_game(m_iTotalRoundsPlayed) + 1)

enum _:DATA_STRUCT {
	DATA__FLAG[64],
	DATA__MIN_ROUND,
	DATA__COUNT
}

new g_eData[DATA_STRUCT], Array:g_aData, g_iMinRound[MAX_PLAYERS + 1], g_iCount[MAX_PLAYERS + 1]
new bool:g_bChecked[MAX_PLAYERS + 1], Float:g_fDelay, g_iEachSpawn, Float:g_fCooldown
new Float:g_fLastEquipTime[MAX_PLAYERS + 1], g_iMinMode, Float:g_fRoundStartTime, g_iEquipEnabled

public plugin_init() {
	register_plugin("[HN] SpawnEquip GameCMS", PLUGIN_VERSION, "mx?!")

	RegisterHookChain(RG_CBasePlayer_OnSpawnEquip, "CBasePlayer_OnSpawnEquip_Post", true)
	RegisterHookChain(RG_CSGameRules_RestartRound, "CSGameRules_RestartRound_Pre")

	g_aData = ArrayCreate(DATA_STRUCT, 6)

	bind_pcvar_num( create_cvar("hn_gamecms_equip_enabled", "1",
		.description = "Включить выдачу (1 - да; 0 - нет) ?"), g_iEquipEnabled );

	bind_pcvar_float( create_cvar("hn_gcms_autoequip_delay", "0.0",
		.has_min = true, .min_val = 0.0,
		.description = "Задержка выдачи после спавна"), g_fDelay );

	bind_pcvar_num( create_cvar("hn_gcms_each_spawn", "0",
		.has_min = true, .min_val = 0.0,
		.description = "Выдавать гранату в случае если игрок спавнится повторно в течение одного раунда (1 - да; 0 - нет) ?"), g_iEachSpawn );

	bind_pcvar_float( create_cvar("hn_gcms_autoequip_cooldown", "0",
		.has_min = true, .min_val = 0.0,
		.description = "Не выдавать гранату чаще одного раза в # секунд (0 - без лимита)"), g_fCooldown );
		
	bind_pcvar_num( create_cvar("hn_min_mode", "0",
		.description = "Режим ограничения"), g_iMinMode );

	register_srvcmd("hn_gcms_reg_flag", "srvcmd_RegFlag");

	new szPath[240]
	get_configsdir(szPath, charsmax(szPath))
	server_cmd("exec %s/%s", szPath, FLAGS_CFG_FILENAME)
}

public srvcmd_RegFlag() {
	enum { arg_flag = 1, arg_round, arg_count, arg_total }

	if(read_argc() < arg_total) {
		return PLUGIN_HANDLED
	}

	read_argv(arg_flag, g_eData[DATA__FLAG], charsmax(g_eData[DATA__FLAG]))
	g_eData[DATA__MIN_ROUND] = read_argv_int(arg_round)
	g_eData[DATA__COUNT] = read_argv_int(arg_count)

	ArrayPushArray(g_aData, g_eData)

	return PLUGIN_HANDLED
}

public client_connect(pPlayer) {
	g_iCount[pPlayer] = 0
	g_bChecked[pPlayer] = false
}

public CheckPlayer(pPlayer) {
#if defined DEBUG
	log_to_file(DEBUG, "CheckPlayer() for %N", pPlayer)
#endif

	for(new i, iArraySize = ArraySize(g_aData); i < iArraySize; i++) {
		ArrayGetArray(g_aData, i, g_eData)

		if(cmsapi_get_user_services(pPlayer, "", g_eData[DATA__FLAG], 0) != Invalid_Array) {
			g_iCount[pPlayer] = g_eData[DATA__COUNT]
			g_iMinRound[pPlayer] = g_eData[DATA__MIN_ROUND]
		#if defined DEBUG
			log_to_file(DEBUG, "%N got count %i, minround %i", pPlayer, g_iCount[pPlayer], g_iMinRound[pPlayer])
		#endif
			break
		}
	}
}

bool:IsInCooldown(pPlayer) {
	if(!g_fCooldown) {
		return false
	}

	new Float:fGameTime = get_gametime()

	if(g_fLastEquipTime[pPlayer] && g_fLastEquipTime[pPlayer] + g_fCooldown > fGameTime) {
		return true
	}

	g_fLastEquipTime[pPlayer] = fGameTime
	return true
}

public CSGameRules_RestartRound_Pre() {
	g_fRoundStartTime = get_gametime()
}

public CBasePlayer_OnSpawnEquip_Post(pPlayer) {
	if(!is_user_alive(pPlayer)) {
		return
	}

	remove_task(pPlayer)

	if(!g_bChecked[pPlayer]) {
		g_bChecked[pPlayer] = true
		CheckPlayer(pPlayer)
	}

	if(
		!g_iEquipEnabled
			||
		g_iCount[pPlayer] < 1
			||
		IsInCooldown(pPlayer)
	) {
		return
	}

	if(!g_iEachSpawn && get_member(pPlayer, m_iNumSpawns) > 1) {
		return
	}

	if(g_fDelay) {
		set_task(g_fDelay, "task_GiveNade", pPlayer)
		return
	}

	if(!CheckMinMode(pPlayer)) {
		return
	}

#if defined DEBUG
	log_to_file(DEBUG, "HealthNade_GiveNade() for %N", pPlayer)
#endif
	HealthNade_GiveNade(pPlayer, g_iCount[pPlayer], g_iCount[pPlayer])
}

public task_GiveNade(pPlayer) {
	if(g_iEquipEnabled && is_user_alive(pPlayer) && g_iCount[pPlayer] && CheckMinMode(pPlayer)) {
		HealthNade_GiveNade(pPlayer, g_iCount[pPlayer], g_iCount[pPlayer])
	}
}

bool:CheckMinMode(pPlayer) {
	switch(g_iMinMode) {
		case 0: return ( rg_get_current_round() >= g_iMinRound[pPlayer] )
		case 1: return ( get_gametime() >= float(g_iMinRound[pPlayer]) )
		case 2: return ( get_gametime() - g_fRoundStartTime >= float(g_iMinRound[pPlayer]) )
	}
	
	return false
}

public client_disconnected(pPlayer) {
	remove_task(pPlayer)
}