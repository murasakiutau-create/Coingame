extends Control
## 画面上のHUD。所持コイン表示・投下ボタン・図鑑/インベントリを開くボタン・
## 新規取得ポップアップをコードで構築する。

signal drop_pressed

var _coin_label: Label
var _progress_label: Label
var _popup: PanelContainer
var _popup_label: RichTextLabel
var _popup_timer: Timer

var _collection_view: Control
var _inventory_view: Control

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build_top_bar()
	_build_drop_button()
	_build_popup()
	_build_sub_views()

	EventBus.coins_changed.connect(_on_coins_changed)
	EventBus.collection_progress.connect(_on_progress_changed)
	EventBus.new_item_registered.connect(_on_new_item)

	_on_coins_changed(GameManager.coins)
	_on_progress_changed(GameManager.collection_ratio())

# ---------------------------------------------------------------- 上部バー

func _build_top_bar() -> void:
	var left := VBoxContainer.new()
	left.position = Vector2(20, 18)
	add_child(left)

	_coin_label = Label.new()
	_coin_label.add_theme_font_size_override("font_size", 34)
	left.add_child(_coin_label)

	_progress_label = Label.new()
	_progress_label.add_theme_font_size_override("font_size", 18)
	left.add_child(_progress_label)

	# 右上のボタン群
	var right := HBoxContainer.new()
	right.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	right.position = Vector2(-260, 20)
	right.add_theme_constant_override("separation", 10)
	add_child(right)

	var col_btn := Button.new()
	col_btn.text = "図鑑"
	col_btn.custom_minimum_size = Vector2(110, 44)
	col_btn.pressed.connect(func(): _toggle(_collection_view))
	right.add_child(col_btn)

	var inv_btn := Button.new()
	inv_btn.text = "インベントリ"
	inv_btn.custom_minimum_size = Vector2(130, 44)
	inv_btn.pressed.connect(func(): _toggle(_inventory_view))
	right.add_child(inv_btn)

# ---------------------------------------------------------------- 投下ボタン

func _build_drop_button() -> void:
	var wrap := VBoxContainer.new()
	wrap.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	wrap.position = Vector2(-90, -110)
	wrap.alignment = BoxContainer.ALIGNMENT_CENTER
	add_child(wrap)

	var drop := Button.new()
	drop.text = "コインを投下"
	drop.custom_minimum_size = Vector2(180, 64)
	drop.add_theme_font_size_override("font_size", 24)
	drop.pressed.connect(func(): drop_pressed.emit())
	wrap.add_child(drop)

	var hint := Label.new()
	hint.text = "（マウスで狙う / ←→で移動 / クリック・スペースで投下）"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 14)
	wrap.add_child(hint)

# ---------------------------------------------------------------- 新規取得ポップアップ

func _build_popup() -> void:
	_popup = PanelContainer.new()
	_popup.set_anchors_preset(Control.PRESET_CENTER)
	_popup.position = Vector2(-180, -160)
	_popup.custom_minimum_size = Vector2(360, 0)
	_popup.visible = false
	add_child(_popup)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_top", 14)
	margin.add_theme_constant_override("margin_bottom", 14)
	_popup.add_child(margin)

	_popup_label = RichTextLabel.new()
	_popup_label.bbcode_enabled = true
	_popup_label.fit_content = true
	_popup_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	margin.add_child(_popup_label)

	_popup_timer = Timer.new()
	_popup_timer.one_shot = true
	_popup_timer.wait_time = 2.8
	_popup_timer.timeout.connect(func(): _popup.visible = false)
	add_child(_popup_timer)

func _on_new_item(data: ItemData) -> void:
	var col: Color = ItemDatabase.RARITY_COLOR.get(data.rarity, Color.WHITE)
	var hex := col.to_html(false)
	_popup_label.text = "[center][b]✨ 図鑑に新規登録！ ✨[/b]\n[color=#%s][font_size=26]%s[/font_size][/color]\n[i]%s[/i][/center]" % [hex, data.item_name, data.flavor_text]
	_popup.visible = true
	_popup_timer.start()

# ---------------------------------------------------------------- サブ画面

func _build_sub_views() -> void:
	_collection_view = Control.new()
	_collection_view.set_script(load("res://scripts/ui/collection_view.gd"))
	_collection_view.set_anchors_preset(Control.PRESET_FULL_RECT)
	_collection_view.visible = false
	add_child(_collection_view)

	_inventory_view = Control.new()
	_inventory_view.set_script(load("res://scripts/ui/inventory_view.gd"))
	_inventory_view.set_anchors_preset(Control.PRESET_FULL_RECT)
	_inventory_view.visible = false
	add_child(_inventory_view)

func _toggle(view: Control) -> void:
	var show_it := not view.visible
	# 片方を開いたらもう片方は閉じる
	_collection_view.visible = false
	_inventory_view.visible = false
	view.visible = show_it
	if show_it and view.has_method("refresh"):
		view.refresh()

# ---------------------------------------------------------------- 更新

func _on_coins_changed(total: int) -> void:
	_coin_label.text = "🪙 %d" % total

func _on_progress_changed(_ratio: float) -> void:
	var done := GameManager.collected_count()
	var total := ItemDatabase.total_count()
	var pct := 0
	if total > 0:
		pct = int(round(float(done) / float(total) * 100.0))
	_progress_label.text = "図鑑 %d / %d （%d%%）" % [done, total, pct]
