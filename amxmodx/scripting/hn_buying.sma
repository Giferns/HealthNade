/*
    1.0 (23.10.2026 by mx?!):
        * Первая версия
*/

new const PLUGIN_VERSION[] = "1.0"

#include <amxmodx>
#include <reapi>
#include <healthnade>

// Создавать и загружать авто-конфиг автоматически.
// Закомментируйте для отключения.
// Значение AUTO_CFG является именем конфига. Указывайте только имя, без расширения (без .cfg)
// Значение "" - по умолчанию (plugin-%plugin_name%.cfg)
#define AUTO_CFG "hn_buying"

// Список клиентских команд для покупки гранаты
new const CLCMDS[][] = {
    "say /hn",
    "say_team /hn",
    "buy_hn"
};

#pragma semicolon 1
#define rg_get_current_round() (get_member_game(m_iTotalRoundsPlayed) + 1)
#define rg_get_user_money(%0) get_member(%0, m_iAccount)
#define rg_set_user_money rg_add_account

enum _:CVAR_ENUM {
    CVAR__ENABLED,
    CVAR__ACCESS[32],
    CVAR__ACCESS_MODE,
    CVAR__OBEY_BUYZONE,
    CVAR__OBEY_BUYTIME,
    CVAR__COST,
    CVAR__MIN_ROUND,
    CVAR__BUY_FREQUENCY
};

new g_eCvar[CVAR_ENUM];
new Trie:g_tLastBuyRound;
new g_msgBlinkAcct;

// Массив для хранения последнего раунда покупки каждым игроком
new g_iLastBuyRound[MAX_PLAYERS + 1];

public plugin_init() {
    register_plugin("[HN] Buying", PLUGIN_VERSION, "mx?!");
    
    register_dictionary("hn_buying.txt");
    
    g_tLastBuyRound = TrieCreate();
    g_msgBlinkAcct = get_user_msgid("BlinkAcct");
    RegisterHookChain(RG_CSGameRules_RestartRound,"CSGameRules_RestartRound_Pre");
    
    for(new i; i < sizeof(CLCMDS); i++) {
        register_clcmd(CLCMDS[i], "ClCmd_BuyHealthNade");
    }
    
    RegCvars();
}

RegCvars() {  
    bind_pcvar_num( create_cvar( "hb_buy_enabled", "1",
        .description = "Покупка выключена (0) или включена (1) ?" ),
        g_eCvar[CVAR__ENABLED]
    );

    bind_pcvar_string( create_cvar( "hb_buy_access", "", 
        .description = "AMXX-флаги доступа к функции покупки гранаты (^"^" - доступ для всех)" ),
        g_eCvar[CVAR__ACCESS], charsmax(g_eCvar[CVAR__ACCESS])
    );
    
    bind_pcvar_num( create_cvar( "hn_buy_access_mode", "0",
        .description = "Требуется любой из (0) AMXX-флагов, или наличие всех перечисленных (1) ?" ),
        g_eCvar[CVAR__ACCESS_MODE]    
    );
    
    bind_pcvar_num( create_cvar( "hb_buy_obey_buyzone", "1",
        .description = "Покупка везде (0), или только в зоне покупки (1) ?" ),
        g_eCvar[CVAR__OBEY_BUYZONE]
    );
    
    bind_pcvar_num( create_cvar( "hb_buy_obey_buytime", "0",
        .description = "Время на покупку: -1 - без лимита, 0 - mp_buytime, 1 и более - время в секундах" ),
        g_eCvar[CVAR__OBEY_BUYTIME]
    );
    
    bind_pcvar_num( create_cvar( "hn_buy_cost", "3000",
        .description = "Стоимость гранаты в $" ),
        g_eCvar[CVAR__COST]
    );
    
    bind_pcvar_num( create_cvar( "hn_buy_min_round", "3",
        .description = "Минимальный раунд для покупки" ),
        g_eCvar[CVAR__MIN_ROUND]
    );
    
    bind_pcvar_num( create_cvar( "hn_buy_frequency", "1",
        .description = "Задержка в раундах между повторными покупками" ),
        g_eCvar[CVAR__BUY_FREQUENCY]
    );
    
#if defined AUTO_CFG
    AutoExecConfig(.name = AUTO_CFG);
#endif
}

