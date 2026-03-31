# saladdays/skills

AI コーディングツール向けのプラグイン集です。Claude Code と Cursor に対応しています。

## プラグイン一覧

| プラグイン | 説明 | スキル |
|---|---|---|
| [design-md](./plugins/design-md/) | AIがつくるUIに一貫性を。対話で DESIGN.md を生成 | `/design-md:generate` |
| [search-best-practice](./plugins/search-best-practice/) | 世の中のベストプラクティスを調査し構造化レポートにまとめる | `/search-best-practice:search` |

## インストール

### Claude Code

```
/plugin marketplace add saladdays/skills
/plugin install design-md@skills
/plugin install search-best-practice@skills
```

### Cursor

Cursor の Chat で `/add-plugin` を実行し、プラグインを検索してインストールしてください。

## License

MIT
