/*
	Форк лечебной гранаты на основе Healthnade 0.0.2 от F@nt0M: https://dev-cs.ru/resources/992/

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
*/

new const PLUGIN_VERSION[] = "0.0.6f";

#pragma semicolon 1

#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>
#include <reapi>
#include <healthnade>

// Минимальный раунд для выдачи (сбрасывается при рестарте)
const MIN_ROUND = 1;

// Радиус лечения
const Float:HEAL_RADIUS = 300.0;

// Объём лечения при броске
const Float:HEAL_AMOUNT_THROW = 20.0;

// Объём лечения при выпивании
const Float:HEAL_AMOUNT_DRINK = 35.0;

// Информирование по центру о функциях (закомментировать для отключения)
new const USAGE_MSG[] = "ЛКМ - Бросить | ПКМ - Выпить";

// Информирование по центру о невозможности выпить зелье (закомментировать для отключения)
new const FULL_HP_MSG[] = "Вы полностью здоровы!";

// Флаг автовыдачи при спавне (закомментировать для выдачи всем)
const ACCESS_FLAG = ADMIN_LEVEL_H;

const WeaponIdType:WEAPON_ID = WEAPON_SMOKEGRENADE;
const WeaponIdType:WEAPON_NEW_ID = WEAPON_GLOCK;
const WeaponIdType:WEAPON_FAKE_ID = WeaponIdType:75;
new const WEAPON_NAME[] = "weapon_smokegrenade";
new const AMMO_NAME[] = "HealthNade";
new const WEAPON_NEW_NAME[] = "reapi_healthnade/weapon_healthnade";
new const ITEM_CLASSNAME[] = "weapon_healthnade";
new const GRENADE_CLASSNAME[] = "healthnade";
const AMMO_ID = 16;

new const VIEWMODEL[] = "models/reapi_healthnade/v_drink9.mdl";
new const WEAPONMODEL[] = "models/reapi_healthnade/p_healthnade.mdl";
new const WORLDMODEL[] = "models/reapi_healthnade/w_healthnade.mdl";
new const SOUND_PULLPIN[] = "weapons/holywater_pinpul.wav";
new const SOUND_DEPLOY[] = "weapons/holywater_deploy.wav";
new const SOUND_DRINK[] = "weapons/holywater_drink.wav";
new const SOUND_EXPLODE[] = "weapons/reapi_healthnade/heal.wav";

#define rg_get_current_round() (get_member_game(m_iTotalRoundsPlayed) + 1)

// copy_entvar(const iEntFrom, const iEntTo, const EntVar:iVar)
#define copy_entvar(%1,%2,%3) set_entvar(%2, %3, get_entvar(%1, %3))

new SpriteCylinder, SpriteExplode, SpriteShape;
new MsgIdWeaponList, MsgIdAmmoPickup, MsgIdStatusIcon, MsgIdScreenFade;
#if WEAPON_NEW_ID != WEAPON_GLOCK
new FwdRegUserMsg, MsgHookWeaponList;
#endif

