extends Node

var client : StreamPeerTCP
var local_ai_server: AIServer # only assigned and used when not using python
var connected := false
var buffer : String = ""
var trying_to_connect := false
var waiting_for_actions := false

func _ready():
	if GlobalConfig.USE_PYTHON_SERVER:
		client = StreamPeerTCP.new() 
		connect_to_server()
		trying_to_connect = true
	else:
		local_ai_server = AIServer.new()

func _process(_delta: float) -> void:
	if trying_to_connect:
		client.poll()  # <- advance internal connection state
		var status = client.get_status()
		match status:
			StreamPeerTCP.STATUS_CONNECTED:
				connected = true
				trying_to_connect = false
			StreamPeerTCP.STATUS_ERROR:
				trying_to_connect = false
			StreamPeerTCP.STATUS_NONE:
				Logger.log("[AIClient] Disconnected from Server", "INFO")

func connect_to_server():
	var err = client.connect_to_host(GlobalConfig.ClientConfig["HOST"], GlobalConfig.ClientConfig["PORT"])
	if err == OK:
		connected = true
	else:
		connected = false
		

	# Wait briefly for connection to actually complete
	await get_tree().create_timer(0.2).timeout

	var status = client.get_status()
	if status == StreamPeerTCP.STATUS_CONNECTED:
		Logger.log("[AIClient] Connected to Python AI at %s:%d" % [client.get_connected_host(), client.get_connected_port()], "INFO")
		connected = true
	else:
		Logger.log("[AIClient] Failed to connect to AI server with status:" + str(status), "WARNING")
		connected = false


func send_message_to_server(msg: Dictionary):
	if GlobalConfig.USE_PYTHON_SERVER:
		if not connected:
			Logger.log("Failed to send message: not connected to server", "WARNING")
			return
		var json_msg = JSON.stringify(msg) + "\n"
		var _err = client.put_data(json_msg.to_utf8_buffer())
	else:
		local_ai_server.handle_message(msg)


func get_ai_actions(states_msg: Dictionary) -> Dictionary:
	if GlobalConfig.USE_PYTHON_SERVER:
		if not connected:
			return {} # fallback action if server is unreachable
		send_message_to_server(states_msg)
		waiting_for_actions = true

		while waiting_for_actions:
			if client.get_available_bytes() > 0:
				waiting_for_actions = false
				return get_actions_from_server()
		return {}
	else:
		# Directly use the GDScript AI server
		return local_ai_server.handle_message(states_msg)


func get_actions_from_server() -> Dictionary:
	var msg_in_bytes = client.get_data(client.get_available_bytes())[1]
	buffer += msg_in_bytes.get_string_from_utf8()
	while "\n" in buffer:
		var msg_and_new_buffer: Array = buffer.split("\n", true, 1) # should return an array with two elements
		var individual_json_msg = msg_and_new_buffer[0]
		buffer = msg_and_new_buffer[1]
		var response = JSON.parse_string(individual_json_msg)
		return response

	return {} # fallback if nothing was returned
