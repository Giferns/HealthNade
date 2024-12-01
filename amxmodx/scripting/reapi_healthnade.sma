/*
	Форк лечебной гранаты на основе Healthnade 0.0.2 от F@nt0M: https://dev-cs.ru/resources/992/

	GitHub: https://github.com/Giferns/HealthNade

	0.0.3f:
		* Добавлена возможность пить зелье на ПКМ (спасибо AnonymousAmx, MayroN, Psycrow)
			* Опция HEAL_AMOUNT переименована в HEAL_AMOUNT_THROW
			* Добавлена опция HEAL_AMOUNT_DRINK
			* Добавлены опции USAGE_MSG и FULL_HP_MSG
			* Заменена модель в руках (v_) на модель с анимацией выпивания
			* Добавлен звук выпивания (обрататие внимание, модель содержит другие пути к звукам!)

	0.0.4f:
		* Добавлена опция MIN_ROUND (минимальный раунд для автовыдачи по флагу)

	0.0.5f:
		* Добавлен натив HealthNade_GiveNade()

	0.0.6f:
		* Перенос параметров хилки в переменные сущности: https://github.com/Giferns/HealthNade/pull/1

	0.0.7f:
		* Добавлены квары и словарь

	0.0.8f:
		* Фикс учёта mp_nadedrops (теперь учитывает значение на лету)
		* Добавлен недостающий учёт квара HealthNade_Give
		* Значение квара HealthNade_Give по-умолчанию теперь 1 (было 0)
		* Исправлена логика создания кастомного веапонбокса

	0.0.9f:
		* Добавлен квар HealthNade_SlotId

	0.0.10f:
		* Добавлен квар HealthNade_EquipDelay

	0.0.11f
		* Добавлен квар HealthNade_ReplaceSmokegren

	0.0.12f
		* Добавлен квар HealthNade_Drink_AccessFlags

	0.0.13f
		* Добавлены квары и обновлен словарь
		* HealthNade_ThrowHealingAmount_With_Flags
		* HealthNade_DrinkHealingAmount_With_Flags
		* HealthNade_Override_AccessFlags

	0.0.14f (29.12.2023)
		* Расширено API под внешнюю выдачу (форварды HealthNade_CanEquip() и HealthNade_GetProp())

	0.0.15f (30.12.2023)
		* Добавлен натив HealthNade_HasNade()
	0.0.16f (19.02.2024)
		* Добавлен отсев ботов в CBasePlayer_OnSpawnEquip_Post()
			* https://github.com/Giferns/HealthNade/pull/13
				* Спасибо https://github.com/anzz1
	0.0.17f (21.08.2024)
		* В натив HealthNade_GiveNade добавлены аргументы count и maximum
		* Квар HealthNade_Give теперь отвечает за кол-во выдаваемых гранат (0 - не выдавать)
		* Улучшена логика для квара HealthNade_NadeDrop
		* Заблокирована выдача ботам
	0.0.18f (12.09.2024)
		* Добавлена консольная серверная команда для внешней выдачи, формат:
			give_healthnade #%userid% кол-во
				либо
			give_healthnade %id% кол-во
	0.0.19f (12.09.2024)
		* Исправление положения функции srvcmd_GiveHealthnade
	0.0.20f (30.09.2024)
		* Конфиг переведён на константный (больше не создаётся автоматически)
		* Пути к моделям переведены с констант на квары
	0.0.21f (17.10.2024)
		* Избавление от хардкода WEAPON_SMOKEGRENADE
	0.0.22f (27.10.2024):
		* Добавлена поддержка mp_infinite_ammo 1/2
	0.0.23f (21.11.2024):
		* Добавлен плагин экипировки по услугам GameCMS
	0.0.24f (30.11.2024):
		* Бамп версии
	0.0.25f (01.11.2024):
		* Добавлен квар HealthNade_BaseWeapon (возможность переопределить оружие-основу)
*/

new const PLUGIN_VERSION[] = "0.0.25f";

#pragma semicolon 1

#include <amxmodx>
#include <amxmisc>
#include <fakemeta>
#include <hamsandwich>
#include <reapi>
#include <xs>
#include <healthnade>

enum E_NadeDropType {
	NadeDrop_Off = 0,
	NadeDrop_On = 1,
	NadeDrop_ByCvar = 2,
}

enum E_Cvars {
	Float:Cvar_ExplodeRadius,
	Float:Cvar_ThrowHealingAmount,
	Float:Cvar_ThrowHealingAmountWithFlags,
	Float:Cvar_DrinkHealingAmount,
	Float:Cvar_DrinkHealingAmountWithFlags,
	bool:Cvar_Give,
	Cvar_Give_AccessFlags[16],
	Cvar_Drink_AccessFlags[16],
	Cvar_Override_AccessFlags[16],
	Cvar_Give_MinRound,
	Float:Cvar_EquipDelay,
	bool:Cvar_ReplaceSmokegren,
	bool:Cvar_Msg_FullHp,
	bool:Cvar_Msg_UsageHint,
	E_NadeDropType:Cvar_NadeDrop,
	InventorySlotType:Cvar_SlotId,
	Cvar_ViewModel[96],
	Cvar_PlayerModel[96],
	Cvar_WorldModel[96],
	Cvar_BaseWeapon[32]
}
new gCvars[E_Cvars];
#define Cvar(%1) gCvars[Cvar_%1]

new const CFG_FILENAME[] = "plugins/HealthNade.cfg"; // comment to disable .cfg loading
new const DICTIONARY_FILENAME[] = "HealthNade.ini";

#define LangS(%1) fmt("%l", %1)

const WeaponIdType:WEAPON_NEW_ID = WEAPON_GLOCK;
const WeaponIdType:WEAPON_FAKE_ID = WeaponIdType:75;
new const AMMO_NAME[] = "HealthNade";
new const WEAPON_NEW_NAME[] = "reapi_healthnade/weapon_healthnade";
new const ITEM_CLASSNAME[] = "weapon_healthnade";
new const GRENADE_CLASSNAME[] = "healthnade";
const AMMO_ID = 16;
const InventorySlotType:ITEM_SLOT = GRENADE_SLOT;

