extends Node2D

export (int) var MAX_PLAYERS = 10

var player_scene = preload("res://Scenes/player.tscn")
# Used on both sides, to keep track of all players.
var players = {}

func _ready():
	$Player.connect("main_player_moved", self, "_on_main_player_moved")
# Gets called when the title scene sets this scene as the main scene
func _enter_tree():
	if Network.connection == Network.Connection.CLIENT_SERVER:
		print("Starting server")
		var peer = NetworkedMultiplayerENet.new()
		peer.create_server(Network.port, MAX_PLAYERS)
		get_tree().network_peer = peer
		get_tree().connect("network_peer_connected", self, "_player_connected")
	elif Network.connection == Network.Connection.CLIENT:
		print("Connecting to ", Network.host, " on port ", Network.port)
		var peer = NetworkedMultiplayerENet.new()
		peer.create_client(Network.host, Network.port)
		get_tree().network_peer = peer
		players[get_tree().get_network_unique_id()] = $Player

func _physics_process(delta):
	if get_tree().is_network_server():
		for receiver_id in players:
			for other_id in players:
				print("Sending player moved to client ", receiver_id, "with pos", players[other_id].position.x, ", ", players[other_id].position.y)
				rpc_id(receiver_id, "other_player_moved", other_id, players[other_id].position, players[other_id].velocity)

# Called on the server when a new client connects
func _player_connected(id):
	var new_player = player_scene.instance()
	new_player.id = id
	new_player.main_player = false
	for id in players:
		# Sends an add_player rpc to the player that just joined
		print("Sending add player to new player ", new_player)
		rpc_id(new_player.id, "player_join", id)
		# Sends the add_player rpc to all other clients
		print("Sending add player to other player ", players[id])
		rpc_id(id, "player_join", new_player.id)

	players[id] = new_player
	add_child(new_player)
	print("Got connection: ", id)
	print("Players: ", players)

# Called from server when another client connects
remote func player_join(other_id):
	# Should only be run on the client
	if get_tree().is_network_server():
		return
	var new_player = player_scene.instance()
	new_player.id = other_id
	new_player.main_player = false
	add_child(new_player)
	players[other_id] = new_player
	print("New player: ", other_id)

# Called from client sides when a player moves
remote func player_moved(new_velocity):
	# Should only be run on the server
	if !get_tree().is_network_server():
		return
	var id = get_tree().get_rpc_sender_id()
	print("Got player move from ", id)
	players[id].velocity = new_velocity

# Called from server when other players move
remote func other_player_moved(id, new_pos, new_velocity):
	# Should only be run on the client
	if get_tree().is_network_server():
		return
	print("Moving ", id, " to ", new_pos.x, ", ", new_pos.y)
	players[id].move_to(new_pos, new_velocity)

func _on_main_player_moved(velocity : Vector2):
	rpc_id(1, "player_moved", velocity)
