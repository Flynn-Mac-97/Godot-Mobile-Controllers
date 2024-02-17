extends Node

# Autoload named Lobby
@onready var join = $"../Connect/Join"
@onready var create = $"../Connect/Create"

@onready var player_list = $"../Connect/PlayerList"
@onready var ip_input = $"../Connect/IP Input"
@onready var debug = $"../Connect/Debug"

# These signals can be connected to by a UI lobby scene or the game scene.
signal player_connected(peer_id, player_info)
signal player_disconnected(peer_id)
signal server_disconnected

const PORT = 50000
const DEFAULT_SERVER_IP = "127.0.0.1" # IPv4 localhost
const MAX_CONNECTIONS = 20

# This will contain player info for every player,
# with the keys being each player's unique IDs.
var players = {}

# This is the local player info. This should be modified locally
# before the connection is made. It will be passed to every other peer.
# For example, the value of "name" can be set to something the player
# entered in a UI scene.
var player_info = {"name": "Name"}

var players_loaded = 0

func _ready():
	multiplayer.peer_connected.connect(_on_player_connected)
	multiplayer.peer_disconnected.connect(_on_player_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_ok)
	multiplayer.connection_failed.connect(_on_connected_fail)
	multiplayer.server_disconnected.connect(_on_server_disconnected)
	debug.text = ""


func join_game(address = ""):
	if address.is_empty():
		address = DEFAULT_SERVER_IP
	var peer = ENetMultiplayerPeer.new()
	var error = peer.create_client(address, PORT)
	if error:
		return error
	multiplayer.multiplayer_peer = peer


func create_game():
	var peer = ENetMultiplayerPeer.new()
	var error = peer.create_server(PORT, MAX_CONNECTIONS)
	if error:
		return error
	multiplayer.multiplayer_peer = peer

	players[1] = player_info
	player_connected.emit(1, player_info)
	if OS.get_name() == "Windows" or OS.get_name() == "X11" or OS.get_name() == "macOS":
		var ip = IP.get_local_addresses()
		for i in ip:
			if i.begins_with("192.168") or i.begins_with("10.") or i.begins_with("172.16"):
				debug_log("Server IP: " + i)
				break


func remove_multiplayer_peer():
	multiplayer.multiplayer_peer = null


# When the server decides to start the game from a UI scene,
# do Lobby.load_game.rpc(filepath)
@rpc("call_local", "reliable")
func load_game(game_scene_path):
	get_tree().change_scene_to_file(game_scene_path)


# Every peer will call this when they have loaded the game scene.
@rpc("any_peer", "call_local", "reliable")
func player_loaded():
	if multiplayer.is_server():
		players_loaded += 1
		if players_loaded == players.size():
			$/root/Game.start_game()
			players_loaded = 0


# When a peer connects, send them my player info.
# This allows transfer of all desired data for each player, not only the unique ID.
func _on_player_connected(id):
	debug_log(str(id))
	_register_player.rpc_id(id, player_info)

@rpc("any_peer", "reliable")
func _register_player(new_player_info):
	var new_player_id = multiplayer.get_remote_sender_id()
	players[new_player_id] = new_player_info
	# Emit signal with player info
	player_connected.emit(new_player_id, new_player_info)
	# Add player to UI list
	if(multiplayer.is_server()):
		add_player_to_list(new_player_id, new_player_info)
	
func add_player_to_list(player_id: int, player_info: Dictionary) -> void:
	var player_label = Label.new()
	player_label.text = "Player %d: %s" % [player_id, player_info["name"]]
	player_list.add_child(player_label)

func _on_player_disconnected(id):
	players.erase(id)
	player_disconnected.emit(id)


func _on_connected_ok():
	var peer_id = multiplayer.get_unique_id()
	players[peer_id] = player_info
	player_connected.emit(peer_id, player_info)


func _on_connected_fail():
	multiplayer.multiplayer_peer = null


func _on_server_disconnected():
	multiplayer.multiplayer_peer = null
	players.clear()
	server_disconnected.emit()

func _on_create_button_pressed():
	var error = create_game()
	if error == null:
		debug_log("Game created successfully")
		# Transition to a "waiting for players" state in the UI
	else:
		debug_log("Failed to create game")
		#debug_log(error)

func _on_join_button_pressed():
	var error = join_game(ip_input.text)
	if error == null:
		debug_log("Joined game successfully")
		# Update UI to show joining status or hide lobby UI
	else:
		debug_log("Failed to join game")
		
func send_joystick_position_to_server(x: int, y: int):
	recieve_joystick_from_client.rpc(x, y)

@rpc("any_peer", "unreliable_ordered")
func recieve_joystick_from_client(x: int, y: int):
	#debug_log(str(players[multiplayer.get_remote_sender_id()]))
	if(multiplayer.is_server()):
		debug_log(str(x) +", "+ str(y))
	
func debug_log(message: String):
	# Update your debug UI with 'message'
	debug.text += message + "\n"
	# Optionally, you can still output to the console for remote debugging or when running in the editor
	print(message)
