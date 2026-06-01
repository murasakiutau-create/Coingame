extends RigidBody3D
## 盤面に落とす物理コイン。回収エリアに入ると所持コインが増える。

func _ready() -> void:
	add_to_group("coin")

## コイン（半径r・厚みh・色c）を一体まるごとコードで生成して返すヘルパー。
static func create(radius: float = 0.35, height: float = 0.08) -> RigidBody3D:
	var body := RigidBody3D.new()
	body.set_script(load("res://scripts/coin.gd"))
	body.mass = 0.2

	var mesh := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = radius
	cyl.bottom_radius = radius
	cyl.height = height
	mesh.mesh = cyl
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.95, 0.78, 0.25)
	mat.metallic = 0.8
	mat.roughness = 0.3
	mesh.material_override = mat
	body.add_child(mesh)

	var shape := CollisionShape3D.new()
	var cyl_shape := CylinderShape3D.new()
	cyl_shape.radius = radius
	cyl_shape.height = height
	shape.shape = cyl_shape
	body.add_child(shape)

	# コインは円盤の面を上下に向けて平らに寝かせる（メダルが床に伏せた状態）。
	# CylinderMesh は既定で軸がY＝面が上下なので、回転は不要。
	return body