public plugin_precache() {
	register_plugin("[ReAPI] Healthnade", PLUGIN_VERSION, "F@nt0M + mx?!");

	precache_generic("sprites/reapi_healthnade/weapon_healthnade.txt");
	precache_generic("sprites/reapi_healthnade/640hud128.spr");

	precache_model(VIEWMODEL);
	precache_model(WEAPONMODEL);
	precache_model(WORLDMODEL);

	precache_sound(SOUND_PULLPIN);
	precache_sound(SOUND_DEPLOY);
	precache_sound(SOUND_DRINK);

	SpriteExplode = precache_model("sprites/reapi_healthnade/heal_explode.spr");
	SpriteShape = precache_model("sprites/reapi_healthnade/heal_shape.spr");
	SpriteCylinder = precache_model("sprites/shockwave.spr");

	precache_sound("weapons/reapi_healthnade/heal.wav");

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
	register_clcmd(WEAPON_NEW_NAME, "CmdSelect");

	RegisterHookChain(RG_CBasePlayer_OnSpawnEquip, "CBasePlayer_OnSpawnEquip_Post", true);

	RegisterHookChain(RG_CSGameRules_CleanUpMap, "CSGameRules_CleanUpMap_Post", true);
	RegisterHookChain(RG_CBasePlayer_GiveAmmo, "CBasePlayer_GiveAmmo_Pre", false);
	RegisterHookChain(RG_CBasePlayerWeapon_DefaultDeploy, "CBasePlayerWeapon_DefaultDeploy_Pre", false);

	RegisterHam(Ham_Item_Deploy, WEAPON_NAME, "Item_Deploy_Post", true);
	RegisterHam(Ham_Item_Holster, WEAPON_NAME, "Item_Holster_Post", true);

	RegisterHam(Ham_Weapon_SecondaryAttack, WEAPON_NAME, "CBasePlayerWeapon_SecondaryAttack_Post", true);
	RegisterHam(Ham_Item_PostFrame, WEAPON_NAME, "CBasePlayerWeapon_ItemPostFrame_Pre");

	RegisterHookChain(RG_CBasePlayer_ThrowGrenade, "CBasePlayer_ThrowGrenade_Pre", false);

	MsgIdAmmoPickup = get_user_msgid("AmmoPickup");
	MsgIdStatusIcon = get_user_msgid("StatusIcon");
	MsgIdScreenFade = get_user_msgid("ScreenFade");

#if WEAPON_NEW_ID == WEAPON_GLOCK
	MsgIdWeaponList = get_user_msgid("WeaponList");
	UTIL_WeapoList(
		MSG_INIT, 0,
		WEAPON_NEW_NAME,
		AMMO_ID, 1,
		-1, -1, GRENADE_SLOT, 4, WEAPON_NEW_ID,
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
	set_msg_arg_int(arg_slot, ARG_BYTE, _:GRENADE_SLOT - 1);
	set_msg_arg_int(arg_position, ARG_BYTE, 4);
	set_msg_arg_int(arg_flags, ARG_BYTE, ITEM_FLAG_LIMITINWORLD | ITEM_FLAG_EXHAUSTIBLE);

	return PLUGIN_CONTINUE;
}
#endif

public CBasePlayer_OnSpawnEquip_Post(const id) {
#if defined ACCESS_FLAG
	if (~get_user_flags(id) & ACCESS_FLAG) {
		return;
	}
#endif

#if defined MIN_ROUND
	if(rg_get_current_round() < MIN_ROUND) {
		return;
	}
#endif

	giveNade(id);
}

public CmdSelect(const id) {
	if (!is_user_alive(id)) {
		return PLUGIN_HANDLED;
	}

	new item = rg_get_player_item(id, ITEM_CLASSNAME, GRENADE_SLOT);
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
	if (FClassnameIs(item, ITEM_CLASSNAME)) {
		SetHookChainArg(2, ATYPE_STRING, VIEWMODEL);
		SetHookChainArg(3, ATYPE_STRING, WEAPONMODEL);
	#if defined USAGE_MSG
		client_print(get_member(item, m_pPlayer), print_center, USAGE_MSG);
	#endif
	}

	new WeaponIdType:wid = WeaponIdType:rg_get_iteminfo(item, ItemInfo_iId);
	if (wid != WEAPON_ID && wid != WEAPON_FAKE_ID) {
		return HC_CONTINUE;
	}

	new lastItem = get_member(get_member(item, m_pPlayer), m_pLastItem);
	if (is_nullent(lastItem) || item == lastItem) {
		return HC_CONTINUE;
	}

	if (WeaponIdType:rg_get_iteminfo(lastItem, ItemInfo_iId) == WEAPON_ID) {
		SetHookChainArg(6, ATYPE_INTEGER, 0);
	}

	return HC_CONTINUE;
}

public Item_Deploy_Post(const item) {
	if (WeaponIdType:rg_get_iteminfo(item, ItemInfo_iId) == WEAPON_FAKE_ID) {
		rg_set_iteminfo(item, ItemInfo_iId, WEAPON_ID);
	}

	new other = get_member(get_member(item, m_pPlayer), m_rgpPlayerItems, GRENADE_SLOT);
	while (!is_nullent(other)) {
		if (item != other && WeaponIdType:rg_get_iteminfo(other, ItemInfo_iId) == WEAPON_ID) {
			rg_set_iteminfo(other, ItemInfo_iId, WEAPON_FAKE_ID);
		}
		other = get_member(other, m_pNext);
	}
}

public Item_Holster_Post(const item) {
	new other = get_member(get_member(item, m_pPlayer), m_rgpPlayerItems, GRENADE_SLOT);
	while (!is_nullent(other)) {
		if (item != other && WeaponIdType:rg_get_iteminfo(other, ItemInfo_iId) == WEAPON_FAKE_ID) {
			rg_set_iteminfo(other, ItemInfo_iId, WEAPON_ID);
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

	if(Float:get_entvar(pPlayer, var_health) >= Float:get_entvar(pPlayer, var_max_health)) {
	#if defined FULL_HP_MSG
		client_print(pPlayer, print_center, FULL_HP_MSG);
	#endif
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

	ExecuteHamB(Ham_TakeHealth, pPlayer, get_entvar(weapon, var_HealthNade_DrinkHealingAmount), DMG_GENERIC);
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

giveNade(const id) {
	new item = rg_get_player_item(id, ITEM_CLASSNAME, GRENADE_SLOT);
	if (item != 0) {
		giveAmmo(id, 1, AMMO_ID, 1);
		return item;
	}

	item = rg_create_entity(WEAPON_NAME, false);
	if (is_nullent(item)) {
		return NULLENT;
	}

	new Float:origin[3];
	get_entvar(id, var_origin, origin);
	set_entvar(item, var_origin, origin);
	set_entvar(item, var_spawnflags, get_entvar(item, var_spawnflags) | SF_NORESPAWN);

	set_member(item, m_Weapon_iPrimaryAmmoType, AMMO_ID);
	set_member(item, m_Weapon_iSecondaryAmmoType, -1);

	set_entvar(item, var_classname, ITEM_CLASSNAME);

	set_entvar(item, var_HealthNade_Radius, HEAL_RADIUS);
	set_entvar(item, var_HealthNade_ThrowHealingAmount, HEAL_AMOUNT_THROW);
	set_entvar(item, var_HealthNade_DrinkHealingAmount, HEAL_AMOUNT_DRINK);

	dllfunc(DLLFunc_Spawn, item);

	set_member(item, m_iId, WEAPON_NEW_ID);

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
	engfunc(EngFunc_SetModel, grenade, WORLDMODEL);
	// set_entvar(grenade, var_dmg, 30.0);
	// set_entvar(grenade, var_dmgtime, get_gametime() + time);

	copy_entvar(item, grenade, var_HealthNade_Radius);
	copy_entvar(item, grenade, var_HealthNade_ThrowHealingAmount);

	SetTouch(grenade, "GrenadeTouch");
	SetThink(grenade, "GrenadeThink");
	return grenade;
}

explodeNade(const grenade) {
	new Float:origin[3];
	get_entvar(grenade, var_origin, origin);

	new Float:fRadius = get_entvar(grenade, var_HealthNade_Radius);

	UTIL_BeamCylinder(origin, SpriteCylinder, 1, 5, 30, 1, {10, 255, 40}, 255, 5, fRadius);
	UTIL_CreateExplosion(origin, 65.0, SpriteExplode, 30, 20, (TE_EXPLFLAG_NOSOUND | TE_EXPLFLAG_NOPARTICLES));
	UTIL_SpriteTrail(origin, SpriteShape);

	rh_emit_sound2(grenade, 0, CHAN_WEAPON, SOUND_EXPLODE, VOL_NORM, ATTN_NORM, 0, PITCH_NORM);

	new id = get_entvar(grenade, var_owner);
	new team = get_member(id, m_iTeam);

	for (new player = 1, Float:playerOrigin[3]; player <= MaxClients; player++) {
		if (!is_user_alive(player) || get_member(player, m_iTeam) != team) {
			continue;
		}

		get_entvar(player, var_origin, playerOrigin);
		if (get_distance_f(origin, playerOrigin) < fRadius) {
			ExecuteHamB(Ham_TakeHealth, player, get_entvar(grenade, var_HealthNade_ThrowHealingAmount), DMG_GENERIC);
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

public plugin_natives() {
	register_native("HealthNade_GiveNade", "_HealthNade_GiveNade");
}

public _HealthNade_GiveNade() {
	enum { player = 1 };
	new pPlayer = get_param(player);

	if(is_user_alive(pPlayer)) {
		return giveNade(pPlayer);
	}

	return NULLENT;
}
