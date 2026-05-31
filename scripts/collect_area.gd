extends Area3D
## 盤面の手前下に置く回収エリア。
## 落ちてきたコイン → 所持コイン+1、アイテム → 図鑑/インベントリへ登録。

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("coin"):
		GameManager.add_coin(1)
		body.queue_free()
	elif body.is_in_group("item"):
		var data: ItemData = body.item_data
		if data != null:
			GameManager.collect_item(data)
		body.queue_free()
