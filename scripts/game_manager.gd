extends Node
## ゲーム全体の状態管理（Autoload）。
## 所持コイン・インベントリ・図鑑の単一の真実の源。セーブ/ロードも担当。

const SAVE_PATH := "user://save.json"
const START_COINS := 20

var coins: int = START_COINS
var inventory: Dictionary = {}   ## item_id -> 所持数(int)
var collection: Dictionary = {}  ## item_id -> { "date": String }

## 図鑑達成報酬の支払い済みしきい値（0.1, 0.25, ... を記録して二重支給を防ぐ）
var _rewards_paid: Array = []
const COLLECTION_REWARDS := [
	{"ratio": 0.10, "coins": 30},
	{"ratio": 0.25, "coins": 100},
	{"ratio": 0.50, "coins": 0},    # 特別アイテム出現率UP（プロト未実装）
	{"ratio": 0.75, "coins": 500},
	{"ratio": 1.00, "coins": 0},    # 称号（プロト未実装）
]

func _ready() -> void:
	load_game()
	# 初期値をUIへ反映
	EventBus.coins_changed.emit(coins)
	EventBus.collection_progress.emit(collection_ratio())

# ---------------------------------------------------------------- コイン

func add_coin(amount: int = 1) -> void:
	coins += amount
	EventBus.coins_changed.emit(coins)

## コインを消費できるなら消費して true。足りなければ false。
func spend_coin(amount: int = 1) -> bool:
	if coins < amount:
		return false
	coins -= amount
	EventBus.coins_changed.emit(coins)
	return true

# ---------------------------------------------------------------- アイテム

func collect_item(data: ItemData) -> void:
	inventory[data.id] = int(inventory.get(data.id, 0)) + 1
	EventBus.item_collected.emit(data)

	var is_new := not collection.has(data.id)
	if is_new:
		collection[data.id] = {"date": Time.get_date_string_from_system()}
		EventBus.new_item_registered.emit(data)
		EventBus.collection_progress.emit(collection_ratio())
		_check_collection_rewards()

	EventBus.inventory_changed.emit()
	save_game()

## アイテムを換金する。成功したら換金額を返す（失敗時 0）。
func sell_item(item_id: String, count: int = 1) -> int:
	var have := int(inventory.get(item_id, 0))
	if have < count:
		return 0
	var data: ItemData = ItemDatabase.get_item(item_id)
	if data == null:
		return 0
	inventory[item_id] = have - count
	if inventory[item_id] <= 0:
		inventory.erase(item_id)
	var gained := data.sell_price * count
	add_coin(gained)
	EventBus.inventory_changed.emit()
	save_game()
	return gained

## 重複（2個目以降）をすべて換金する。図鑑登録済みでも1個は手元に残す。
## 未登録アイテムは安全のため除外（誤操作防止）。返り値は得たコイン総額。
func sell_all_duplicates() -> int:
	var total := 0
	for id in inventory.keys().duplicate():
		if not collection.has(id):
			continue  # 未登録は除外
		var have := int(inventory[id])
		if have > 1:
			total += sell_item(id, have - 1)
	return total

func inventory_count(item_id: String) -> int:
	return int(inventory.get(item_id, 0))

# ---------------------------------------------------------------- 図鑑

func is_registered(item_id: String) -> bool:
	return collection.has(item_id)

func collected_count() -> int:
	return collection.size()

func collection_ratio() -> float:
	var total := ItemDatabase.total_count()
	if total == 0:
		return 0.0
	return float(collection.size()) / float(total)

func _check_collection_rewards() -> void:
	var ratio := collection_ratio()
	for reward in COLLECTION_REWARDS:
		var key: float = reward["ratio"]
		if ratio >= key and not _rewards_paid.has(key):
			_rewards_paid.append(key)
			if reward["coins"] > 0:
				add_coin(reward["coins"])

# ---------------------------------------------------------------- セーブ/ロード

func save_game() -> void:
	var data := {
		"coins": coins,
		"inventory": inventory,
		"collection": collection,
		"rewards_paid": _rewards_paid,
	}
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(data))
		f.close()

func load_game() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f == null:
		return
	var text := f.get_as_text()
	f.close()
	var parsed = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		return
	coins = int(parsed.get("coins", START_COINS))
	inventory = parsed.get("inventory", {})
	collection = parsed.get("collection", {})
	_rewards_paid = parsed.get("rewards_paid", [])

## デバッグ用：セーブを消して最初から
func reset_game() -> void:
	coins = START_COINS
	inventory = {}
	collection = {}
	_rewards_paid = []
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)
	EventBus.coins_changed.emit(coins)
	EventBus.inventory_changed.emit()
	EventBus.collection_progress.emit(collection_ratio())
