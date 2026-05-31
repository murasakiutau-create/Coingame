extends Node
## グローバルなシグナルの中継地点（Autoload）。
## UIと各ゲームシステムを疎結合にするために使う。

## 所持コインが変化したとき（新しい合計値）
signal coins_changed(total: int)

## アイテムを回収したとき（図鑑に既出かどうかに関わらず毎回）
signal item_collected(data: ItemData)

## 図鑑に「初めて」登録されたとき（新規取得演出のトリガ）
signal new_item_registered(data: ItemData)

## インベントリ（所持アイテム）の中身が変化したとき
signal inventory_changed()

## 図鑑の達成率が変化したとき（0.0〜1.0）
signal collection_progress(ratio: float)
