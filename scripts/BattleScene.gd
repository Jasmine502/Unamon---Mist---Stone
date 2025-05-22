# scripts/BattleScene.gd
extends Node2D

# --- EXPORTED TEXTURES (NEW APPROACH) ---
@export var unamon_sprite_entries: Array[SpriteEntry]
@export var opponent_trainer_sprite_entries: Array[SpriteEntry]
@export var player_trainer_default_sprite: Texture2D

# --- EXPORTED SOUNDS ---
@export var battle_music: AudioStream
@export var hit_sound: AudioStream
@export var faint_sound: AudioStream
@export var select_sound: AudioStream

# Helper dictionaries for quick lookup, populated in _ready()
var _unamon_textures_map: Dictionary = {}
var _opponent_trainer_textures_map: Dictionary = {}
var _unamon_cry_sounds_map: Dictionary = {}

# --- UI Node References ---
@onready var player_unamon_sprite_node: Sprite2D = $PlayerUnamonSprite
@onready var opponent_unamon_sprite_node: Sprite2D = $OpponentUnamonSprite
@onready var player_trainer_sprite_node: Sprite2D = $PlayerTrainerSprite
@onready var opponent_trainer_sprite_node: Sprite2D = $OpponentTrainerSprite

@onready var player_unamon_name_label: Label = $UILayer/PlayerInfo/PlayerUnamonName
@onready var player_hp_bar: ProgressBar = $UILayer/PlayerInfo/PlayerHPBar
@onready var player_hp_text_label: Label = $UILayer/PlayerInfo/PlayerHPText

@onready var opponent_unamon_name_label: Label = $UILayer/OpponentInfo/OpponentUnamonName
@onready var opponent_hp_bar: ProgressBar = $UILayer/OpponentInfo/OpponentHPBar
@onready var opponent_hp_text_label: Label = $UILayer/OpponentInfo/OpponentHPText

@onready var battle_log_label: Label = $UILayer/BattleLog
@onready var action_menu: HBoxContainer = $UILayer/ActionMenu
@onready var fight_button: Button = $UILayer/ActionMenu/FightButton
@onready var switch_button: Button = $UILayer/ActionMenu/SwitchButton

@onready var move_menu: GridContainer = $UILayer/MoveMenu
@onready var move_buttons: Array[Button] = [
	$UILayer/MoveMenu/Move1Button,
	$UILayer/MoveMenu/Move2Button,
	$UILayer/MoveMenu/Move3Button,
	$UILayer/MoveMenu/Move4Button
]

@onready var switch_menu_container: VBoxContainer = $UILayer/SwitchMenu
@onready var game_over_label: Label = $UILayer/GameOverLabel

# --- Sound Node References ---
@onready var sound_hit: AudioStreamPlayer = $SoundHit
@onready var sound_faint: AudioStreamPlayer = $SoundFaint
@onready var sound_select: AudioStreamPlayer = $SoundSelect
@onready var sound_battle_music: AudioStreamPlayer = $BattleMusic
@onready var sound_cry: AudioStreamPlayer = $SoundCry

# --- Battle State Variables ---
var player_team: Array = []
var opponent_team: Array = []
var player_active_unamon_index: int = 0
var opponent_active_unamon_index: int = 0
var has_opponent_switched_after_faint := false

var player_active_unamon: Dictionary
var opponent_active_unamon: Dictionary

var current_actor: String = "PLAYER"
var turn_action_taken_by_player: bool = false
var turn_action_taken_by_opponent: bool = false

var battle_phase: String = "INIT"

var battle_log_queue: Array[String] = []
var is_displaying_log_message: bool = false
const MAX_LOG_LINES = 4
var current_log_display_array : Array[String] = []

const LEVEL = 50
const TYPEWRITER_DELAY = 0.03
const MESSAGE_DELAY = 0.75 # Increased slightly for readability
const CRY_DUCK_VOLUME = -10.0 # Volume in dB to duck the battle music during cries
const NORMAL_MUSIC_VOLUME = 0.0 # Normal volume for battle music

