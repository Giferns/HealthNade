/*
	1.0 (21.08.2024 by mx?!):
		* Первый релиз
*/

new const PLUGIN_VERSION[] = "1.0"

// Серверная команда для внешней выдачи через BonusMenu RBS
new const SRVCMD_BONUSMENU_RBS[] = "hn_bmrbs"

// Имя файла основного конфига в 'amxmodx/configs'
new const CFG_FILENAME[] = "plugins/hn_bonusmenu_rbs.cfg"

/* ------------------------------------------------------------------ */

// BonusMenu RBS https://fungun.net/shop/?p=show&id=106
native bonusmenu_get_user_points(id)
native bonusmenu_add_user_points(id, points)

#include <amxmodx>
#include <amxmisc>
#include <reapi>
#include <healthnade>

#define rg_get_current_round() (get_member_game(m_iTotalRoundsPlayed) + 1)
new g_iCooldown[MAX_PLAYERS + 1], g_iBuyzone, g_iDmMode

public plugin_init() {
	register_plugin("[HN] BonusMenu RBS", PLUGIN_VERSION, "mx?!")

	RegCvars()

	register_srvcmd(SRVCMD_BONUSMENU_RBS, "srvcmd_GiveItem_BonusMenuRBS")

	RegisterHookChain(RG_CSGameRules_RestartRound, "CSGameRules_RestartRound_Pre")
}

RegCvars() {
	bind_pcvar_num( create_cvar("hn_bmrbs_only_buyzone", "1",
		.description = "Разрешить покупать гранату только в зоне закупки (1/0) ?" ), g_iBuyzone );

	bind_pcvar_num( create_cvar("hn_bmrbs_dm_mode", "1",
		.description = "Режим 'без раундов': задержка в раундах заменяется на задержку в секундах" ), g_iDmMode );

	new szPath[PLATFORM_MAX_PATH]
	get_configsdir(szPath, charsmax(szPath))
	server_cmd("exec %s/%s", szPath, CFG_FILENAME)
}

public srvcmd_GiveItem_BonusMenuRBS() {
	enum { arg_userid = 1, arg_price, arg_count, arg_min_round, arg_cooldown, arg_access_flag }

	new szUserId[16]
	read_argv(arg_userid, szUserId, charsmax(szUserId))

	new pPlayer = find_player("k", str_to_num(szUserId[1]))

	if(!pPlayer) {
		abort(AMX_ERR_GENERAL, "[1] Player '%s' not found", szUserId[1])
	}

	new iCount = read_argv_int(arg_count)

	if(iCount < 1) {
		abort(AMX_ERR_GENERAL, "[1] Wrong count %i", iCount)
	}

	new szFlag[32]
	read_argv(arg_access_flag, szFlag, charsmax(szFlag))

	new bitFlag = read_flags(szFlag)

	if(bitFlag && szFlag[0] != '0' && !(get_user_flags(pPlayer) & bitFlag)) {
		client_print_color(pPlayer, print_team_red, "%l", "HN_BMRBS_NO_ACCESS")
		return PLUGIN_HANDLED
	}

	if(!is_user_alive(pPlayer)) {
		client_print_color(pPlayer, print_team_red, "%l", "HN_BMRBS_ONLY_ALIVE")
		return PLUGIN_HANDLED
	}

	if(HealthNade_HasNade(pPlayer)) {
		client_print_color(pPlayer, print_team_red, "%l", "HN_BMRBS_ALREADY_HAVE")
		return PLUGIN_HANDLED
	}

	if(!CheckMinRound(pPlayer, read_argv_int(arg_min_round))) {
		return PLUGIN_HANDLED
	}

	if(!CheckCooldown(pPlayer)) {
		return PLUGIN_HANDLED
	}

	if(g_iBuyzone && !rg_get_user_buyzone(pPlayer)) {
		client_print_color(pPlayer, print_team_red, "%l", "HN_BMRBS_ONLY_BUYZONE")
		return PLUGIN_HANDLED
	}

	new iPrice = read_argv_int(arg_price)

	if(iPrice) {
		if(bonusmenu_get_user_points(pPlayer) < iPrice) {
			client_print_color(pPlayer, print_team_red, "%l", "HN_BMRBS_NOT_ENOUGH_POINTS")
			return PLUGIN_HANDLED
		}

		bonusmenu_add_user_points(pPlayer, -iPrice)
	}

	new iCooldown = read_argv_int(arg_cooldown)

	if(g_iDmMode) {
		g_iCooldown[pPlayer] = floatround(get_gametime()) + iCooldown
	}
	else {
		g_iCooldown[pPlayer] = read_argv_int(arg_cooldown)
	}

	HealthNade_GiveNade(pPlayer, iCount, iCount)

	return PLUGIN_HANDLED
}

