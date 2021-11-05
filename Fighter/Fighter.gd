tool
extends Node
class_name Fighter


enum INPUT_MODES {
	NO_ACTION,
	SINGLE_ACTION,
	NINE_ACTIONS,
	ACTION_RELEASE
}

export var reset_editor = false setget _reset
export(int, 1, 4) var player = 1 setget _set_player
var player_number : String

export(NodePath) var state_index
export(String) var reset_state
var apply_state setget _set_state

export(NodePath) var hinge_node
var hinge

var movement_mode = INPUT_MODES.NO_ACTION
var jumps_mode = INPUT_MODES.NO_ACTION
var strikes_mode = INPUT_MODES.NO_ACTION
var throws_mode = INPUT_MODES.NO_ACTION
var guards_mode = INPUT_MODES.NO_ACTION
var specials_mode = INPUT_MODES.NO_ACTION
var taunts_mode = INPUT_MODES.NO_ACTION

var movement_player = NodePath()
var jumps_player = NodePath()
var strikes_player = NodePath()
var throws_player = NodePath()
var guards_player = NodePath()
var specials_player = NodePath()
var taunts_player = NodePath()

var jumps_suffix = ''
var strikes_suffix = ''
var throws_suffix = ''
var guards_suffix = ''
var specials_suffix = ''
var taunts_suffix = ''

var reactions_player = NodePath()
var reactions_countdown = false
var reactions_state = 0
var countdown = 0
var suspend_ = 0

var win_effect_out_animator = NodePath()
var win_effect_out_action = ''
var win_effect_out_attach_fighter = false
var win_effect_out_type = 0
var win_effect_out_induce_countdown = false
var win_effect_out_countdown = 0
var win_effect_out_apply_velocity = false
var win_effect_out_velocity = Vector2.ZERO

var win_effect_local_animator = NodePath()
var win_effect_local_action = ''
var win_effect_local_type = 0
var win_effect_local_induce_countdown = false
var win_effect_local_countdown = 0
var win_effect_local_apply_velocity = false
var win_effect_local_velocity = Vector2.ZERO

var current_player : AnimationPlayer
var free_current_player = false

var pivot_node = NodePath()


func get_class():
	return 'SimpleFighter'


func _get_property_list():
	if get_class() == 'SimpleFighter':
		return _property_list()
	else:
		return []


const PROPERTY_USAGE_ANIMATE_DEFAULT = \
	PROPERTY_USAGE_DEFAULT | PROPERTY_USAGE_SCRIPT_VARIABLE

func _button_property_list(button : String):
	return [
		{
			name = button,
			type = TYPE_NIL,
			hint_string = button + '_',
			usage = PROPERTY_USAGE_GROUP
		},
		{
			name = button + '_mode',
			type = TYPE_INT,
			hint = PROPERTY_HINT_ENUM,
			hint_string = \
				'No Action,Single Action,Nine Actions,Action Release',
			usage = PROPERTY_USAGE_ANIMATE_DEFAULT
		},
		{
			name = button + '_player',
			type = TYPE_NODE_PATH,
			hint = PROPERTY_HINT_NONE,
			usage = PROPERTY_USAGE_ANIMATE_DEFAULT
		},
		{
			name = button + '_suffix',
			type = TYPE_STRING,
			hint = PROPERTY_HINT_NONE,
			usage = PROPERTY_USAGE_ANIMATE_DEFAULT
		}
	]

func _property_list():
	return [
		{
			name = 'Animation Logic',
			type = TYPE_NIL,
			usage = PROPERTY_USAGE_CATEGORY
		},
		{
			name = 'apply_state',
			type = TYPE_STRING,
			hint = PROPERTY_HINT_NONE,
			usage = PROPERTY_USAGE_ANIMATE_DEFAULT
		},
		{
			name = 'movement',
			type = TYPE_NIL,
			hint_string = 'movement_',
			usage = PROPERTY_USAGE_GROUP
		},
		{
			name = 'movement_mode',
			type = TYPE_INT,
			hint = PROPERTY_HINT_ENUM,
			hint_string = \
				'No Action,Single Action,Nine Actions,Action Release',
			usage = PROPERTY_USAGE_ANIMATE_DEFAULT
		},
		{
			name = 'movement_player',
			type = TYPE_NODE_PATH,
			hint = PROPERTY_HINT_NONE,
			usage = PROPERTY_USAGE_ANIMATE_DEFAULT
		}
	] \
	+ _button_property_list('jumps') \
	+ _button_property_list('strikes') \
	+ _button_property_list('throws') \
	+ _button_property_list('guards') \
	+ _button_property_list('special') \
	+ _button_property_list('taunts') \
	+ [
		{
			name = 'reactions',
			type = TYPE_NIL,
			hint_string = 'reactions_',
			usage = PROPERTY_USAGE_GROUP
		},
		{
			name = 'reactions_player',
			type = TYPE_NODE_PATH,
			hint = PROPERTY_HINT_NONE,
			usage = PROPERTY_USAGE_ANIMATE_DEFAULT
		},
		{
			name = 'reactions_countdown',
			type = TYPE_BOOL,
			hint = PROPERTY_HINT_NONE,
			usage = PROPERTY_USAGE_ANIMATE_DEFAULT
		},
		{
			name = 'reactions_state',
			type = TYPE_INT,
			hint = PROPERTY_HINT_ENUM,
			hint_string = \
				'None,High,Low,Airborne',
			usage = PROPERTY_USAGE_ANIMATE_DEFAULT
		}
	]