new const SOUND_PULLPIN[] = "weapons/holywater_pinpul.wav";
new const SOUND_DEPLOY[] = "weapons/holywater_deploy.wav";
new const SOUND_DRINK[] = "weapons/holywater_drink.wav";
new const SOUND_EXPLODE[] = "weapons/reapi_healthnade/heal.wav";
// TODO: Вынести остальные пути в константы

#define rg_get_current_round() (get_member_game(m_iTotalRoundsPlayed) + 1)

// copy_entvar(const iEntFrom, const iEntTo, const EntVar:iVar)
#define copy_entvar(%1,%2,%3) set_entvar(%2, %3, get_entvar(%1, %3))

new SpriteCylinder, SpriteExplode, SpriteShape;
new MsgIdWeaponList, MsgIdAmmoPickup, MsgIdStatusIcon, MsgIdScreenFade;
#if WEAPON_NEW_ID != WEAPON_GLOCK
new FwdRegUserMsg, MsgHookWeaponList;
#endif
new g_iCvarNadeDrops;
new g_fwdCanEquip, g_fwdGetProp, g_PropString[MAX_PROP_STRING_LEN];
new WeaponIdType:g_iWeaponID;

public plugin_precache() {
	register_plugin("[ReAPI] Healthnade", PLUGIN_VERSION, "DEV-CS.RU Community");
	register_dictionary(DICTIONARY_FILENAME);

	InitCvars();
#if defined CFG_FILENAME
	new szPath[240];
	get_configsdir(szPath, charsmax(szPath));
	server_cmd("exec %s/%s", szPath, CFG_FILENAME);
	server_exec();
#endif

	g_iWeaponID = rg_get_weapon_info(Cvar(BaseWeapon), WI_ID);

	precache_generic("sprites/reapi_healthnade/weapon_healthnade.txt");
	precache_generic("sprites/reapi_healthnade/640hud128.spr");

	precache_model(Cvar(ViewModel));
	precache_model(Cvar(PlayerModel));
	precache_model(Cvar(WorldModel));

	precache_sound(SOUND_PULLPIN);
	precache_sound(SOUND_DEPLOY);
	precache_sound(SOUND_DRINK);

	SpriteExplode = precache_model("sprites/reapi_healthnade/heal_explode.spr");
	SpriteShape = precache_model("sprites/reapi_healthnade/heal_shape.spr");
	SpriteCylinder = precache_model("sprites/shockwave.spr");

	precache_sound(SOUND_EXPLODE);

#if WEAPON_NEW_ID != WEAPON_GLOCK
	MsgIdWeaponList = get_user_msgid("WeaponList");
	if (MsgIdWeaponList) {
		MsgHookWeaponList = register_message(MsgIdWeaponList, "HookWeaponList");
	} else {
		FwdRegUserMsg = register_forward(FM_RegUserMsg, "RegUserMsg_Post", true);
	}
#endif
}

public plugin_init() {
	register_srvcmd("give_healthnade", "srvcmd_GiveHealthnade");
	register_clcmd(WEAPON_NEW_NAME, "CmdSelect");

	g_fwdCanEquip = CreateMultiForward("HealthNade_CanEquip", ET_STOP, FP_CELL);
	g_fwdGetProp = CreateMultiForward("HealthNade_GetProp", ET_STOP, FP_CELL, FP_CELL, FP_VAL_BYREF, FP_ARRAY);

	RegisterHookChain(RG_CBasePlayer_OnSpawnEquip, "CBasePlayer_OnSpawnEquip_Post", true);
	RegisterHookChain(RG_CBasePlayer_Killed, "CBasePlayer_Killed_Pre", false);

	RegisterHookChain(RG_CSGameRules_CleanUpMap, "CSGameRules_CleanUpMap_Post", true);
	RegisterHookChain(RG_CBasePlayer_GiveAmmo, "CBasePlayer_GiveAmmo_Pre", false);
	RegisterHookChain(RG_CBasePlayerWeapon_DefaultDeploy, "CBasePlayerWeapon_DefaultDeploy_Pre", false);

	RegisterHam(Ham_Item_Deploy, Cvar(BaseWeapon), "Item_Deploy_Post", true);
	RegisterHam(Ham_Item_Holster, Cvar(BaseWeapon), "Item_Holster_Post", true);

	RegisterHam(Ham_Weapon_SecondaryAttack, Cvar(BaseWeapon), "CBasePlayerWeapon_SecondaryAttack_Post", true);
	RegisterHam(Ham_Item_PostFrame, Cvar(BaseWeapon), "CBasePlayerWeapon_ItemPostFrame_Pre");

	RegisterHookChain(RG_CBasePlayer_ThrowGrenade, "CBasePlayer_ThrowGrenade_Pre", false);

	RegisterHookChain(RG_CBasePlayer_AddPlayerItem, "CBasePlayer_AddPlayerItem_Pre");
	RegisterHookChain(RG_CBasePlayer_HasRestrictItem, "CBasePlayer_HasRestrictItem_Pre");

	MsgIdAmmoPickup = get_user_msgid("AmmoPickup");
	MsgIdStatusIcon = get_user_msgid("StatusIcon");
	MsgIdScreenFade = get_user_msgid("ScreenFade");

#if WEAPON_NEW_ID == WEAPON_GLOCK
	MsgIdWeaponList = get_user_msgid("WeaponList");
	UTIL_WeapoList(
		MSG_INIT, 0,
		WEAPON_NEW_NAME,
		AMMO_ID, 1,
		-1, -1, Cvar(SlotId), 4, WEAPON_NEW_ID,
		ITEM_FLAG_LIMITINWORLD | ITEM_FLAG_EXHAUSTIBLE
	);
#else
	if (FwdRegUserMsg) {
		unregister_forward(FM_RegUserMsg, FwdRegUserMsg, true);
	}
	unregister_message(MsgIdWeaponList, MsgHookWeaponList);
#endif
}

