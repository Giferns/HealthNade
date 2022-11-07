# [ReAPI] Health Nade

Форк лечебной гранаты на основе [Healthnade 0.0.2 от F@nt0M](https://dev-cs.ru/resources/992/) с добавлением возможности выпивания гранаты.

## Настройки

Файл настроек: `amxmodx/configs/plugins/HealthNade.cfg`. Создаётся при первом запуске плагина.

```
// Радиус взрыва гранаты.
HealthNade_ExplodeRadius "300.0"

// Кол-во ХП, восполняемое от взрыва гранаты.
HealthNade_ThrowHealingAmount "20.0"

// Кол-во ХП, восполняемое от выпивания гранаты.
HealthNade_DrinkHealingAmount "35.0"

// Флаги доступа для получения гранаты при спавне. Оставить пустым, чтобы выдавать всем.
HealthNade_Give_AccessFlags "t"

// С какого раунда будет выдаваться граната.
HealthNade_Give_MinRound "1"

// Выдавать ли хилку при спавне.
HealthNade_Give "0"

// Показывать подсказку по использованию гранаты.
HealthNade_Msg_UsageHint "1"

// Показывать сообщение при попытке вылечиться с полным ХП.
HealthNade_Msg_FullHp "1"
```

## Благодарности

- **fantom** - за исходный плагин [Healthnade](https://dev-cs.ru/resources/992/);
- **AnonymousAmx**, **MayroN**, **Psycrow** - за [модельку гранаты с анимацией](https://dev-cs.ru/threads/18355/);
- **steelzzz**, **wopox1337** - за стоки эффектов.
- **[RedFoxxx](https://dev-cs.ru/members/8560/)** - за перевод на англ.