public CSGameRules_RestartRound_Pre() {
    if(get_member_game(m_bCompleteReset)) {
        arrayset(g_iLastBuyRound, 0, sizeof(g_iLastBuyRound));
        TrieClear(g_tLastBuyRound);
    }
}

public client_disconnected(id) {
    if(!g_iLastBuyRound[id]) {
        return;
    }
    
    new szAuthId[64];
    get_user_authid(id, szAuthId, charsmax(szAuthId));
    TrieSetCell(g_tLastBuyRound, szAuthId, 0);
    g_iLastBuyRound[id] = 0;
}

public client_putinserver(id) {
    new szAuthId[64];
    get_user_authid(id, szAuthId, charsmax(szAuthId));
    TrieGetCell(g_tLastBuyRound, szAuthId, g_iLastBuyRound[id]);
}

public ClCmd_BuyHealthNade(id) {
    if(!g_eCvar[CVAR__ENABLED]) {
        client_print(id, print_center, "#Cstrike_TitlesTXT_Command_Not_Available"); // This command is not available to you at this point
        client_print_color(id, print_team_red, "%l", "HN_BUY_NO_DISABLED");
        return PLUGIN_HANDLED;   
    }

    if(!CheckAccess(id)) {
        client_print(id, print_center, "#Cstrike_TitlesTXT_Command_Not_Available"); // This command is not available to you at this point
        client_print_color(id, print_team_red, "%l", "HN_BUY_NO_ACCESS");
        return PLUGIN_HANDLED;  
    }

    if(!is_user_alive(id)) {
        client_print(id, print_center, "#Cstrike_TitlesTXT_Command_Not_Available"); // This command is not available to you at this point
        client_print_color(id, print_team_red, "%l", "HN_BUY_DEAD");
        return PLUGIN_HANDLED;
    }
    
    new iCurrentRound = rg_get_current_round();
    
    new iMinRound = g_eCvar[CVAR__MIN_ROUND];
    if(iCurrentRound < iMinRound) {
        client_print(id, print_center, "#Cstrike_TitlesTXT_Cannot_Buy_This"); // You cannot buy this item!
        client_print_color(id, print_team_red, "%l", "HN_BUY_MIN_ROUND", iMinRound, iCurrentRound);
        return PLUGIN_HANDLED;
    }
    
    if(g_iLastBuyRound[id]) {
        new iFreq = max(1, g_eCvar[CVAR__BUY_FREQUENCY]);
        new iDiff = iCurrentRound - g_iLastBuyRound[id];
        if(iDiff < iFreq) {
            client_print(id, print_center, "#Cstrike_TitlesTXT_Cannot_Buy_This"); // You cannot buy this item!
            new iWait = iFreq - iDiff;
            client_print_color(id, print_team_red, "%l", "HN_BUY_FREQ_WAIT", iWait);
            return PLUGIN_HANDLED;
        }
    }
    
    if(HealthNade_HasNade(id)) {
        client_print(id, print_center, "#Cstrike_TitlesTXT_Cannot_Carry_Anymore"); // You cannot carry anymore!
        client_print_color(id, print_team_red, "%l", "HN_BUY_ALREADY_HAVE");
        return PLUGIN_HANDLED;
    }
    
    new iCost  = g_eCvar[CVAR__COST];
    new iMoney = rg_get_user_money(id);
    
    if(iMoney < iCost) {
        client_print(id, print_center, "#Cstrike_TitlesTXT_Not_Enough_Money"); // You have insufficient funds!
        new iIns = iCost - iMoney;
        client_print_color(id, print_team_red, "%l", "HN_BUY_NO_MONEY", iCost, iIns);
        message_begin(MSG_ONE_UNRELIABLE, g_msgBlinkAcct, .player = id);
        write_byte(2); // amount of blinks
        message_end();
        return PLUGIN_HANDLED;
    }
    
    if(g_eCvar[CVAR__OBEY_BUYZONE] && !rg_get_user_buyzone(id)) {
        client_print(id, print_center, "#Cstrike_TitlesTXT_Cannot_Buy_This"); // You cannot buy this item!
        client_print_color(id, print_team_red, "%l", "HN_BUY_OBEY_BUYZONE");
        return PLUGIN_HANDLED;
    }
    
    if(!CheckBuyTime()) {
        client_print(id, print_center, "#Cstrike_TitlesTXT_Cannot_Buy_This"); // You cannot buy this item!
        client_print_color(id, print_team_red, "%l", "HN_BUY_OBEY_BUYTIME");
        return PLUGIN_HANDLED; 
    }
    
    // Выдача гранаты и списание денег
    // Натив возвращает HN_NULLENT (-1) при неудаче, иначе > 0. В значении может появиться 0, только 
    // если будет добавлен native_filter с блокировкой ошибки, в таком случае поменять на условие с 
    // "!= HN_NULLENT" на "> 0".
    if(HealthNade_GiveNade(id, 1) != HN_NULLENT) {
        rg_set_user_money(id, -iCost); // TODO: TEST -0
        g_iLastBuyRound[id] = iCurrentRound;
        client_print_color(id, print_team_red, "%l", "HN_BUY_SUCCESS", iCost);
        return PLUGIN_HANDLED;
    }
    
    client_print_color(id, print_team_red, "%l", "HN_BUY_FAILED");

    return PLUGIN_HANDLED;
}

