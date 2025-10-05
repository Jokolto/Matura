extends Node

var client : StreamPeerTCP
var local_ai_server: AIServer # only assigned and used when not using python
var connected := false
var buffer : String = ""
var latest_actions = {}  
var message_queue = []  # stores fully parsed JSON messages
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

func handle_server_msg(msg: Dictionary):
	var msg_type = msg.get("type")
	var data = msg.get("data")

	match msg_type:
		"ACTION":
			# store them for enemies to pick up
			latest_actions = data.duplicate() # dictionary of actions: {enemy_id: action}
		"INIT":
			GlobalConfig.run_id = data["run_id"]
			GlobalConfig.seed_n = data["seed"]
			GlobalConfig.config = data["config"]
			seed(GlobalConfig.seed_n)
		"SHUTDOWN":   # not used
			get_tree().quit()
		# maybe future message types
		_:
			Logger.log("Unknown msg type:" + str(msg_type), "WARNING")


func connect_to_server():
	var err = client.connect_to_host(GlobalConfig.ClientConfig["HOST"], GlobalConfig.ClientConfig["PORT"])
	if err == OK:
		connected = true
	else:
		connected = false
		

	# Wait briefly for connection to actually complete
	await get_tree().create_timer(0.05).timeout

	var status = client.get_status()
	if status == StreamPeerTCP.STATUS_CONNECTED:
		Logger.log("[AIClient] Connected to Python AI at %s:%d" % [client.get_connected_host(), client.get_connected_port()], "INFO")
		connected = true
	else:
		Logger.log("[AIClient] Failed to connect to AI server with port %s with status: %s" \
		 % [GlobalConfig.ClientConfig['PORT'], status], "WARNING")
		connected = false


func send_message_to_server(msg: Dictionary):
	if GlobalConfig.USE_PYTHON_SERVER:
		if not connected:
			return
		var json_msg = JSON.stringify(msg) + "\n"
		var err = client.put_data(json_msg.to_utf8_buffer())
		return err
	else:
		var server_responce = local_ai_server.handle_message(msg)
		return server_responce


func process_incoming_bytes():
	if not connected:
		return
	# Read all available bytes
	if client.get_available_bytes() > 0:
		var msg_in_bytes = client.get_data(client.get_available_bytes())[1]
		buffer += msg_in_bytes.get_string_from_utf8()

	# Split complete messages by newline
	while "\n" in buffer:
		var parts = buffer.split("\n", true, 1)
		var individual_json_msg = parts[0]
		buffer = parts[1]
		var response = JSON.parse_string(individual_json_msg)
		if response:
			message_queue.append(response)
		else:
			Logger.log("Failed to parse JSON:" + str(individual_json_msg), 'WARNING')


func handle_pending_messages():
	while message_queue.size() > 0:
		var msg = message_queue.pop_front()
		handle_server_msg(msg)  

# Called in enemies.gd
func get_latest_actions() -> Dictionary:
	return latest_actions.duplicate()  


# so stuff does not leak in build
func _exit_tree():
	if is_instance_valid(local_ai_server):
		local_ai_server.queue_free()
	local_ai_server = null
	
	if client:
		client.disconnect_from_host()
		client = null
