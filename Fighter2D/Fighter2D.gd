tool
extends Fighter
class_name Fighter2D


export(NodePath) var target_node
var target

export(bool) var track_target = false

var pivot : Node2D
var collider_nodes = []
var colliders = []

var reset_displacement = false
var displacement = Vector2()
var analog_displacement = Vector2()
var analog_strength = Vector2()

var weight = 0.0

var gravity_delay = 0.0
var gravity_delay_tracker = 0.0
var gravity_parabola = 1.0
var max_fall_speed = 10.0

var force = Vector2.ZERO

var launch = Vector2.ZERO

var body : KinematicBody2D


func get_class():
	return 'HitboxFighter2D'


func _get_property_list():
	return _property_list() + [
		{
			name = 'Physical Properties',
			type = TYPE_NIL,
			usage = PROPERTY_USAGE_CATEGORY
		},
		{
			name = 'bodies',
			type = TYPE_NIL,
			usage = PROPERTY_USAGE_GROUP
		},
		{
			name = 'pivot_node',
			type = TYPE_NODE_PATH,
			usage = PROPERTY_USAGE_ANIMATE_DEFAULT
		},
		{
			name = 'collider_nodes',
			type = TYPE_ARRAY,
			usage = PROPERTY_USAGE_ANIMATE_DEFAULT
		},
		{
			name = 'displacement',
			type = TYPE_NIL,
			usage = PROPERTY_USAGE_GROUP
		},
		{
			name = 'displacement',
			type = TYPE_VECTOR2,
			usage = PROPERTY_USAGE_ANIMATE_DEFAULT,
		},
		{
			name = 'analog_displacement',
			type = TYPE_VECTOR2,
			usage = PROPERTY_USAGE_ANIMATE_DEFAULT,
		},
		{
			name = 'physics',
			type = TYPE_NIL,
			usage = PROPERTY_USAGE_GROUP
		},
		{
			name = 'weight',
			type = TYPE_REAL,
			hint = PROPERTY_HINT_RANGE,
			hint_string = '0,5000,.1,or_greater',
			usage = PROPERTY_USAGE_ANIMATE_DEFAULT
		},
		{
			name = 'gravity_delay',
			type = TYPE_REAL,
			hint = PROPERTY_HINT_RANGE,
			hint_string = '0,5,.001,or_greater',
			usage = PROPERTY_USAGE_ANIMATE_DEFAULT
		},
		{
			name = 'gravity_parabola',
			type = TYPE_REAL,
			hint = PROPERTY_HINT_RANGE,
			hint_string = '.001,20,.001,or_greater',
			usage = PROPERTY_USAGE_ANIMATE_DEFAULT
		},
		{
			name = 'max_fall_speed',
			type = TYPE_REAL,
			hint = PROPERTY_HINT_RANGE,
			hint_string = '0,1000,.1,or_greater',
			usage = PROPERTY_USAGE_ANIMATE_DEFAULT
		}
	]


func _ready():
	# "Multiple inheritance"-trick taken from takaturre:
	# https://godotengine.org/qa/10442
	#	/tricks-extending-gdscript-between-different-extended-classes
	#	?show=74754#c74754
	var _self = self
	if _self is KinematicBody2D:
		body = _self
	
	if Engine.editor_hint:
		return
	
	if target_node:
		target = get_node(target_node)
	
	if pivot_node:
		pivot = get_node(pivot_node)
	
	for n in collider_nodes:
		colliders.push_back(get_node(n))


func reset_properties():
	.reset_properties()
	
	track_target = false
	
	for cn in collider_nodes:
		var n = get_node(cn)
		
		n.position = Vector2.ZERO
		n.rotation_degrees = 0
		n.scale = Vector2.ONE
		n.visible = false
		
		# Reset direct children shapes.
		if n is CollisionShape2D:
			n.disabled = true
			
			if n.shape is RectangleShape2D:
				n.shape.extents = Vector2.ZERO
			elif n.shape is CircleShape2D:
				n.shape.radius = 0
		
		# Reset hitboxes attached to limbs.
		for c in n.get_children():
			if c is Hitbox2D:
				c.reset()
			elif c is CollisionShape2D:
				c.disabled = true
				if c.shape is RectangleShape2D:
					c.shape.extents = Vector2.ZERO
				elif c.shape is CircleShape2D:
					c.shape.radius = 0
	
	if reset_displacement \
			or Engine.editor_hint:
		displacement = Vector2.ZERO
	analog_displacement = Vector2.ZERO


func release_hinge():
	for c in hinge.get_children():
	#	c.position += body.position + hinge.position
		var t = c.get_global_transform()
		hinge.remove_child(c)
		$'..'.add_child(c)
		c.global_transform = t


func set_to_origin():
	if body:
		body.position = Vector2.ZERO
	else:
		self.position = Vector2.ZERO


func reset_position(_anim_name = '', animator : AnimationPlayer = null):
	if animator:
		current_player = animator
	body.position = Vector2.ZERO


var _cap = 0


func _process(delta):
	# Orient towards target.
	if track_target and target:
		if target is RigidBody2D:
			if target.position.x < body.position.x:
				pivot.scale.x = -1
			else:
				pivot.scale.x = 1
	
	# Apply displacements.
	if current_player \
			&& current_player.current_animation:
		# Reset position of Fighter2D if loop-testing animations
		# within the editor.
		if Engine.editor_hint:
			if current_player.current_animation_position < _cap:
				reset_position()
			_cap = current_player.current_animation_position
		
		if body:
			var d = displacement
			if pivot:
				d *= Vector2(sign(pivot.scale.x), sign(pivot.scale.y))
			# warning-ignore:return_value_discarded
			body.move_and_slide(d, Vector2.UP)
			
			if not Engine.editor_hint:
				var a = _analog_movement()
				# warning-ignore:return_value_discarded
				body.move_and_slide(analog_displacement * a, Vector2.UP)
	
	if suspend_ > 0:
		suspend_ -= 1
		if suspend_ <= 0:
			pass
	
	# Apply gravity.
	if !Engine.editor_hint and weight and body:
		gravity_delay_tracker += delta
		if gravity_delay_tracker > gravity_delay:
			force.y += weight * delta * gravity_parabola
			if force.y > max_fall_speed:
				force.y = max_fall_speed
		
		# warning-ignore:return_value_discarded
		body.move_and_slide(force, Vector2.UP)
		
		if body.is_on_floor():
			force.y = 0
			gravity_delay_tracker = 0


func _analog_movement():
	return Vector2(
		Input.get_action_strength('1_right')
			- Input.get_action_strength('1_left'),
		Input.get_action_strength('1_up')
			- Input.get_action_strength('1_down'))


func apply_force(f : Vector2, apply_pivot : bool = false):
	if apply_pivot and pivot:
		f *= pivot.scale
	force = f


func throw_apply_velocity(velocity : Vector2):
	for c in hinge.get_children():
		if c is RigidBody2D:
			c.linear_velocity = velocity
			c.linear_velocity.x *= sign(pivot.scale.x)
