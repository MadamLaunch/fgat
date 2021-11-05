extends Area2D
class_name Hitbox2D


enum HITBOX {
	NEUTRAL,
	STRIKE,
	THROW,
	GUARD
}

export(NodePath) var fighter_node
var fighter

export(Texture) var texture setget _set_texture
func _set_texture(value : Texture):
	texture = value

export(HITBOX) var hitbox_type = HITBOX.NEUTRAL
var active_type

export(bool) var hit_neutral = false

var win_effect_out_animator : NodePath
var win_effect_out_action : String
var win_effect_out_attach_fighter : bool
var win_effect_out_type : int
var win_effect_out_induce_countdown : bool
var win_effect_out_countdown : int
var win_effect_out_apply_velocity : bool
var win_effect_out_velocity : Vector2

var win_effect_local_animator : NodePath
var win_effect_local_action : String
var win_effect_local_type : int
var win_effect_local_induce_countdown : bool
var win_effect_local_countdown : int
var win_effect_local_apply_velocity : bool
var win_effect_local_velocity : Vector2


signal win_collision(fighter)


const PROPERTY_USAGE_ANIMATE_DEFAULT = \
	PROPERTY_USAGE_DEFAULT | PROPERTY_USAGE_SCRIPT_VARIABLE


func _get_property_list():
	return [
		{
			name = 'Collision Win Effects',
			type = TYPE_NIL,
			usage = PROPERTY_USAGE_CATEGORY
		},
		{
			name = 'win_effect_out',
			type = TYPE_NIL,
			hint_string = 'win_effect_out_',
			usage = PROPERTY_USAGE_GROUP
		},
		{
			name = 'win_effect_out_animator',
			type = TYPE_NODE_PATH,
			hint = PROPERTY_HINT_NONE,
			usage = PROPERTY_USAGE_ANIMATE_DEFAULT
		},
		{
			name = 'win_effect_out_action',
			type = TYPE_STRING,
			hint = PROPERTY_HINT_NONE,
			usage = PROPERTY_USAGE_ANIMATE_DEFAULT
		},
		{
			name = 'win_effect_out_attach_fighter',
			type = TYPE_BOOL,
			hint = PROPERTY_HINT_NONE,
			usage = PROPERTY_USAGE_ANIMATE_DEFAULT
		},
		{
			name = 'win_effect_out_type',
			type = TYPE_INT,
			hint = PROPERTY_HINT_ENUM,
			hint_string = \
				'No Effect,High,Low,Overhead,Launcher,Trip,Aerial',
			usage = PROPERTY_USAGE_ANIMATE_DEFAULT
		},
		{
			name = 'win_effect_out_induce_countdown',
			type = TYPE_BOOL,
			hint = PROPERTY_HINT_NONE,
			usage = PROPERTY_USAGE_ANIMATE_DEFAULT
		},
		{
			name = 'win_effect_out_countdown',
			type = TYPE_INT,
			hint = PROPERTY_HINT_NONE,
			usage = PROPERTY_USAGE_ANIMATE_DEFAULT
		},
		{
			name = 'win_effect_out_apply_velocity',
			type = TYPE_BOOL,
			hint = PROPERTY_HINT_NONE,
			usage = PROPERTY_USAGE_ANIMATE_DEFAULT
		},
		{
			name = 'win_effect_out_velocity',
			type = TYPE_VECTOR2,
			hint = PROPERTY_HINT_NONE,
			usage = PROPERTY_USAGE_ANIMATE_DEFAULT
		},
		{
			name = 'win_effect_local',
			type = TYPE_NIL,
			hint_string = 'win_effect_local_',
			usage = PROPERTY_USAGE_GROUP
		},
		{
			name = 'win_effect_local_animator',
			type = TYPE_NODE_PATH,
			hint = PROPERTY_HINT_NONE,
			usage = PROPERTY_USAGE_ANIMATE_DEFAULT
		},
		{
			name = 'win_effect_local_action',
			type = TYPE_STRING,
			hint = PROPERTY_HINT_NONE,
			usage = PROPERTY_USAGE_ANIMATE_DEFAULT
		},
		{
			name = 'win_effect_local_type',
			type = TYPE_INT,
			hint = PROPERTY_HINT_ENUM,
			hint_string = \
				'No Effect,Strike,Slash,Parry,Block',
			usage = PROPERTY_USAGE_ANIMATE_DEFAULT
		},
		{
			name = 'win_effect_local_induce_countdown',
			type = TYPE_BOOL,
			hint = PROPERTY_HINT_NONE,
			usage = PROPERTY_USAGE_ANIMATE_DEFAULT
		},
		{
			name = 'win_effect_local_countdown',
			type = TYPE_INT,
			hint = PROPERTY_HINT_NONE,
			usage = PROPERTY_USAGE_ANIMATE_DEFAULT
		},
		{
			name = 'win_effect_local_apply_velocity',
			type = TYPE_BOOL,
			hint = PROPERTY_HINT_NONE,
			usage = PROPERTY_USAGE_ANIMATE_DEFAULT
		},
		{
			name = 'win_effect_local_velocity',
			type = TYPE_VECTOR2,
			hint = PROPERTY_HINT_NONE,
			usage = PROPERTY_USAGE_ANIMATE_DEFAULT
		}
	]


