# コイン落とし × 図鑑収集ゲーム 設計書

## ゲームコンセプト

プッシャー型コイン落としで、ファンタジー系・日常雑貨系ごちゃ混ぜのアイテムを集めて図鑑を埋めていくゲーム。
いらないアイテムは換金してコインに戻し、また投下する循環が楽しさの核心。

---

## ゲームの楽しさの中心

> 「まだ持っていないアイテムが出た瞬間の"これ何だ！"という驚きと、図鑑が少しずつ埋まっていく満足感」

---

## ゲームループ

```
コインを投下
    ↓
盤面にコイン・アイテムが落ちる
    ↓
プッシャーで押し出して回収
    ↓
アイテム → 図鑑に登録 or 換金
コイン → ストックに追加
    ↓
コインをまた投下（循環）
    ↓
図鑑が埋まっていく…！
```

---

## アイテム設計

### ジャンル一覧（ごちゃ混ぜ）

| カテゴリ | 例 |
|---|---|
| ファンタジー | ポーション、魔法書、剣、杖、指輪、宝石 |
| 日常雑貨 | 靴、食器、帽子、傘、時計、カバン |
| 食べ物 | りんご、パン、ケーキ、チーズ |
| 骨董・不思議 | 古地図、謎の鍵、コンパス、砂時計 |
| 自然 | きのこ、貝殻、羽根、石ころ |

### レアリティ

| レアリティ | 出現率 | 換金額 | 図鑑での扱い |
|---|---|---|---|
| ★Common | 60% | 2コイン | 灰色枠 |
| ★★Uncommon | 25% | 5コイン | 緑枠 |
| ★★★Rare | 12% | 15コイン | 青枠 |
| ★★★★Epic | 3% | 50コイン | 金枠・光るエフェクト |

- 初回入手時は図鑑登録演出（ポップアップ＋SE）
- 2個目以降は「換金 or コレクションに追加（複数所持）」を選択

---

## 図鑑システム

### 図鑑の構成

```
図鑑
├── ファンタジー（N/30）
├── 日常雑貨（N/25）
├── 食べ物（N/20）
├── 骨董・不思議（N/15）
└── 自然（N/20）
    合計 N/110
```

### 図鑑の各ページ

- アイテム名
- イラスト（取得前はシルエット）
- レアリティ
- フレーバーテキスト（短い説明文）
- 取得日時

### 図鑑達成報酬

| 達成率 | 報酬 |
|---|---|
| 10% | コイン×30 |
| 25% | コイン×100 |
| 50% | 特別アイテム出現率UP（期間限定） |
| 75% | コイン×500 |
| 100% | 称号「万物の収集家」＋特別演出 |

---

## 換金システム

### 流れ

1. アイテム回収時に「図鑑登録」か「換金」を選択
   - 未登録アイテム → 図鑑登録を推奨表示（強制ではない）
   - 登録済みアイテム → 換金ボタンが前面に
2. 換金するとストックコインが増える
3. コインはそのまま投下に使用

### 一括換金機能

- インベントリ画面から「重複アイテムをすべて換金」ボタン
- 未登録アイテムは除外して換金（誤操作防止）

---

## シーン構成（Godot）

```
Main.tscn
├── PusherStage
│   ├── Platform          # AnimatableBody3D（往復するプッシャー板）
│   ├── CoinSpawner       # 投下ポイント
│   ├── CollectArea       # Area3D（回収エリア）
│   └── ItemSpawner       # アイテム出現管理
├── UILayer
│   ├── CoinStock         # 所持コイン数
│   ├── DropButton        # コイン投下ボタン
│   ├── CollectionButton  # 図鑑を開くボタン
│   ├── InventoryButton   # 所持アイテムを開くボタン
│   └── GetItemPopup      # アイテム取得ポップアップ
├── CollectionView        # 図鑑画面（別シーン）
├── InventoryView         # インベントリ画面（別シーン）
└── GameManager           # Autoload
```

---

## Godot実装メモ

### 物理設定

```
コイン・アイテム : RigidBody3D + 形状に合わせたCollisionShape3D
プッシャー板    : AnimatableBody3D + BoxShape3D
回収エリア      : Area3D（body_entered シグナルで回収処理）
床・壁          : StaticBody3D
```

### アイテムデータ（Resource）

```gdscript
# item_data.gd
class_name ItemData extends Resource

@export var id: String
@export var item_name: String
@export var category: String
@export var rarity: String       # "common" / "uncommon" / "rare" / "epic"
@export var sell_price: int
@export var icon: Texture2D
@export var flavor_text: String
```

### アイテム出現ロジック

```gdscript
# ItemSpawner.gd
const RARITY_WEIGHTS = {
    "common": 60,
    "uncommon": 25,
    "rare": 12,
    "epic": 3
}

func spawn_item():
    # 一定確率でコインの代わりにアイテムを出現
    if randf() < 0.15:  # 15%の確率でアイテム
        var rarity = pick_rarity()
        var candidates = item_database.filter(func(i): return i.rarity == rarity)
        var item_data = candidates.pick_random()
        # アイテムをRigidBody3Dとしてスポーン
```

### 回収処理

```gdscript
# CollectArea.gd
func _on_body_entered(body):
    if body.is_in_group("coin"):
        GameManager.add_coin(1)
        body.queue_free()
    elif body.is_in_group("item"):
        var data = body.item_data
        GameManager.collect_item(data)
        body.queue_free()
```

### GameManager（Autoload）

```gdscript
# GameManager.gd
var coins: int = 10  # 初期コイン
var inventory: Dictionary = {}   # item_id: count
var collection: Dictionary = {}  # item_id: { registered, date }

func collect_item(data: ItemData):
    inventory[data.id] = inventory.get(data.id, 0) + 1
    if not collection.has(data.id):
        collection[data.id] = { "registered": true, "date": Time.get_date_string_from_system() }
        # 新規登録演出を発火
        EventBus.emit_signal("new_item_registered", data)

func sell_item(item_id: String, count: int = 1):
    if inventory.get(item_id, 0) >= count:
        inventory[item_id] -= count
        var price = ItemDatabase.get_item(item_id).sell_price
        coins += price * count
```

---

## 開発フェーズ

### Phase 1 — 物理コア
- [ ] プッシャー盤面の3D構築（板・壁・回収エリア）
- [ ] コイン投下・物理挙動の確認
- [ ] コイン回収 → 所持コイン増加

### Phase 2 — アイテム基盤
- [ ] ItemDataリソースの定義
- [ ] アイテムデータベース作成（まず各カテゴリ3〜5個）
- [ ] アイテムスポーン＆回収処理

### Phase 3 — 図鑑・インベントリ
- [ ] 図鑑UI（シルエット→解放演出）
- [ ] インベントリUI
- [ ] 新規取得ポップアップ

### Phase 4 — 換金システム
- [ ] 単体換金
- [ ] 一括換金（重複のみ）

### Phase 5 — 演出・調整
- [ ] Epic取得時の特別演出
- [ ] 図鑑達成報酬
- [ ] SE・BGM
- [ ] アイテム数を本数まで増やす

---

## アイテム数の目標

| フェーズ | アイテム数 |
|---|---|
| プロトタイプ | 各カテゴリ5個 = 25個 |
| α版 | 各カテゴリ15個 = 75個 |
| 完成版 | 合計110個 |
