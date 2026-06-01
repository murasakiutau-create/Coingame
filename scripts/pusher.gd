extends AnimatableBody3D
## 奥から手前へ「引き出しのように」スライドして出てくるプッシャー。
## 盤面の奥側を占める大きな板で、手前のコインの山ごと押し出す。
## AnimatableBody3D なので position を動かすだけで RigidBody3D を物理的に押せる。

@export var stroke: float = 1.6   ## 手前へ出てくる距離（引き出しの伸び）
@export var speed: float = 1.2    ## 往復の速さ

var _base_z: float = 0.0          ## 引っ込んでいる時のZ（奥側のホーム位置）
var _t: float = 0.0

func _ready() -> void:
	sync_to_physics = true
	_base_z = position.z

func _physics_process(delta: float) -> void:
	_t += delta * speed
	# (1 - cos)/2 は 0→1→0 を滑らかに動く。常に手前(+Z)へ出て、奥へ戻る。
	# 引き出しが「にゅいん」と出て、また引っ込む動き。
	var phase := (1.0 - cos(_t)) * 0.5
	position.z = _base_z + phase * stroke
