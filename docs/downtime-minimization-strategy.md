# ダウンタイム最小化戦略

このドキュメントでは、Kustomize管理からHelm Chart管理への移行時に、ダウンタイムを最小化するための具体的な戦略と手法を説明します。

## 目標

- **ダウンタイム**: 5分未満（理想）、15分未満（最悪）
- **データロス**: ゼロ
- **ユーザー影響**: 最小限（一時的な接続エラーのみ）

## 戦略概要

1. **Blue-Green デプロイメント方式**: 新旧環境を並行稼働させ、Ingressの切り替えで瞬時に移行
2. **段階的移行**: コンポーネントごとに移行し、問題発生時の影響範囲を限定
3. **迅速なロールバック**: 問題発生時は即座に旧環境へ切り戻し

## 詳細戦略

### 戦略1: Blue-Green デプロイメント（推奨）

最もダウンタイムが少ない方法。新旧環境を並行稼働させ、Ingressの切り替えのみで移行します。

#### メリット
- ダウンタイム: 数秒〜数十秒（Ingress切り替えのみ）
- ロールバックが即座に可能
- 新環境の動作確認が十分に行える

#### デメリット
- リソース使用量が一時的に倍増
- コスト増加（一時的）

#### 実施手順

```bash
# ステップ1: 既存リソースにラベルを付与（識別用）
kubectl label deployment mastodon-web app.kubernetes.io/version=kustomize
kubectl label deployment mastodon-streaming app.kubernetes.io/version=kustomize
kubectl label deployment mastodon-worker app.kubernetes.io/version=kustomize

# ステップ2: Helm chartを別名でインストール
helm install mastodon-helm mastodon/mastodon \
  --namespace default \
  --values helm/values-production.yaml \
  --set nameOverride=mastodon-helm

# この時点でのリソース構成:
# - 旧: mastodon-web, mastodon-streaming, mastodon-worker
# - 新: mastodon-helm-web, mastodon-helm-streaming, mastodon-helm-sidekiq

# ステップ3: 新環境のヘルスチェック（5分間）
for i in {1..30}; do
  echo "Health check attempt $i/30"
  kubectl exec deployment/mastodon-helm-web -- curl -f http://localhost:3000/health && echo "OK" || echo "FAIL"
  sleep 10
done

# ステップ4: 新環境への少量トラフィックテスト（オプション）
# 一時的なServiceを作成し、port-forwardでアクセステスト
kubectl port-forward service/mastodon-helm-web 3001:3000 &
curl http://localhost:3001/health

# ステップ5: Ingressを新Serviceに切り替え
# Ingressを削除（Kustomize管理）
kubectl delete ingress mastodon

# Helm chartによるIngressを有効化
# （既に作成されているはず）
kubectl get ingress mastodon-helm

# 必要に応じてGCP固有アノテーションを追加
kubectl annotate ingress mastodon-helm \
  kubernetes.io/ingress.global-static-ip-name=ykzts-technology-ip \
  networking.gke.io/managed-certificates=mastodon-certificate

# ステップ6: トラフィック監視（5-10分）
# エラーレート、レスポンスタイム、ユーザーアクセスを監視
kubectl logs -f deployment/mastodon-helm-web

# ステップ7: 問題なければ旧環境を削除
kubectl delete deployment mastodon-web mastodon-streaming mastodon-worker
kubectl delete service mastodon-web mastodon-streaming mastodon-assets mastodon-emoji

# ステップ8: リソース名の正規化（オプション）
# 一度アンインストールして、標準名で再インストール
helm uninstall mastodon-helm
helm install mastodon mastodon/mastodon \
  --namespace default \
  --values helm/values-production.yaml
```

**想定ダウンタイム**: Ingress切り替え時の5-30秒

---

### 戦略2: Rolling Update方式

既存リソースを段階的に置き換える方法。

#### メリット
- リソース使用量の増加が少ない
- コストが低い

#### デメリット
- ダウンタイムが長くなる可能性（5-15分）
- ロールバックに時間がかかる

#### 実施手順

