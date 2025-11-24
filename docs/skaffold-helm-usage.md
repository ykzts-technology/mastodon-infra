# Skaffoldを使ったHelm管理

このドキュメントでは、SkaffoldとMastodon公式Helm Chartを組み合わせて使用する方法を説明します。

## 概要

Skaffoldは、Kubernetesアプリケーションの開発とデプロイメントを簡素化するツールです。このプロジェクトでは、Kustomizeベースのデプロイメント（既存）とHelmベースのデプロイメント（新規）の両方をサポートしています。

## Skaffoldプロファイル

`skaffold.yaml`には以下のプロファイルが定義されています：

| プロファイル | デプロイ方式 | 対象環境 | 説明 |
|------------|------------|---------|------|
| `default` | Kustomize | Development | デフォルト。開発環境用（既存） |
| `production` | Kustomize | Production | 本番環境用（既存） |
| `helm-dev` | Helm | Development | Helm使用の開発環境用（新規） |
| `helm-production` | Helm | Production | Helm使用の本番環境用（新規） |

## 基本的な使い方

### インストール

Skaffoldがインストールされていない場合：

```bash
# macOS
brew install skaffold

# Linux
curl -Lo skaffold https://storage.googleapis.com/skaffold/releases/latest/skaffold-linux-amd64
sudo install skaffold /usr/local/bin/

# または、パッケージマネージャーを使用
# https://skaffold.dev/docs/install/
```

### Helm Repositoryの追加

初回のみ、Mastodon Helm repositoryを追加：

```bash
helm repo add mastodon https://mastodon.github.io/helm-charts/
helm repo update
```

### デプロイメント

#### 開発環境（Helm）

```bash
# 一度だけデプロイ
skaffold run -p helm-dev

# 継続的な開発モード（ファイル変更を監視して自動デプロイ）
skaffold dev -p helm-dev
```

#### 本番環境（Helm）

```bash
# 本番環境へデプロイ
skaffold run -p helm-production

# デプロイメントの状態確認
kubectl get pods -l app.kubernetes.io/instance=mastodon
```

### デプロイメントの削除

```bash
# 開発環境の削除
skaffold delete -p helm-dev

# 本番環境の削除
skaffold delete -p helm-production
```

## 設定のカスタマイズ

### values.yamlの編集

デプロイメント設定を変更する場合は、`helm/values-production.yaml`を編集します：

```bash
# エディタで編集
vim helm/values-production.yaml

# デプロイ
skaffold run -p helm-production
```

### 環境固有の設定

開発環境と本番環境で異なる設定を使用する場合：

1. **開発環境用のvalues.yaml作成**

```bash
cp helm/values-production.yaml helm/values-development.yaml
```

2. **skaffold.yamlの更新**

```yaml
profiles:
  - name: helm-dev
    deploy:
      helm:
        releases:
          - name: mastodon
            # ...
            valuesFiles:
              - helm/values-development.yaml  # 開発環境用
```

### コマンドラインでの上書き

一時的に設定を上書きする場合：

```bash
skaffold run -p helm-production \
  --set mastodon.web.replicas=3 \
  --set image.tag=v4.5.2
```

## 継続的な開発ワークフロー

### 開発モード（skaffold dev）

`skaffold dev`は、ファイル変更を監視して自動的に再デプロイします：

```bash
skaffold dev -p helm-dev
```

特徴：
- ファイル変更の自動検出
- 自動的な再デプロイ
- ログのストリーミング表示
- Ctrl+Cで終了時に自動クリーンアップ

### デバッグモード

```bash
skaffold debug -p helm-dev
```

デバッグポートが自動的に公開され、IDEから接続できます。

## Kustomizeからの移行

既存のKustomizeベースのデプロイメントからHelmベースへ移行する場合：

### 段階的な移行

1. **テスト環境でHelmを試す**

```bash
# 別のNamespaceでテスト
kubectl create namespace mastodon-helm-test
skaffold run -p helm-dev --namespace mastodon-helm-test
```

2. **動作確認**

```bash
kubectl get pods -n mastodon-helm-test
kubectl logs -n mastodon-helm-test deployment/mastodon-web
```

3. **問題なければテスト環境を削除**

```bash
skaffold delete -p helm-dev --namespace mastodon-helm-test
kubectl delete namespace mastodon-helm-test
```

4. **本番環境へ適用**

詳細は[Helm Migration Guide](./helm-migration-guide.md)を参照してください。

