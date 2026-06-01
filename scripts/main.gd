extends Node3D
## ゲームのメインシーン。盤面・カメラ・ライト・UIをコードで構築し、
## コイン投下とアイテム出現を管理する。
##
## ※ Godotエディタが無い環境で作ったため、シーンツリーをコードで組んでいる。
##   エディタで開けば各ノードはシーンドックにも現れるので、後から視覚編集も可能。

const COIN_SCRIPT := preload("res://scripts/coin.gd")
const ITEM_SCRIPT := preload("res://scripts/item.gd")

# --- 盤面・ゲームのパラメータ（手触りはここを調整） ---
const DROP_Z := -0.6           ## コインを落とすZ位置（奥の板の手前＝山の後ろに乗る）
const DROP_Y := 4.0            ## コインを落とす高さ
const DROP_X_RANGE := 2.5      ## 落下位置を左右に動かせる範囲
const AIM_SPEED := 5.0         ## ←→キーで狙いを動かす速さ
const COINS_PER_ITEM := 10     ## コインを何枚入れたらアイテムが1個出るか
const MAX_ITEMS_ON_BOARD := 8  ## 盤面に出すアイテムの上限

var _camera: Camera3D
var _dynamic_root: Node3D       ## コイン/アイテムをぶら下げる親
var _indicator: Node3D          ## 落下位置マーカー
var _drop_x := 0.0              ## 現在の落下X位置
var _coins_dropped := 0         ## これまでに投入したコイン総数

func _ready() -> void:
	_build_environment()
	_build_stage()
	_build_dynamic_root()
	_build_indicator()
	_build_ui()
	_preplace_coins()

func _process(delta: float) -> void:
	# ←→（またはA/D）で落下位置を動かす
	var axis := Input.get_axis("ui_left", "ui_right")
	if axis != 0.0:
		_drop_x = clampf(_drop_x + axis * AIM_SPEED * delta, -DROP_X_RANGE, DROP_X_RANGE)
	if _indicator:
		_indicator.position.x = _drop_x

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		_aim_with_mouse(event.position)
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		drop_coin()
	elif event.is_action_pressed("drop_coin"):
		drop_coin()

## マウス位置を落下高さの平面に投影して、落下X位置を決める
func _aim_with_mouse(screen_pos: Vector2) -> void:
	if _camera == null:
		return
	var origin := _camera.project_ray_origin(screen_pos)
	var dir := _camera.project_ray_normal(screen_pos)
	var plane := Plane(Vector3.UP, DROP_Y)
	var hit = plane.intersects_ray(origin, dir)
	if hit != null:
		_drop_x = clampf(hit.x, -DROP_X_RANGE, DROP_X_RANGE)

# ---------------------------------------------------------------- 環境

