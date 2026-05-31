extends RigidBody3D
## 盤面に出現する物理アイテム。回収エリアに入ると図鑑/インベントリへ。
## item_data に対応する ItemData を持つ。

var item_data: ItemData

func _ready() -> void:
	add_to_group("item")

## ItemData から物理アイテムを生成するヘルパー。
## アイコン画像が無いので、今はレアリティ色付きの箱で表現する。
static func create(data: ItemData) -> RigidBody3D:
	var body := RigidBody3D.new()
	body.set_script(load("res://scripts/item.gd"))
	body.item_data = data
	body.mass = 0.3

	var size := 0.55
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(size, size, size)
	mesh.mesh = box
	var mat := StandardMaterial3D.new()
	mat.albedo_color = data.color
	mat.roughness = 0.5
	# Epic はほんのり光らせる（企画書の「光るエフェクト」の簡易版）
	if data.rarity == "epic":
		mat.emission_enabled = true
		mat.emission = data.color
		mat.emission_energy_multiplier = 0.6
	mesh.material_override = mat
	body.add_child(mesh)

	var shape := CollisionShape3D.new()
	var box_shape := BoxShape3D.new()
	box_shape.size = Vector3(size, size, size)
	shape.shape = box_shape
	body.add_child(shape)
	return body
