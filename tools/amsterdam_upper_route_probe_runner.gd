extends SceneTree

const PROBE_SCENE: PackedScene = preload("res://tools/amsterdam_upper_route_probe.tscn")

func _initialize() -> void:
	call_deferred("_start_probe")

func _start_probe() -> void:
	print("AMSTERDAM_UPPER_ROUTE_RUNNER_STARTED")
	root.add_child(PROBE_SCENE.instantiate())