bool:CheckAccess(id) {
    new bitFlags = read_flags(g_eCvar[CVAR__ACCESS]);
    
    if(!bitFlags) {
        return true;
    }
    
    if(g_eCvar[CVAR__ACCESS_MODE]) {
        return (get_user_flags(id) & bitFlags) == bitFlags;
    }
    
    return (get_user_flags(id) & bitFlags) > 0;
}

// hb_buy_obey_buytime ---> Время на покупку: -1 - без лимита, 0 - mp_buytime, 1 и более - время в секундах
bool:CheckBuyTime() {
    switch(g_eCvar[CVAR__OBEY_BUYTIME]) {
        case -1: {
            return true;
        }
        case 0: {
            if(IsBuyTimeOver()) {
                return false;
            }
        }
        default: {
            if(get_gametime() - Float:get_member_game(m_fRoundStartTime) > float(g_eCvar[CVAR__OBEY_BUYTIME])) {
                return false;
            }
        }
    }

    // dummy (logically unreachable)
    return true;
}

stock bool:rg_get_user_buyzone(pPlayer) {
	new iSignals[UnifiedSignals];
	get_member(pPlayer, m_signals, iSignals);
	return bool:(SignalState:iSignals[US_State] & SIGNAL_BUY);
}

// Проверка, истёк ли байтайм
// https://github.com/s1lentq/ReGameDLL_CS/blob/2eba3b1186d5814408f4c082fd72aee637eaaac3/regamedll/dlls/player.cpp#L4231
stock bool:IsBuyTimeOver() {
	static pCvar, Float:fBuyTime;

	if(!pCvar) {
		pCvar = get_cvar_pointer("mp_buytime");
		bind_pcvar_float(pCvar, fBuyTime);
	}

	if(fBuyTime == -1.0) {
		return false;
	}

	// https://github.com/s1lentq/ReGameDLL_CS/blob/fd06d655ec62a623d27178dc015a25f472c6ab03/regamedll/dlls/player.h#L42
	const Float:MIN_BUY_TIME = 15.0;

	new Float:fTime = floatmax(MIN_BUY_TIME, fBuyTime * 60.0);

	return (get_gametime() - Float:get_member_game(m_fRoundStartTime) > fTime);
}
