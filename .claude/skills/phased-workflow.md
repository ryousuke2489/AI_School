# フェーズ別ワークフロー スキル

## 概要
教材コンテンツ制作の全フェーズを順序立てて実行するスキルです。
各フェーズは前フェーズの成果物を参照し、品質を積み上げます。

## フェーズ構成

```
Phase 1: 構成（カリキュラム）     ← 基準文書。全フェーズが参照
    ↓
Phase 2: 台本（講義ごとに並列）   ← カリキュラムを参照して生成
    ↓
Phase 3: 資料（講義ごとに並列）   ← カリキュラム＋台本を参照して生成
    ↓
Phase 4: 動画編集（講義ごとに並列）← カリキュラム＋台本＋スライドを参照して生成
```

## 実行手順

### Phase 1: 構成
1. `curriculum-designer` スキルで `content/00_curriculum/curriculum.md` を作成
2. 他の全フェーズがこれを基準文書として参照する

### Phase 2: 台本
1. Phase 1 の完了を確認
2. `script-writer` スキルで各講義の台本を並列生成
3. 参照: `content/00_curriculum/curriculum.md`
4. 出力: `content/01_scripts/lecture_01.md` 〜 `lecture_05.md`

### Phase 3: 資料
1. Phase 2 の完了を確認
2. `slide-creator` スキルで各講義のスライドを並列生成
3. 参照: `content/00_curriculum/curriculum.md` + `content/01_scripts/lecture_XX.md`
4. 出力: `content/02_slides/lecture_01.md` 〜 `lecture_05.md`

### Phase 4: 動画編集
1. Phase 3 の完了を確認
2. `video-editor` スキルで全体方針書 + 各講義の編集指示書を並列生成
3. 参照: カリキュラム + 台本 + スライド
4. 出力: `content/03_video_editing/editing_guide.md` + `lecture_01.md` 〜 `lecture_05.md`

## 依存関係ルール
- 各フェーズは前フェーズが**全て完了**してから開始すること
- 同一フェーズ内の講義は**並列実行**可能
- 前フェーズの成果物は**読み取りのみ**で参照すること
- 各エージェントは自分の担当ディレクトリ内のファイルのみを編集すること

## 参照関係マトリクス

| Phase | カリキュラム | 台本 | スライド |
|-------|------------|------|----------|
| 1. 構成 | 作成 | - | - |
| 2. 台本 | 参照 | 作成 | - |
| 3. 資料 | 参照 | 参照 | 作成 |
| 4. 動画 | 参照 | 参照 | 参照 |