```bash
# ステップ1: Sidekiq（バックグラウンドワーカー）を先に移行
# ユーザーへの直接的な影響が少ないため

# 旧workerをスケールダウン
kubectl scale deployment mastodon-worker --replicas=0

# Helm chartでsidekiqのみデプロイ（他を無効化）
helm install mastodon-sidekiq mastodon/mastodon \
  --namespace default \
  --values helm/values-production.yaml \
  --set mastodon.web.replicas=0 \
  --set mastodon.streaming.replicas=0

# 動作確認（5分）
kubectl logs deployment/mastodon-sidekiq-all-queues

# ステップ2: Streaming APIを移行
# WebSocketコネクションは一時的に切断されるが、自動再接続される

# 旧streamingをスケールダウン
kubectl scale deployment mastodon-streaming --replicas=0

# Helm chartでstreamingを有効化
helm upgrade mastodon-sidekiq mastodon/mastodon \
  --namespace default \
  --values helm/values-production.yaml \
  --set mastodon.web.replicas=0 \
  --set mastodon.streaming.replicas=1

# 動作確認（3分）
kubectl exec deployment/mastodon-streaming -- \
  curl -f http://localhost:4000/api/v1/streaming/health

# ステップ3: Web（最も重要）を最後に移行
# この時点でダウンタイムが発生

# 旧webをスケールダウン
kubectl scale deployment mastodon-web --replicas=0

# Helm chartでwebを有効化
helm upgrade mastodon-sidekiq mastodon/mastodon \
  --namespace default \
  --values helm/values-production.yaml \
  --set mastodon.web.replicas=1 \
  --set mastodon.streaming.replicas=1

# Podが起動するまで待機（2-5分）
kubectl wait --for=condition=ready pod -l app.kubernetes.io/component=web --timeout=300s

# Ingressを更新
kubectl delete ingress mastodon
# Helm chartによるIngressが自動作成される

# ステップ4: 動作確認（10分）
# エラーなく動作していることを確認

# ステップ5: 旧リソースを削除
kubectl delete deployment mastodon-web mastodon-streaming mastodon-worker
kubectl delete service mastodon-web mastodon-streaming mastodon-assets mastodon-emoji
```

**想定ダウンタイム**: Web移行時の5-10分

---

### 戦略3: メンテナンスモード方式（最も安全）

メンテナンス画面を表示し、完全に移行作業を行う方法。

#### メリット
- 最も安全で確実
- 作業時間に余裕がある
- ロールバックのプレッシャーが少ない

#### デメリット
- ダウンタイムが最も長い（30分〜1時間）
- ユーザーへの影響が大きい

#### 実施手順

```bash
# ステップ1: メンテナンスページの準備
# 静的なメンテナンスページを配信する簡易Deployment

cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: maintenance-page
spec:
  replicas: 2
  selector:
    matchLabels:
      app: maintenance-page
  template:
    metadata:
      labels:
        app: maintenance-page
    spec:
      containers:
      - name: nginx
        image: nginx:alpine
        ports:
        - containerPort: 80
        volumeMounts:
        - name: html
          mountPath: /usr/share/nginx/html
      volumes:
      - name: html
        configMap:
          name: maintenance-html
---
apiVersion: v1
kind: Service
metadata:
  name: maintenance-page
spec:
  selector:
    app: maintenance-page
  ports:
  - port: 80
    targetPort: 80
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: maintenance-html
data:
  index.html: |
    <!DOCTYPE html>
    <html>
    <head>
      <title>メンテナンス中 - ykzts.technology</title>
      <meta charset="utf-8">
      <style>
        body {
          font-family: sans-serif;
          text-align: center;
          padding: 50px;
          background: #282c37;
          color: #fff;
        }
        h1 { color: #9baec8; }
      </style>
    </head>
    <body>
      <h1>メンテナンス中</h1>
      <p>現在、システムのアップグレード作業中です。</p>
      <p>まもなく復旧いたします。ご不便をおかけして申し訳ございません。</p>
      <p>Maintenance in progress. We will be back soon.</p>
    </body>
    </html>
EOF

# ステップ2: Ingressをメンテナンスページに切り替え
kubectl patch ingress mastodon --type=json -p='[
  {
    "op": "replace",
    "path": "/spec/rules/0/http/paths/0/backend/service/name",
    "value": "maintenance-page"
  },
  {
    "op": "replace",
    "path": "/spec/rules/0/http/paths/0/backend/service/port/number",
    "value": 80
  }
]'

# ステップ3: 既存環境の停止
kubectl scale deployment mastodon-web --replicas=0
kubectl scale deployment mastodon-streaming --replicas=0
kubectl scale deployment mastodon-worker --replicas=0

# ステップ4: 移行作業を実施
# データベースバックアップ
gcloud sql backups create --instance=mastodon-db

# Helm chartのインストール
helm install mastodon mastodon/mastodon \
  --namespace default \
  --values helm/values-production.yaml \
  --timeout 15m

# Podの起動待ち
kubectl wait --for=condition=ready pod \
  -l app.kubernetes.io/instance=mastodon \
  --timeout=600s

# ステップ5: 動作確認
kubectl exec deployment/mastodon-web -- curl -f http://localhost:3000/health
kubectl exec deployment/mastodon-web -- bundle exec rails db:version

# ステップ6: Ingressを新環境に切り替え
kubectl delete ingress mastodon
# Helm chartによるIngressが作成される

# ステップ7: アクセステスト
curl -I https://ykzts.technology/health

# ステップ8: 問題なければメンテナンスページを削除
kubectl delete deployment maintenance-page
kubectl delete service maintenance-page
kubectl delete configmap maintenance-html

# ステップ9: 旧環境のクリーンアップ
kubectl delete deployment mastodon-web mastodon-streaming mastodon-worker
kubectl delete service mastodon-web mastodon-streaming mastodon-assets mastodon-emoji
```

