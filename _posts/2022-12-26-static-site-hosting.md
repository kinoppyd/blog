---
author: kinoppyd
layout: post
title: ブログを静的ジェネレータに置き換えたので、どこにホスティングするか？
image: /assets/images/icon.png
date: 2022-12-26 02:30 +0900
excerpt_separator: "<!--more-->"
---

## 静的サイトのホスティング

ブログをJekyllに移行しました。 これまでのWordpressと違い、配信を勝手にはやってくれないので、何かしらの方法を使ってホスティングと配信する必要があります。

前回にも書きましたが、ブログを静的ジェネレータに移行した理由は、Wordpressを動かしているサーバーの値段がバカらしいこと、サーバーの更新が面倒で放置しがちになるのでセキュリティ的に良くないことがあげられます。なので、ホスティングに何を使うかの選択はJekyll移行の目的を達成できるかどうかにも関わってきます。やっていきましょう。

## 実際にたどった順路（TL;DR）

ホスティングに求められる機能は二つです。静的ファイルの配信と、これまでのtolarian-academy.netでのアクセスをkinoppyd.devにリダイレクトする機能です。

まずはGitHub Pagesが候補でした。ですが、GitHub Pages のJekyllサポートは、使用できるプラグインの中にpagination-v2が含まれておらず、パーマネントリンクを多用している自分のブログでは使用することができませんでした。

次にS3の静的ホスティング機能を使おうとしました。しかし、SSLに対応していないので、CloudFrontが必要だということもわかりました。今回移行した `.dev` ドメインは、HSTSという仕組みでブラウザアクセス時に強制的にHTTPSプロトコルにリダイレクトがかかるようになっており、HTTPS対応は必須でした。しかし、CloudFrontに刺す証明書をACMで取ろうとしたところ、Route53以外で取得したドメインではうまく証明書が割り当てられないことがわかり、AWS構成は諦めました。

さらなる候補はGCPで、GCSから静的ホスティングを行いCloud Load Balancingを使ってマネージド証明書を利用する方法でした。この方法はうまくいきましたが、Cloud Load Balancing の転送ルールに時間ごとに0.025ドルがかかり、月あたりまあまあな額の課金が発生します。これまでWordpressを配信していたサーバー維持費よりもさらに倍以上の値段がかかってしまうため、この方法もイマイチでした。

最終的には、GitHub Pages に対して Actions でデプロイができるベータが始まったことを知り、そこに移行しました。割と簡単な設定で、自前でビルドした成果物を置けるので、前述のパーマネントリンクの問題も解決です。

残っている課題は、tolarian-academu.net ドメインからのリダイレクト設定をどうしようかという点です。一旦GCP側に設定を残していますが、これも近日中に何かしらの解決策を見つけないといけないです。

<!--more-->

## GitHub Pages

GitHub Pages には、デフォルトでJekyllのサポートが組み込まれています。というか、正確にはGitHub Pagesが内部でビルドにJekyllを使っています。Jekyllを使ったビルドを何年くらい前からやっているか記憶は無いですが、たしか結構長いことやっていた気がします。

