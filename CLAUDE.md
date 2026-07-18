# CLAUDE.md

このリポジトリで作業する際の Claude 向けメモ。

## デプロイ構成

| 層 | ホスティング | 備考 |
|---|---|---|
| フロント (Web) | Cloudflare Workers | 公開URL: `https://income-and-expense.annndddddooooooo.workers.dev/` |
| iOS | Xcode Cloud | リリースビルドで配布 |
| バックエンド (Django API) | DigitalOcean 上の Dokku | API URL: `https://income-and-expense.167.172.65.18.nip.io/api` |

### 接続先設定の場所
- iOS: `ios/IncomeAndExpense/App/AppConfig.swift`（DEBUG=localhost、リリース=本番API URL）
- Web: `frontend/.env.production` の `VITE_API_BASE_URL`、フォールバックは `frontend/src/api/client.ts` / `frontend/src/api/auth.ts`
- バックエンドの `ALLOWED_HOSTS` / `CORS_ALLOWED_ORIGINS` は `config/settings/production.py` で**環境変数から読む**（デフォルト値なし＝未設定だと全拒否）。値はサーバー（Dokku）側の環境変数で管理。

## TODO（別の修正機会にまとめてやる）

### CI/CD: 検証ブランチでの自動ビルド・ステージング整備
「本番相当で動作確認してから main にマージ」を実現するため、以下を整備したい:
- **Cloudflare (フロント)**: ブランチ/PR ごとのプレビューデプロイを有効化し、検証ブランチをプレビューURLで確認できるようにする
- **Dokku (バックエンド)**: 検証ブランチ用のステージングアプリ（**本番とは別DB**）を用意し、検証ブランチ push で自動デプロイ
- **Xcode Cloud (iOS)**: 検証ブランチ用のワークフローを追加
- 原則: 検証ブランチ → ステージング/プレビュー、`main` → 本番。両者を分離し、検証が本番データ・本番URLを汚さないようにする

