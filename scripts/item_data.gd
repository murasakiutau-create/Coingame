class_name ItemData
extends Resource
## 1種類のアイテムの定義データ。
## 企画書の Resource 設計に対応。今はアイコン画像が無いので、
## 代わりに色(color)で見た目を区別する。アートができたら icon を追加する。

@export var id: String
@export var item_name: String
@export var category: String              ## "fantasy" / "daily" / "food" / "antique" / "nature"
@export var rarity: String                ## "common" / "uncommon" / "rare" / "epic"
@export var sell_price: int
@export var flavor_text: String
@export var color: Color = Color.WHITE     ## 仮の見た目用（アイコン代替）
# @export var icon: Texture2D             ## アートができたら有効化する
