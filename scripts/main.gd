extends Node3D
## ゲームのメインシーン。盤面・カメラ・ライト・UIをコードで構築し、
## コイン投下とアイテム自動出現を管理する。
##
## ※ Godotエディタが無い環境で作っているため、シーンツリーをコードで組んでいる。
##   エディタで開けば各ノードはシーンドック上にも現れるので、後から視覚編集も可能。

const COIN_SCRIPT := preload("res://scripts/coin.gd")
const ITEM_SCRIPT := preload("res://scripts/item.gd")

# 盤面の寸法（おおよそ）
const DECK_TOP_Y := 0.0
const ITEM_SPAWN_INTERVAL := 5.0   ## アイテム自動出現の間隔（秒）
const MAX_ITEMS_ON_BOARD := 8      ## 盤面に出すアイテムの上限

var _dynamic_root: Node3D           ## コイン/アイテムをぶら下げる親
var _item_timer: Timer

func _ready() -> void:
	_build_environment()
	_build_stage()
	_build_dynamic_root()
	_build_ui()
	_start_item_spawner()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("drop_coin"):
		drop_coin()

# ---------------------------------------------------------------- 環境

func _build_environment() -> void:
	var cam := Camera3D.new()
	cam.position = Vector3(0, 7.0, 8.5)
	cam.fov = 55
	add_child(cam)
	# look_at はツリーに入った後に呼ぶ（グローバル変換が必要なため）
	cam.look_at(Vector3(0, 0, -1.0), Vector3.UP)

	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-55, -35, 0)
	light.light_energy = 1.1
	light.shadow_enabled = true
	add_child(light)

	var world_env := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.12, 0.13, 0.18)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.4, 0.42, 0.5)
	env.ambient_light_energy = 1.0
	world_env.environment = env
	add_child(world_env)

# ---------------------------------------------------------------- 盤面

func _build_stage() -> void:
	# 床（デッキ）：上面が y=0
	_make_static_box(Vector3(6, 0.5, 7), Vector3(0, -0.25, -1.5), Color(0.25, 0.27, 0.33))
	# 左右の壁
	_make_static_box(Vector3(0.5, 2, 7), Vector3(-3.25, 0.75, -1.5), Color(0.2, 0.22, 0.28))
	_make_static_box(Vector3(0.5, 2, 7), Vector3(3.25, 0.75, -1.5), Color(0.2, 0.22, 0.28))
	# 奥の壁
	_make_static_box(Vector3(6.5, 2, 0.5), Vector3(0, 0.75, -5.25), Color(0.2, 0.22, 0.28))

	# プッシャー板（往復）
	var pusher := AnimatableBody3D.new()
	pusher.set_script(load("res://scripts/pusher.gd"))
	pusher.position = Vector3(0, 0.5, -3.0)
	var pmesh := MeshInstance3D.new()
	var pbox := BoxMesh.new()
	pbox.size = Vector3(5.6, 1.0, 1.6)
	pmesh.mesh = pbox
	var pmat := StandardMaterial3D.new()
	pmat.albedo_color = Color(0.85, 0.4, 0.3)
	pmesh.material_override = pmat
	pusher.add_child(pmesh)
	var pcol := CollisionShape3D.new()
	var pshape := BoxShape3D.new()
	pshape.size = Vector3(5.6, 1.0, 1.6)
	pcol.shape = pshape
	pusher.add_child(pcol)
	add_child(pusher)

	# 回収エリア（手前下）：盤面の前端 z=2 から「落ちた」ものだけを受ける。
	# デッキ上面(y=0)より十分下・前端より手前に置き、デッキ上のコインを誤回収しない。
	var collect := Area3D.new()
	collect.set_script(load("res://scripts/collect_area.gd"))
	collect.position = Vector3(0, -2.0, 4.0)
	var acol := CollisionShape3D.new()
	var ashape := BoxShape3D.new()
	ashape.size = Vector3(8, 3, 4)
	acol.shape = ashape
	collect.add_child(acol)
	add_child(collect)

func _make_static_box(size: Vector3, pos: Vector3, color: Color) -> void:
	var body := StaticBody3D.new()
	body.position = pos
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mesh.mesh = box
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mesh.material_override = mat
	body.add_child(mesh)
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	col.shape = shape
	body.add_child(col)
	add_child(body)

func _build_dynamic_root() -> void:
	_dynamic_root = Node3D.new()
	_dynamic_root.name = "Dynamic"
	add_child(_dynamic_root)

# ---------------------------------------------------------------- 投下/出現

## コインを1枚投下する。所持コインを1消費する。
func drop_coin() -> void:
	if not GameManager.spend_coin(1):
		return
	var coin := COIN_SCRIPT.create()
	coin.position = Vector3(randf_range(-2.2, 2.2), 4.5, -2.6)
	_dynamic_root.add_child(coin)

func _start_item_spawner() -> void:
	_item_timer = Timer.new()
	_item_timer.wait_time = ITEM_SPAWN_INTERVAL
	_item_timer.autostart = true
	_item_timer.timeout.connect(_on_item_timer)
	add_child(_item_timer)

func _on_item_timer() -> void:
	if _count_items() >= MAX_ITEMS_ON_BOARD:
		return
	var data := ItemDatabase.random_item()
	if data == null:
		return
	var item := ITEM_SCRIPT.create(data)
	item.position = Vector3(randf_range(-2.0, 2.0), 4.5, -3.2)
	_dynamic_root.add_child(item)

func _count_items() -> int:
	var n := 0
	for c in _dynamic_root.get_children():
		if c.is_in_group("item"):
			n += 1
	return n

# ---------------------------------------------------------------- UI

func _build_ui() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var hud := Control.new()
	hud.set_script(load("res://scripts/ui/hud.gd"))
	hud.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(hud)
	hud.drop_pressed.connect(drop_coin)
