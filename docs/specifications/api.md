# nota-zig API 仕様

## 概要

nota-zig の公開 API 仕様。ユーザーが直接利用するインターフェースを定義する。

## 公開 API

### `nota.Lexer`

```zig
pub fn Lexer(comptime TokenEnum: type, comptime opts: LexerOptions) type
```

comptime 関数。トークン定義から最適化された Lexer 型を生成する。

**パラメータ**:

| 名前 | 型 | 説明 |
|------|-----|------|
| `TokenEnum` | `type` | トークン種別を定義する enum |
| `opts` | `LexerOptions` | Lexer 設定 |

**戻り値**: 生成された Lexer 型（struct）

### `LexerOptions`

```zig
pub const LexerOptions = struct {
    /// トークンパターン定義（フィールド名 → 正規表現文字列）
    patterns: anytype = .{},

    /// コールバックパターン定義（フィールド名 → マッチ関数）
    callbacks: anytype = .{},

    /// スキップするトークン（Lexerが自動的に読み飛ばす）
    skip: anytype = .{},

    /// Token出力形式
    token_format: TokenFormat = .slice,
};

pub const TokenFormat = enum {
    /// Token{ .tag, .slice } — 入力スライスへの参照
    slice,
    /// Token{ .tag, .start, .end } — バイトオフセット
    offset,
};
```

### 生成される Lexer 型

#### `init`

```zig
pub fn init(input: []const u8) Self
```

Lexer を初期化する。入力のコピーは行わない。

#### `next`

```zig
pub fn next(self: *Self) ?Token
```

次のトークンを返す。EOF で `null` を返す。`skip` に指定されたトークンは自動的にスキップされる。

#### `peek`

```zig
pub fn peek(self: *Self) ?Token
```

次のトークンを返すが、位置は進めない。

#### `reset`

```zig
pub fn reset(self: *Self) void
```

Lexer を入力の先頭にリセットする。

#### `position`

```zig
pub fn position(self: Self) usize
```

現在のバイトオフセット位置を返す。

#### `rest`

```zig
pub fn rest(self: Self) []const u8
```

まだ処理されていない入力の残りを返す。

### Token 型

#### slice 形式

```zig
pub const Token = struct {
    tag: TokenEnum,
    slice: []const u8,
};
```

#### offset 形式

```zig
pub const Token = struct {
    tag: TokenEnum,
    start: u32,
    end: u32,
};
```

### コールバック関数シグネチャ

```zig
fn(input: []const u8, pos: usize) ?usize
```

- `input`: 入力全体のスライス
- `pos`: 現在の位置（バイトオフセット）
- 戻り値: マッチした場合はマッチ終了位置、しなかった場合は `null`

## トークン定義規則

### リテラルトークン

enum のフィールド名がそのままリテラルパターンになる:

```zig
const Token = enum {
    @"if",      // "if" にマッチ
    @"else",    // "else" にマッチ
    @"+",       // "+" にマッチ
    @"==",      // "==" にマッチ
};
```

`@"..."` 構文で任意の文字列をフィールド名にできる Zig の機能を活用。

### 正規表現トークン

`opts.patterns` でフィールド名と正規表現を対応付け:

```zig
const MyLexer = nota.Lexer(Token, .{
    .patterns = .{
        .number = "[0-9]+",
        .ident = "[a-zA-Z_][a-zA-Z0-9_]*",
        .string = "\"[^\"]*\"",
    },
});
```

`patterns` に含まれないフィールドはリテラルトークンとして扱われる。

### コールバックトークン

`opts.callbacks` でフィールド名とマッチ関数を対応付け:

```zig
const MyLexer = nota.Lexer(Token, .{
    .callbacks = .{
        .block_comment = struct {
            fn match(input: []const u8, pos: usize) ?usize {
                if (!std.mem.startsWith(u8, input[pos..], "/*")) return null;
                var depth: u32 = 1;
                var i = pos + 2;
                while (i + 1 < input.len) : (i += 1) {
                    if (input[i] == '/' and input[i + 1] == '*') { depth += 1; i += 1; }
                    else if (input[i] == '*' and input[i + 1] == '/') {
                        depth -= 1;
                        if (depth == 0) return i + 2;
                        i += 1;
                    }
                }
                return null;
            }
        }.match,
    },
});
```

### 暗黙の `invalid` トークン

enum に `invalid` フィールドがある場合、マッチしない入力に対してそのトークンが返される。`invalid` が定義されていない場合はコンパイルエラー。

### 優先度

1. 定義順（enum のフィールド宣言順）
2. 同一長マッチの場合、先に定義されたトークンが優先
3. 異なる長さのマッチの場合、最長一致が優先

## 制約・前提条件

- `TokenEnum` は `enum` 型でなければコンパイルエラー
- `TokenEnum` に `invalid` フィールドが必須
- `patterns` のフィールド名は `TokenEnum` のフィールド名と一致しなければコンパイルエラー
- コールバック関数は comptime で参照可能でなければならない

## 関連要件

- REQ-CORE-001: comptime API
- REQ-CORE-002: リテラルトークン
- REQ-CORE-003: コールバック
- REQ-CORE-006: Token 出力形式
- REQ-CORE-008: Iterator
