---
author: kinoppyd
date: 2015-12-21 18:20:29+00:00
layout: post
title: ConoHaちゃんが好きすぎるので、WebAPIを叩くためのGemを（途中まで）作ってみた
excerpt_separator: <!--more-->
---

この記事は、[ConoHaちゃん Advent Calendar](http://qiita.com/advent-calendar/2015/conoha) の22日目です


## TL;DR


ConoHaちゃんが、普通にクラウドサービス的に使えて便利な上にマスコットは清楚かわいいしWebAPIも用意されていてプログラマフレンドリーだし、好きすぎるからAPI用のRubygemを途中まで作ったけどいろいろ大変だった話。


## ConoHaちゃん


このはちゃんは、昔は一応VPSサービスと言っていましたが、リニューアル後はクラウドと名乗っています。フルSSDが使えて転送量は定額、そして一番小さなインスタンスだと国内で（たぶん）一番安い料金設定がステキです。

このはちゃんとの出会いは、丁度いまの会社に入った時に、同僚の人たちに「このサービスのキャラかわいいよ」と教えてもらったことに始まります。確かにキャラが可愛かったことと、サービスとしても気軽にサーバーを借りられて、しかも転送量が一定であること、さらに結構頻繁にイベントや勉強会をやっていて、そこでクーポンをばらまいてくれるというどの辺が清楚なのかわからないところが好きで、いまでは自分で何かするときにはとりあえずこのはちゃんのサーバーで検証してたりします。先日、別のAdvent Calendar に書いた「[Deep learning でニコ生監視システム](http://tolarian-academy.net/niconama-watcher-with-deep-learning/)」にも、ConoHaちゃんのサーバーを使っています。

ちなみに、1年くらいはもらったクーポンで運用できてましたが、最近は普通に課金しまくってます。

<!--more-->


## ConoHaAPI


このはちゃんには、OpenStackに準拠した（らしい、実は私はよくわかってない）WebAPIが用意されていて、ほぼすべての操作をAPI経由で実行できます。できますが、APIの数がかなり多いのと、クエリをビルドするのが結構たいへんなので、これはライブラリ書くしかないなと思ってGemにしました。

[conoha_api](https://github.com/kinoppyd/conoha-api)


#### Usage



```ruby
require 'conoha_api'

client = ConohaApi::Client.new(
  login: 'username',
  password: 'password',
  tenant_id: 'tenant_id',
  api_endpoint: 'identityサーバーのエンドポイント'
)

# 登録してたキーペアの先頭を取得
key = client.keypairs.keypairs.first
# マシンの一覧の先頭を取得
flavor = client.flavors.flavors.first
# イメージの一覧の先頭を取得
image = client.images.images.first

# 集めた情報で、新しいサーバーを作成
client.add_server(image.id, flavor.id, key_name: key.keypair.name)

# 全部のサーバーを削除
client.servers.servers.each do |server|
  puts client.delete_server(server.id)
end
```



## 問題点


conoha-apiは、以前に作った[Goraku](http://tolarian-academy.net/chinachu-ruboty-useful/)と同様に、Octokitを参考に作られています。が、このはちゃんのAPIは、GithubやChinachuと違い、サービスごとにAPIのエンドポイントが変わります。たとえば、VMを操作するCompute Serviceと、アカウント情報を管理するAccount Service、アクセスの認証を得る Identity Serviceは、全部APIのホストが違います。ただパスが違うだけだったら良いんですが、普通にホスト名レベルで違います。最初は面倒だな程度に思っていましたが、実装を進めていくうちにいろんな問題にぶち当たりました。


#### ConohaApi::Clientのモジュールたち


ConohaAPIへのアクセスは、ConohaApi::Connectionモジュールに書かれたrequestメソッドから、Sawyerのラッパーを経由して行われます。そして各APIのエンドポイントは、ConohaApi::Clientクラスの名前空間の下にある、各サービス名に対応したモジュールに定義されています。たとえば、Computeサービスであれば、ConohaApi::Client::Computeモジュールにエンドポイントとメソッドとクエリが記述されています。

```tree
lib/
├── conoha_api/
│   ├── authentication.rb
│   ├── connection.rb     # request(get, post, put, patch, deleteでラップ)やagentメソッドが定義
│   ├── client.rb         # クライアントクラス
│   ├── client
│   │   ├── account.rb         # Clientクラスにincludeされ、requestメソッドを実際に発火する
│   │   ├── black_strage.rb
│   │   ├── compute.rb
│   │   ├── database_hosting.rb
│   │   ├── dns.rb
...
...
└── conoha_api.rb
```

ここで問題になるのは、各モジュールでアクセスするホストが違うということです。OctokitやGorakuであれば、ConnectionモジュールをClientクラスにincludeし、Connectionクラスに定義されたget, put, post, patch, delete メソッドを呼び出すことで単一のエンドポイントに統一的にAPIにアクセス出来るのですが、conoha-apiの場合は、APIの定義されたモジュールごとに、ホストを切り替えなくてはいけません。

```tree
lib/
├── conoha_api/
│   ├── authentication.rb
│   ├── connection.rb
│   ├── client.rb
│   ├── client
│   │   ├── account.rb         # ここの各Serviceに対応するモジュールは、それぞれ接続先が違う
│   │   ├── black_strage.rb
│   │   ├── compute.rb
│   │   ├── database_hosting.rb
│   │   ├── dns.rb
...
...
└── conoha_api.rb
```

とりあえず、まずは各サービスのモジュールに、エンドポイントを定義して、呼びだされたモジュールごとにホストを切り替えたSawyerオブジェクト（agentという名前で定義して、requestの中から呼び出されます）の向け先を変えようと思っていました。ですが、ある程度実装を進めたときに、問題にぶち当たりました。



	
  1. Identity Service でアクセストークンを取得するときに、各サービスのエンドポイントが提示される

	
  2. ライブラリとしての使い勝手を考えた時、Identity Serviceへのアクセスは暗黙的に行われるべき


1つ目の問題点は、各モジュールにホストをハードコートできないということです。Identity Service にアクセスした時に取得する情報こそ真に信じるべき情報であって、エンドポイントの情報はハードコートされるべきではないからです。これに関しては、Identity Service にアクセスした時に、各エンドポイントの情報を保持することで対応は出来ました。Clientクラスが持っているクラス変数に、各モジュールの名前をキーにしたハッシュマップを用意し、その中にIdentity Service にアクセスした時の情報を保持しておきます。そして、各サービスのモジュールからメソッドをコールした時、Clientクラスはそのメソッドをスタックコールから確認し、そのモジュール名に対応したエンドポイントをクラス変数から引くようにしました。

```tree
lib/
├── conoha_api/
│   ├── authentication.rb
│   ├── connection.rb
│   ├── client.rb
│   ├── client     # Identity Service にアクセスした時、Clientクラスのクラス変数に各エンドポイントを保持
│   │   ├── account.rb
│   │   ├── black_strage.rb
│   │   ├── compute.rb
│   │   ├── database_hosting.rb
│   │   ├── dns.rb
...
...
└── conoha_api.rb
```

更に大きな問題は、2つ目の問題でした。例えば、conoha-apiをrequireして、VMを立ち上げるためにComputeサービスにアクセスするために、わざわざClientオブジェクトを作成して、authを行う、という2ステップは行いたくありません。普通は、Clientオブジェクトを作成して、Computeサービスのメソッドをそのまま呼び出します。そうしたとき、Computeサービスが利用しているConnectionモジュールのAgentは、リクエストがあったときにまず認証情報があるかを内部的に確認します。そして、ない場合はIdentity Serviceにアクセスして、トークンを取得し、そして何事もなかったかのようにCompute Service のメソッドを呼び出します。こうすると、ユーザーが明示的にauth処理を行うこと無くライブラリを使えます。

ここで問題になるのは、実際にAPIを呼び出しているのはComputeモジュールなのに、内部で必要な通信はIdentity Serviceということです。ということは、1つ目の問題を解決した「呼び出し元のモジュールによってホストを変える」作戦だと、微妙にうまく行かなくなります。Connection#requestメソッドが複数回コールされた時、微妙に整合性がとれなくなります。

```
+ ConohaAPI::Client::Compute#add_server をコール
+ Clientが、認証情報を確認
+ 認証情報がない場合は、取得
+ ConohaAPI::Client::Identity#tokens をコール
この時、元の呼び出しがComputeモジュールだから、接続先はCompute Serviceのエンドポイント
どうやって切り替える？
```

最初は、Connection#requestがコールされた時に、現在のagentをtmp変数に保持して、新しくagentを取得し、最終的にtmpに戻すという方法をとりました。しかし、これではrequestの中で使用されるagentメソッド自体に、自分がどこに接続されているかの情報を渡す必要があり、agentを毎回新しく作成しなさなくてはならないという、やや微妙な実装になりました。インスタンス変数自体にその情報を持っても良いのですが、少なくとも自分が書いたコードでは、なんだか複雑な見た目になってイマイチだと感じました。

そこで、Connectionクラスのインスタンス変数に、次に繋ぎたいエンドポイントをスタックとして所持することによって、この問題はひとまず回避しました。requestがコールされた時、スタックトレースからServiceのつなぎ先を取得しスタックに積み、agentメソッドがこのスタックを参照してSawyerオブジェクトを切り替えることで、コネクションのプーリングが可能になりました。スタックにすることによって、agentもconnectionも複雑な処理や見た目を持つこと無く、比較的わかりやすく書けたと思います。

```
+ ConohaAPI::Client::Compute#add_server をコール
  - ConohaAPI::Connection#request をコール
    + ClientのConnectionStackに、Computeをpush
    + Clientが、認証情報を確認
    + 認証情報がない場合は、取得
    + ConohaAPI::Client::Identity#tokens をコール
      - ClientのConnectionStackに、Identityをpush
        + ConohaAPI::Connection#request をコール
          - ConohaAPI::Connection#agentをコール
            + ConnectionStackから、Identityを取得
            + Identityへ接続
            + ConnectionStack を pop
    + 認証完了
    + ConohaAPI::Connection#agent をコール
      - ConnectionStackから、Computeを取得
      - Computeへ接続
      - ConnectionStack を pop
```

もちろん、これはベストプラクティスとは思えないので、今後改良の余地はありますが、ひとまずこのように対応しました。


## 最大の問題点


Connectionモジュールの問題を解決すると、今度はまた別の問題が出てきました。ConoHaAPIは、数が多すぎることです……


#### 数字の問題


ConoHaAPIは、かなりの数があります。Connectionの問題を解決したら、あとはAPIの仕様に沿って機械的にガーッとエンドポイントを定義していくだけなのですが、それでも大量のリクエストJSONの作成や、例外処理、デフォルト挙動の定義など、かなり時間のかかる作業です。

そのため、一旦公開するバージョンはv0.1.0として、Identity Service と Compute Serviceの一部を実現した形になりました。理由は、Identity Service と Compute Serviceさえ実現できれば、最低限のVMの操作を行えるからです。これ以上の各サービスは、順次時間と必要を見て実装していこうと思います。


#### お金の問題


ライブラリを作った以上、テストをしないわけにはいきません。

が、このはちゃんがいくらリーズナブルとはいえ、VMを落としたり立ち上げたりしてたら、まあそこそこのお金になることは想像できます。今のところ、かかっているお金は数十円ですが、これから先各サービスを実装していくうえで、金銭的な負担はまあまあのものになりそうな気がしています。

これに関しては、モチベーションだけではなく、財布的な意味でも辛いので、ConoHaAPIのサンドボックス環境ができるか、あるいは勉強会でクーポンをもらうまでは、あまり積極的に開発に臨めないかも知れません。


## 今後


とりあえず、他のAdvent Calendar のネタにした、[Deep Learning でニコ生を完全監視システム](http://tolarian-academy.net/niconama-watcher-with-deep-learning/)を、API経由でぱぱっと立ち上げられるくらいには、ライブラリと周辺ツールを整備させていきたいと思います。

あと、すごくこのはちゃんのカレンダー欲しいです。今年の分は勉強会に行ったらもらえてすごくハッピーだったんだけど、リニューアル後はなんかあまり勉強会が開かれて無くて、このはちゃんと触れ合う機械が少なくて正直しょんぼりしています。
