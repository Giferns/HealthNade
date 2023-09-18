#include <amxmodx>
#include <healthnade>

public plugin_init() {
	register_plugin("Healthnade AES Layer", "1.0", "mx?!")
}

// TODO: значение будет > 0 если у игрока уже есть граната, потому следует добавить byref-аргумент, отражающий факт
// выдачи (как это сделано у меня в молотове)
public public_GiveNade(id, count, maximum) {
	return (HealthNade_GiveNade(id) > 0)
}