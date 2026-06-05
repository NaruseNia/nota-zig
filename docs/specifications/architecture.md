# nota-zig アーキテクチャ仕様

## 概要

nota-zig は 2 つのフェーズで動作する:

1. **コンパイル時 (comptime)**: 正規表現のパース → NFA 構築 → DFA 変換 → 状態遷移テーブル生成
2. **ランタイム**: テーブルドリブン DFA 実行による高速トークナイズ

この分離により、正規表現の複雑さがランタイム性能に影響しない。

## システム構成

```
┌─────────────────────────────────────────────────────────┐
│                    comptime phase                        │
│                                                         │
│  ┌──────────┐    ┌──────────┐    ┌──────────┐          │
│  │  Regex   │───▶│   NFA    │───▶│   DFA    │          │
│  │  Parser  │    │  Builder │    │ Compiler │          │
│  └──────────┘    └──────────┘    └──────────┘          │
│       ▲                               │                 │
│       │                               ▼                 │
│  ┌──────────┐              ┌────────────────┐          │
│  │  Token   │              │  Transition    │          │
│  │  Defs    │              │  Table         │          │
│  │  (enum)  │              │  (comptime)    │          │
│  └──────────┘              └────────────────┘          │
│                                    │                    │
├────────────────────────────────────┼────────────────────┤
│                    runtime phase   │                    │
│                                    ▼                    │
│                          ┌────────────────┐            │
│  ┌──────────┐            │    Lexer       │            │
│  │  Input   │───────────▶│  (table-driven │            │
│  │  []u8    │            │   DFA runner)  │            │
│  └──────────┘            └────────────────┘            │
│                                    │                    │
│                                    ▼                    │
│                          ┌────────────────┐            │
│                          │  Token Stream  │            │
│                          │  (Iterator)    │            │
│                          └────────────────┘            │
└─────────────────────────────────────────────────────────┘
```

## モジュール構成

```
src/
├── nota.zig              # 公開API（Lexer関数）
├── regex/
│   ├── parser.zig        # 正規表現パーサー → AST
│   ├── ast.zig           # 正規表現AST定義
│   ├── nfa.zig           # Thompson's construction
│   └── dfa.zig           # 部分集合構成法 + DFA最小化
├── engine/
│   ├── compiler.zig      # Token定義 → 統合DFA → 遷移テーブル
│   ├── table.zig         # 遷移テーブルのレイアウト・最適化
│   └── runner.zig        # テーブルドリブンDFA実行エンジン
├── lexer.zig             # Lexer型定義・Iteratorインターフェース
└── token.zig             # Token型定義（slice/offset両版）
```

## 詳細設計

### 1. 公開 API (`nota.zig`)

```zig
pub fn Lexer(comptime TokenEnum: type, comptime config: Config) type {
    // TokenEnumのフィールドを走査し、パターン情報を抽出
    // → compiler.compileに渡してDFAテーブルを生成
    // → 生成されたテーブルを持つLexer型を返す
}

pub const Config = struct {
    token_format: enum { slice, offset } = .slice,
};
```

ユーザーの使用例:

```zig
const std = @import("std");
const nota = @import("nota");

const Token = enum {
    // リテラル
    @"if",
    @"else",
    @"fn",
    @"+",
    @"==",

    // 正規表現（decl名にパターンを書けないため、宣言順にパターン配列で対応）
    number,
    ident,
    whitespace,

    // エラー
    invalid,
};

const MyLexer = nota.Lexer(Token, .{
    .patterns = .{
        .number = "[0-9]+",
        .ident = "[a-zA-Z_][a-zA-Z0-9_]*",
        .whitespace = "[ \\t\\n\\r]+",
    },
    .skip = .{.whitespace},
});

pub fn main() void {
    var lexer = MyLexer.init("if x == 42");
    while (lexer.next()) |tok| {
        std.debug.print("{s}: '{s}'\n", .{@tagName(tok.tag), tok.slice});
    }
}
```

### 2. 正規表現パーサー (`regex/parser.zig`)

comptime で正規表現文字列を AST に変換する。

**サポート構文**:

