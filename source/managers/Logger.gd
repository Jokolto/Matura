extends Node

var log_path: String = "user://logs/godot.log"
var log_file: FileAccess

func _ready():
	log_file = FileAccess.open(log_path, FileAccess.WRITE_READ)

func log(msg: String, level: String) -> void:
	var now = Time.get_datetime_dict_from_system()
	var timestamp = "%s:%s:%s" % [now.hour, now.minute, now.second]
	var typed_msg = "[%s][%s] %s" % [timestamp, level, msg]
	match level:
		"WARNING":
			push_warning(msg)
		"ERROR":
			push_error(msg)
	print(typed_msg)
	log_file.seek_end()
	log_file.store_line(typed_msg)