#if WEAPON_NEW_ID != WEAPON_GLOCK
public RegUserMsg_Post(const name[]) {
	if (strcmp(name, "WeaponList") == 0) {
		MsgIdWeaponList = get_orig_retval();
		MsgHookWeaponList = register_message(MsgIdWeaponList, "HookWeaponList");
	}
}

public HookWeaponList(const msg_id, const msg_dest, const msg_entity) {
	enum {
		arg_name = 1,
		arg_ammo1,
		arg_ammo1_max,
		arg_ammo2,
		arg_ammo2_max,
		arg_slot,
		arg_position,
		arg_id,
		arg_flags,
	};

	if (msg_dest != MSG_INIT || WeaponIdType:get_msg_arg_int(arg_id) != WEAPON_NEW_ID) {
		return PLUGIN_CONTINUE;
	}

	set_msg_arg_string(arg_name,WEAPON_NEW_NAME);
	set_msg_arg_int(arg_ammo1, ARG_BYTE, AMMO_ID);
	set_msg_arg_int(arg_ammo1_max, ARG_BYTE, 1);
	set_msg_arg_int(arg_ammo2, ARG_BYTE, -1);
	set_msg_arg_int(arg_ammo2_max, ARG_BYTE, -1);
	set_msg_arg_int(arg_slot, ARG_BYTE, _:Cvar(SlotId) - 1);
	set_msg_arg_int(arg_position, ARG_BYTE, 4);
	set_msg_arg_int(arg_flags, ARG_BYTE, ITEM_FLAG_LIMITINWORLD | ITEM_FLAG_EXHAUSTIBLE);

	return PLUGIN_CONTINUE;
}
#endif

public srvcmd_GiveHealthnade() {
	enum { player = 1, count };

	new szArg[32], pPlayer; read_argv(player, szArg, charsmax(szArg));

	if(szArg[0] == '#') {
		pPlayer = find_player("k", str_to_num(szArg[1]));
	}
	else {
		pPlayer = str_to_num(szArg);
	}

	new iCount = max(1, read_argv_int(count));
	giveNade(pPlayer, iCount, iCount);
	return PLUGIN_HANDLED;
}

public CBasePlayer_OnSpawnEquip_Post(const id) {
	remove_task(id);

	if (!Cvar(Give) || is_user_bot(id) || !UserHasFlagsS(id, Cvar(Give_AccessFlags))) {
		return;
	}

	if(rg_get_current_round() < Cvar(Give_MinRound)) {
		return;
	}

	new iRet;
	ExecuteForward(g_fwdCanEquip, iRet, id);

	if(iRet) {
		return;
	}

	if(!Cvar(EquipDelay)) {
		giveNade(id, Cvar(Give), Cvar(Give));
		return;
	}

	set_task(Cvar(EquipDelay), "task_DelayedEquip", id);
}

public task_DelayedEquip(const id) {
	new count = max(1, Cvar(Give));
	giveNade(id, count, count);
}

public CBasePlayer_Killed_Pre(const id) {
	if (Cvar(NadeDrop) == NadeDrop_Off) {
		return;
	}

	if (Cvar(NadeDrop) == NadeDrop_ByCvar) {
		switch (g_iCvarNadeDrops) {
			case 0:
				return;
			case 1: {
				new iItem = get_member(id, m_rgpPlayerItems, ITEM_SLOT);

				if (is_nullent(iItem) || !FClassnameIs(iItem, ITEM_CLASSNAME)) {
					return;
				}
			}
		}
	}

	if (!get_member(id, m_rgAmmo, AMMO_ID)) {
		return;
	}

	new eEnt, Float:fOrigin[3];

	get_entvar(id, var_origin, fOrigin);

	new Float:fVelocity[3];
	get_entvar(id, var_velocity, fVelocity);
	xs_vec_mul_scalar(fVelocity, 0.75, fVelocity);

	eEnt = rg_create_entity("info_target");

	if(is_nullent(eEnt)) {
		return;
	}

	set_entvar(eEnt, var_classname, "healthnade_drop");

	engfunc(EngFunc_SetOrigin, eEnt, fOrigin);
	set_entvar(eEnt, var_movetype, MOVETYPE_TOSS);
	set_entvar(eEnt, var_solid, SOLID_TRIGGER);
	engfunc(EngFunc_SetModel, eEnt, Cvar(WorldModel));
	engfunc(EngFunc_SetSize, eEnt, Float:{-6.0, -6.0, -1.0}, Float:{6.0, 6.0, 1.0});

	set_entvar(eEnt, var_velocity, fVelocity);
	SetThink(eEnt, "think_healthnade_drop");
	set_entvar(eEnt, var_nextthink, get_gametime() + get_cvar_float("mp_item_staytime"));

	set_entvar(eEnt, var_iuser4, get_member(id, m_rgAmmo, AMMO_ID));
	SetTouch(eEnt, "touch_healthnade_drop");
}

public think_healthnade_drop(const eEnt) {
	if(is_entity(eEnt)) {
		set_entvar(eEnt, var_flags, FL_KILLME);
	}
}

