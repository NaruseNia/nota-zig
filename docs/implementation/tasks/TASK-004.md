# TASK-004: NFA 構築

- **関連要件**: REQ-REGEX-002
- **規模**: L
- **依存タスク**: TASK-002

## 実装概要

Thompson's construction で正規表現 AST から NFA を comptime で構築する。複数パターンの統合も行う。

## 対象ファイル

- `src/regex/nfa.zig`

## 実装ステップ

1. NFA の状態・遷移データ構造を定義（comptime 配列ベース）
2. Thompson's construction の各変換規則を実装:
   - Literal → 単一遷移
   - CharClass → 条件付き遷移
   - Concat → フラグメント連結
   - Alt → ε分岐
   - Repeat → ε遷移ループ
   - Group → フラグメントラップ
3. ε-closure の計算関数を実装
4. 複数パターン統合: 共通開始状態 → 各パターン NFA への ε遷移
5. 受理状態にトークン種別を関連付け
6. NFA が正しく構築されることのテストを作成（状態数・遷移の検証）
