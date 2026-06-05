# nota-zig 実装計画

## 概要

nota-zig v0.1.0 の実装計画。13 タスクを 4 フェーズに分けて段階的に実装する。

## 実装順序

### Phase 1: 基盤 + 正規表現エンジン

プロジェクトセットアップと正規表現エンジンのコア部分。他の全タスクの土台。

```
TASK-001 (S) プロジェクト基盤セットアップ
    │
    ├── TASK-002 (L) 正規表現パーサー
    │       │
    │       ├── TASK-003 (M) 先読み・非貪欲拡張
    │       │
    │       └── TASK-004 (L) NFA 構築
    │               │
    │               └── TASK-005 (L) DFA 変換・最小化
    │
    └── TASK-012 (S) GitHub Actions CI
```

### Phase 2: エンジン統合

DFA テーブルとランタイムエンジンの結合。Lexer として動作可能になる。

```
TASK-005 ──┬── TASK-007 (M) ランタイムエンジン
           │
           └── TASK-009 (M) コンパイラ統合
```

### Phase 3: 公開 API + 先読み統合

ユーザー向け API の完成と先読み機能の DFA 統合。

```
TASK-007 ──┬── TASK-008 (M) Lexer型・Token型・Iterator
           │
TASK-003 ──┤
TASK-005 ──┴── TASK-006 (M) 先読みの DFA 統合
```

### Phase 4: 品質・ドキュメント

ベンチマーク、ファズテスト、ドキュメント。

```
TASK-008 ──┬── TASK-010 (M) ベンチマークスイート
           ├── TASK-011 (S) ファズテスト
           └── TASK-013 (S) ドキュメント・README
```

## 依存関係グラフ

```
TASK-001 ─┬─ TASK-002 ─┬─ TASK-003 ─┬─ TASK-006
           │             │             │
           │             └─ TASK-004 ──┴─ TASK-005 ─┬─ TASK-007 ─── TASK-008 ─┬─ TASK-010
           │                                        │                          ├─ TASK-011
           │                                        └─ TASK-009                └─ TASK-013
           │
           └─ TASK-012
```

## トレーサビリティマトリクス

| REQ-ID | TASK-ID |
|--------|---------|
| REQ-CORE-001 | TASK-008, TASK-009 |
| REQ-CORE-002 | TASK-009 |
| REQ-CORE-003 | TASK-009 |
| REQ-CORE-004 | TASK-009 |
| REQ-CORE-005 | TASK-007 |
| REQ-CORE-006 | TASK-008 |
| REQ-CORE-007 | TASK-007 |
| REQ-CORE-008 | TASK-008 |
| REQ-REGEX-001 | TASK-002 |
| REQ-REGEX-002 | TASK-004 |
| REQ-REGEX-003 | TASK-005 |
| REQ-REGEX-004 | TASK-002 |
| REQ-REGEX-005 | TASK-002 |
| REQ-REGEX-006 | TASK-002 |
| REQ-REGEX-007 | TASK-003, TASK-006 |
| REQ-REGEX-008 | TASK-003 |
| REQ-PERF-001 | TASK-007 |
| REQ-PERF-002 | TASK-010 |
| REQ-INFRA-001 | TASK-001, TASK-012 |
| REQ-INFRA-002 | TASK-001, TASK-013 |
| REQ-INFRA-003 | TASK-001 |
| REQ-INFRA-004 | TASK-012 |
| REQ-INFRA-005 | TASK-011 |

## 規模見積

| 規模 | タスク数 | タスク |
|------|---------|--------|
| S (小) | 4 | TASK-001, TASK-011, TASK-012, TASK-013 |
| M (中) | 6 | TASK-003, TASK-006, TASK-007, TASK-008, TASK-009, TASK-010 |
| L (大) | 3 | TASK-002, TASK-004, TASK-005 |

## クリティカルパス

```
TASK-001 → TASK-002 → TASK-004 → TASK-005 → TASK-007 → TASK-008
```

このパスが全体のスケジュールを支配する。特に TASK-002 (正規表現パーサー), TASK-004 (NFA), TASK-005 (DFA) は規模 L で、comptime での正しい動作検証に時間がかかる。

## マイルストーン

| マイルストーン | 到達条件 | 含むタスク |
|---------------|---------|-----------|
| M1: 正規表現エンジン完成 | comptime で regex → DFA 変換が動作 | TASK-001〜005 |
| M2: 基本 Lexer 動作 | 簡単なトークン定義で正しくトークナイズ | + TASK-007〜009 |
| M3: 全機能完成 | 先読み、コールバック含む全機能動作 | + TASK-003, 006 |
| M4: v0.1.0 リリース | ベンチマーク、テスト、ドキュメント完備 | + TASK-010〜013 |