func _ready():
	if Engine.editor_hint: return
	player_number = str(player) + '_'
	
	if hinge_node:
		hinge = get_node(hinge_node)


func _reset(_value):
	if not Engine.editor_hint: return
	
	reset_properties()
	
	if state_index:
		var si = get_node(state_index)
		if si.has_animation(reset_state):
			si.play(reset_state)


func _set_player(value : int):
	if not value is int:
		player_number = ''
	else:
		player = value
		player_number = str(value) + '_'


func _set_state(value):
	apply_state = value
	
	if not has_node(state_index):
		return
	
	var index : AnimationPlayer = get_node(state_index)
	if index is AnimationPlayer \
			and index.has_animation(value):
		index.play(value)
		index.advance(0)


func _process(_delta):
	if Engine.editor_hint: return
	
	if reactions_countdown and countdown > 0:
		countdown -= 1
		if countdown <= 0:
			reactions_countdown = false
			countdown = 0
			current_player.playback_speed = 1
		else:
			current_player.playback_speed = 0
	
	take_action('jumps')
	take_action('strikes')
	take_action('throws')
	take_action('guards')
	take_action('specials')
	take_action('taunts')
	take_and_hold_action(movement_player, movement_mode, 'move')


func _stop_current_player():
	if current_player:
		current_player.stop()
		current_player.playback_speed = 1
		if free_current_player:
			current_player.queue_free()
			free_current_player = false


func take_action \
		(property_prefix : String, editor_substr : int = 1):
	var mode = get(property_prefix + '_mode')
	if mode == INPUT_MODES.NO_ACTION:
		return
	
	var animator = get_node(get(property_prefix + '_player'))
	if not animator is AnimationPlayer:
		return
	
	var editor_prefix = property_prefix.substr \
		(0, property_prefix.length() - editor_substr)
	
	var animation \
		= editor_prefix + get(property_prefix + '_suffix')
	if mode == INPUT_MODES.NINE_ACTIONS:
		animation += get_direction()
	
	var action = player_number + editor_prefix
	var act : bool
	if mode == INPUT_MODES.ACTION_RELEASE:
		act = !Input.is_action_pressed(action)
	else:
		act = Input.is_action_just_pressed(action)
	
	if act:
		_stop_current_player()
		
		if animator.has_animation(animation):
			reset_properties()
			animator.play(animation)
			animator.advance(0)
			current_player = animator


func take_and_hold_action \
		(anim_node : NodePath, mode : int, animation : String):
	if mode == INPUT_MODES.NO_ACTION:
		return
	
	var animator = get_node(anim_node)
	if not animator is AnimationPlayer:
		return
	
	animation += get_direction()
	
	if animator.has_animation(animation):
		if current_player != animator:
			_stop_current_player()
		
		if not animator.is_playing() \
				or animation != animator.assigned_animation:
			reset_properties()
			animator.play(animation)
			animator.advance(0)
		
		current_player = animator


func induce_action(anim_node : NodePath, animation : String):
	_stop_current_player()
	
	var animator = get_node(anim_node)
	if not animator is AnimationPlayer:
		return
	
	reset_properties()
	player.play(animation)
	#player.advance(0)
	
	current_player = animator


func inject_action(animator : AnimationPlayer, animation : String):
	_stop_current_player()
	
	current_player = animator.duplicate()
	add_child(current_player)
	free_current_player = true
	
	reset_properties()
	current_player.play(animation)
	current_player.advance(0)


func get_direction():
	var notation = 5
	
	if Input.is_action_pressed(player_number + 'left'):
		notation -= 1
	if Input.is_action_pressed(player_number + 'right'):
		notation += 1
	
	if Input.is_action_pressed(player_number + 'up'):
		notation += 3
	if Input.is_action_pressed(player_number + 'down'):
		notation -= 3
	
	return '.' + str(notation)


func _reset_button_properties(button : String):
	set(button + '_player', '')
	set(button + '_mode', INPUT_MODES.NO_ACTION)
	set(button + '_suffix', '')


func reset_properties():
	apply_state = ''
	
	_reset_button_properties('jumps')
	_reset_button_properties('strikes')
	_reset_button_properties('throws')
	_reset_button_properties('guards')
	_reset_button_properties('special')
	_reset_button_properties('taunts')
	
	movement_player = ''
	movement_mode = INPUT_MODES.NO_ACTION
	
	reactions_countdown = false


func stun(freeze : int = 0):
	if reactions_player:
		induce_action(reactions_player, 'stun')
		countdown = freeze


func release_hinge():
	for c in hinge.get_children():
		hinge.remove_child(c)
		$'..'.add_child(c)


func set_to_origin():
	pass