### 既存のKustomizeデプロイメントとの併用

移行期間中は、両方を併用できます：

```bash
# Kustomizeベースのリソース（既存）
skaffold run -p production

# Helmベースのリソース（新規、別名でデプロイ）
skaffold run -p helm-production --set nameOverride=mastodon-helm
```

## トラブルシューティング

### Helm repositoryが見つからない

```bash
# Helm repositoryを追加
helm repo add mastodon https://mastodon.github.io/helm-charts/
helm repo update

# 確認
helm search repo mastodon
```

### values.yamlが読み込まれない

```bash
# ファイルの存在確認
ls -la helm/values-production.yaml

# YAMLの文法チェック
cat helm/values-production.yaml | yq eval '.' -
```

### Podが起動しない

```bash
# Skaffoldのログを確認
skaffold run -p helm-production -v info

# Podの詳細を確認
kubectl get pods -l app.kubernetes.io/instance=mastodon
kubectl describe pod [POD_NAME]
kubectl logs [POD_NAME]
```

### Helmリリースが残っている

```bash
# リリース一覧を確認
helm list

# 残っているリリースを削除
helm uninstall mastodon

# 再度Skaffoldでデプロイ
skaffold run -p helm-production
```

## CI/CDでの使用

### GitHub Actions

```yaml
name: Deploy to Production

on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Set up Cloud SDK
        uses: google-github-actions/setup-gcloud@v1
      
      - name: Get GKE credentials
        run: |
          gcloud container clusters get-credentials mastodon-cluster \
            --region asia-northeast1 \
            --project ${{ secrets.GCP_PROJECT_ID }}
      
      - name: Install Skaffold
        run: |
          curl -Lo skaffold https://storage.googleapis.com/skaffold/releases/latest/skaffold-linux-amd64
          sudo install skaffold /usr/local/bin/
      
      - name: Add Helm repository
        run: |
          helm repo add mastodon https://mastodon.github.io/helm-charts/
          helm repo update
      
      - name: Deploy with Skaffold
        run: skaffold run -p helm-production
```

### Cloud Build

```yaml
steps:
  - name: 'gcr.io/k8s-skaffold/skaffold'
    args:
      - 'run'
      - '-p'
      - 'helm-production'
    env:
      - 'CLOUDSDK_COMPUTE_REGION=asia-northeast1'
      - 'CLOUDSDK_CONTAINER_CLUSTER=mastodon-cluster'
```

## 高度な使用方法

### プロファイルのオーバーライド

複数のプロファイルを組み合わせる：

```bash
# 基本設定 + 追加の設定
skaffold run -p helm-production -p monitoring
```

### カスタムプロファイルの作成

`skaffold.yaml`に新しいプロファイルを追加：

```yaml
profiles:
  - name: helm-staging
    deploy:
      helm:
        releases:
          - name: mastodon
            remoteChart: mastodon/mastodon
            repo: https://mastodon.github.io/helm-charts/
            valuesFiles:
              - helm/values-staging.yaml
```

### 条件付きデプロイメント

特定の条件でのみデプロイ：

```bash
# イメージタグを確認してからデプロイ
if [[ $(kubectl get deployment mastodon-web -o jsonpath='{.spec.template.spec.containers[0].image}') != *"nightly"* ]]; then
  skaffold run -p helm-production
fi
```

## まとめ

### Skaffold + Helmの利点

- ✅ 一貫したデプロイメントコマンド
- ✅ 環境ごとの設定管理が容易
- ✅ CI/CDへの統合が簡単
- ✅ 開発モードでの自動リロード
- ✅ Helmの機能（ロールバック、履歴管理）を利用可能

### 推奨ワークフロー

1. **開発**: `skaffold dev -p helm-dev`で継続的な開発
2. **ステージング**: `skaffold run -p helm-production`でテスト
3. **本番**: CI/CDから`skaffold run -p helm-production`で自動デプロイ

### 参考リンク

- [Skaffold公式ドキュメント](https://skaffold.dev/docs/)
- [Skaffold + Helmガイド](https://skaffold.dev/docs/pipeline-stages/deployers/helm/)
- [Mastodon Helm Chart](https://github.com/mastodon/helm-charts)
- [Helm Migration Guide](./helm-migration-guide.md)

---

**注意**: Skaffoldはデプロイメントツールであり、インフラストラクチャの管理（Terraform）とは分離されています。データベース、Redis、GCS等のインフラリソースはTerraformで管理してください。
