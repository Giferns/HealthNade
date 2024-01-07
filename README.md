# [ReAPI] Health Nade

Форк лечебной гранаты на основе [Healthnade 0.0.2 от F@nt0M](https://dev-cs.ru/resources/992/) с добавлением возможности выпивания гранаты.

## Настройки

Файл настроек: `amxmodx/configs/plugins/HealthNade.cfg`. Создаётся при первом запуске плагина.

```
// Радиус взрыва гранаты.
HealthNade_ExplodeRadius "300.0"

// Кол-во ХП, восполняемое от взрыва гранаты.
HealthNade_ThrowHealingAmount "20.0"

// Кол-во ХП, восполняемое от взрыва гранаты при наличии флага доступа HealthNade_ThorwHealing_AccessFlags.
HealthNade_ThrowHealingAmount_With_Flags "40.0"

// Кол-во ХП, восполняемое от выпивания гранаты.
HealthNade_DrinkHealingAmount "35.0"

// Кол-во ХП, восполняемое от выпивания гранаты при наличии флага доступа HealthNade_ThorwHealing_AccessFlags.
HealthNade_DrinkHealingAmount_With_Flags "60.0"

// Флаг доступа, изменяющий объём восполнения здоровья от взрыва/выпивания гранаты.
HealthNade_Override_AccessFlags "t"

// Выдавать ли хилку при спавне.
HealthNade_Give "0"

// Флаги доступа для получения гранаты при спавне. Оставить пустым, чтобы выдавать всем.
HealthNade_Give_AccessFlags "t"

// Флаги доступа для возможности выпивания.
HealthNade_Drink_AccessFlags "t"

// С какого раунда будет выдаваться граната.
HealthNade_Give_MinRound "1"

// Задержка выдачи (в секундах)
HealthNade_EquipDelay "0.0"

// Подменять дымовую гранату?
HealthNade_ReplaceSmokegren "0"

// Показывать подсказку по использованию гранаты.
HealthNade_Msg_UsageHint "1"

// Показывать сообщение при попытке вылечиться с полным ХП.
HealthNade_Msg_FullHp "1"

// Тип дропа
// 0 - выкл | 1 - вкл | 2 - учитывать квар mp_nadedrops
HealthNade_NadeDrop "2"

// Номер слота, в котором будет хилка (1-5)
HealthNade_SlotId "4"
```

## Благодарности

- **fantom** - за исходный плагин [Healthnade](https://dev-cs.ru/resources/992/);
- **AnonymousAmx**, **MayroN**, **Psycrow** - за [модельку гранаты с анимацией](https://dev-cs.ru/threads/18355/);
- **steelzzz**, **wopox1337** - за стоки эффектов.

- **[RedFoxxx](https://dev-cs.ru/members/8560/)**  - 
1)[за перевод на английский язык] 
2)[за квары HealthNade_ThrowHealingAmount_With_Flags и HealthNade_DrinkHealingAmount_With_Flags, HealthNade_Override_AccessFlags и обновлен словарь]
3)[Добавил натив IsPlayer_HealthNade() ]
4)[Добавил console command HealthNade ]
5)[Добавлена функция register_srvcmd("amx_give_HealthNade", "SrvHealthNade", и #include <amxmisc>]

- **[bizon](https://dev-cs.ru/members/4218/)** - за реализацию выпадения гранаты после смерти.
- **[Nordic Warrior](https://dev-cs.ru/members/3093/)** - Добавил натив HealthNade_HasNade
