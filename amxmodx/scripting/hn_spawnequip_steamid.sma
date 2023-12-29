/*
	1.0 (29.12.2023):
		* Первая версия
*/

new const PLUGIN_VERSION[] = "1.0"

new const STEAMS_FILENAME[] = "plugins/hn_spawnequip_steamid.ini"

#include <amxmodx>
#include <amxmisc>
#include <reapi>
#include <healthnade>

#define rg_get_current_round() (get_member_game(m_iTotalRoundsPlayed) + 1)

enum _:DATA_STRUCT {
	bool:DATA__EXISTS,
	DATA__MIN_ROUND,
	DATA__COUNT_PER_ROUND,
	Float:DATA__DRINK_HEAL_AMT,
	Float:DATA__THROW_HEAL_AMT,
	Float:DATA__EXPLODE_RADIUS,
	DATA__UNTIL
}

new Trie:g_tData, g_ePlayerData[MAX_PLAYERS + 1][DATA_STRUCT]
new g_iTaked[MAX_PLAYERS + 1]

public plugin_init() {
	register_plugin("[HN] SpawnEquip SteamID", PLUGIN_VERSION, "mx?!")

	g_tData = TrieCreate()

	LoadAccessCfg()

	RegisterHookChain(RG_CBasePlayer_OnSpawnEquip, "CBasePlayer_OnSpawnEquip_Post", true)
	RegisterHookChain(RG_CSGameRules_RestartRound, "CSGameRules_RestartRound_Pre")
}

LoadAccessCfg() {
	new szPath[240]
	new iLen = get_configsdir(szPath, charsmax(szPath))
	formatex(szPath[iLen], charsmax(szPath) - iLen, "/%s", STEAMS_FILENAME)
	new hFile = fopen(szPath, "r")

	if(!hFile) {
		set_fail_state("Can't %s '%s'", file_exists(szPath) ? "read" : "find", szPath)
	}

	new szAuthID[64], szMinRound[6], szCountPerRound[6], szUntil[32], iSysTime = get_systime()
	new szDrinkHealAmt[6], szThrowHealAmt[6], szExplodeRadius[6]

	g_ePlayerData[0][DATA__EXISTS] = true

	while(fgets(hFile, szPath, charsmax(szPath))) {
		trim(szPath)

		if(!szPath[0] || szPath[0] == '/' || szPath[0] == ';') {
			continue
		}

		parse( szPath,
			szAuthID, charsmax(szAuthID),
			szMinRound, charsmax(szMinRound),
			szCountPerRound, charsmax(szCountPerRound),
			szDrinkHealAmt, charsmax(szDrinkHealAmt),
			szThrowHealAmt, charsmax(szThrowHealAmt),
			szExplodeRadius, charsmax(szExplodeRadius),
			szUntil, charsmax(szUntil)
		);

		g_ePlayerData[0][DATA__UNTIL] = parse_time(szUntil, "%d.%m.%Y")

		if(iSysTime >= g_ePlayerData[0][DATA__UNTIL]) {
			continue
		}

		g_ePlayerData[0][DATA__MIN_ROUND] = str_to_num(szMinRound)
		g_ePlayerData[0][DATA__COUNT_PER_ROUND] = str_to_num(szCountPerRound)
		g_ePlayerData[0][DATA__DRINK_HEAL_AMT] = str_to_float(szDrinkHealAmt)
		g_ePlayerData[0][DATA__THROW_HEAL_AMT] = str_to_float(szThrowHealAmt)
		g_ePlayerData[0][DATA__EXPLODE_RADIUS] = str_to_float(szExplodeRadius)

		TrieSetArray(g_tData, szAuthID, g_ePlayerData[0], sizeof(g_ePlayerData[]))
	}

	fclose(hFile)
}

public client_putinserver(pPlayer) {
	new szAuthID[64]
	get_user_authid(pPlayer, szAuthID, charsmax(szAuthID))

	if(!TrieGetArray(g_tData, szAuthID, g_ePlayerData[pPlayer], sizeof(g_ePlayerData[]))) {
		g_ePlayerData[pPlayer][DATA__EXISTS] = false
		return
	}

	if(g_ePlayerData[pPlayer][DATA__UNTIL] <= get_systime()) {
		g_ePlayerData[pPlayer][DATA__EXISTS] = false
		TrieDeleteKey(g_tData, szAuthID)
	}
}

public HealthNade_CanEquip(const id) {
	return (g_ePlayerData[id][DATA__EXISTS] && g_ePlayerData[id][DATA__UNTIL] > get_systime())
}

public HealthNade_GetProp(const id, const iPropType, &any:PropValue, PropString[MAX_PROP_STRING_LEN]) {
	if(!g_ePlayerData[id][DATA__EXISTS] || g_ePlayerData[id][DATA__UNTIL] <= get_systime()) {
		return PLUGIN_CONTINUE
	}

	switch(iPropType) {
		case HnProp_DrinkHealingAmount: PropValue = g_ePlayerData[id][DATA__DRINK_HEAL_AMT]
		case HnProp_ThrowHealingAmount: PropValue = g_ePlayerData[id][DATA__THROW_HEAL_AMT]
		case HnProp_ExplodeRadius: PropValue = g_ePlayerData[id][DATA__EXPLODE_RADIUS]
		default: {
			return PLUGIN_CONTINUE
		}
	}

	return PLUGIN_HANDLED
}

public CSGameRules_RestartRound_Pre() {
	arrayset(g_iTaked, 0, sizeof(g_iTaked))
}

public CBasePlayer_OnSpawnEquip_Post(pPlayer) {
	if(!g_ePlayerData[pPlayer][DATA__EXISTS] || !is_user_alive(pPlayer)) {
		return
	}

	if(rg_get_current_round() < g_ePlayerData[pPlayer][DATA__MIN_ROUND]) {
		return
	}

	if(g_iTaked[pPlayer] > g_ePlayerData[pPlayer][DATA__COUNT_PER_ROUND]) {
		return
	}

	g_iTaked[pPlayer]++

	HealthNade_GiveNade(pPlayer)
}