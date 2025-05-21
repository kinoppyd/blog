---
layout: post
title: 関西Ruby会議08のプロポーザル落ちたので公開します
date: 2025-05-21 23:13 +0900
---
[関西Ruby会議08](https://regional.rubykaigi.org/kansai08/)のプロポーザルを2本送ったのですが、力及ばず採択されなかったため公開します。

今回は2本送ったのですが、1本はもう少しブラッシュアップして、またそのうちどこか違うイベントに送って再利用しようと思います。

## 1本目

### Title (Publicly viewable title. Ideally catchy, interesting, essence of the talk. **Limited to 60 characters**.)

Solid State Society

### Session format (**Fixed at 20 minutes.**)
### Abstract (A concise, engaging description for the public program. **Limited to 600 characters.**)

Rails 8 では、rails new をしたときにSolidQueue、SolidCache、SolidCableという3つのgemが標準で有効化されるようになりました。これらSolidの名を冠するGemは、それぞれActiveJob、ActiveSupport::Cache、ActionCableのバックエンドにデータベースを使用します。このデータベースはSSD上で動作していることが期待され、Solidという名前の由来もSSDからきています。また、Rails 8 からはProduction環境でのSQLite利用が推進されています。そしてこのSQLiteとSolid gemsのシナジーが、Railsの生産性をさらに加速させてくれます。このトークでは、SolidとSQLiteを使用することで、0->1開発の景色がどれだけ変わるかを皆さんにお伝えしたいと思います。

### Details (Provide an overview, expected outcomes, target audience, and any other relevant details.)

SolidQueue、SolidCache、SolidCableだけではなく、ActiveRecord::SessionStore、ActiveStorageDBを使い完全にSolidなRailsアプリケーションを開発体験をお伝えしたいと思います。
Railsはかなり容易に0->1ができるフレームワークですが、一方でRails 7 までは本番環境の構築にはRailsが動く実行環境に加え、PosrgreSQL/MySQLとRedisがほぼ必須のミドルウェアとして要求されていました。しかし、Rails 8の登場で本番環境でのSQLiteが推奨され、さらにSolid gemsが標準化されたことで、本番環境にRailsが動く実行環境以外のミドルウェアは基本的に必要なくなりました。このトークでは、さらにSessionStoreとActiveStorageもDB化することによって、真にSQLite以外を必要としないRailsの開発体験の話をします。本番環境でのインフラ構築に悩まないことが、どれだけ開発におけるマインドシェアを奪われず開発に集中することができるかを伝えたいと思います。
また、SQLiteを使うことによって生じるデプロイの難しさや、環境の制約についてもお話しします。特にクラウド環境でSQLiteを使う場合、複数のインスタンスにDBファイルが存在することは基本的にできず、取り回しが非常に難しいです。なるべくサーバレスサービスを使わず、同じくRails 8 で標準化したデプロイツールであるkamalを使うことが現状ではベストプラクティスになるという結論です。
このトークの対象者は、まだRails 8でrails newをしたことがない人たちです。新しいプロダクトを思いついたとき、難しいインフラ構成を考慮せず最速で本番環境まで持って行ける体験の良さを、まだSolidを使ったことが無い多くの人に伝えたいです。

このトークは、次のテックブログにて書かれているRubyKaigiのスケジュールアプリ構築の話をベースとします。
[https://tech.smarthr.jp/entry/2025/04/17/185354](https://tech.smarthr.jp/entry/2025/04/17/185354)

### Pitch (Explain why your proposal should be accepted and why you are the right person to speak on this topic.)

Rails 8 は、DHHが言うとおり0->1からIPOまでを全てこなせるフレームワークです。その真の実力を少しでも伝えることで、聴講者の中から起業とIPOを目指そうと思う人が出るかも知れない、つまりRubyで会社を作ろうと思ってくれるかもしれない可能性があることが、このトークを採択すべき理由です。私は実際に数百人が利用するRubyKaigiのスケジュールアプリを完全にSQLiteだけで運用した実績があり、その良さと悪さは十分に知っています。ゆえに私だからできるトークであり、私が公演するにふさわしい理由です。

### Your Name (A publicly visible name or ID.)

kinoppyd

### Speaker Bio (A short introduction about yourself, related to your talk. ****Limited to** 500 characters.**)

A Ruby programmer work at SmartHR Ltd, Inc.

## 2本目

### Title (Publicly viewable title. Ideally catchy, interesting, essence of the talk. **Limited to 60 characters**.)

Rubyでつくって子供と遊ぼう

### Session format (**Fixed at 20 minutes.**)
### Abstract (A concise, engaging description for the public program. **Limited to 600 characters.**)

Raspberry Pi Pico と PicoRubyを使って電子工作すると、オモチャが作れるらしいんですよ。つまりそのオモチャを使って遊んでいる子供は、もはやRubyistと言っても過言ではないですよね？
自分の子供をエリートRubyistにするために、PicoRubyでオモチャを作ってみよう。

### Details (Provide an overview, expected outcomes, target audience, and any other relevant details.)

マジな話、作る予定はあるんですが今のところ全く何もできてないんですよ。たとえば光るスイッチを一杯つけたり、音を鳴らしたり、そういう子供が好きなことができるはずなんです、PicoRubyを使えば。だってほぼ同じ要件のキーボードができるんだから。
GWを利用して子供にPicoRubyでオモチャを作ってあげる実験をしようと思っています。アイディアとしては、7セグ電卓やフィンガードラムなんかは作れそうだなと思いつつ、そこにRubyらしさをどう混ぜていくかを工夫することになると思います。その成果物に関して話すことになりますが、これを書いている今のところ何の成果物もないので、当日のお楽しみになります。
### Pitch (Explain why your proposal should be accepted and why you are the right person to speak on this topic.)

もしまかりまちがってこれが採択された場合、締め切り駆動開発で苦しむ私を見ることができます。

### Your Name (A publicly visible name or ID.)

kinoppyd

### Speaker Bio (A short introduction about yourself, related to your talk. ****Limited to** 500 characters.**)

A Ruby programmer work at SmartHR Ltd, Inc.
