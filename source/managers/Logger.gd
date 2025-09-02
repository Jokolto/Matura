extends Node

# too much logging, do not turn this thing on
const PRINT_DEBUG = false


func log(msg: String, level: String) -> void:
	if not PRINT_DEBUG and (level == "DEBUG"):
		return
	var now = Time.get_datetime_dict_from_system()
	var timestamp = "%s:%s:%s" % [now.hour, now.minute, now.second]
	var typed_msg = "[%s][%s] %s" % [timestamp, level, msg]
	match level:
		"WARNING":
			push_warning(msg)
		"ERROR":
			push_error(msg)
	print(typed_msg)