public touch_healthnade_drop(const eEnt, const id) {
	if (is_nullent(eEnt) || !is_user_alive(id)) {
		return;
	}

	new iWpAmmo = get_entvar(eEnt, var_iuser4);
	new iToAdd = iWpAmmo;
	new iPlayerAmmo = get_member(id, m_rgAmmo, AMMO_ID);

	if(rg_get_player_item(id, ITEM_CLASSNAME, ITEM_SLOT)) {
		if(iPlayerAmmo >= iWpAmmo) {
			return;
		}

		iToAdd = iWpAmmo - iPlayerAmmo;
	}

	if(iPlayerAmmo) {
		emit_sound(id, CHAN_ITEM, "items/gunpickup2.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
	}

	set_entvar(eEnt, var_nextthink, -1.0);
	set_entvar(eEnt, var_flags, FL_KILLME);

	giveNade(id, iToAdd, iWpAmmo);
}

public CmdSelect(const id) {
	if (!is_user_alive(id)) {
		return PLUGIN_HANDLED;
	}

	new item = rg_get_player_item(id, ITEM_CLASSNAME, ITEM_SLOT);
	if (item != 0 && get_member(id, m_pActiveItem) != item) {
		rg_switch_weapon(id, item);
	}
	return PLUGIN_HANDLED;
}

public CSGameRules_CleanUpMap_Post() {
	new ent = rg_find_ent_by_class(NULLENT, GRENADE_CLASSNAME, false);
	while (ent > 0) {
		destroyNade(ent);
		ent = rg_find_ent_by_class(ent, GRENADE_CLASSNAME, false);
	}

	ent = rg_find_ent_by_class(NULLENT, "healthnade_drop", false);
	while (ent > 0) {
		destroyNade(ent);
		ent = rg_find_ent_by_class(ent, "healthnade_drop", false);
	}
}

public CBasePlayer_GiveAmmo_Pre(const id, const amount, const name[]) {
	if (strcmp(name, AMMO_NAME) != 0) {
		return HC_CONTINUE;
	}

	giveAmmo(id, amount, AMMO_ID, 1);
	SetHookChainReturn(ATYPE_INTEGER, AMMO_ID);
	return HC_SUPERCEDE;
}


public CBasePlayerWeapon_DefaultDeploy_Pre(const item, const szViewModel[], const szWeaponModel[], const iAnim, const szAnimExt[], const skiplocal) {
	new UserId = get_member(item, m_pPlayer);

	if (FClassnameIs(item, ITEM_CLASSNAME)) {
		SetHookChainArg(2, ATYPE_STRING, Cvar(ViewModel));
		SetHookChainArg(3, ATYPE_STRING, Cvar(PlayerModel));

		if (Cvar(Msg_UsageHint)) {
			client_print(UserId, print_center, "%L", UserId, "HEALTHNADE_USAGE_HINT");
		}
	}

	new WeaponIdType:wid = WeaponIdType:rg_get_iteminfo(item, ItemInfo_iId);
	if (wid != g_iWeaponID && wid != WEAPON_FAKE_ID) {
		return HC_CONTINUE;
	}

	new lastItem = get_member(UserId, m_pLastItem);
	if (is_nullent(lastItem) || item == lastItem) {
		return HC_CONTINUE;
	}

	if (WeaponIdType:rg_get_iteminfo(lastItem, ItemInfo_iId) == g_iWeaponID) {
		SetHookChainArg(6, ATYPE_INTEGER, 0);
	}

	return HC_CONTINUE;
}

public Item_Deploy_Post(const item) {
	if (WeaponIdType:rg_get_iteminfo(item, ItemInfo_iId) == WEAPON_FAKE_ID) {
		rg_set_iteminfo(item, ItemInfo_iId, g_iWeaponID);
	}

	new other = get_member(get_member(item, m_pPlayer), m_rgpPlayerItems, ITEM_SLOT);
	while (!is_nullent(other)) {
		if (item != other && WeaponIdType:rg_get_iteminfo(other, ItemInfo_iId) == g_iWeaponID) {
			rg_set_iteminfo(other, ItemInfo_iId, WEAPON_FAKE_ID);
		}
		other = get_member(other, m_pNext);
	}
}

public Item_Holster_Post(const item) {
	new other = get_member(get_member(item, m_pPlayer), m_rgpPlayerItems, ITEM_SLOT);
	while (!is_nullent(other)) {
		if (item != other && WeaponIdType:rg_get_iteminfo(other, ItemInfo_iId) == WEAPON_FAKE_ID) {
			rg_set_iteminfo(other, ItemInfo_iId, g_iWeaponID);
		}
		other = get_member(other, m_pNext);
	}
}

enum {
	HG_ANIMATION_IDLE = 0,
	HG_ANIMATION_PULLPIN,
	HG_ANIMATION_THROW,
	HG_ANIMATION_DEPLOY,
	HG_ANIMATION_DRINK
};

public CBasePlayerWeapon_SecondaryAttack_Post(weapon) {
	if(!is_entity(weapon) || !FClassnameIs(weapon, ITEM_CLASSNAME)) {
		return;
	}

	set_member(weapon, m_Weapon_flNextSecondaryAttack, 0.3);

	if(get_member(weapon, m_flStartThrow) > 0.0) {
		return;
	}

	new pPlayer = get_member(weapon, m_pPlayer);

	new iBpAmmo = get_member(pPlayer, m_rgAmmo, AMMO_ID);

	if(!iBpAmmo) {
		return;
	}

	new Float:fDrinkHealingAmount, iRet;

	//g_PropString[0] = EOS;
	ExecuteForward(g_fwdGetProp, iRet, pPlayer, HnProp_DrinkHealingAmount, fDrinkHealingAmount, PrepareArray(g_PropString, sizeof(g_PropString), .copyback = 1));

	if((!iRet || fDrinkHealingAmount < 1.0) && !UserHasFlagsS(pPlayer, Cvar(Drink_AccessFlags))) {
		client_print(pPlayer, print_center, "%L", pPlayer, "HEALTHNADE_NO_ACCESS");
		return;
	}

	if(Float:get_entvar(pPlayer, var_health) >= Float:get_entvar(pPlayer, var_max_health)) {
		if (Cvar(Msg_FullHp)) {
			client_print(pPlayer, print_center, "%L", pPlayer, "HEALTHNADE_FULL_HP");
		}

		return;
	}

	const Float:fAnimTime = 3.15; // 63 frames / 20 fps
	set_member(weapon, m_Weapon_flTimeWeaponIdle, fAnimTime);
	set_member(weapon, m_Weapon_flNextPrimaryAttack, fAnimTime);
	set_member(weapon, m_Weapon_flNextSecondaryAttack, fAnimTime);
	SendWeaponAnimation(pPlayer, HG_ANIMATION_DRINK);
}

// PostFrame() а не WeaponIdle() т.к. при прожатых IN_ATTACK|IN_ATTACK2|IN_RELOAD WeaponIdle() не вызывается
// т.е. зажатие любой из этих кнопок приведёт к неработоспособности логики
public CBasePlayerWeapon_ItemPostFrame_Pre(weapon) {
	if(/*!is_entity(weapon) || */!FClassnameIs(weapon, ITEM_CLASSNAME)) {
		return;
	}

	if(get_member(weapon, m_Weapon_flTimeWeaponIdle) > 0.0) {
		return;
	}

	new pPlayer = get_member(weapon, m_pPlayer);

	if(get_entvar(pPlayer, var_weaponanim) != HG_ANIMATION_DRINK) {
		return;
	}

	// Нам надо обеспечить вызов WeaponIdle()
	// https://github.com/s1lentq/ReGameDLL_CS/blob/67cc153f5d0abab1e42b32a83ef4a470c8781a5c/regamedll/dlls/weapons.cpp#L1007
	// https://github.com/s1lentq/ReGameDLL_CS/blob/67cc153f5d0abab1e42b32a83ef4a470c8781a5c/regamedll/dlls/weapons.cpp#L1019
	// https://github.com/s1lentq/ReGameDLL_CS/blob/67cc153f5d0abab1e42b32a83ef4a470c8781a5c/regamedll/dlls/weapons.cpp#L1092
	set_entvar(pPlayer, var_button, get_entvar(pPlayer, var_button) & ~(IN_ATTACK|IN_ATTACK2|IN_RELOAD));

	new iBpAmmo = get_member(pPlayer, m_rgAmmo, AMMO_ID);

	if(!iBpAmmo) {
		return;
	}

	set_member(pPlayer, m_rgAmmo, iBpAmmo - 1, AMMO_ID);

	// RetireWeapon() средствами regamedll если бпаммо нет, либо отправка анимации деплоя
	// https://github.com/s1lentq/ReGameDLL_CS/blob/b979b5e84f36dc0eb870f97da670b700756217f1/regamedll/dlls/wpn_shared/wpn_smokegrenade.cpp#L225
	set_member(weapon, m_flReleaseThrow, 0.1);

	new Float:fDrinkHealingAmount, iRet;

	//g_PropString[0] = EOS;
	ExecuteForward(g_fwdGetProp, iRet, pPlayer, HnProp_DrinkHealingAmount, fDrinkHealingAmount, PrepareArray(g_PropString, sizeof(g_PropString), .copyback = 1));

	if(!iRet || fDrinkHealingAmount < 0.0) {
		fDrinkHealingAmount = get_entvar(weapon, var_HealthNade_DrinkHealingAmount);
	}

	ExecuteHamB(Ham_TakeHealth, pPlayer, fDrinkHealingAmount, DMG_GENERIC);
	UTIL_ScreenFade(pPlayer);
}

stock SendWeaponAnimation(const id, const iAnimation) {
	set_entvar(id, var_weaponanim, iAnimation);

	message_begin(MSG_ONE_UNRELIABLE, SVC_WEAPONANIM, .player = id);
	write_byte(iAnimation);
	write_byte(0);
	message_end();
}

public CBasePlayer_ThrowGrenade_Pre(const id, const item, const Float:vecSrc[3], const Float:vecThrow[3], const Float:time, const const usEvent) {
	if (!FClassnameIs(item, ITEM_CLASSNAME)) {
		return HC_CONTINUE;
	}

	new grenade = throwNade(id, item, vecSrc, vecThrow, time);
	SetHookChainReturn(ATYPE_INTEGER, grenade);
	return HC_SUPERCEDE;
}

public CBasePlayer_AddPlayerItem_Pre(const id, const item) {
	if(!Cvar(ReplaceSmokegren) || is_nullent(item) || get_member(item, m_iId) != g_iWeaponID || !is_user_alive(id)) {
		return HC_CONTINUE;
	}

	set_entvar(item, var_flags, FL_KILLME);

	giveNade(id);

	SetHookChainReturn(ATYPE_INTEGER, 0);
	return HC_SUPERCEDE;
}

public CBasePlayer_HasRestrictItem_Pre(id, ItemID:item, ItemRestType:rest_type) {
	if(!Cvar(ReplaceSmokegren)) {
		return HC_CONTINUE;
	}

	if(item == ItemID:g_iWeaponID && rg_get_player_item(id, ITEM_CLASSNAME, ITEM_SLOT)) {
		if(rest_type == ITEM_TYPE_BUYING) {
			client_print(id, print_center, "#Cstrike_TitlesTXT_Cannot_Carry_Anymore");
		}

		SetHookChainReturn(ATYPE_BOOL, true);
		return HC_SUPERCEDE;
	}

	return HC_CONTINUE;
}

public GrenadeTouch(const grenade, const other) {
	if (!is_nullent(grenade)) {
		explodeNade(grenade);
	}
}

public GrenadeThink(const grenade) {
	if (!is_nullent(grenade)) {
		explodeNade(grenade);
	}
}

giveNade(const id, count = 1, maximum = 1) {
	if(!is_user_alive(id) || is_user_bot(id)) {
		return NULLENT;
	}

	new item = rg_get_player_item(id, ITEM_CLASSNAME, ITEM_SLOT);
	if (item != 0) {
		giveAmmo(id, count, AMMO_ID, maximum);
		return item;
	}

	item = rg_create_entity(Cvar(BaseWeapon), false);
	if (is_nullent(item)) {
		return NULLENT;
	}

	new iWeaponInfiniteIds = get_member(id, m_iWeaponInfiniteIds);
	
	if (get_cvar_num("mp_infinite_ammo") == 2) {
		set_member(id, m_iWeaponInfiniteIds, iWeaponInfiniteIds > 0 ? (iWeaponInfiniteIds & ~(1<<_:WEAPON_NEW_ID)) : CSW_ALL_GUNS & ~(1<<_:WEAPON_NEW_ID));
	}

	new Float:origin[3];
	get_entvar(id, var_origin, origin);
	set_entvar(item, var_origin, origin);
	set_entvar(item, var_spawnflags, get_entvar(item, var_spawnflags) | SF_NORESPAWN);

	set_member(item, m_Weapon_iPrimaryAmmoType, AMMO_ID);
	set_member(item, m_Weapon_iSecondaryAmmoType, -1);

	set_entvar(item, var_classname, ITEM_CLASSNAME);

	set_entvar(item, var_HealthNade_Radius, Cvar(ExplodeRadius));

	if(UserHasFlagsS(id, Cvar(Override_AccessFlags))){
		set_entvar(item, var_HealthNade_ThrowHealingAmount, Cvar(ThrowHealingAmountWithFlags));
		set_entvar(item, var_HealthNade_DrinkHealingAmount,  Cvar(DrinkHealingAmountWithFlags));
	}else{
		set_entvar(item, var_HealthNade_ThrowHealingAmount, Cvar(ThrowHealingAmount));
		set_entvar(item, var_HealthNade_DrinkHealingAmount,  Cvar(DrinkHealingAmount));
	}

	dllfunc(DLLFunc_Spawn, item);

	set_member(item, m_iId, WEAPON_NEW_ID);
	
	rg_set_iteminfo(item, ItemInfo_iMaxClip, -1);

	rg_set_iteminfo(item, ItemInfo_pszName, WEAPON_NEW_NAME);
	rg_set_iteminfo(item, ItemInfo_pszAmmo1, AMMO_NAME);
	rg_set_iteminfo(item, ItemInfo_iMaxAmmo1, 1);
	rg_set_iteminfo(item, ItemInfo_iId, WEAPON_FAKE_ID);
	rg_set_iteminfo(item, ItemInfo_iPosition, 4);
	rg_set_iteminfo(item, ItemInfo_iWeight, 1);

	dllfunc(DLLFunc_Touch, item, id);

	if (get_entvar(item, var_owner) != id) {
		set_entvar(item, var_flags, FL_KILLME);
		return NULLENT;
	}

	set_member(id, m_rgAmmo, count, AMMO_ID);

	return item;
}

giveAmmo(const id, const amount, const ammo, const max) {
	if (get_entvar(id, var_flags) & FL_SPECTATOR) {
		return;
	}

	new count = get_member(id, m_rgAmmo, ammo);
	new add = min(amount, max - count);
	if (add < 1) {
		return;
	}

	set_member(id, m_rgAmmo, count + add, ammo);

	emessage_begin(MSG_ONE, MsgIdAmmoPickup, .player = id);
	ewrite_byte(ammo);
	ewrite_byte(add);
	emessage_end();
}

throwNade(const id, const item, const Float:vecSrc[3], const Float:vecThrow[3], const Float:time) {
	new grenade = rg_create_entity("info_target", false);
	if (is_nullent(grenade)) {
		return 0;
	}

	set_entvar(grenade, var_classname, GRENADE_CLASSNAME);

	set_entvar(grenade, var_movetype, MOVETYPE_BOUNCE);
	set_entvar(grenade, var_solid, SOLID_BBOX);

	engfunc(EngFunc_SetOrigin, grenade, vecSrc);

	new Float:angles[3];
	get_entvar(id, var_angles, angles);
	set_entvar(grenade, var_angles, angles);

	set_entvar(grenade, var_owner, id);

	if (time < 0.1) {
		set_entvar(grenade, var_nextthink, get_gametime());
		set_entvar(grenade, var_velocity, Float:{0.0, 0.0, 0.0});
	} else {
		set_entvar(grenade, var_nextthink, get_gametime() + time);
		set_entvar(grenade, var_velocity, vecThrow);
	}

	set_entvar(grenade, var_sequence, random_num(3, 6));
	set_entvar(grenade, var_framerate, 1.0);
	set_entvar(grenade, var_gravity, 0.5);
	set_entvar(grenade, var_friction, 0.8);
	engfunc(EngFunc_SetModel, grenade, Cvar(WorldModel));

	copy_entvar(item, grenade, var_HealthNade_Radius);
	copy_entvar(item, grenade, var_HealthNade_ThrowHealingAmount);

	SetTouch(grenade, "GrenadeTouch");
	SetThink(grenade, "GrenadeThink");
	return grenade;
}

explodeNade(const grenade) {
	new Float:origin[3];
	get_entvar(grenade, var_origin, origin);

	new id = get_entvar(grenade, var_owner);

	new Float:fRadius, iRet;

	//g_PropString[0] = EOS;
	ExecuteForward(g_fwdGetProp, iRet, id, HnProp_ExplodeRadius, fRadius, PrepareArray(g_PropString, sizeof(g_PropString), .copyback = 1));

	if(!iRet || fRadius < 0.0) {
		fRadius = get_entvar(grenade, var_HealthNade_Radius);
	}

	UTIL_BeamCylinder(origin, SpriteCylinder, 1, 5, 30, 1, {10, 255, 40}, 255, 5, fRadius);
	UTIL_CreateExplosion(origin, 65.0, SpriteExplode, 30, 20, (TE_EXPLFLAG_NOSOUND | TE_EXPLFLAG_NOPARTICLES));
	UTIL_SpriteTrail(origin, SpriteShape);

	rh_emit_sound2(grenade, 0, CHAN_WEAPON, SOUND_EXPLODE, VOL_NORM, ATTN_NORM, 0, PITCH_NORM);

	new team = get_member(id, m_iTeam);

	new Float:fThrowHealingAmount;

	iRet = 0;
	//g_PropString[0] = EOS;
	ExecuteForward(g_fwdGetProp, iRet, id, HnProp_ThrowHealingAmount, fThrowHealingAmount, PrepareArray(g_PropString, sizeof(g_PropString), .copyback = 1));

	if(!iRet || fThrowHealingAmount < 0.0) {
		fThrowHealingAmount = get_entvar(grenade, var_HealthNade_ThrowHealingAmount);
	}

	for (new player = 1, Float:playerOrigin[3]; player <= MaxClients; player++) {
		if (!is_user_alive(player) || get_member(player, m_iTeam) != team) {
			continue;
		}

		get_entvar(player, var_origin, playerOrigin);

		if (get_distance_f(origin, playerOrigin) < fRadius && ExecuteHamB(Ham_TakeHealth, player, fThrowHealingAmount, DMG_GENERIC)) {
			UTIL_ScreenFade(player);
		}
	}

	destroyNade(grenade);
}

destroyNade(const grenade) {
	SetTouch(grenade, "");
	SetThink(grenade, "");
	set_entvar(grenade, var_flags, FL_KILLME);
}

InitCvars() {
	bind_pcvar_float(create_cvar(
		"HealthNade_ExplodeRadius", "300.0", FCVAR_NONE,
		LangS("HEALTHNADE_CVAR_EXPLODE_RADIUS"),
		true, 1.0
	), Cvar(ExplodeRadius));

	bind_pcvar_float(create_cvar(
		"HealthNade_ThrowHealingAmount", "20.0", FCVAR_NONE,
		LangS("HEALTHNADE_CVAR_THROW_HEALING_AMOUNT")
	), Cvar(ThrowHealingAmount));

	bind_pcvar_float(create_cvar(
		"HealthNade_ThrowHealingAmount_With_Flags", "40.0", FCVAR_NONE,
		LangS("HEALTHNADE_CVAR_THROW_HEALING_AMOUNT_WITH_FLAGS")
	), Cvar(ThrowHealingAmountWithFlags));

	bind_pcvar_float(create_cvar(
		"HealthNade_DrinkHealingAmount", "35.0", FCVAR_NONE,
		LangS("HEALTHNADE_CVAR_DRINK_HEALING_AMOUNT")
	), Cvar(DrinkHealingAmount));

	bind_pcvar_float(create_cvar(
		"HealthNade_DrinkHealingAmount_With_Flags", "60.0", FCVAR_NONE,
		LangS("HEALTHNADE_CVAR_DRINK_HEALING_AMOUNT_WITH_FLAGS")
	), Cvar(DrinkHealingAmountWithFlags));

	bind_pcvar_num(create_cvar(
		"HealthNade_Give", "1", FCVAR_NONE,
		LangS("HEALTHNADE_CVAR_GIVE")
	), Cvar(Give));

	bind_pcvar_string(create_cvar(
		"HealthNade_Give_AccessFlags", "t", FCVAR_NONE,
		LangS("HEALTHNADE_CVAR_GIVE_ACCESS_FLAGS")
	), Cvar(Give_AccessFlags), charsmax(Cvar(Give_AccessFlags)));

	bind_pcvar_string(create_cvar(
		"HealthNade_Override_AccessFlags", "t", FCVAR_NONE,
		LangS("HEALTHNADE_CVAR_THROWHEALING_ACCESS_FLAGS")
	), Cvar(Override_AccessFlags), charsmax(Cvar(Override_AccessFlags)));

	bind_pcvar_string(create_cvar(
		"HealthNade_Drink_AccessFlags", "t", FCVAR_NONE,
		LangS("HEALTHNADE_CVAR_DRINK_ACCESS_FLAGS")
	), Cvar(Drink_AccessFlags), charsmax(Cvar(Drink_AccessFlags)));

	bind_pcvar_num(create_cvar(
		"HealthNade_Give_MinRound", "1", FCVAR_NONE,
		LangS("HEALTHNADE_CVAR_GIVE_MIN_ROUND"),
		true, 1.0
	), Cvar(Give_MinRound));

	bind_pcvar_float(create_cvar(
		"HealthNade_EquipDelay", "0.0", FCVAR_NONE,
		LangS("HEALTHNADE_CVAR_EQUIP_DELAY"),
		true, 0.0
	), Cvar(EquipDelay));

	bind_pcvar_num(create_cvar(
		"HealthNade_ReplaceSmokegren", "0.0", FCVAR_NONE,
		LangS("HEALTHNADE_CVAR_REPLACE_SG"),
		true, 0.0, true, 1.0
	), Cvar(ReplaceSmokegren));

	bind_pcvar_num(create_cvar(
		"HealthNade_Msg_UsageHint", "1", FCVAR_NONE,
		LangS("HEALTHNADE_CVAR_MSG_USAGE_HINT"),
		true, 0.0, true, 1.0
	), Cvar(Msg_UsageHint));

	bind_pcvar_num(create_cvar(
		"HealthNade_Msg_FullHp", "1", FCVAR_NONE,
		LangS("HEALTHNADE_CVAR_MSG_FULL_HP"),
		true, 0.0, true, 1.0
	), Cvar(Msg_FullHp));

	bind_pcvar_num(create_cvar(
		"HealthNade_NadeDrop", "2", FCVAR_NONE,
		LangS("HEALTHNADE_CVAR_NADE_DROP"),
		true, 0.0, true, 2.0
	), Cvar(NadeDrop));

	bind_pcvar_num(create_cvar(
		"HealthNade_SlotId", "4", FCVAR_NONE,
		LangS("HEALTHNADE_CVAR_SLOT_ID"),
		true, 1.0, true, 5.0
	), Cvar(SlotId));
	
	bind_pcvar_string(create_cvar(
		"HealthNade_ViewModel", "models/reapi_healthnade/v_drink9.mdl", FCVAR_NONE,
		"1st person model (v_)"
	), Cvar(ViewModel), charsmax(Cvar(ViewModel)));
	
	bind_pcvar_string(create_cvar(
		"HealthNade_PlayerModel", "models/reapi_healthnade/p_healthnade.mdl", FCVAR_NONE,
		"3rd person model (p_)"
	), Cvar(PlayerModel), charsmax(Cvar(PlayerModel)));
	
	bind_pcvar_string(create_cvar(
		"HealthNade_WorldModel", "models/reapi_healthnade/w_healthnade.mdl", FCVAR_NONE,
		"World model (w_)"
	), Cvar(WorldModel), charsmax(Cvar(WorldModel)));
	
	bind_pcvar_string(create_cvar(
		"HealthNade_BaseWeapon", "weapon_smokegrenade", FCVAR_NONE,
		"Base weapon"
	), Cvar(BaseWeapon), charsmax(Cvar(BaseWeapon)));

	bind_pcvar_num(get_cvar_pointer("mp_nadedrops"), g_iCvarNadeDrops);
}

stock rg_get_player_item(const id, const classname[], const InventorySlotType:slot = NONE_SLOT) {
	new item = get_member(id, m_rgpPlayerItems, slot);
	while (!is_nullent(item)) {
		if (FClassnameIs(item, classname)) {
			return item;
		}
		item = get_member(item, m_pNext);
	}

	return 0;
}

stock bool:IsBlind(const player) {
	return bool:(Float:get_member(player, m_blindUntilTime) > get_gametime());
}

stock UTIL_WeapoList(
	const type,
	const player,
	const name[],
	const ammo1,
	const maxAmmo1,
	const ammo2,
	const maxammo2,
	const InventorySlotType:slot,
	const position,
	const WeaponIdType:id,
	const flags
) {
	message_begin(type, MsgIdWeaponList, .player = player);
	write_string(name);
	write_byte(ammo1);
	write_byte(maxAmmo1);
	write_byte(ammo2);
	write_byte(maxammo2);
	write_byte(_:slot - 1);
	write_byte(position);
	write_byte(_:id);
	write_byte(flags);
	message_end();
}

stock UTIL_StatusIcon(const player, const type, const sprite[], const color[3]) {
	message_begin(MSG_ONE, MsgIdStatusIcon, .player = player);
	write_byte(type); // 0 - hide 1 - show 2 - flash
	write_string(sprite);
	write_byte(color[0]);
	write_byte(color[1]);
	write_byte(color[2]);
	message_end();
}

stock UTIL_ScreenFade(const player, const Float:fxTime = 1.0, const Float:holdTime = 0.3, const color[3] = {170, 255, 0}, const alpha = 80) {
	if (IsBlind(player)) {
		return;
	}

	const FFADE_IN = 0x0000;

	message_begin(MSG_ONE_UNRELIABLE, MsgIdScreenFade, .player = player);
	write_short(FixedUnsigned16(fxTime));
	write_short(FixedUnsigned16(holdTime));
	write_short(FFADE_IN);
	write_byte(color[0]);
	write_byte(color[1]);
	write_byte(color[2]);
	write_byte(alpha);
	message_end();
}

stock UTIL_BeamCylinder(const Float:origin[3], const sprite, const framerate, const life, const width, const amplitude, const color[3], const bright, const speed, const Float:size) {
	message_begin_f(MSG_PVS, SVC_TEMPENTITY, origin, 0);
	write_byte(TE_BEAMCYLINDER);
	write_coord_f(origin[0]);
	write_coord_f(origin[1]);
	write_coord_f(origin[2]);
	write_coord_f(origin[0]);
	write_coord_f(origin[1]);
	write_coord_f(origin[2] + size);
	write_short(sprite);
	write_byte(0);
	write_byte(framerate);
	write_byte(life);
	write_byte(width);
	write_byte(amplitude);
	write_byte(color[0]);
	write_byte(color[1]);
	write_byte(color[2]);
	write_byte(bright);
	write_byte(speed);
	message_end();
}

stock UTIL_CreateExplosion(const Float:origin[3], const Float:vecUp, const modelIndex, const scale, const frameRate, const flags) {
	message_begin_f(MSG_PVS, SVC_TEMPENTITY, origin, 0);
	write_byte(TE_EXPLOSION);
	write_coord_f(origin[0]);
	write_coord_f(origin[1]);
	write_coord_f(origin[2] + vecUp);
	write_short(modelIndex);
	write_byte(scale);
	write_byte(frameRate);
	write_byte(flags);
	message_end();
}

stock UTIL_SpriteTrail(Float:origin[3], const sprite, const cound = 20, const life = 20, const scale = 4, const noise = 20, const speed = 10) {
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY); // MSG_PVS
	write_byte(TE_SPRITETRAIL);
	write_coord_f(origin[0]);
	write_coord_f(origin[1]);
	write_coord_f(origin[2] + 20.0);
	write_coord_f(origin[0]);
	write_coord_f(origin[1]);
	write_coord_f(origin[2] + 80.0);
	write_short(sprite);
	write_byte(cound);
	write_byte(life);
	write_byte(scale);
	write_byte(noise);
	write_byte(speed);
	message_end();
}

stock FixedUnsigned16(Float:value, scale = (1 << 12)) {
	return clamp(floatround(value * scale), 0, 0xFFFF);
}

bool:UserHasFlagsS(const UserId, const sFlags[], const bool:bStrict = false) {
	if (!sFlags[0]) {
		return true;
	}

	new iFlags = read_flags(sFlags);
	new iUserFlags = get_user_flags(UserId);

	return bStrict
		? (iUserFlags & iFlags) == iFlags
		: (iUserFlags & iFlags) > 0;
}

public plugin_natives() {
	register_native("HealthNade_GiveNade", "_HealthNade_GiveNade");
	register_native("HealthNade_HasNade", "_HealthNade_HasNade");
}

public _HealthNade_GiveNade() {
	enum { player = 1, count, maximum };
	return giveNade(get_param(player), get_param(count), get_param(maximum));
}

public _HealthNade_HasNade() {
	enum { player = 1 };

	new pPlayer = get_param(player);

	if(!is_user_alive(pPlayer)) {
		return false;
	}

	return bool:(get_member(pPlayer, m_rgAmmo, AMMO_ID));
}