# --- Initialization ---
func _ready():
	randomize()

	for entry in unamon_sprite_entries:
		if entry and entry.entry_name != "" and entry.texture:
			_unamon_textures_map[entry.entry_name] = entry.texture
			if entry.cry_sound:
				_unamon_cry_sounds_map[entry.entry_name] = entry.cry_sound
		elif entry:
			printerr("Invalid Unamon SpriteEntry: Name or Texture missing. Name: '", entry.entry_name, "'")

	for entry in opponent_trainer_sprite_entries:
		if entry and entry.entry_name != "" and entry.texture:
			_opponent_trainer_textures_map[entry.entry_name] = entry.texture
		elif entry:
			printerr("Invalid Opponent Trainer SpriteEntry: Name or Texture missing. Name: '", entry.entry_name, "'")

	# Set up sound streams
	if battle_music:
		sound_battle_music.stream = battle_music
	if hit_sound:
		sound_hit.stream = hit_sound
	if faint_sound:
		sound_faint.stream = faint_sound
	if select_sound:
		sound_select.stream = select_sound

	fight_button.pressed.connect(_on_fight_button_pressed)
	switch_button.pressed.connect(_on_switch_button_pressed)
	for i in move_buttons.size():
		move_buttons[i].pressed.connect(Callable(self, "_on_move_button_pressed").bind(i))

	if player_trainer_default_sprite:
		player_trainer_sprite_node.texture = player_trainer_default_sprite
	else:
		printerr("Player trainer default sprite not set in BattleScene inspector!")

	sound_battle_music.play()
	start_new_battle()

# --- Sound Management ---
func play_unamon_cry(unamon_name: String) -> Signal:
	if _unamon_cry_sounds_map.has(unamon_name):
		sound_cry.stream = _unamon_cry_sounds_map[unamon_name]
		sound_battle_music.volume_db = CRY_DUCK_VOLUME
		sound_cry.play()
		return sound_cry.finished
	return get_tree().create_timer(0.0).timeout

