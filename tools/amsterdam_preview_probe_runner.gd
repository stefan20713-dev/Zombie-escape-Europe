extends SceneTree

const PROBE_SCENE: PackedScene = preload("res://tools/amsterdam_preview_probe.tscn")

func _initialize() -> void:
	call_deferred("_start_probe")

func _start_probe() -> void:
	print("AMSTERDAM_PREVIEW_RUNNER_STARTED")
	root.add_child(PROBE_SCENE.instantiate())
