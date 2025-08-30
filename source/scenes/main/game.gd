extends Node

@onready var http := $HTTPRequest

# Replace with your dreamlo private code
const DREAMLO_PRIVATE_URL = "http://dreamlo.com/lb/Lg6YUy6iREiToPXTcR4jSQTNhHEOU4NU-AFyOnc-K-Kg"
const DREAMLO_PUBLIC_URL = "http://dreamlo.com/lb/68b2c88d8f40bb12e078c937"


func submit_score(player_name: String, score: int) -> void:
	var url = "%s/add/%s/%d" % [DREAMLO_PRIVATE_URL, player_name, score]
	http.request(url)
	

func fetch_leaderboard() -> void:
	http.request(DREAMLO_PUBLIC_URL)

func _on_HTTPRequest_request_completed(result, response_code, headers, body):
	if response_code == 200:
		var text = body.get_string_from_utf8()
		# dreamlo "pipe" format: name|score|seconds|date
		var lines = text.strip_edges().split("\n")
		for line in lines:
			var parts = line.split("|")
			if parts.size() >= 2:
				var name = parts[0]
				var score = int(parts[1])
				print("%s - %d" % [name, score])