<!-- BEGIN claude-knowledge (distill 自動管理 / この外側は温存) -->
## 既知の決定・ハマり所（自動蒸留 / 2026-07-09 更新）
- **デプロイは push で自動化されている**: フロント(Cloudflare)・iOS(Xcode Cloud)・バック(Dokku リモートへの push)いずれも push で自動ビルド・デプロイが走る。GitHub Actions が無いからと「CI 無し・手動 `wrangler deploy` 必要」と誤認しない（上の TODO はこの自動化に加えて、検証ブランチ用の**別ステージング**を整備する話）。
- **ブランチ運用**: 作業ブランチ → develop へ `--no-ff` マージ → push（自動ビルドでステージング確認）→ 承認後 develop → main + タグ（`Ver3.x` 系）。
- **App Store Connect アップロードは iOS 26 SDK 必須 → Xcode Cloud のみ有効**: Xcode 15.2 (iOS 17.2 SDK) から直接アップロードすると `"built with the iOS 17.2 SDK. All iOS and iPadOS apps must be built with the iOS 26 SDK or later"` エラーになる。Xcode 26 は macOS Sonoma 以降が必要（MacBook Pro 2017 は Ventura が上限）→ Xcode Cloud 経由のみ。USB 実機デバッグも同様に DDI ミスマッチで不可。
- **TestFlight 配布フロー**: 外部テスターはビルドごとに Beta App Review 提出が必要（初回通過後は軽微変更で数分〜数時間）。ビルド番号 (`CURRENT_PROJECT_VERSION`) は毎アップロードに +1 必須（pbxproj 内 6 箇所）。「ビルド番号上げてpush」で依頼可。内部グループへのビルド割り当ても手動（「+」ボタン）が必要で「Xcodeビルドを自動配信」表示は見かけ倒し。
- **iOS 一覧・表示画面は `List(.insetGrouped)` を使わない** → `ScrollView + VStack(spacing:12) + yutoriCard()`。理由: insetGrouped はセクション間に除去不能の固定余白を挿入し「奇妙な隙間」になる。削除は `.contextMenu`（`swipeActions` は List 専用）、更新は `.refreshable`。入力フォームだけは iOS 標準 `Form` を維持。
- **iOS デザインシステムは `Palette.swift` に集約**（トークン + ScreenHeading/GroupCaption/yutoriCard()/YutoriPillButton/StatePickerRow/Font.yutori）。新規 .swift を作らず既存へ吸収し pbxproj 編集を回避。色は Palette トークンのみ（`Color.blue/red/green`・`systemBackground`・`.tint(.accentColor)` は残さない）。M PLUS Rounded 1c は未バンドルで `Font.yutori`=`.rounded` フォールバック。
- **iOS の見た目検証は simulator 実描画で**: ViewModel にモックを一時注入 + RootView を対象画面へ向け `simctl io screenshot` → 確認後 `git` で一時変更のみ revert。
- **iOS 一覧行の区切りは `·` (U+00B7 + 前後スペース)**: Apple純正アプリ(Music/Mail/App Store)の慣例。スペースのみは曖昧。絵文字アイコンは iOS 17/18 トレンドで不使用（文字＋`·`のみ）。
- **iOS 日本語日付は `DateFormat.swift` に集約**: `Date.japaneseMonthDay`（X月Y日）・`Date.japaneseYearMonthDay`（X年Y月Z日）の 2 拡張。フォームの DatePicker は `JapaneseDatePicker.swift`（タップで展開する graphical picker、閉時に日本語日付ラベルを表示）を使う。**新規 .swift は必ず xcodeproj に登録する**（PBXFileReference + PBXBuildFile の 2 エントリ）。
- **iOS でマイナス数値を入力させるには `.numbersAndPunctuation`**: `.numberPad` ではマイナス符号が打てない。残高などの負値入力フィールドはキーボードタイプを切り替える。
- **Web モバイル落とし穴**: CSS grid で `lg:grid-cols-[...]` 等デスクトップ列だけ指定しモバイル基底列が無いと、トラックが子(recharts 等)の固有幅に引っ張られページが overflow → ブラウザがズームアウトしカード端がズレる。基底に `grid-cols-1`(=minmax(0,1fr)) を明示 + 可変幅の子に `min-w-0`。空データでは再現せず実データで初めて出る。
- **設定ページ（`/settings/...`）では月ナビゲーションバーを非表示**: `MAIN_NAV` に属さないパスでは AppLayout のヘッダー月ナビ（前月/次月/年月/今月）を非表示にする（`AppLayout.tsx` の `isMainNav` フラグ）。月のコンテキストを持たない新規ページを追加する際は同様の対応が必要。
- **Web デザイントークンは `frontend/src/index.css`**、共通クラスは `frontend/src/lib/ui.ts`、shadcn `Input` は全体テーマ化済み。状態表現は Select ではなく Segmented/StatePickerRow に統一。
- **アプリ内ロゴ差し替えは 4 箇所チェック**: ① Web ナビヘッダー（AppLayout.tsx）、② Web サイドパネル（AppLayout.tsx）、③ Web ログイン（Login.tsx）、④ iOS ログイン（LoginView.swift）。1 箇所だけ更新するとモレが出る（実績あり）。
- **iOS asset catalog への imageset 追加は pbxproj 不要**: `.xcassets/` 内に imageset ディレクトリ（`Contents.json` + 画像）を置くだけでビルドに自動取り込みされる（.swift ファイルとは異なる）。
- **ステージング環境が 3 層で稼働済み**: Web=`income-and-expense-staging.annndddddooooooo.workers.dev` / API=`income-and-expense-staging.167.172.65.18.nip.io/api` / iOS=INEX(Staging) via TestFlight Internal。develop/* 作業中の動作確認はここで行う。DB は Neon staging ブランチ。
- **iOS Build Configuration は Debug/Staging/Release の 3 種（xcconfig）**: Staging は staging API に向き Bundle ID=`.staging`。Xcode Cloud の `develop/*` ワークフローは `IncomeAndExpense (Staging)` scheme でビルド。Configuration の直接選択は Xcode Cloud UI では不可 → scheme で間接指定する。
- **iOS NavigationLink value-based の罠**: `NavigationLink(value:)` + `navigationDestination(for:)` を ScrollView 内で使うと「1 回目タップ = ハイライトのみ、2 回目 or 戻り後 = 遷移」になる。destination 直接渡し形式（`NavigationLink { DestView() } label: { ... }`）に変更して解消。
- **金額入力フォームの 0 → 空欄**: `amount` 系フィールドは初期値 0 のとき `value={v === 0 ? '' : v}` で空欄表示し、`onChange` で空文字を 0 に変換（"01000" 問題防止）。`pay_day`・年月など「意味のある既定値」は対象外。
- **収支一覧のソート順**: `_InexViewSetBase.get_queryset()` で `method__account__user__name → method__name → method__account__bank__name → -amount → state → pay_date → name`（同一支払方法内で金額降順）。
- **Radix Select / shadcn Select の race condition**: 非同期で取得した選択肢リスト（`methods` 等）を使う Select で `form.reset` を `if (existing)` だけでガードすると、`existing` が先に返った初回アクセス時に SelectValue が "選択" のまま残る。SelectItem は「生まれた時点で既に isSelected」だと Radix がラベル書き込みをスキップするため。修正: `if (existing && methods.length > 0)` に変更し deps に `methods.length` を追加する（5 フォームに適用済み）。
- **CLI ビルド（`CODE_SIGNING_ALLOWED=NO`）では Keychain が動かない**: entitlements が付かずシミュレータの Keychain 操作が黙って失敗。ログイン → トークン保存失敗 → 401 → `logout()` の即ログアウトループになる。動作確認は Xcode に Apple ID を追加（無料可）してから ⌘R で実行する（ad-hoc 署名が付いて Keychain が正常動作する）。
- **DRF `validate_<field>` は更新(PUT/PATCH)でも走る**: `ModelSerializer.validate_<field>` は新規作成だけでなく更新リクエストでも呼ばれる。更新時に特定フィールドが変わっていない場合はスキップするため先頭に `if self.instance is not None and self.instance.field == value: return value` を追加する。ViewSet が同じチェックを二重に持っていると Serializer を直しても症状が変わらない（ViewSet が Serializer より先に弾くため）。`_can_update_or_delete` は `_can_delete` にリネームし削除のみに絞った（`api_views.py`）。
- **DRF 非フィールドバリデーションエラーは JSON 配列形式**: `add_defaults` 等のコレクション action で `raise ValidationError("...")` すると `["エラー文字列"]`（トップレベル配列）で返る。フィールドエラーの `{"field": ["..."]}` (辞書) とは別形式。`AppError.errorDescription` のパーサは辞書・配列の両方を処理しないと「通信エラー(HTTP 400)」にフォールバックし続ける。
- **ローカル開発の Django ポート 8000 競合**: macOS では `127.0.0.1:8000`（特定）と `0.0.0.0:8000`（ワイルドカード）を別々にバインドできる。複数 Django プロジェクトを同時起動すると `localhost:8000` は 127.0.0.1 側（別プロジェクト）に優先ルーティングされ、全 API が 404 になる。`lsof -i :8000` でプロセスを確認して不要なサーバを停止するか、プロジェクトごとに別ポートを割り当てる。
- **Web モバイルの html font-size は 17.5px**（デスクトップは 16px デフォルト）: `frontend/src/index.css` の `@media (max-width: 768px)` で `html { font-size: 17.5px }` を設定済み。rem ベースの Tailwind クラスが全体比例変化するため、個別クラス変更より root font-size 一括調整の方が一貫性が保たれる。
- **`useSidebar()` は SidebarProvider の内側でしか呼べない**: `AppLayout` 等の SidebarProvider 親コンポーネントで `useSidebar()` を直接使おうとするとコンテキストエラー。`AppLayoutContent` のような内側コンポーネントに切り出して呼ぶ（現行の `AppLayout.tsx` がこのパターン）。
- **React 制御コンポーネントでマイナス値入力には `string` 状態**: `number` 型の state で `-` 単独入力すると `Number("-") === NaN` になり入力が即座に消える。残高など負値を受け付けるフィールドは `string` 型で状態管理し、送信時に `Number()` 変換する（iOS は `.numbersAndPunctuation` キーボード、バックは `IntegerField` 対応済み）。
<!-- END claude-knowledge -->