| 構文 | 意味 |
|------|------|
| `[a-z]` | 文字クラス（範囲） |
| `[^a-z]` | 否定文字クラス |
| `\w \d \s` | ショートハンド文字クラス |
| `\W \D \S` | ショートハンド否定文字クラス |
| `.` | 任意のバイト（改行除く） |
| `*` | 0回以上（貪欲） |
| `+` | 1回以上（貪欲） |
| `?` | 0回または1回（貪欲） |
| `{n}` `{n,}` `{n,m}` | 回数指定 |
| `*?` `+?` `??` | 非貪欲量指定子 |
| `\|` | 選択 |
| `(...)` | グループ |
| `(?=...)` | 肯定先読み |
| `(?!...)` | 否定先読み |
| `\\` | エスケープ |

**AST ノード型**:

```zig
const Regex = union(enum) {
    literal: u8,
    char_class: CharClass,
    dot,
    concat: struct { left: *const Regex, right: *const Regex },
    alt: struct { left: *const Regex, right: *const Regex },
    repeat: struct { child: *const Regex, min: u32, max: ?u32, greedy: bool },
    group: *const Regex,
    lookahead: struct { child: *const Regex, positive: bool },
};
```

### 3. NFA 構築 (`regex/nfa.zig`)

Thompson's construction アルゴリズムで AST → NFA 変換。

- 各正規表現 AST ノードを NFA フラグメントに変換
- フラグメントを連結して最終 NFA を構築
- 複数のトークンパターンを統合: 共通の開始状態から各パターンの NFA に ε 遷移
- 各受理状態にトークン種別を関連付け

### 4. DFA 変換 (`regex/dfa.zig`)

部分集合構成法（subset construction）で NFA → DFA 変換。

- ε-closure の計算
- NFA 状態集合 → DFA 状態のマッピング
- DFA 最小化（Hopcroft のアルゴリズム）
- 受理状態に複数のトークン種別が関連する場合、定義順で最初のものを選択（REQ-CORE-004）

### 5. 遷移テーブル (`engine/table.zig`)

DFA をコンパクトな遷移テーブルに変換する。

**テーブルレイアウト**:

```zig
const TransitionTable = struct {
    // 256エントリ × 状態数 の遷移テーブル
    // table[state][byte] → next_state
    transitions: [state_count][256]StateId,

    // 各状態の受理情報
    // accept[state] → ?TokenType (nullなら非受理)
    accept: [state_count]?TokenType,

    state_count: u16,
    start_state: StateId,
};
```

**最適化**:
- 同一遷移行の共有（等価クラスベースの圧縮）
- デッドステートの除去
- 遷移テーブルを `[256]u8` → `[equiv_class_count]u8` に圧縮可能

### 6. ランタイムエンジン (`engine/runner.zig`)

テーブルドリブン DFA の実行。ランタイムのホットパス。

```zig
fn matchToken(table: *const TransitionTable, input: []const u8, pos: usize) ?Match {
    var state = table.start_state;
    var last_accept: ?Match = null;

    var i = pos;
    while (i < input.len) : (i += 1) {
        state = table.transitions[state][input[i]];
        if (state == DEAD_STATE) break;
        if (table.accept[state]) |token_type| {
            last_accept = .{ .tag = token_type, .end = i + 1 };
        }
    }

    return last_accept;
}
```

ポイント:
- 最長一致: 受理状態を通過してもマッチを続行し、デッド状態で最後の受理を返す
- ブランチレスな内部ループ（テーブルルックアップのみ）
- 入力バイトをインデックスとして直接テーブル参照（ハッシュ不要）

### 7. コールバック統合

コールバックトークンは DFA の外で処理する。

1. DFA マッチを先に試行
2. DFA がマッチしない、またはコールバックトークンがより長くマッチする場合、コールバックを実行
3. 両方マッチした場合は定義順で優先度を決定

## 制約・前提条件

- Zig 0.16.x の comptime 機能に依存
- comptime メモリ上限に注意（Zig の comptime はメモリ制限がある）
- 巨大な正規表現（数千状態の DFA）はコンパイル時間が長くなる可能性
- 入力は常にメモリ上の完全なバイトスライス

## 関連要件

- REQ-CORE-001〜008: コア機能全般
- REQ-REGEX-001〜008: 正規表現エンジン全般
- REQ-PERF-001: 性能目標