bool:CheckCooldown(pPlayer) {
	if(!g_iDmMode) {
		if(g_iCooldown[pPlayer]) {
			new szRounds[32]
			func_GetEnding(g_iCooldown[pPlayer], "HN_BMRBS_ROUNDS_1", "HN_BMRBS_ROUNDS_2", "HN_BMRBS_ROUNDS_3", szRounds, charsmax(szRounds))
			client_print_color(pPlayer, print_team_red, "%l", "HN_BMRBS_WAIT_MORE_ROUNDS", g_iCooldown[pPlayer], szRounds)
			return false
		}

		return true
	}

	new iGameTime = floatround(get_gametime())

	if(!g_iCooldown[pPlayer] || iGameTime >= g_iCooldown[pPlayer]) {
		return true
	}

	new iSeconds = g_iCooldown[pPlayer] - iGameTime
	client_print_color(pPlayer, print_team_red, "%l", "HN_BMRBS_WAIT_MORE_SECONDS", iSeconds / 60, iSeconds % 60)
	return false
}

bool:CheckMinRound(pPlayer, iMinRound) {
	if(!g_iDmMode) {
		if(rg_get_current_round() < iMinRound) {
			client_print_color(pPlayer, print_team_red, "%l", "HN_BMRBS_MIN_ROUND", iMinRound)
			return false
		}

		return true
	}

	new iGameTime = floatround(get_gametime())

	if(iGameTime < iMinRound) {
		new iSeconds = iMinRound - iGameTime
		client_print_color(pPlayer, print_team_red, "%l", "HN_BMRBS_WAIT_MORE_SECONDS", iSeconds / 60, iSeconds % 60)
		return false
	}

	return true
}

public CSGameRules_RestartRound_Pre() {
	if(g_iDmMode) {
		return
	}

	for(new i; i < sizeof(g_iCooldown); i++) {
		if(g_iCooldown[i]) {
			g_iCooldown[i]--
		}
	}
}

public client_disconnected(pPlayer) {
	g_iCooldown[pPlayer] = 0
}

stock func_GetEnding(iValue, const szA[], const szB[], const szC[], szBuffer[], iMaxLen) {
	new iValue100 = iValue % 100, iValue10 = iValue % 10;

	if(iValue100 >= 5 && iValue100 <= 20 || iValue10 == 0 || iValue10 >= 5 && iValue10 <= 9) {
		copy(szBuffer, iMaxLen, szA)
		return
	}

	if(iValue10 == 1) {
		copy(szBuffer, iMaxLen, szB)
		return
	}

	/*if(iValue10 >= 2 && iValue10 <= 4) {
		copy(szBuffer, iMaxLen, szC)
	}*/

	copy(szBuffer, iMaxLen, szC)
}

// Аналог cs_get_user_buyzone() https://dev-cs.ru/threads/222/post-32988
bool:rg_get_user_buyzone(pPlayer) {
	new iSignals[UnifiedSignals]
	get_member(pPlayer, m_signals, iSignals)
	return bool:(SignalState:iSignals[US_State] & SIGNAL_BUY)
}
