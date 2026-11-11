extends RefCounted

# Amsterdam's opening collectible note; later city stories will be written with their routes.
const LOGS: Array[Dictionary] = [
	{"title": "Letzter Fährplan", "text": "Zwischen den Grachten liegt ein alter Fluchtplan. Die Straße nach Norden ist blockiert, aber der Kombi kann sich durch die zerstörten Brücken und Barrikaden einen Weg bahnen."}
]

static func get_log(index: int) -> Dictionary:
	if index < 0 or index >= LOGS.size():
		return {}
	return LOGS[index].duplicate(true)