func _ready():
	if fighter_node:
		fighter = get_node(fighter_node)


func state_process():
	$Shape.disabled \
		= not is_visible_in_tree() or modulate.a < 1.0
	
	if modulate.v < 1.0:
		active_type = HITBOX.NEUTRAL
	else:
		active_type = hitbox_type


func reset():
	position = Vector2.ZERO
	rotation_degrees = 0
	scale = Vector2.ONE
	modulate = Color.white
	
	hit_neutral = false
	
	win_effect_out_animator = ''
	win_effect_out_action = ''
	win_effect_out_type = 0
	win_effect_out_induce_countdown = false
	win_effect_out_countdown = 0
	win_effect_out_apply_velocity = false
	win_effect_out_velocity = Vector2.ZERO
	
	win_effect_local_animator = ''
	win_effect_local_action = ''
	win_effect_local_type = 0
	win_effect_local_induce_countdown = false
	win_effect_local_countdown = 0
	win_effect_local_apply_velocity = false
	win_effect_local_velocity = Vector2.ZERO


func _on_area_entered(area):
	if not 'hitbox_type' in area \
			or fighter == area.fighter \
			or area.fighter == null:
		return
	
	if (hit_neutral and area.active_type == HITBOX.NEUTRAL) \
			or (active_type == HITBOX.STRIKE
				and area.active_type == HITBOX.THROW) \
			or (active_type == HITBOX.THROW
				and area.active_type == HITBOX.GUARD) \
			or (active_type == HITBOX.GUARD
				and area.active_type == HITBOX.STRIKE):
		emit_signal('win_collision', area.fighter)


func win_collision(other_fighter):
	# Inject win-effect data into opposing fighter.
	# ACTION INJECTION
	if win_effect_out_animator \
			and win_effect_out_action:
		var anim = get_node(win_effect_out_animator)
		
		# Search for character-specific variant of action.
		var alt_action \
			= win_effect_out_action + ' ' + other_fighter.name
		if anim.has_animation(alt_action):
			other_fighter.call_deferred \
				('inject_action', anim, alt_action)
		else:
			other_fighter.call_deferred \
				('inject_action', anim, win_effect_out_action)
		
		# Link both fighters for concerted actions.
		if win_effect_out_attach_fighter \
				and fighter.hinge:
			var fighter_parent = other_fighter.get_node('..')
			fighter_parent.remove_child(other_fighter)
			
			fighter.hinge.call_deferred('add_child', other_fighter)
			other_fighter.set_to_origin()
	
	# STUN/EFFECT APPLICATION
	# This is applied after action-injection in case the action was
	# meant to alter the Fighter's active set of prescribed effects.
	if win_effect_out_type:
		# Calculate which hitstun to apply and call `advance(0)`.
		pass
	
	# IMPOSE HIT-STOP
	# This is applied after stuns/effects in case of things like a
	# stun having a variable amount of duration.
	other_fighter.reactions_countdown = win_effect_out_induce_countdown
	other_fighter.countdown = win_effect_out_countdown
	
	if win_effect_out_apply_velocity \
			and other_fighter is RigidBody2D:
		var flip = Vector2.ONE
		if fighter.pivot:
			flip = fighter.pivot.scale
		other_fighter.linear_velocity = win_effect_out_velocity * flip
	
	# LOCAL EFFECT DATA INJECTION
	if fighter:
		if win_effect_local_animator \
				and win_effect_local_action:
			var anim = get_node(win_effect_local_animator)
			# Search for character-specific variant of action.
			var alt_action \
				= win_effect_local_action + ' ' + other_fighter.name
			if anim.has_animation(alt_action):
				fighter.call_deferred \
					('inject_action', anim, alt_action)
			else:
				fighter.call_deferred \
					('inject_action', anim, win_effect_local_action)
		
		if win_effect_out_type:
			# Calculate which hitstun to apply and call `advance(0)`.
			pass
		
		fighter.reactions_countdown = win_effect_local_induce_countdown
		fighter.countdown = win_effect_local_countdown
