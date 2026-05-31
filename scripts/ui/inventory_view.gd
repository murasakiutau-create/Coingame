extends Control
## インベントリ画面。所持アイテムを一覧表示し、単体換金・重複一括換金ができる。

var _list: VBoxContainer

func _ready() -> void:
	_build()
	EventBus.inventory_changed.connect(_on_inventory_changed)

func _on_inventory_changed() -> void:
	if visible:
		refresh()

func _build() -> void:
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.6)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)

	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.custom_minimum_size = Vector2(520, 560)
	panel.position = Vector2(-260, -280)
	add_child(panel)

	var margin := MarginContainer.new()
	for m in ["margin_left", "margin_right", "margin_top", "margin_bottom"]:
		margin.add_theme_constant_override(m, 16)
	panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	margin.add_child(vbox)

	var header := HBoxContainer.new()
	vbox.add_child(header)
	var title := Label.new()
	title.text = "🎒 インベントリ"
	title.add_theme_font_size_override("font_size", 28)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	var close := Button.new()
	close.text = "✕ 閉じる"
	close.pressed.connect(func(): visible = false)
	header.add_child(close)

	var sell_all := Button.new()
	sell_all.text = "重複アイテムをすべて換金（登録済みのみ）"
	sell_all.pressed.connect(_on_sell_all)
	vbox.add_child(sell_all)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.custom_minimum_size = Vector2(0, 440)
	vbox.add_child(scroll)

	_list = VBoxContainer.new()
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list.add_theme_constant_override("separation", 4)
	scroll.add_child(_list)

func refresh() -> void:
	if _list == null:
		return
	for c in _list.get_children():
		c.queue_free()

	if GameManager.inventory.is_empty():
		var empty := Label.new()
		empty.text = "まだ何も持っていません。コインを投下して集めよう！"
		_list.add_child(empty)
		return

	for id in GameManager.inventory:
		var data: ItemData = ItemDatabase.get_item(id)
		if data == null:
			continue
		_list.add_child(_make_row(data, int(GameManager.inventory[id])))

func _make_row(data: ItemData, count: int) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)

	var swatch := ColorRect.new()
	swatch.color = data.color
	swatch.custom_minimum_size = Vector2(24, 24)
	row.add_child(swatch)

	var label := Label.new()
	label.text = "%s  x%d  （%dコイン/個）" % [data.item_name, count, data.sell_price]
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(label)

	var sell_one := Button.new()
	sell_one.text = "換金"
	sell_one.pressed.connect(func(): GameManager.sell_item(data.id, 1))
	row.add_child(sell_one)

	return row

func _on_sell_all() -> void:
	GameManager.sell_all_duplicates()
	refresh()
