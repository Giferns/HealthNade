# [ReAPI] Health Nade

Форк лечебной гранаты на основе [Healthnade 0.0.2 от F@nt0M](https://dev-cs.ru/resources/992/) с добавлением возможности выпивания гранаты.

## Настройки

Файл настроек: `amxmodx/configs/plugins/HealthNade.cfg`.

```
// Радиус взрыва гранаты.
//
// Grenade explosion radius.
// -
// Default: "300.0"
// Minimum: "1.000000"
HealthNade_ExplodeRadius "300.0"

// Количество ХП, восстанавливаемых от взрыва гранаты.
//
// The amount of HP restored from a grenade explosion.
// -
// Default: "20.0"
HealthNade_ThrowHealingAmount "20.0"


// Количество ХП, восполняемое от взрыва гранаты. (Для игроков с флагом доступа)
//
// The number of HP replenished from the grenade explosion. (For players with an access flag)
// -
// Default: "40.0"
HealthNade_ThrowHealingAmount_With_Flags "40.0"

// Количество ХП, восстанавливаемых при выпивке гранаты.
//
// The amount of HP restored from a grenade drinking.
// -
// Default: "35.0"
HealthNade_DrinkHealingAmount "35.0"

// Количество ХП пополняется от выпивания гранаты. (Для игроков с флагом доступа)
//
// The number of HP replenished from drinking a grenade. (For players with an access flag)
// -
// Default: "60.0"
HealthNade_DrinkHealingAmount_With_Flags "60.0"


// Сколько гранат выдавать при появлении.
//
// How many grenades to give out at spawn.
// -
// Default: "1"
HealthNade_Give "1"

// Флаги доступа для выдачи гранаты при появлении. Оставьте пустым, чтобы поделиться со всеми.
//
// Access flags for giving a grenade when spawn. Leave blank to share with everyone.
// -
// Default: "t"
HealthNade_Give_AccessFlags "t"

// Флаг доступа для изменения пополнения здоровья от взрыва гранаты.
//
// An access flag for changing health replenishment from a grenade explosion.
// -
// Default: "t"
HealthNade_Override_AccessFlags "t"

// Флаги доступа к возможности питья.
//
// Access flags for drinkability.
// -
// Default: "t"
HealthNade_Drink_AccessFlags "t"

// С какого раунда будет выдаваться граната.
//
// From which round will the grenade be given.
// -
// Default: "1"
// Minimum: "1.000000"
HealthNade_Give_MinRound "1"

// Задержка выдачи (в секундах)
//
// Equip delay (in seconds)
// -
// Default: "0.0"
// Minimum: "0.000000"
HealthNade_EquipDelay "0.0"

// Подменять дымовую гранату?
//
// Replace smoke grenade?
// -
// Default: "0.0"
// Minimum: "0.000000"
// Maximum: "1.000000"
HealthNade_ReplaceSmokegren "0.0"

// Показывать подсказку по использованию гранаты.
//
// Show a tooltip for using a grenade.
// -
// Default: "1"
// Minimum: "0.000000"
// Maximum: "1.000000"
HealthNade_Msg_UsageHint "1"

// Показывать сообщение при попытке вылечиться с полным ХП.
//
// Show message when trying to heal with full HP.
// -
// Default: "1"
// Minimum: "0.000000"
// Maximum: "1.000000"
HealthNade_Msg_FullHp "1"

// Тип дропа
// 0 - выкл | 1 - вкл | 2 - учитывать квар `mp_nadedrops`
//
// Drop type
// 0 - off | 1 - on | 2 - allow cvar `mp_nade drops`
// -
// Default: "2"
// Minimum: "0.000000"
// Maximum: "2.000000"
HealthNade_NadeDrop "2"

// Номер слота, в котором будет хилка (1-5).
//
// Number of the slot in which the grenade will be (1-5).
// -
// Default: "4"
// Minimum: "1.000000"
// Maximum: "5.000000"
HealthNade_SlotId "4"

// Модель которую вы видите в своих руках (v_)
//
// 1st person model (v_)
// -
// Default: "models/reapi_healthnade/v_drink9.mdl"
HealthNade_ViewModel "models/reapi_healthnade/v_drink9.mdl"

// Модель которую мы видим в руках других игроков (p_)
//
// 3rd person model (p_)
// -
// Default: "models/reapi_healthnade/p_healthnade.mdl"
HealthNade_PlayerModel "models/reapi_healthnade/p_healthnade.mdl"

// Модель которую можно видеть на земле (w_)
//
// World model (w_)
// -
// Default: "models/reapi_healthnade/w_healthnade.mdl"
HealthNade_WorldModel "models/reapi_healthnade/w_healthnade.mdl"
```

## Благодарности

- **fantom** - за исходный плагин [Healthnade](https://dev-cs.ru/resources/992/);
- **AnonymousAmx**, **MayroN**, **Psycrow** - за [модельку гранаты с анимацией](https://dev-cs.ru/threads/18355/);
- **steelzzz**, **wopox1337** - за стоки эффектов.
- **[RedFoxxx](https://dev-cs.ru/members/8560/)** - за перевод на английский язык, за квары HealthNade_ThrowHealingAmount_With_Flags и HealthNade_DrinkHealingAmount_With_Flags.
- **[bizon](https://dev-cs.ru/members/4218/)** - за реализацию выпадения гранаты после смерти.
- **tails_master** - за помощь с MultiLang