[GitHub PagesとJekyllについて - GitHub Docs](https://docs.github.com/ja/pages/setting-up-a-github-pages-site-with-jekyll/about-github-pages-and-jekyll)

ただ、組み込みのJekyllサポートでは、いろいろと制約があります。その一つが、プラグインです。GitHub Pagesでは、GitHub側が対応しているプラグイン以外の使用はできません。

[Dependency versions | GitHub Pages](https://pages.github.com/versions/)

以前はWordpressで運用していた自分のブログは、各ページへのリンクに `YYYY/MM/DD/hogehoge` のデフォルトスタイルではなく、専用の文字列を割り振ってパーマネントリンクを作っていました。理由は、なんかパスに日付とかが入るのが嫌だったためです。同様の機能をJekyllで実現しようとしたとき、ページネーション用のプラグインがパーマネントリンクに対応していないという問題がありました。もちろん、対応しているプラグインもあるのでそっちを使うのですが、GitHub Pagesの対応リストにあるのは対応してない方のプラグインのみでした。そのため、組み込みのJekyllで公開するのは無理だということになりました。

GitHub Pagesは、元々が特定ブランチの `/docs` ディレクトリ配下を静的ファイルとして公開するものなので、ActionsなどをつかってJekyllでビルドし、特定のブランチに青果物をコミットするという方法も可能です。実際、Jekyll以外の静的サイトジェネレータを使っている場合は、その方法が公式で紹介されています。ですが、なんかブランチをいじくってActionsでコミットするという動作が気持ち悪いので、一旦GitHub Pagesは諦めることにしました。

## S3 + CloudFront

静的サイトのホスティングと言えば、真っ先に出てくるのがS3です。これもいつからある機能なのかは全然覚えていませんが、AWS全体で見ても相当古い部類の機能のはずです。ただ、この機能はHTTPSに対応していないという問題があります。自分が登録している `.dev` のドメインは、HSTSという技術を使ってモダンブラウザからのアクセスは全てHTTPSを強制するという仕組みになっています。そのため、S3の配信機能だけでは、 `kinoppyd.dev` ドメインを使ってアクセスできないということになってしまいます。

[.devドメインと.appドメインがHTTPSを強制する仕組み - Qiita](https://qiita.com/tomoyk/items/187aa6723e80e1bba675)

そこで、S3で配信しつつHTTPSを実現する方法として。CloudFrontを使うのが一般的な解決策です。

[CloudFront を使用して Amazon S3 バケットに対する HTTPS リクエストを処理する](https://aws.amazon.com/jp/premiumsupport/knowledge-center/cloudfront-https-requests-s3/)

### ACMで証明書がとれない……

上記の手順を実行しようとしたときに、一つ問題が発生します。CloudFrontへのアクセスはHTTPSなので、当然証明書が必要になります。そしてAWSには、証明書を管理してくれるACMという素晴らしいサービスがあります。ですが、問題はその証明書の検証方法にありました。SSL証明書は、発行しようとしている証明書のドメインが本当にドメインを所有している人からのリクエストなのかを検証刷る必要があります。検証しないと、誰でも他の人が持っているドメインの証明書を作ることができてしまい、証明書の意味が無いからです。AWSのACMをはじめとした、無料で取得できる証明書の検証には、ほとんどの場合でDNSレコードでの検証が行われます。これは、DNSレコードに任意の値を設定できる人は、そのドメインを所有していることと同義だからです。ACMであれば、ドメインのCNAMEに特定の文字列を設定します。他にも、Let's EncryptではTXTレコードに特定の文字列を設定したり、Cloud Load BalancingであればAレコードにLBのIPを設定し、ドメインの所有を証明します。

ACMで証明書を取得しようとして発生した問題は、この「証明するドメインのCNAMEレコードに特定の文字列を入れる」というところでした。自分のブログは `blog.kinoppyd.dev` のようなサブドメインを置かず、 `kinoppyd.dev/blog` のようにAPEXドメインのパスで配信することを決めていたので、ACMで証明書を発行するためにはこのAPEXドメインにCNAMEを設定しなくてはなりませんでした。ですが、これは実はRFCで禁止されている仕様なのです。

[CNAME を巡る 2/3 のジレンマ - 鷲ノ巣](https://tech.blog.aerie.jp/entry/2014/09/09/162135)

Route53で取得したドメインであれば、この制約を回避する方法が提供されており、ACMを使って問題なく証明書を取得することができるようです。ですが、自分の `kinoppyd.dev` ドメインは、Googleドメインを使って取得しています。わざわざこのRoute53の便利機能のためにレジストラを移管するのもバカらしいですし、そもそもわりと急いでいたのでそんなことをしたくもありませんでした。

[AWS でホストしているサービスのエイリアスレコードを作成](https://aws.amazon.com/jp/premiumsupport/knowledge-center/route-53-create-alias-records/)

というわけで、ACMで証明書が取得できないという理由で、S3+CloudFrontの構成は利用できないということがわかりました。

## GCS + Cloud Load balancing

AWSがダメならGCPにすればいいじゃん、というわけで次に考えたのが、GCS + Cloud Load Balancing 案です。GCSはS3互換？　のため、S3にできることはだいたいできます。静的ファイルのホスティングもできます。Cloud Load BalancingはCloudFrontとは大分違いますが、SSL化するという意味では同じことができます。やってみました。

### GCSの設定

設定は大体このドキュメント通りです。ドメインの設定とかはやらないので、ファイルのアップロードと共有周りだけの手順をなぞります。

\
[HTTP を使用した静的ウェブサイトのホスティング  |  Cloud Storage  |  Google Cloud](https://cloud.google.com/storage/docs/hosting-static-website-http?hl=ja)

ただ、なぜかWebUIからうまく共有設定をできなくて、gcloudコマンドを使いました。最初はこのチュートリアルを見ずに手でがーっとやってうまくいかなかったので手順を確認したため、よくわからんことをしてしまっていた可能性が高いです。


### Cloud Load Balancing の設定と証明書の取得

Cloud Load Balancing で使う証明書は、ロードバランサを作成するフローで一緒に作成することができます。ACMとは違い、Cloud Load Balancing の証明書はDNSのAレコードで指定したIPが設定されているかどうかをチェックするチャレンジ方式なので、CNAMEがAPEXドメインに設定できないなどの問題を抱えることはありません。

\
[グローバル外部 HTTP(S) ロードバランサ（従来）のトラフィック管理の概要  |  負荷分散  |  Google Cloud](https://cloud.google.com/load-balancing/docs/https/traffic-management?hl=ja)

Cloud Load Balancing はちょっとややこしくて、フロントエンドとバックエンドが分離した設定になっていたり、「グローバル HTTP(S) ロードバランサ（従来型）」というものを選んで作らないとIPの構成が思った通りにならんかったりと、いろいろ面倒です。ドキュメントやハウツーはいろいろあるので、根気はいりますが一通り目を通せばなんとなく理解できる感じにはなります。

他にも、自分が必要だったものとして、元々ブログを書いていた `tolarian-academy.net` ドメインから `kinoppyd.dev` ドメインへのリダイレクトがあります。これも、Cloud Load Balancing の機能で対応可能です。

\
[グローバル外部 HTTP(S) ロードバランサ（従来）に URL の書き換えを設定する  |  負荷分散  |  Google Cloud](https://cloud.google.com/load-balancing/docs/https/setting-up-url-rewrite?hl=ja)

\
[グローバル外部 HTTP(S) ロードバランサ（従来）で HTTP から HTTPS へのリダイレクトを設定する  |  負荷分散  |  Google Cloud](https://cloud.google.com/load-balancing/docs/https/setting-up-http-https-redirect?hl=ja)

この機能もなんかイマイチ設定がよくわからなくて、何度も設定変えては試行錯誤みたいなことをやってしまいました。特に、これまでWordpressだったため、リソース管理はWordpress側でやっていた関係でパーマネントリンクの末尾に `/` は必要ありませんでしたが、静的ジェネレータを使うことになりディレクトリベースのパスルールが強制されるので、末尾の `/` が必須になりました。例えば、`tolarian-academu.net/zoom-gacha` という記事から `kinoppyd.dev/blog/zoom-gacha/` というURLにリダイレクトする必要があり、この設定がよくわからなかったですし、未だに納得のいく説明ができていないです。とりあえず、こんな感じの設定で動くようにはなっていますが……何で動くのかよくわかってないです。

<img alt="Cloud Load Balancingのリダイレクト設定" src="{{ site.baseurl }}/assets/images/2022/12/スクリーンショット 2022-12-26 1.16.10.png" width="50%">

### めっちゃお金かかっとるやん

お金かかってるんですよ。すごい。何でですかね……と思ったら、どうやらCloud Load Balancing のプライスは転送ルールの数によって決まるらしく、転送ルールを一個持っているだけで普通にまあまあな金額がかかるっぽいです。さらに、固定のIPもLB用に一つ持っているので、その値段もかかるっぽい？　です。ただ、GCPの支払い明細ってComputingとかそういう単位でしか出してくれないので、何にどれだけお金かかってるか正直よくわからないんですよね。

<img alt="お金めっちゃかかってる画像1" src="{{ site.baseurl }}/assets/images/2022/12/スクリーンショット 2022-12-22 1.20.21.png" width="40%">
<img alt="お金めっちゃかかってる画像2" src="{{ site.baseurl }}/assets/images/2022/12/スクリーンショット 2022-12-22 1.20.48.png" width="40%">

\
[ネットワーキングのすべての料金体系  |  Virtual Private Cloud  |  Google Cloud](https://cloud.google.com/vpc/network-pricing?hl=ja#lb)

ともかく、この金額はさすがに毎月払うのは話にならないので、GCP案もダメですということになりました。

## GitHub Pages + Actions

GCP案がダメで、どうしよっかなVPSでも借りてNginx建てようかな、CloudflareのPagesもいいなと思っていたところ、最初に没にしたGitHub Pagesに、なんとActions経由でPagesのオブジェクトを置く方法がBeta公開されたことを知りました。

\
[GitHub Pages: Custom GitHub Actions Workflows (beta) | GitHub Changelog](https://github.blog/changelog/2022-07-27-github-pages-custom-github-actions-workflows-beta/)

これ絶対欲しかった奴と思い、早速設定をしてみました。

具体的な設定としては、以下のステップを踏んでいきます。

ます、ブログのリポジトリのSettingsから、左ペインのPagesを選んで、Build and DeploymentのSourceをActionsに設定します。

<img alt="SourceをActionsに設定" src="{{ site.baseurl }}/assets/images/2022/12/スクリーンショット 2022-12-22 0.04.14.png" width="70%">

次に、使うActionsのWorkflowがサジェストされるので、Configureボタンを押します。

<img alt="Configureを押す" src="{{ site.baseurl }}/assets/images/2022/12/スクリーンショット 2022-12-22 0.04.40.png" width="70%">

Actionsでデプロイするためのワークフローがエディタ上で表示されるので、内容を確認してコミットします。

<img alt="Workflowが出るので編集して保存する" src="{{ site.baseurl }}/assets/images/2022/12/スクリーンショット 2022-12-22 0.05.10.png" width="70%">

デフォルトのワークフローの内容としては、チェックアウトしてJekyllの環境を用意し、ビルドしてPagesに投げるという一連の流れを行っており、ほとんど手を加えるところはありません。唯一、自分はtailwindを使っていたためPostCSS処理のためにNodeが必要で、nodeの環境セットアップだけを追加しました。

```diff
diff --git a/.github/workflows/jekyll.yml b/.github/workflows/jekyll.yml
index b480fe8..aabbafc 100644
--- a/.github/workflows/jekyll.yml
+++ b/.github/workflows/jekyll.yml
@@ -33,4 +33,11 @@ jobs:
       - name: Checkout
         uses: actions/checkout@v3
+      - name: Setup Node.js
+        uses: actions/setup-node@v3
+        with:
+          node-version: 16
+          cache: 'yarn'
+      - name: Install Node dependencies
+        run: yarn install --frozen-lockfile
       - name: Setup Ruby
         uses: ruby/setup-ruby@ee2113536afb7f793eed4ce60e8d3b26db912da4 # v1.127.0
```

これで、mainブランチにpushすると自動でビルドしてGitHub Pagesが更新されるようになりました。あとは、ドメインの設定だけです。

### ドメイン設定

GitHub Pages に独自ドメインを設定すると、自動でSSL対応もやってくれます。

[GitHub Pages サイトのカスタムドメインを管理する - GitHub Docs](https://docs.github.com/ja/pages/configuring-a-custom-domain-for-your-github-pages-site/managing-a-custom-domain-for-your-github-pages-site#configuring-an-apex-domain)

証明書のチャレンジはいくつかの方法が用意されていますが、DNSのAレコードを確認する方法が使えるので、問題なくAPEXドメインでも設定が可能です。自分の環境では、IPv4だけではなくAAAAレコードでIPv6対応も入れないと、ドメインチャレンジが成功しませんでした。

<img alt="なんだか不穏な警告が出ているが無視してる様子" src="{{ site.baseurl }}/assets/images/2022/12/スクリーンショット 2022-12-22 1.12.00.png" width="70%">

また、GitHub Pagesのドメイン設定では、APEXを設定する場合には `www` サブドメインの設定も推奨されているため、設定していないと警告が出ます。出ますが、私は無視しています。

### 残る問題点

これで `kinoppyd.dev` ドメインで GitHub Pagesを使った配信が可能になしました。しかし、残っている問題としては `tolarian-academy.net` のドメインからのリダイレクト設定です。このブログを書いている時点では、まだCloud Load Balancing で実現しており、お金をめっちゃ食い潰している状態です。そのうち、違うサービスが動いているVPSなどに設定をし直す予定です。

## まとめ

GitHub PagesのActions対応によって、なんだかキモいブランチ対応なしで、好きな環境でビルドした成果物を扱えるようになりました。これはすごく便利です。
