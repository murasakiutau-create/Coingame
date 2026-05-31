extends AnimatableBody3D
## 往復するプッシャー板。前後（Z方向）に正弦運動して盤面のコイン・アイテムを押し出す。
## AnimatableBody3D なので position を動かすだけで RigidBody3D を物理的に押せる。

@export var stroke: float = 1.4   ## 前後の振れ幅（片側）
@export var speed: float = 1.2    ## 往復の速さ

var _base_z: float = 0.0
var _t: float = 0.0

func _ready() -> void:
	sync_to_physics = true
	_base_z = position.z

func _physics_process(delta: float) -> void:
	_t += delta * speed
	position.z = _base_z + sin(_t) * stroke
