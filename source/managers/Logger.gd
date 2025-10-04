extends Node
# maybe it was a bit unneccessary thing to make
 
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
			push_warning(msg)   # some disadvantage of pushing it here, is that in debugger it will say this is the source of warning
		"ERROR":
			push_error(msg)     # or error
	print(typed_msg)
