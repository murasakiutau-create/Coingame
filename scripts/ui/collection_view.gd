extends Control
## 図鑑画面。全アイテムをカテゴリごとに一覧表示。
## 未取得はシルエット（？？？）、取得済みは名前・レアリティ・説明を表示。

var _list: VBoxContainer

func _ready() -> void:
	_build()

func _build() -> void:
	# 背景の薄暗い幕
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
	title.text = "📖 図鑑"
	title.add_theme_font_size_override("font_size", 28)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	var close := Button.new()
	close.text = "✕ 閉じる"
	close.pressed.connect(func(): visible = false)
	header.add_child(close)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.custom_minimum_size = Vector2(0, 470)
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

	for cat in ItemDatabase.CATEGORIES:
		var meta: Dictionary = ItemDatabase.CATEGORIES[cat]
		var items := ItemDatabase.items_in_category(cat)
		var owned := 0
		for it in items:
			if GameManager.is_registered(it.id):
				owned += 1

		var head := Label.new()
		head.text = "■ %s  （%d / %d）" % [meta["label"], owned, items.size()]
		head.add_theme_font_size_override("font_size", 20)
		_list.add_child(head)

		for it in items:
			_list.add_child(_make_row(it))

func _make_row(it: ItemData) -> Control:
	var row := Label.new()
	if GameManager.is_registered(it.id):
		var col: Color = ItemDatabase.RARITY_COLOR.get(it.rarity, Color.WHITE)
		row.add_theme_color_override("font_color", col)
		row.text = "  ◆ %s（%s）— %s" % [it.item_name, _rarity_jp(it.rarity), it.flavor_text]
	else:
		row.add_theme_color_override("font_color", Color(0.45, 0.45, 0.45))
		row.text = "  ◇ ？？？"
	return row

func _rarity_jp(r: String) -> String:
	match r:
		"common": return "★"
		"uncommon": return "★★"
		"rare": return "★★★"
		"epic": return "★★★★"
	return r
