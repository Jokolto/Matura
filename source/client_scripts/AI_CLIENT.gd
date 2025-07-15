extends Node

var client := StreamPeerTCP.new()
var connected := false
var buffer := PackedByteArray()


func _ready():
	connect_to_server()

func connect_to_server():
	var err = client.connect_to_host(GlobalConfig.ClientConfig["HOST"], GlobalConfig.ClientConfig["PORT"])
	if err == OK:
		connected = true
		print("[AIClient] Connected to Python AI at %s:%d" % [GlobalConfig.ClientConfig["HOST"], GlobalConfig.ClientConfig["PORT"]])
	else:
		connected = false
		printerr("[AIClient] Failed to connect to AI server")

func send_json_from_dict_message(msg: Dictionary):
	if not connected:
		print("Failed to send message: not connected to server")
		return
		
	var json_msg = JSON.stringify(msg) + "\n"
	client.put_data(json_msg.to_utf8_buffer())


func get_ai_action(msg: Dictionary) -> String:
	if not connected:
		return "idle"  # fallback action if server is unreachable

	# Send message to Python AI as a JSON 
	send_json_from_dict_message(msg)

	# Read response from Python
	if client.get_available_bytes() > 0:
		buffer = client.get_data(client.get_available_bytes())[1]
		var response = buffer.get_string_from_utf8().strip_edges()
		return response

	return "idle"  # fallback if nothing was returned