**想定ダウンタイム**: 30分〜1時間

---

## ダウンタイム発生の主な原因と対策

### 原因1: Podの起動が遅い

**対策**:
- `imagePullPolicy: IfNotPresent`を設定し、イメージが既にキャッシュされているようにする
- リソース requests/limits を適切に設定し、ノードリソース不足を避ける
- `initialDelaySeconds`を適切に設定し、ヘルスチェック失敗を避ける

### 原因2: データベース接続エラー

**対策**:
- 事前に接続情報（ホスト名、パスワード等）を十分に検証
- Secret設定を正確に確認
- 移行前にテスト環境で接続テストを実施

### 原因3: Ingress更新の遅延

**対策**:
- GCP Load Balancerの更新には時間がかかる（1-3分）ことを考慮
- 可能であれば、既存のIngress設定を引き継ぐ
- `ManagedCertificate`は事前に作成しておく

### 原因4: DNS伝播の遅延

**対策**:
- IPアドレスを変更しないようにする（既存のstatic IPを利用）
- 既存のIngress annotationsを引き継ぐ

## 推奨戦略の選択

| シチュエーション | 推奨戦略 | 理由 |
|----------------|---------|------|
| 本番環境、高トラフィック | Blue-Green | ダウンタイム最小 |
| 本番環境、低トラフィック | Rolling Update | コスト効率的 |
| 初回移行、不安が大きい | メンテナンスモード | 最も安全 |
| ステージング環境 | Rolling Update | コスト効率的 |

## ロールバック時のダウンタイム最小化

問題が発生した場合、迅速にロールバックすることが重要です。

### 即座のロールバック（1-2分）

```bash
# Ingressを旧Serviceに戻す
kubectl apply -f backup/ingress-mastodon.yaml

# 旧Deploymentがまだ残っている場合、スケールアップ
kubectl scale deployment mastodon-web --replicas=1
kubectl scale deployment mastodon-streaming --replicas=1
kubectl scale deployment mastodon-worker --replicas=1
```

### 完全ロールバック（5-10分）

```bash
# Helm releaseの削除
helm uninstall mastodon

# Kustomize構成の再適用
kubectl apply -k k8s/overlays/production

# HPA、BackendConfig等の復元
kubectl apply -f k8s/overlays/production/hpa.yaml
kubectl apply -f k8s/overlays/production/backendconfig.yaml
```

## モニタリングとアラート

移行中は以下をモニタリングします：

### 必須メトリクス
- [ ] HTTP 5xx エラー率
- [ ] HTTP レスポンスタイム
- [ ] Pod Ready 状態
- [ ] データベース接続数
- [ ] Redis接続数

### アラート基準
- 5xx エラー率が5%を超えたらロールバック検討
- レスポンスタイムが通常の2倍を超えたらロールバック検討
- 10分以上Podが起動しない場合はロールバック

## まとめ

- **Blue-Green デプロイメント方式**がダウンタイム最小化に最適
- 十分な準備とテストが成功の鍵
- 迅速なロールバック手順を常に準備しておく
- モニタリングとアラートで問題を早期検知

本番環境での実施前に、必ずステージング環境でのテストを実施してください。
