extends Node
## 全アイテムのマスターデータ（Autoload）。
## プロトタイプでは各カテゴリ5個＝計25個をコードで定義する。
## 完成版では .tres リソースや外部ファイルに移すこともできる。

## レアリティごとの出現重み（企画書より）
const RARITY_WEIGHTS := {
	"common": 60,
	"uncommon": 25,
	"rare": 12,
	"epic": 3,
}

## レアリティごとの換金額（企画書より）
const RARITY_PRICE := {
	"common": 2,
	"uncommon": 5,
	"rare": 15,
	"epic": 50,
}

## レアリティの枠色（図鑑表示用）
const RARITY_COLOR := {
	"common": Color(0.6, 0.6, 0.6),    # 灰
	"uncommon": Color(0.3, 0.8, 0.3),  # 緑
	"rare": Color(0.3, 0.5, 0.95),     # 青
	"epic": Color(0.95, 0.8, 0.2),     # 金
}

## カテゴリの表示名と目標数（企画書より）
const CATEGORIES := {
	"fantasy": {"label": "ファンタジー", "goal": 30},
	"daily": {"label": "日常雑貨", "goal": 25},
	"food": {"label": "食べ物", "goal": 20},
	"antique": {"label": "骨董・不思議", "goal": 15},
	"nature": {"label": "自然", "goal": 20},
}

var items: Array[ItemData] = []
var _by_id: Dictionary = {}

func _ready() -> void:
	_build_database()

func _build_database() -> void:
	# id, name, category, rarity, flavor, color
	var defs := [
		# --- ファンタジー ---
		["fan_potion", "回復のポーション", "fantasy", "common", "ひと口飲むとほんのり温かい。", Color(0.9, 0.3, 0.4)],
		["fan_book", "古びた魔法書", "fantasy", "uncommon", "ページをめくると埃と呪文が舞う。", Color(0.5, 0.3, 0.7)],
		["fan_sword", "見習いの剣", "fantasy", "uncommon", "刃こぼれしているが、まだ戦える。", Color(0.7, 0.75, 0.8)],
		["fan_ring", "願いの指輪", "fantasy", "rare", "誰かの願いが込められているらしい。", Color(0.85, 0.7, 0.3)],
		["fan_gem", "星屑の宝石", "fantasy", "epic", "夜空を閉じ込めたような輝き。", Color(0.4, 0.8, 0.95)],
		# --- 日常雑貨 ---
		["dly_shoe", "片方だけの靴", "daily", "common", "相棒はどこへ行ったのだろう。", Color(0.55, 0.35, 0.2)],
		["dly_cup", "欠けたマグカップ", "daily", "common", "それでもお気に入りだったらしい。", Color(0.8, 0.8, 0.85)],
		["dly_hat", "つば広の帽子", "daily", "uncommon", "日差しの強い日にどうぞ。", Color(0.6, 0.5, 0.3)],
		["dly_umbrella", "水玉の傘", "daily", "uncommon", "雨の日が少し楽しくなる。", Color(0.3, 0.6, 0.8)],
		["dly_watch", "止まった懐中時計", "daily", "rare", "針は3時15分を指したまま。", Color(0.85, 0.75, 0.4)],
		# --- 食べ物 ---
		["fod_apple", "つやつやのりんご", "food", "common", "かじると小気味よい音がする。", Color(0.85, 0.2, 0.2)],
		["fod_bread", "丸いパン", "food", "common", "焼きたての香りがふわり。", Color(0.8, 0.6, 0.35)],
		["fod_cheese", "穴あきチーズ", "food", "uncommon", "誰かがかじった跡が…？", Color(0.95, 0.85, 0.4)],
		["fod_cake", "苺のショートケーキ", "food", "rare", "特別な日のためのひと切れ。", Color(0.95, 0.7, 0.75)],
		["fod_honey", "黄金の蜂蜜", "food", "epic", "ひと匙で一日中ごきげん。", Color(0.95, 0.75, 0.15)],
		# --- 骨董・不思議 ---
		["ant_map", "色あせた古地図", "antique", "common", "宝の在り処は…にじんで読めない。", Color(0.75, 0.65, 0.45)],
		["ant_key", "謎の鍵", "antique", "uncommon", "どの扉にも合わなかった。", Color(0.6, 0.55, 0.3)],
		["ant_compass", "迷いのコンパス", "antique", "rare", "北を指さない。気分屋らしい。", Color(0.7, 0.6, 0.35)],
		["ant_hourglass", "逆さの砂時計", "antique", "rare", "落ちた砂が、また上へ昇っていく。", Color(0.8, 0.7, 0.55)],
		["ant_orb", "予言の水晶玉", "antique", "epic", "覗き込むと、明日の自分と目が合う。", Color(0.6, 0.85, 0.85)],
		# --- 自然 ---
		["nat_mushroom", "赤いきのこ", "nature", "common", "食べられるかは保証しない。", Color(0.85, 0.3, 0.3)],
		["nat_shell", "渦巻きの貝殻", "nature", "common", "耳に当てると遠い波の音。", Color(0.9, 0.85, 0.75)],
		["nat_feather", "青い羽根", "nature", "uncommon", "見たことのない鳥のものだ。", Color(0.35, 0.55, 0.85)],
		["nat_pebble", "ただの石ころ", "nature", "common", "…のはずだが、妙に愛おしい。", Color(0.5, 0.5, 0.5)],
		["nat_crystal", "森の雫の結晶", "nature", "epic", "朝露が永遠に凍りついたもの。", Color(0.6, 0.9, 0.8)],
	]
	for d in defs:
		var it := ItemData.new()
		it.id = d[0]
		it.item_name = d[1]
		it.category = d[2]
		it.rarity = d[3]
		it.flavor_text = d[4]
		it.color = d[5]
		it.sell_price = RARITY_PRICE[d[3]]
		items.append(it)
		_by_id[it.id] = it

func get_item(id: String) -> ItemData:
	return _by_id.get(id, null)

func total_count() -> int:
	return items.size()

func items_in_category(category: String) -> Array[ItemData]:
	var result: Array[ItemData] = []
	for it in items:
		if it.category == category:
			result.append(it)
	return result

## 重み付き抽選でレアリティを1つ選ぶ
func pick_rarity() -> String:
	var total := 0
	for w in RARITY_WEIGHTS.values():
		total += w
	var roll := randi() % total
	var acc := 0
	for r in RARITY_WEIGHTS:
		acc += RARITY_WEIGHTS[r]
		if roll < acc:
			return r
	return "common"

## ランダムに1アイテムを抽選して返す（レアリティ抽選 → その中から1つ）
func random_item() -> ItemData:
	var rarity := pick_rarity()
	var candidates := items.filter(func(i): return i.rarity == rarity)
	if candidates.is_empty():
		candidates = items
	return candidates.pick_random()
