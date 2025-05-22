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
const MESSAGE_DELAY = 0.75
const CRY_DUCK_VOLUME = -10.0
const NORMAL_MUSIC_VOLUME = 0.0

# --- Initialization ---
func _ready() -> void:
	randomize()
	_setup_sprite_maps()
	_setup_sound_streams()
	_connect_signals()
	_validate_required_resources()
	sound_battle_music.play()
	start_new_battle()

func _setup_sprite_maps() -> void:
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

func _setup_sound_streams() -> void:
	if battle_music:
		sound_battle_music.stream = battle_music
	if hit_sound:
		sound_hit.stream = hit_sound
	if faint_sound:
		sound_faint.stream = faint_sound
	if select_sound:
		sound_select.stream = select_sound

func _connect_signals() -> void:
	fight_button.pressed.connect(_on_fight_button_pressed)
	switch_button.pressed.connect(_on_switch_button_pressed)
	for i in move_buttons.size():
		move_buttons[i].pressed.connect(Callable(self, "_on_move_button_pressed").bind(i))

func _validate_required_resources() -> void:
	if not player_trainer_default_sprite:
		printerr("Player trainer default sprite not set in BattleScene inspector!")
		player_trainer_sprite_node.texture = null
	else:
		player_trainer_sprite_node.texture = player_trainer_default_sprite

# --- Sound Management ---
func play_unamon_cry(unamon_name: String) -> Signal:
	if _unamon_cry_sounds_map.has(unamon_name):
		sound_cry.stream = _unamon_cry_sounds_map[unamon_name]
		sound_battle_music.volume_db = CRY_DUCK_VOLUME
		sound_cry.play()
		return sound_cry.finished
	return get_tree().create_timer(0.0).timeout

