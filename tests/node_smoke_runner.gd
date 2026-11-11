extends SceneTree

func _initialize() -> void:
	call_deferred("_launch_smoke")

func _launch_smoke() -> void:
	var user_arguments: PackedStringArray = OS.get_cmdline_user_args()
	if user_arguments.is_empty():
		push_error("Node smoke runner needs a res:// script path after '--'.")
		quit(2)
		return
	var smoke_script: Script = load(user_arguments[0]) as Script
	if smoke_script == null:
		push_error("Could not load Node smoke script: %s" % user_arguments[0])
		quit(2)
		return
	var smoke_node: Node = smoke_script.new() as Node
	if smoke_node == null:
		push_error("Smoke script must extend Node: %s" % user_arguments[0])
		quit(2)
		return
	root.add_child(smoke_node)