# --- Battle Entry Animation ---
func play_battle_entry_animation(is_player: bool):
	var sprite_node = player_unamon_sprite_node if is_player else opponent_unamon_sprite_node
	var unamon = player_active_unamon if is_player else opponent_active_unamon
	
	# Update sprite texture immediately
	if unamon and _unamon_textures_map.has(unamon.name):
		sprite_node.texture = _unamon_textures_map[unamon.name]
	else:
		printerr("Unamon sprite for '", unamon.name, "' not found in configured sprite entries!")
		sprite_node.texture = null
	
	# Reset sprite position and scale
	sprite_node.position = Vector2(284, 417) if is_player else Vector2(926, 185)
	sprite_node.scale = Vector2(0.3, 0.3)
	
	# Start with holographic blue at 0 opacity
	sprite_node.modulate = Color(0.5, 0.8, 1.0, 0.0)
	sprite_node.visible = true
	
	# Start both the cry and animation simultaneously
	var cry_task = play_unamon_cry(unamon.name)
	
	# Create a parallel tween for color and opacity
	var tween = create_tween().set_parallel(true)
	
	# Fade in over 3 seconds
	tween.tween_property(sprite_node, "modulate:a", 1.0, 3.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	
	# Shift from holographic blue to normal color over 3 seconds
	tween.tween_property(sprite_node, "modulate", Color(1.0, 1.0, 1.0, 1.0), 3.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	
	# Wait for both the animation and cry to finish
	await tween.finished
	await cry_task

# --- Battle State Management ---
func start_new_battle():
	player_team = []
	opponent_team = []
	battle_log_queue = []
	current_log_display_array = []
	battle_log_label.text = ""
	turn_action_taken_by_player = false
	turn_action_taken_by_opponent = false
	has_opponent_switched_after_faint = false  # Reset the switch flag

	add_battle_log_message_to_queue("Battle Started!")

	var all_unamon_names = UnamonData.get_all_unamon_names()
	all_unamon_names.shuffle()
	for i in range(min(6, all_unamon_names.size())):
		var unamon_instance = UnamonData.create_unamon_instance(all_unamon_names[i])
		if unamon_instance: player_team.append(unamon_instance)

	if player_team.is_empty(): printerr("Player team empty!"); get_tree().quit(); return
	player_active_unamon_index = 0
	player_active_unamon = player_team[player_active_unamon_index]

	var opponent_names_available = UnamonData.get_opponent_names()
	if opponent_names_available.is_empty():
		printerr("No opponents defined in UnamonData!")
		get_tree().quit()
		return
	var chosen_opponent_name = opponent_names_available[randi() % opponent_names_available.size()]
	var opponent_info = UnamonData.get_opponent_data(chosen_opponent_name)
	
	if opponent_info.is_empty():
		printerr("Could not get opponent data for: ", chosen_opponent_name)
		if opponent_names_available.size() > 1:
			opponent_names_available.erase(chosen_opponent_name)
			if opponent_names_available.is_empty(): get_tree().quit()
			chosen_opponent_name = opponent_names_available[randi() % opponent_names_available.size()]
			opponent_info = UnamonData.get_opponent_data(chosen_opponent_name)
		else:
			get_tree().quit()
			return

	add_battle_log_message_to_queue("You are facing " + chosen_opponent_name + "!")
	
	if _opponent_trainer_textures_map.has(chosen_opponent_name):
		opponent_trainer_sprite_node.texture = _opponent_trainer_textures_map[chosen_opponent_name]
	else:
		printerr("Trainer sprite for opponent '", chosen_opponent_name, "' not found in configured sprite entries!")

	for unamon_name_str in opponent_info.team:
		var unamon_instance = UnamonData.create_unamon_instance(unamon_name_str)
		if unamon_instance: opponent_team.append(unamon_instance)

	if opponent_team.is_empty(): printerr("Opponent team for ", chosen_opponent_name, " is empty!"); get_tree().quit(); return
	opponent_active_unamon_index = 0
	opponent_active_unamon = opponent_team[opponent_active_unamon_index]

	# Ensure sprites are properly reset before starting
	player_unamon_sprite_node.visible = true
	opponent_unamon_sprite_node.visible = true
	player_unamon_sprite_node.modulate = Color.WHITE
	opponent_unamon_sprite_node.modulate = Color.WHITE

	# Play entry animations and cries
	await play_battle_entry_animation(false) # Opponent's Unamon enters first
	await play_battle_entry_animation(true)  # Then player's Unamon enters

	update_unamon_display(player_active_unamon, true, true)
	update_unamon_display(opponent_active_unamon, false, true)
	update_hp_display(player_active_unamon, true)
	update_hp_display(opponent_active_unamon, false)

	set_battle_phase("PROCESSING_MESSAGES")

# --- Battle Log Management ---
func add_battle_log_message_to_queue(message: String):
	battle_log_queue.append(message)
	if not is_displaying_log_message:
		process_next_log_message()

func process_next_log_message():
	if battle_phase == "GAME_OVER" and battle_log_queue.is_empty():
		is_displaying_log_message = false
		var restart_button_check = get_node_or_null("UILayer/RestartButton")
		if not restart_button_check and game_over_label.visible: 
			var restart_button = Button.new()
			restart_button.name = "RestartButton"
			restart_button.text = "Restart Battle"
			restart_button.pressed.connect(_on_restart_button_pressed)
			var ui_layer_node = $UILayer
			ui_layer_node.add_child(restart_button)
			restart_button.size = Vector2(150, 40)
			var viewport_size = get_viewport_rect().size
			restart_button.position = Vector2(
				(viewport_size.x - restart_button.size.x) / 2,
				game_over_label.position.y + game_over_label.size.y + 30
			)
		return

	if battle_log_queue.is_empty():
		is_displaying_log_message = false
		if battle_phase == "PROCESSING_MESSAGES":
			# Check if active Unamon fainted (and its sprite is now invisible due to faint animation)
			if player_active_unamon.calculated_stats.current_hp <= 0 and not player_unamon_sprite_node.visible:
				set_battle_phase("AWAIT_PLAYER_FAINT_SWITCH")
				# Fall through to AWAIT_PLAYER_FAINT_SWITCH logic below
			elif opponent_active_unamon.calculated_stats.current_hp <= 0 and not opponent_unamon_sprite_node.visible:
				set_battle_phase("AWAIT_OPPONENT_FAINT_SWITCH")
				# Fall through to AWAIT_OPPONENT_FAINT_SWITCH logic below
			elif turn_action_taken_by_player and turn_action_taken_by_opponent:
				start_new_round_sequence()
			elif current_actor == "PLAYER" and not turn_action_taken_by_player:
				set_battle_phase("ACTION_SELECT")
			elif current_actor == "OPPONENT" and not turn_action_taken_by_opponent:
				set_battle_phase("ANIMATING_OPPONENT_ATTACK") # This phase name might be misleading, it's just before opponent acts
				opponent_action()
			else: # Should cover cases where one has acted and the other hasn't, or start of new round
				determine_next_actor_or_new_round()

		# This logic will now be hit if the phase was set above AND battle_log_queue is empty
		if battle_phase == "AWAIT_PLAYER_FAINT_SWITCH":
			var can_switch_player = false
			for unamon_member in player_team:
				if unamon_member.calculated_stats.current_hp > 0:
					can_switch_player = true
					break
			if can_switch_player:
				if not switch_menu_container.visible: # Only display if not already shown
					display_switch_options_for_player(true)
			else:
				game_over(false) # No Unamon left

		elif battle_phase == "AWAIT_OPPONENT_FAINT_SWITCH":
			if not has_opponent_switched_after_faint:
				var can_switch_opponent = false
				for unamon_member in opponent_team:
					if unamon_member.calculated_stats.current_hp > 0:
						can_switch_opponent = true
						break
				if can_switch_opponent:
					has_opponent_switched_after_faint = true
					await opponent_switch_fainted()
				else:
					game_over(true) # Opponent has no Unamon left
		return

	is_displaying_log_message = true
	var next_message = battle_log_queue.pop_front()
	current_log_display_array.append("")
	if current_log_display_array.size() > MAX_LOG_LINES:
		current_log_display_array.pop_front()
	battle_log_label.text = "\n".join(current_log_display_array)
	typewrite_message_to_label(next_message, battle_log_label, current_log_display_array.size() - 1)


func typewrite_message_to_label(full_message: String, label_node: Label, line_index: int):
	var current_text_on_line = ""
	for char_idx in range(full_message.length()):
		current_text_on_line += full_message[char_idx]
		if line_index < current_log_display_array.size(): 
			current_log_display_array[line_index] = current_text_on_line
			label_node.text = "\n".join(current_log_display_array)
		await get_tree().create_timer(TYPEWRITER_DELAY).timeout
	print(full_message) 
	await get_tree().create_timer(MESSAGE_DELAY).timeout
	process_next_log_message()


# --- UI Update Functions ---
func update_unamon_display(unamon: Dictionary, is_player: bool, is_initial_setup_or_direct_set: bool = false):
	var sprite_node_to_update = player_unamon_sprite_node if is_player else opponent_unamon_sprite_node
	var name_label = player_unamon_name_label if is_player else opponent_unamon_name_label

	if unamon and unamon.has("name"):
		if _unamon_textures_map.has(unamon.name):
			sprite_node_to_update.texture = _unamon_textures_map[unamon.name]
			# Always make sprite visible when setting texture
			sprite_node_to_update.visible = true
			if is_initial_setup_or_direct_set:
				sprite_node_to_update.modulate = Color.WHITE
		else:
			printerr("Unamon sprite for '", unamon.name, "' not found in configured sprite entries!")
			sprite_node_to_update.texture = null
			sprite_node_to_update.visible = false

		name_label.text = unamon.name + " (Lvl " + str(LEVEL) + ")"
	else: # Unamon data is null or invalid
		sprite_node_to_update.texture = null
		sprite_node_to_update.visible = false # Hide if no valid Unamon
		name_label.text = "---"

	# Print debug information
	print("Updating Unamon display for ", "player" if is_player else "opponent")
	print("Unamon name: ", unamon.name if unamon and unamon.has("name") else "none")
	print("Sprite visible: ", sprite_node_to_update.visible)
	print("Has texture: ", sprite_node_to_update.texture != null)
	print("Sprite position: ", sprite_node_to_update.position)

func update_hp_display(unamon: Dictionary, is_player: bool):
	if unamon:
		var hp_bar = player_hp_bar if is_player else opponent_hp_bar
		var hp_text = player_hp_text_label if is_player else opponent_hp_text_label
		hp_bar.max_value = unamon.calculated_stats.max_hp
		hp_bar.value = unamon.calculated_stats.current_hp
		hp_text.text = "HP: " + str(unamon.calculated_stats.current_hp) + "/" + str(unamon.calculated_stats.max_hp)

func set_battle_phase(new_phase: String):
	battle_phase = new_phase
	#print("Battle Phase set to: ", battle_phase) # For debugging
	
	# Ensure menus are properly shown/hidden based on phase
	action_menu.visible = (battle_phase == "ACTION_SELECT" and not is_displaying_log_message)
	move_menu.visible = (battle_phase == "MOVE_SELECT")
	
	# Manage switch menu visibility
	if battle_phase == "AWAIT_PLAYER_FAINT_SWITCH" or battle_phase == "SWITCH_SELECT":
		# display_switch_options_for_player will be called by process_next_log_message or button press
		pass # Visibility handled by display_switch_options_for_player
	elif switch_menu_container.visible: # Hide if not in a switch phase
		switch_menu_container.visible = false

	# Trigger UI updates based on phase
	if battle_phase == "MOVE_SELECT": 
		display_moves_for_player()
	elif battle_phase == "SWITCH_SELECT": 
		display_switch_options_for_player(false)
	# AWAIT_PLAYER_FAINT_SWITCH display is handled in process_next_log_message

	# If we set phase to processing and nothing is currently displaying, kick it off
	if battle_phase == "PROCESSING_MESSAGES" and not is_displaying_log_message:
		process_next_log_message()


func _on_fight_button_pressed():
	sound_select.play()
	set_battle_phase("MOVE_SELECT")

func _on_switch_button_pressed():
	sound_select.play()
	set_battle_phase("SWITCH_SELECT") # This will trigger display_switch_options_for_player

func display_moves_for_player():
	for i in move_buttons.size():
		var btn = move_buttons[i]
		if i < player_active_unamon.battle_moves.size():
			var move_data = player_active_unamon.battle_moves[i]
			btn.text = move_data.name + " (PP: " + str(move_data.current_pp) + "/" + str(move_data.pp) + ")"
			btn.disabled = (move_data.current_pp == 0)
			var type_name = UnamonData.get_type_name(move_data.type)
			var category_name = UnamonData.get_move_category_name(move_data.category)
			btn.tooltip_text = "Type: " + type_name + \
							   "\nCategory: " + category_name + \
							   "\nPower: " + str(move_data.power) + \
							   "\nAccuracy: " + str(move_data.accuracy) + "%" + \
							   "\nMax PP: " + str(move_data.pp)
		else:
			btn.text = "-"
			btn.disabled = true
			btn.tooltip_text = ""

func _on_move_button_pressed(move_idx: int):
	sound_select.play()
	if battle_phase == "MOVE_SELECT" and current_actor == "PLAYER":
		var selected_move = player_active_unamon.battle_moves[move_idx]
		if selected_move.current_pp <= 0:
			add_battle_log_message_to_queue(selected_move.name + " is out of PP!") 
			set_battle_phase("PROCESSING_MESSAGES") 
			return

		selected_move.current_pp -= 1
		turn_action_taken_by_player = true
		execute_turn_sequence(player_active_unamon, opponent_active_unamon, selected_move, true)

func display_switch_options_for_player(must_switch: bool):
	switch_menu_container.visible = true 
	for child in switch_menu_container.get_children():
		child.queue_free()

	var can_make_a_valid_switch = false
	for i in player_team.size():
		var team_member = player_team[i]
		var switch_btn = Button.new()

		var stats_str = "HP: %d, ATK: %d, DEF: %d\nSpA: %d, SpD: %d, SPE: %d" % [
			team_member.calculated_stats.max_hp, team_member.calculated_stats.attack,
			team_member.calculated_stats.defense, team_member.calculated_stats.special_attack,
			team_member.calculated_stats.special_defense, team_member.calculated_stats.speed
		]
		var types_str = UnamonData.get_type_name(team_member.types[0])
		if team_member.types.size() > 1: types_str += "/" + UnamonData.get_type_name(team_member.types[1])
		switch_btn.tooltip_text = "Name: " + team_member.name + "\nTypes: " + types_str + "\n" + stats_str

		if team_member.calculated_stats.current_hp > 0:
			if i == player_active_unamon_index and not must_switch:
				switch_btn.text = team_member.name + " (Active)"
				switch_btn.disabled = true
			else:
				switch_btn.text = team_member.name + " (" + str(team_member.calculated_stats.current_hp) + " HP)"
				switch_btn.pressed.connect(Callable(self, "_on_player_select_switch_unamon").bind(i, must_switch))
				can_make_a_valid_switch = true
		else:
			switch_btn.text = team_member.name + " (Fainted)"
			switch_btn.disabled = true
		switch_menu_container.add_child(switch_btn)

	if not can_make_a_valid_switch and must_switch: # Should only happen if all Unamon fainted
		add_battle_log_message_to_queue("No Unamon left to switch!") 
		set_battle_phase("PROCESSING_MESSAGES") # Process this message
		game_over(false) # Then game over


func _on_player_select_switch_unamon(unamon_idx: int, was_faint_switch: bool):
	sound_select.play()
	switch_menu_container.visible = false 

	if not was_faint_switch and player_active_unamon and player_unamon_sprite_node.visible:
		await play_switch_out_animation(player_unamon_sprite_node)
	# If it was a faint switch, the old one is already "fainted" (invisible by play_faint_animation).

	player_active_unamon_index = unamon_idx
	player_active_unamon = player_team[player_active_unamon_index]

	add_battle_log_message_to_queue("Player sent out " + player_active_unamon.name + "!") 
	update_unamon_display(player_active_unamon, true, false) # is_initial_setup_or_direct_set = false
	update_hp_display(player_active_unamon, true)
	
	# Ensure sprite is visible before starting switch-in animation
	player_unamon_sprite_node.visible = true
	await play_switch_in_animation(player_unamon_sprite_node) # Await for anim to complete
	
	if not was_faint_switch: 
		turn_action_taken_by_player = true
		# After switching, determine next actor or start new round
		determine_next_actor_or_new_round()
	else:
		# For faint switches, we need to check if opponent needs to switch too
		if opponent_active_unamon.calculated_stats.current_hp <= 0 and not opponent_unamon_sprite_node.visible:
			set_battle_phase("AWAIT_OPPONENT_FAINT_SWITCH")
		else:
			# If opponent is still alive, continue with normal battle flow
			determine_next_actor_or_new_round()
	
	# Ensure phase advancement after switch is complete
	set_battle_phase("PROCESSING_MESSAGES")


# --- Battle Logic & Turn Sequencing ---
func execute_turn_sequence(attacker: Dictionary, defender: Dictionary, move: Dictionary, attacker_is_player: bool):
	var attacker_sprite = player_unamon_sprite_node if attacker_is_player else opponent_unamon_sprite_node
	var defender_sprite = opponent_unamon_sprite_node if attacker_is_player else player_unamon_sprite_node
	
	if attacker.calculated_stats.current_hp <=0: # Attacker fainted before it could move (e.g. recoil, status)
		set_battle_phase("PROCESSING_MESSAGES")
		return

	play_attack_animation(attacker_sprite, attacker_is_player)
	# No await here, message comes first

	add_battle_log_message_to_queue(attacker.name + " used " + move.name + "!") 

	if randf() * 100.0 >= move.accuracy and move.accuracy != 101: # 101 for always hit
		add_battle_log_message_to_queue(attacker.name + "'s attack missed!") 
	else:
		var damage = calculate_damage(attacker, defender, move) 
		if damage > 0: 
			play_hit_flash(defender_sprite)
			sound_hit.play()
		apply_damage(defender, damage, not attacker_is_player) # defender_is_player = not attacker_is_player
		
		if damage > 0 :
			add_battle_log_message_to_queue(defender.name + " took " + str(damage) + " damage!") 
		elif UnamonData.get_type_effectiveness(move.type, defender.types) == 0.0 :
			add_battle_log_message_to_queue("It had no effect on " + defender.name + "...")
		else: # Move hit, but did 0 damage (e.g. not very effective rounding down)
			add_battle_log_message_to_queue(attacker.name + "'s attack had little effect!")


		# Check for defender faint immediately after damage and messages are queued
		if defender.calculated_stats.current_hp <= 0:
			add_battle_log_message_to_queue(defender.name + " fainted!")
			# The actual animation will play when this message is processed if using await
			# For now, we'll let the message queue handle the animation call via process_next_log_message
			# by awaiting it there. To ensure it plays before switch prompt:
			await play_faint_animation(defender_sprite) # Await here to ensure it's done before next phase logic
			
			# Reset the switch flag when an opponent Unamon faints
			if attacker_is_player:
				has_opponent_switched_after_faint = false
			
			# Set the appropriate phase based on who fainted
			if attacker_is_player:
				set_battle_phase("AWAIT_OPPONENT_FAINT_SWITCH")
			else:
				set_battle_phase("AWAIT_PLAYER_FAINT_SWITCH")

	set_battle_phase("PROCESSING_MESSAGES") # This will process all queued messages including faint


func calculate_damage(attacker: Dictionary, defender: Dictionary, move: Dictionary) -> int:
	var attacker_stat: int
	var defender_stat: int

	if move.category == UnamonData.MOVE_CATEGORY.PHYSICAL:
		attacker_stat = attacker.calculated_stats.attack
		defender_stat = defender.calculated_stats.defense
	else: # SPECIAL
		attacker_stat = attacker.calculated_stats.special_attack
		defender_stat = defender.calculated_stats.special_defense

	var stab_multiplier = 1.0
	if move.type in attacker.types:
		stab_multiplier = 1.5

	var type_effectiveness_multiplier = UnamonData.get_type_effectiveness(move.type, defender.types)

	# Queue effectiveness messages here, before damage calculation, so they appear first
	if type_effectiveness_multiplier > 1.1: add_battle_log_message_to_queue("It's super effective!") 
	if type_effectiveness_multiplier < 0.9 && type_effectiveness_multiplier > 0.01: add_battle_log_message_to_queue("It's not very effective...") 
	
	# Special case for moves like Night Shade
	if move.name == "Night Shade": # Assuming Night Shade always deals fixed damage equal to level
		if type_effectiveness_multiplier == 0.0: # Ghost type vs Normal
			return 0
		return LEVEL # STAB doesn't apply to fixed damage moves like Night Shade typically

	# Standard damage formula
	var base_damage_numerator = (2.0 * LEVEL / 5.0 + 2.0) * move.power * (float(attacker_stat) / float(max(1, defender_stat))) # Prevent division by zero
	var base_damage = base_damage_numerator / 50.0 + 2.0
	
	var final_damage = int(base_damage * stab_multiplier * type_effectiveness_multiplier)
	# Randomization factor (0.85 to 1.0)
	final_damage = int(final_damage * (randf_range(0.85, 1.0))) 
	return max(0 if type_effectiveness_multiplier == 0.0 else 1, final_damage) # Ensure at least 1 damage if effective, unless 0 effectiveness

func apply_damage(target_unamon: Dictionary, damage_amount: int, target_is_player: bool):
	target_unamon.calculated_stats.current_hp = max(0, target_unamon.calculated_stats.current_hp - damage_amount)
	update_hp_display(target_unamon, target_is_player)

func determine_next_actor_or_new_round():
	if battle_phase == "GAME_OVER": return

	# Check for faints first (sprites should be invisible already if fainted)
	if player_active_unamon.calculated_stats.current_hp <= 0 and not player_unamon_sprite_node.visible:
		set_battle_phase("AWAIT_PLAYER_FAINT_SWITCH")
		process_next_log_message() # Will trigger switch menu if messages are clear
		return
	if opponent_active_unamon.calculated_stats.current_hp <= 0 and not opponent_unamon_sprite_node.visible:
		set_battle_phase("AWAIT_OPPONENT_FAINT_SWITCH")
		process_next_log_message() # Will trigger opponent switch if messages are clear
		return

	if turn_action_taken_by_player and turn_action_taken_by_opponent:
		start_new_round_sequence()
		return

	# Determine actor based on speed if both haven't acted or one has
	var player_faster = player_active_unamon.calculated_stats.speed >= opponent_active_unamon.calculated_stats.speed

	if player_faster:
		if not turn_action_taken_by_player:
			current_actor = "PLAYER"
			set_battle_phase("ACTION_SELECT")
		elif not turn_action_taken_by_opponent: # Player acted, opponent's turn
			current_actor = "OPPONENT"
			set_battle_phase("ANIMATING_OPPONENT_ATTACK") # Prepare for opponent's move
			opponent_action() # Opponent makes their move
	else: # Opponent is faster
		if not turn_action_taken_by_opponent:
			current_actor = "OPPONENT"
			set_battle_phase("ANIMATING_OPPONENT_ATTACK")
			opponent_action()
		elif not turn_action_taken_by_player: # Opponent acted, player's turn
			current_actor = "PLAYER"
			set_battle_phase("ACTION_SELECT")


func start_new_round_sequence():
	if battle_phase == "GAME_OVER": return
	add_battle_log_message_to_queue("--- New Round ---") 
	turn_action_taken_by_player = false
	turn_action_taken_by_opponent = false

	# Faint checks are handled by determine_next_actor_or_new_round or execute_turn_sequence
	if player_active_unamon.calculated_stats.current_hp <= 0:
		if not player_unamon_sprite_node.visible: # Already fainted and invisible
			set_battle_phase("AWAIT_PLAYER_FAINT_SWITCH")
		# If somehow HP is 0 but sprite is visible, execute_turn_sequence should handle faint anim
	elif opponent_active_unamon.calculated_stats.current_hp <= 0:
		if not opponent_unamon_sprite_node.visible: # Already fainted and invisible
			set_battle_phase("AWAIT_OPPONENT_FAINT_SWITCH")
	else: # Both are active, determine who goes first
		if player_active_unamon.calculated_stats.speed >= opponent_active_unamon.calculated_stats.speed:
			current_actor = "PLAYER"
			add_battle_log_message_to_queue(player_active_unamon.name + " acts first this round.") 
		else:
			current_actor = "OPPONENT"
			add_battle_log_message_to_queue(opponent_active_unamon.name + " acts first this round.") 
	set_battle_phase("PROCESSING_MESSAGES") # To display the "New Round" and "acts first" messages

func opponent_action():
	if battle_phase == "GAME_OVER" or opponent_active_unamon.calculated_stats.current_hp <= 0:
		set_battle_phase("PROCESSING_MESSAGES") 
		determine_next_actor_or_new_round() 
		return

	var available_moves_with_pp = []
	for mv in opponent_active_unamon.battle_moves:
		if mv.current_pp > 0: available_moves_with_pp.append(mv)

	if available_moves_with_pp.is_empty():
		add_battle_log_message_to_queue(opponent_active_unamon.name + " is out of moves!") 
		turn_action_taken_by_opponent = true 
		set_battle_phase("PROCESSING_MESSAGES") 
		return

	var opponent_move = available_moves_with_pp[randi() % available_moves_with_pp.size()]
	opponent_move.current_pp -= 1 

	if battle_phase != "GAME_OVER": 
		turn_action_taken_by_opponent = true
		execute_turn_sequence(opponent_active_unamon, player_active_unamon, opponent_move, false)

func opponent_switch_fainted():
	# This function is called when the opponent needs to switch due to a faint.
	# The fainted Unamon's sprite should already be invisible from play_faint_animation.
	var new_opponent_idx = -1
	var available_indices = []
	for i in opponent_team.size():
		if opponent_team[i].calculated_stats.current_hp > 0:
			available_indices.append(i)

	if not available_indices.is_empty():
		new_opponent_idx = available_indices[randi() % available_indices.size()]
		
		# No need to play_switch_out_animation as the previous one fainted and is invisible.
		
		opponent_active_unamon_index = new_opponent_idx
		opponent_active_unamon = opponent_team[opponent_active_unamon_index]
		add_battle_log_message_to_queue("Opponent sent out " + opponent_active_unamon.name + "!") 
		update_unamon_display(opponent_active_unamon, false, false) # is_initial_setup_or_direct_set = false
		update_hp_display(opponent_active_unamon, false)
		
		await play_switch_in_animation(opponent_unamon_sprite_node) # Await for anim to complete
		
		# After opponent switches, check if we need to start a new round or continue the current one
		if turn_action_taken_by_player:
			# If player has already acted this round, start a new round
			start_new_round_sequence()
		else:
			# If player hasn't acted yet, let them continue their turn
			current_actor = "PLAYER"
			set_battle_phase("ACTION_SELECT")
		
		# Removed the set_battle_phase("PROCESSING_MESSAGES") call as it's handled by the caller
	else: # No Unamon left for opponent
		game_over(true) # Player wins

# --- Animation Functions ---
func play_attack_animation(sprite: Sprite2D, is_player: bool):
	var original_pos = sprite.position
	var original_scale = sprite.scale
	var move_dir = Vector2(30, -15) if is_player else Vector2(-30, 15)
	var tween = create_tween().set_parallel(false) 
	tween.tween_property(sprite, "scale", original_scale * 1.15, 0.1).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(sprite, "position", original_pos + move_dir, 0.1).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	await tween.finished # Await this part of the animation
	var tween_back = create_tween()
	tween_back.tween_property(sprite, "scale", original_scale, 0.1).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tween_back.tween_property(sprite, "position", original_pos, 0.1).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	await tween_back.finished


func play_hit_flash(sprite: Sprite2D):
	var tween = create_tween().set_loops(2) 
	var hit_color = Color(1.0, 0.5, 0.5, sprite.modulate.a) 
	var normal_color = Color(1.0, 1.0, 1.0, sprite.modulate.a) 
	tween.tween_property(sprite, "modulate", hit_color, 0.08)
	tween.tween_property(sprite, "modulate", normal_color, 0.08)
	# No await, this is a quick visual effect

func play_faint_animation(sprite: Sprite2D):
	sound_faint.play()
	var tween = create_tween()
	# Ensure sprite is visible before starting fade, in case it was hidden by switch_out
	sprite.visible = true 
	sprite.modulate.a = 1.0 # Reset alpha before fading

	tween.tween_property(sprite, "modulate:a", 0.0, 0.75).set_delay(0.1) 
	await tween.finished
	sprite.visible = false # Hide it AFTER the tween is fully complete

func play_switch_out_animation(sprite: Sprite2D):
	if not sprite.visible: return # Don't animate if already invisible

	var tween = create_tween()
	tween.tween_property(sprite, "modulate:a", 0.0, 0.2) 
	await tween.finished
	sprite.visible = false # Set invisible AFTER animation

func play_switch_in_animation(sprite: Sprite2D):
	# Ensure correct texture for the NEW active Unamon
	var active_unamon_for_sprite = player_active_unamon if sprite == player_unamon_sprite_node else opponent_active_unamon
	if active_unamon_for_sprite and _unamon_textures_map.has(active_unamon_for_sprite.name):
		sprite.texture = _unamon_textures_map[active_unamon_for_sprite.name]
	else:
		var name_to_print = active_unamon_for_sprite.name if active_unamon_for_sprite else "Unknown Unamon"
		printerr("Texture not found for ", name_to_print, " in switch_in_animation")
		sprite.texture = null 

	# Reset properties for a fresh animation
	sprite.visible = true
	sprite.modulate = Color(0.5, 0.8, 1.0, 0.0)  # Start with holographic blue at 0 opacity
	
	# Start both the cry and animation simultaneously
	var cry_task = play_unamon_cry(active_unamon_for_sprite.name)
	
	# Create a parallel tween for color and opacity
	var tween = create_tween().set_parallel(true)
	
	# Fade in over 3 seconds
	tween.tween_property(sprite, "modulate:a", 1.0, 3.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	
	# Shift from holographic blue to normal color over 3 seconds
	tween.tween_property(sprite, "modulate", Color(1.0, 1.0, 1.0, 1.0), 3.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	
	# Wait for both the animation and cry to finish
	await tween.finished
	await cry_task


func game_over(player_wins: bool):
	set_battle_phase("GAME_OVER") 
	action_menu.visible = false
	move_menu.visible = false
	switch_menu_container.visible = false

	game_over_label.visible = true
	if player_wins:
		game_over_label.text = "YOU WIN!"
		add_battle_log_message_to_queue("Congratulations! You won!") 
	else:
		game_over_label.text = "YOU LOSE!"
		add_battle_log_message_to_queue("Better luck next time!") 
	# The restart button logic is handled in process_next_log_message when queue is empty

func _on_restart_button_pressed():
	var restart_btn_node = get_node_or_null("UILayer/RestartButton")
	if restart_btn_node: restart_btn_node.queue_free()

	game_over_label.visible = false
	# Ensure sprites are reset for the new battle display
	player_unamon_sprite_node.modulate = Color.WHITE
	opponent_unamon_sprite_node.modulate = Color.WHITE
	# Visibility will be handled by update_unamon_display in start_new_battle

	start_new_battle()