# --- Battle Entry Animation ---
func play_battle_entry_animation(is_player: bool) -> void:
	var sprite_node = player_unamon_sprite_node if is_player else opponent_unamon_sprite_node
	var unamon = player_active_unamon if is_player else opponent_active_unamon
	
	if not unamon or not _unamon_textures_map.has(unamon.name):
		printerr("Unamon sprite for '", unamon.name if unamon else "none", "' not found in configured sprite entries!")
		sprite_node.texture = null
		return
	
	sprite_node.texture = _unamon_textures_map[unamon.name]
	sprite_node.position = Vector2(284, 417) if is_player else Vector2(926, 185)
	sprite_node.scale = Vector2(0.3, 0.3)
	sprite_node.modulate = Color(0.5, 0.8, 1.0, 0.0)
	sprite_node.visible = true
	
	var cry_task = play_unamon_cry(unamon.name)
	
	var tween = create_tween().set_parallel(true)
	tween.tween_property(sprite_node, "modulate:a", 1.0, 3.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(sprite_node, "modulate", Color(1.0, 1.0, 1.0, 1.0), 3.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	
	await tween.finished
	await cry_task

# --- Battle State Management ---
func start_new_battle() -> void:
	_reset_battle_state()
	_setup_player_team()
	_setup_opponent_team()
	_play_initial_animations()

func _reset_battle_state() -> void:
	player_team.clear()
	opponent_team.clear()
	battle_log_queue.clear()
	current_log_display_array.clear()
	battle_log_label.text = ""
	turn_action_taken_by_player = false
	turn_action_taken_by_opponent = false
	has_opponent_switched_after_faint = false
	add_battle_log_message_to_queue("Battle Started!")

func _setup_player_team() -> void:
	var all_unamon_names = UnamonData.get_all_unamon_names()
	all_unamon_names.shuffle()
	for i in range(min(6, all_unamon_names.size())):
		var unamon_instance = UnamonData.create_unamon_instance(all_unamon_names[i])
		if unamon_instance:
			player_team.append(unamon_instance)

	if player_team.is_empty():
		printerr("Player team empty!")
		get_tree().quit()
		return

	player_active_unamon_index = 0
	player_active_unamon = player_team[player_active_unamon_index]

func _setup_opponent_team() -> void:
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
			if opponent_names_available.is_empty():
				get_tree().quit()
				return
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
		if unamon_instance:
			opponent_team.append(unamon_instance)

	if opponent_team.is_empty():
		printerr("Opponent team for ", chosen_opponent_name, " is empty!")
		get_tree().quit()
		return

	opponent_active_unamon_index = 0
	opponent_active_unamon = opponent_team[opponent_active_unamon_index]

func _play_initial_animations() -> void:
	# Reset sprite states
	player_unamon_sprite_node.visible = false
	opponent_unamon_sprite_node.visible = false
	player_unamon_sprite_node.modulate = Color.WHITE
	opponent_unamon_sprite_node.modulate = Color.WHITE

	# Set initial textures
	if player_active_unamon and _unamon_textures_map.has(player_active_unamon.name):
		player_unamon_sprite_node.texture = _unamon_textures_map[player_active_unamon.name]
	else:
		printerr("Failed to set initial player Unamon texture")
		return

	if opponent_active_unamon and _unamon_textures_map.has(opponent_active_unamon.name):
		opponent_unamon_sprite_node.texture = _unamon_textures_map[opponent_active_unamon.name]
	else:
		printerr("Failed to set initial opponent Unamon texture")
		return

	# Update UI displays
	update_unamon_display(player_active_unamon, true, true)
	update_unamon_display(opponent_active_unamon, false, true)
	update_hp_display(player_active_unamon, true)
	update_hp_display(opponent_active_unamon, false)

	# Play entry animations
	await play_battle_entry_animation(false)  # Opponent's Unamon enters first
	await play_battle_entry_animation(true)   # Then player's Unamon enters

	set_battle_phase("PROCESSING_MESSAGES")

# --- Battle Log Management ---
func add_battle_log_message_to_queue(message: String) -> void:
	battle_log_queue.append(message)
	if not is_displaying_log_message:
		process_next_log_message()

func process_next_log_message() -> void:
	if battle_phase == "GAME_OVER" and battle_log_queue.is_empty():
		_handle_game_over_log_completion()
		return

	if battle_log_queue.is_empty():
		is_displaying_log_message = false
		_handle_empty_log_queue()
		return

	is_displaying_log_message = true
	var next_message = battle_log_queue.pop_front()
	current_log_display_array.append("")
	if current_log_display_array.size() > MAX_LOG_LINES:
		current_log_display_array.pop_front()
	battle_log_label.text = "\n".join(current_log_display_array)
	typewrite_message_to_label(next_message, battle_log_label, current_log_display_array.size() - 1)

func _handle_game_over_log_completion() -> void:
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

func _handle_empty_log_queue() -> void:
	if battle_phase == "PROCESSING_MESSAGES":
		_handle_processing_messages_phase()
	elif battle_phase == "AWAIT_PLAYER_FAINT_SWITCH":
		_handle_player_faint_switch()
	elif battle_phase == "AWAIT_OPPONENT_FAINT_SWITCH":
		_handle_opponent_faint_switch()

func _handle_processing_messages_phase() -> void:
	if player_active_unamon.calculated_stats.current_hp <= 0 and not player_unamon_sprite_node.visible:
		set_battle_phase("AWAIT_PLAYER_FAINT_SWITCH")
	elif opponent_active_unamon.calculated_stats.current_hp <= 0 and not opponent_unamon_sprite_node.visible:
		set_battle_phase("AWAIT_OPPONENT_FAINT_SWITCH")
	elif turn_action_taken_by_player and turn_action_taken_by_opponent:
		start_new_round_sequence()
	elif current_actor == "PLAYER" and not turn_action_taken_by_player:
		set_battle_phase("ACTION_SELECT")
	elif current_actor == "OPPONENT" and not turn_action_taken_by_opponent:
		set_battle_phase("ANIMATING_OPPONENT_ATTACK")
		opponent_action()
	else:
		determine_next_actor_or_new_round()

func _handle_player_faint_switch() -> void:
	var can_switch_player = false
	for unamon_member in player_team:
		if unamon_member.calculated_stats.current_hp > 0:
			can_switch_player = true
			break
	if can_switch_player:
		display_switch_options_for_player(true)
	else:
		game_over(false)

func _handle_opponent_faint_switch() -> void:
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
			game_over(true)

func typewrite_message_to_label(full_message: String, label_node: Label, line_index: int) -> void:
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
func update_unamon_display(unamon: Dictionary, is_player: bool, is_initial_setup_or_direct_set: bool = false) -> void:
	var sprite_node_to_update = player_unamon_sprite_node if is_player else opponent_unamon_sprite_node
	var name_label = player_unamon_name_label if is_player else opponent_unamon_name_label

	if unamon and unamon.has("name"):
		if _unamon_textures_map.has(unamon.name):
			sprite_node_to_update.texture = _unamon_textures_map[unamon.name]
			sprite_node_to_update.visible = true
			if is_initial_setup_or_direct_set:
				sprite_node_to_update.modulate = Color.WHITE
		else:
			printerr("Unamon sprite for '", unamon.name, "' not found in configured sprite entries!")
			sprite_node_to_update.texture = null
			sprite_node_to_update.visible = false

		name_label.text = unamon.name + " (Lvl " + str(LEVEL) + ")"
	else:
		sprite_node_to_update.texture = null
		sprite_node_to_update.visible = false
		name_label.text = "---"

func update_hp_display(unamon: Dictionary, is_player: bool) -> void:
	if unamon:
		var hp_bar = player_hp_bar if is_player else opponent_hp_bar
		var hp_text = player_hp_text_label if is_player else opponent_hp_text_label
		hp_bar.max_value = unamon.calculated_stats.max_hp
		hp_bar.value = unamon.calculated_stats.current_hp
		hp_text.text = "HP: " + str(unamon.calculated_stats.current_hp) + "/" + str(unamon.calculated_stats.max_hp)

func set_battle_phase(new_phase: String) -> void:
	battle_phase = new_phase
	
	# Ensure menus are properly shown/hidden based on phase
	action_menu.visible = (battle_phase == "ACTION_SELECT" and not is_displaying_log_message)
	move_menu.visible = (battle_phase == "MOVE_SELECT")
	
	# Handle switch menu visibility
	if battle_phase == "AWAIT_PLAYER_FAINT_SWITCH":
		display_switch_options_for_player(true)
	elif battle_phase == "SWITCH_SELECT":
		display_switch_options_for_player(false)
	elif switch_menu_container.visible:
		switch_menu_container.visible = false

	# Trigger UI updates based on phase
	if battle_phase == "MOVE_SELECT":
		display_moves_for_player()

	# Process messages if needed
	if battle_phase == "PROCESSING_MESSAGES" and not is_displaying_log_message:
		process_next_log_message()

# --- Button Handlers ---
func _on_fight_button_pressed() -> void:
	sound_select.play()
	set_battle_phase("MOVE_SELECT")

func _on_switch_button_pressed() -> void:
	sound_select.play()
	set_battle_phase("SWITCH_SELECT")

func display_moves_for_player() -> void:
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

func _on_move_button_pressed(move_idx: int) -> void:
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

func display_switch_options_for_player(must_switch: bool) -> void:
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
		if team_member.types.size() > 1:
			types_str += "/" + UnamonData.get_type_name(team_member.types[1])
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

	if not can_make_a_valid_switch and must_switch:
		add_battle_log_message_to_queue("No Unamon left to switch!")
		set_battle_phase("PROCESSING_MESSAGES")
		game_over(false)

func _on_player_select_switch_unamon(unamon_idx: int, was_faint_switch: bool) -> void:
	sound_select.play()
	switch_menu_container.visible = false

	if not was_faint_switch and player_active_unamon and player_unamon_sprite_node.visible:
		await play_switch_out_animation(player_unamon_sprite_node)

	player_active_unamon_index = unamon_idx
	player_active_unamon = player_team[player_active_unamon_index]

	add_battle_log_message_to_queue("Player sent out " + player_active_unamon.name + "!")
	update_unamon_display(player_active_unamon, true, false)
	update_hp_display(player_active_unamon, true)
	
	player_unamon_sprite_node.visible = true
	await play_switch_in_animation(player_unamon_sprite_node)
	
	if not was_faint_switch:
		turn_action_taken_by_player = true
		determine_next_actor_or_new_round()
	else:
		if opponent_active_unamon.calculated_stats.current_hp <= 0 and not opponent_unamon_sprite_node.visible:
			set_battle_phase("AWAIT_OPPONENT_FAINT_SWITCH")
		else:
			determine_next_actor_or_new_round()
	
	set_battle_phase("PROCESSING_MESSAGES")

# --- Battle Logic & Turn Sequencing ---
func execute_turn_sequence(attacker: Dictionary, defender: Dictionary, move: Dictionary, attacker_is_player: bool) -> void:
	var attacker_sprite = player_unamon_sprite_node if attacker_is_player else opponent_unamon_sprite_node
	var defender_sprite = opponent_unamon_sprite_node if attacker_is_player else player_unamon_sprite_node
	
	if attacker.calculated_stats.current_hp <= 0:
		set_battle_phase("PROCESSING_MESSAGES")
		return

	play_attack_animation(attacker_sprite, attacker_is_player)
	add_battle_log_message_to_queue(attacker.name + " used " + move.name + "!")

	if randf() * 100.0 >= move.accuracy and move.accuracy != 101:
		add_battle_log_message_to_queue(attacker.name + "'s attack missed!")
	else:
		var damage = calculate_damage(attacker, defender, move)
		if damage > 0:
			play_hit_flash(defender_sprite)
			sound_hit.play()
		apply_damage(defender, damage, not attacker_is_player)
		
		if damage > 0:
			add_battle_log_message_to_queue(defender.name + " took " + str(damage) + " damage!")
		elif UnamonData.get_type_effectiveness(move.type, defender.types) == 0.0:
			add_battle_log_message_to_queue("It had no effect on " + defender.name + "...")
		else:
			add_battle_log_message_to_queue(attacker.name + "'s attack had little effect!")

		if defender.calculated_stats.current_hp <= 0:
			add_battle_log_message_to_queue(defender.name + " fainted!")
			await play_faint_animation(defender_sprite)
			
			if attacker_is_player:
				has_opponent_switched_after_faint = false
			
			if attacker_is_player:
				set_battle_phase("AWAIT_OPPONENT_FAINT_SWITCH")
			else:
				set_battle_phase("AWAIT_PLAYER_FAINT_SWITCH")
			return

	set_battle_phase("PROCESSING_MESSAGES")

func calculate_damage(attacker: Dictionary, defender: Dictionary, move: Dictionary) -> int:
	var attacker_stat: int
	var defender_stat: int

	if move.category == UnamonData.MOVE_CATEGORY.PHYSICAL:
		attacker_stat = attacker.calculated_stats.attack
		defender_stat = defender.calculated_stats.defense
	else:
		attacker_stat = attacker.calculated_stats.special_attack
		defender_stat = defender.calculated_stats.special_defense

	var stab_multiplier = 1.5 if move.type in attacker.types else 1.0
	var type_effectiveness_multiplier = UnamonData.get_type_effectiveness(move.type, defender.types)

	if type_effectiveness_multiplier > 1.1:
		add_battle_log_message_to_queue("It's super effective!")
	if type_effectiveness_multiplier < 0.9 and type_effectiveness_multiplier > 0.01:
		add_battle_log_message_to_queue("It's not very effective...")
	
	if move.name == "Night Shade":
		if type_effectiveness_multiplier == 0.0:
			return 0
		return LEVEL

	var base_damage_numerator = (2.0 * LEVEL / 5.0 + 2.0) * move.power * (float(attacker_stat) / float(max(1, defender_stat)))
	var base_damage = base_damage_numerator / 50.0 + 2.0
	
	var final_damage = int(base_damage * stab_multiplier * type_effectiveness_multiplier)
	final_damage = int(final_damage * randf_range(0.85, 1.0))
	return max(0 if type_effectiveness_multiplier == 0.0 else 1, final_damage)

func apply_damage(target_unamon: Dictionary, damage_amount: int, target_is_player: bool) -> void:
	target_unamon.calculated_stats.current_hp = max(0, target_unamon.calculated_stats.current_hp - damage_amount)
	update_hp_display(target_unamon, target_is_player)

func determine_next_actor_or_new_round() -> void:
	if battle_phase == "GAME_OVER":
		return

	if player_active_unamon.calculated_stats.current_hp <= 0 and not player_unamon_sprite_node.visible:
		set_battle_phase("AWAIT_PLAYER_FAINT_SWITCH")
		process_next_log_message()
		return
	if opponent_active_unamon.calculated_stats.current_hp <= 0 and not opponent_unamon_sprite_node.visible:
		set_battle_phase("AWAIT_OPPONENT_FAINT_SWITCH")
		process_next_log_message()
		return

	if turn_action_taken_by_player and turn_action_taken_by_opponent:
		start_new_round_sequence()
		return

	var player_faster = player_active_unamon.calculated_stats.speed >= opponent_active_unamon.calculated_stats.speed

	if player_faster:
		if not turn_action_taken_by_player:
			current_actor = "PLAYER"
			set_battle_phase("ACTION_SELECT")
		elif not turn_action_taken_by_opponent:
			current_actor = "OPPONENT"
			set_battle_phase("ANIMATING_OPPONENT_ATTACK")
			opponent_action()
	else:
		if not turn_action_taken_by_opponent:
			current_actor = "OPPONENT"
			set_battle_phase("ANIMATING_OPPONENT_ATTACK")
			opponent_action()
		elif not turn_action_taken_by_player:
			current_actor = "PLAYER"
			set_battle_phase("ACTION_SELECT")

func start_new_round_sequence() -> void:
	if battle_phase == "GAME_OVER":
		return
	add_battle_log_message_to_queue("--- New Round ---")
	turn_action_taken_by_player = false
	turn_action_taken_by_opponent = false

	if player_active_unamon.calculated_stats.current_hp <= 0:
		if not player_unamon_sprite_node.visible:
			set_battle_phase("AWAIT_PLAYER_FAINT_SWITCH")
	elif opponent_active_unamon.calculated_stats.current_hp <= 0:
		if not opponent_unamon_sprite_node.visible:
			set_battle_phase("AWAIT_OPPONENT_FAINT_SWITCH")
	else:
		if player_active_unamon.calculated_stats.speed >= opponent_active_unamon.calculated_stats.speed:
			current_actor = "PLAYER"
			add_battle_log_message_to_queue(player_active_unamon.name + " acts first this round.")
		else:
			current_actor = "OPPONENT"
			add_battle_log_message_to_queue(opponent_active_unamon.name + " acts first this round.")
	set_battle_phase("PROCESSING_MESSAGES")

func opponent_action() -> void:
	if battle_phase == "GAME_OVER" or opponent_active_unamon.calculated_stats.current_hp <= 0:
		set_battle_phase("PROCESSING_MESSAGES")
		determine_next_actor_or_new_round()
		return

	var available_moves_with_pp = []
	for mv in opponent_active_unamon.battle_moves:
		if mv.current_pp > 0:
			available_moves_with_pp.append(mv)

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

func opponent_switch_fainted() -> void:
	var new_opponent_idx = -1
	var available_indices = []
	for i in opponent_team.size():
		if opponent_team[i].calculated_stats.current_hp > 0:
			available_indices.append(i)

	if not available_indices.is_empty():
		new_opponent_idx = available_indices[randi() % available_indices.size()]
		
		opponent_active_unamon_index = new_opponent_idx
		opponent_active_unamon = opponent_team[opponent_active_unamon_index]
		add_battle_log_message_to_queue("Opponent sent out " + opponent_active_unamon.name + "!")
		update_unamon_display(opponent_active_unamon, false, false)
		update_hp_display(opponent_active_unamon, false)
		
		await play_switch_in_animation(opponent_unamon_sprite_node)
		
		if turn_action_taken_by_player:
			start_new_round_sequence()
		else:
			current_actor = "PLAYER"
			set_battle_phase("ACTION_SELECT")
	else:
		game_over(true)

# --- Animation Functions ---
func play_attack_animation(sprite: Sprite2D, is_player: bool) -> void:
	var original_pos = sprite.position
	var original_scale = sprite.scale
	var move_dir = Vector2(30, -15) if is_player else Vector2(-30, 15)
	var tween = create_tween().set_parallel(false)
	tween.tween_property(sprite, "scale", original_scale * 1.15, 0.1).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(sprite, "position", original_pos + move_dir, 0.1).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	await tween.finished
	var tween_back = create_tween()
	tween_back.tween_property(sprite, "scale", original_scale, 0.1).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tween_back.tween_property(sprite, "position", original_pos, 0.1).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	await tween_back.finished

func play_hit_flash(sprite: Sprite2D) -> void:
	var tween = create_tween().set_loops(2)
	var hit_color = Color(1.0, 0.5, 0.5, sprite.modulate.a)
	var normal_color = Color(1.0, 1.0, 1.0, sprite.modulate.a)
	tween.tween_property(sprite, "modulate", hit_color, 0.08)
	tween.tween_property(sprite, "modulate", normal_color, 0.08)

func play_faint_animation(sprite: Sprite2D) -> void:
	sound_faint.play()
	var tween = create_tween()
	sprite.visible = true
	sprite.modulate.a = 1.0

	tween.tween_property(sprite, "modulate:a", 0.0, 0.75).set_delay(0.1)
	await tween.finished
	sprite.visible = false

func play_switch_out_animation(sprite: Sprite2D) -> void:
	if not sprite.visible:
		return

	var tween = create_tween()
	tween.tween_property(sprite, "modulate:a", 0.0, 0.2)
	await tween.finished
	sprite.visible = false

func play_switch_in_animation(sprite: Sprite2D) -> void:
	var active_unamon_for_sprite = player_active_unamon if sprite == player_unamon_sprite_node else opponent_active_unamon
	if active_unamon_for_sprite and _unamon_textures_map.has(active_unamon_for_sprite.name):
		sprite.texture = _unamon_textures_map[active_unamon_for_sprite.name]
	else:
		var name_to_print = active_unamon_for_sprite.name if active_unamon_for_sprite else "Unknown Unamon"
		printerr("Texture not found for ", name_to_print, " in switch_in_animation")
		sprite.texture = null

	sprite.visible = true
	sprite.modulate = Color(0.5, 0.8, 1.0, 0.0)
	
	var cry_task = play_unamon_cry(active_unamon_for_sprite.name)
	
	var tween = create_tween().set_parallel(true)
	tween.tween_property(sprite, "modulate:a", 1.0, 3.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(sprite, "modulate", Color(1.0, 1.0, 1.0, 1.0), 3.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	
	await tween.finished
	await cry_task

func game_over(player_wins: bool) -> void:
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

func _on_restart_button_pressed() -> void:
	var restart_btn_node = get_node_or_null("UILayer/RestartButton")
	if restart_btn_node:
		restart_btn_node.queue_free()

	game_over_label.visible = false
	player_unamon_sprite_node.modulate = Color.WHITE
	opponent_unamon_sprite_node.modulate = Color.WHITE

	start_new_battle()