func _build_environment() -> void:
	_camera = Camera3D.new()
	_camera.position = Vector3(0, 6.5, 7.5)
	_camera.fov = 58
	add_child(_camera)
	# look_at はツリーに入った後に呼ぶ（グローバル変換が必要なため）
	_camera.look_at(Vector3(0, 0, -1.5), Vector3.UP)

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
	# 床（デッキ）：上面が y=0、奥 z=-4 〜 手前の前端 z=1.2
	_make_static_box(Vector3(6, 0.5, 5.2), Vector3(0, -0.25, -1.4), Color(0.25, 0.27, 0.33))
	# 奥の壁（ここで完全に塞ぐので、コインが奥へ落ちることはない）
	_make_static_box(Vector3(6.5, 2, 0.5), Vector3(0, 0.75, -4.25), Color(0.2, 0.22, 0.28))
	# 左右の壁
	_make_static_box(Vector3(0.5, 2, 5.2), Vector3(-3.25, 0.75, -1.4), Color(0.2, 0.22, 0.28))
	_make_static_box(Vector3(0.5, 2, 5.2), Vector3(3.25, 0.75, -1.4), Color(0.2, 0.22, 0.28))

	# プッシャー（奥側を占める大きな板）。引き出しのように手前へスライドして、
	# 手前にあるコインの山ごと押し出す。板の長さを十分とり、奥にコインが
	# 取り残されない（板の後ろに回り込めない）ようにする。
	var slab_len := 3.2                         # 奥行き方向の長さ（大きな板）
	var pusher := AnimatableBody3D.new()
	pusher.set_script(load("res://scripts/pusher.gd"))
	# ホーム位置：板の手前端がだいたい z=-1.5 あたりに来るよう、中心を奥へ置く
	pusher.position = Vector3(0, 0.3, -4.0 + slab_len * 0.5)
	pusher.set("stroke", 1.6)
	pusher.set("speed", 1.2)
	var pmesh := MeshInstance3D.new()
	var pbox := BoxMesh.new()
	pbox.size = Vector3(5.6, 0.6, slab_len)     # 幅広・奥行きのある大きな板
	pmesh.mesh = pbox
	var pmat := StandardMaterial3D.new()
	pmat.albedo_color = Color(0.85, 0.45, 0.3)
	pmesh.material_override = pmat
	pusher.add_child(pmesh)
	var pcol := CollisionShape3D.new()
	var pshape := BoxShape3D.new()
	pshape.size = Vector3(5.6, 0.6, slab_len)
	pcol.shape = pshape
	pusher.add_child(pcol)
	add_child(pusher)

	# 回収エリア（手前下）：前端 z=1.2 から「落ちた」ものだけを受ける。
	var collect := Area3D.new()
	collect.set_script(load("res://scripts/collect_area.gd"))
	collect.position = Vector3(0, -2.0, 2.6)
	var acol := CollisionShape3D.new()
	var ashape := BoxShape3D.new()
	ashape.size = Vector3(8, 3, 3)
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

## 落下位置を示すマーカー（下向きの矢印っぽいコーン）
func _build_indicator() -> void:
	_indicator = Node3D.new()
	_indicator.position = Vector3(0, 2.4, DROP_Z)
	var mesh := MeshInstance3D.new()
	var cone := CylinderMesh.new()
	cone.top_radius = 0.0
	cone.bottom_radius = 0.28
	cone.height = 0.6
	mesh.mesh = cone
	mesh.rotation_degrees = Vector3(180, 0, 0)   # 先端を下に向ける
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(1.0, 0.9, 0.2)
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.8, 0.1)
	mat.emission_energy_multiplier = 0.5
	mesh.material_override = mat
	_indicator.add_child(mesh)
	add_child(_indicator)

# ---------------------------------------------------------------- 開始時のコイン配置

## 盤面に最初からコインを敷き詰めておく（メダルゲームのように山がある状態）。
## グリッド状に置き、重なりによる物理の暴れを防ぐ。
func _preplace_coins() -> void:
	var cols := 7
	var rows := 4
	for cx in cols:
		for cz in rows:
			var x := lerpf(-2.4, 2.4, float(cx) / float(cols - 1))
			# 板の手前（z≈-0.7）から前端（z≈1.0）の範囲に敷く。板の奥には置かない。
			var z := lerpf(-0.6, 1.0, float(cz) / float(rows - 1))
			var coin := COIN_SCRIPT.create()
			coin.position = Vector3(
				x + randf_range(-0.08, 0.08),
				0.25,
				z + randf_range(-0.08, 0.08)
			)
			_dynamic_root.add_child(coin)

# ---------------------------------------------------------------- 投下/出現

## コインを1枚、現在の狙い位置に投下する。所持コインを1消費する。
func drop_coin() -> void:
	if not GameManager.spend_coin(1):
		return
	var coin := COIN_SCRIPT.create()
	coin.position = Vector3(_drop_x, DROP_Y, DROP_Z)
	_dynamic_root.add_child(coin)

	_coins_dropped += 1
	# コインを一定枚数入れるごとにアイテムを1個出す
	if _coins_dropped % COINS_PER_ITEM == 0:
		_spawn_item()

func _spawn_item() -> void:
	if _count_items() >= MAX_ITEMS_ON_BOARD:
		return
	var data := ItemDatabase.random_item()
	if data == null:
		return
	var item := ITEM_SCRIPT.create(data)
	item.position = Vector3(randf_range(-DROP_X_RANGE, DROP_X_RANGE), DROP_Y, DROP_Z)
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
