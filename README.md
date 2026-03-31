# saladdays/agent-skills

AI コーディングツール向けのプラグイン集です。Claude Code と Cursor に対応しています。

## プラグイン一覧

| プラグイン | 説明 | スキル |
|---|---|---|
| [design-md](./plugins/design-md/) | AIがつくるUIに一貫性を。対話で DESIGN.md を生成 | `/design-md:generate` |
| [best-practice](./plugins/best-practice/) | 世の中のベストプラクティスを調査し構造化レポートにまとめる | `/best-practice:search` |
| [roundtable](./plugins/roundtable/) | 多分野の専門家を集めて構造化された議論で多角的な評価・提言 | `/roundtable:start` |

## インストール

### Claude Code

```
/plugin marketplace add saladdays/agent-skills
/plugin install design-md@saladdays-skills
/plugin install best-practice@saladdays-skills
/plugin install roundtable@saladdays-skills
```

### Cursor

Cursor のプラグインマーケットプレイスからプラグインを検索してインストールしてください。

> [Cursor Marketplace](https://cursor.com/marketplace) に公開後はワンクリックでインストールできます。

## License

MIT
