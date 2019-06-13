extends KinematicBody2D

const hole_scn = preload("res://hole.tscn")
const font = preload("res://assets/kenney_thick_dynfont.tres")

const speed_max:float = 400.0
const friction:float = 150.0

var prev_speed:float = 0.0
var speed:float = 0.0
var direction:Vector2 = Vector2()
var active:bool = false
var player_id:int

var preview_length:int = 0
var preview_direction:Vector2 = Vector2()
const preview_length_max:int = 150

onready var level = get_node("../")
onready var level_terrain = get_node("../Terrain")
onready var level_hole = get_node("../Hole")

signal movement_finished

enum COLLISION_TYPE {
		NOTHING = -1,
		HOLE = 0,
		WALL = 1
	}

enum COLLISION_SIDE {
		RIGHT = 0,
		BOTTOM = 1,
		LEFT = 2,
		TOP = 3
	}

func _ready() -> void:
	pass

func _process(delta: float) -> void:
	update_preview(get_global_mouse_position())

func _physics_process(delta: float) -> void:
	move(delta)

#Called from process
func move(delta:float)->void:
	speed = clamp(speed - friction*delta,0,speed_max)
	if(prev_speed > speed && speed <= 0 && global.game.player_get(player_id).playing):
		emit_signal("movement_finished")
	prev_speed = speed
	collision_handle(move_and_collide(direction.normalized() * speed * delta))
	#position += direction.normalized() * speed * delta

#called from move() when colliding
func collision_handle(collision:KinematicCollision2D)->void:
	if(!is_instance_valid(collision)):
		return
	#tilemap collisions
	if(collision.collider is TileMap):
		var tm_pos:Vector2 = level_terrain.world_to_map(collision.position)
		tm_pos += direction.normalized()*0.1
		if(level_terrain.tile_set.tile_get_name(level_terrain.get_cellv(tm_pos)) == "wall"): #check for wall collision
			print(self, "collided with wall")
			#determine side
			var delta:Vector2
			delta.x = position.x - collision.position.x
			delta.y = position.y - collision.position.y
			if(abs(delta.x) > abs(delta.y)):
				direction.x = -direction.x
			else:
				direction.y = -direction.y
			return
	#other ball collision
	#TODO HIER WEITERMACHEN HALLOOOOOOOOOOOOOoo

#Called when clicked (+ player's turn)
#Player shoots the ball
func shoot(mouse_pos:Vector2)->Object:
	assert(active)
	active = false
	speed = clamp(position.distance_to(mouse_pos),0,preview_length_max) * (speed_max/preview_length_max)
	direction = position.direction_to(mouse_pos)
	print("shot ",self," with vel: ", speed*direction)
	return self

#Called when mouse moved (+ player's turn)
#Updates the aim line var's and call's for redraw
#Call with Vector2() as param to hide
func update_preview(mouse_pos:Vector2)->void:
	preview_length = clamp(position.distance_to(mouse_pos),0,preview_length_max) if active else 0
	preview_direction = position.direction_to(mouse_pos)
	update()

func _draw() -> void:
	draw_line(Vector2(),preview_direction*preview_length,ColorN("red"))
	draw_string(font,Vector2(0,-16),global.game.player_get(player_id).nick)

func point_in_rect(point:Vector2, rect:Rect2)->bool:
	return (point.x >= rect.position.x &&point.y >= rect.position.y && point.x <= rect.position.x+rect.size.x && point.y <= rect.position.y+rect.size.y)