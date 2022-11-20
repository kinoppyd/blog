---
author: kinoppyd
date: 2016-03-06 18:40:27+00:00
layout: post
title: S3クローンMinioを使って、自前MicroServices用データストレージを構築する
excerpt_separator: <!--more-->
---

## Minio


[Minio](https://minio.io/)という、S3のクローンサービスがある。Goで書かれたAWSのS3のオープンソースクローンで、API互換のあるすごいプロダクトだ。Minioの起動時のヘルプに書かれている説明が非常にわかりやすいので、そのまま引用する。


<blockquote>Minio - Cloud Storage Server for Micro Services.</blockquote>


S3は使いたいが、個人プロダクトだからそんな派手な利用をするわけではないし、そんなちまちましたことでS3の料金をシミュレーションしてわざわざ胃を傷めたくないので、何かしらいい感じのクローンが無いかと思って探していたところ、普通に[s3 互換][検索]でぐぐったら上の方に[このエントリ](http://masawada.hatenablog.jp/entry/2015/12/15/000000)が出てきたので、早速試してみた。

なお、Minioはサーバー版のDLページに移動すると書いてあるが、「Minio server is under active development. Do not deploy in production.」とのこと。確かに、コミット履歴を見てみると、そこそこの勢いで更新され続けている。自分は単なる自分用のしょうもないサービスのストレージに使いたかっただけなので問題ないが、素直にプロダクション環境に使いたいなら、S3を使ったほうが良さそう。あるいは、S3でCI回すのがコスト的にキツイ時の代替手段程度だろう。


## 起動


ダウンロードページにも書いてあるが、非常に簡単。

```shell-session
$ curl https://dl.minio.io/server/minio/release/linux-amd64/minio > minio
$ chmod +x minio
$ ./minio
```

Goで書かれているので、単体のバイナリとして配布されているのが嬉しい。

ただ、上の方法だとhelpが表示されるだけなので、実際に起動するときは

```shell-session
$ ./minio server ./
```

の様に、serverコマンドとオブジェクトを保存するディレクトリを指定する必要がある。

起動すると、Minio内でAWSのaccess_key_idとsecret_access_keyとして扱える値が表示される。

素晴らしく簡単。

<!--more-->

## Webコンソール


Minioを起動すると、デフォルトでは9000ポートでサービスが起動し、同時に9001ポートでWebUIでMinioを操作できるコンソールが起動する。

ローカルで起動しているなら、http://localhost:9001にアクセスし、Minioの起動時に表示されたaccess_key_idとsecret_access_keyを入力すると、BucketやObjectを作って遊べるWebUIが提供される。

これを触っているだけでもそこそこおもしろいので、SDKからアクセスして挙動を試すために、いくつかBucketやObjectを登録しておくと良い。

[![Screenshot from 2016-03-07 02:41:51]({{ site.baseurl }}/assets/images/2016/03/Screenshot-from-2016-03-07-024151.png)]({{ site.baseurl }}/assets/images/2016/03/Screenshot-from-2016-03-07-024151.png)



とりあえず、テスト用にDownloadのフォルダにあったMemtestとUnetbootinを適当にぶん投げてみた。（どうして自分はUbuntuを使っているのに、rpmのファイルがDownloadに入っていたのだろう……？）


## Rubyからのアクセス


素直に、Amazonが公式で用意している [aws-sdk](https://github.com/aws/aws-sdk-ruby) gem を使用する。

aws-sdk自体は、AWSの他のサービスのAPIも全て含んでいて、AWSを普通に使う分には申し訳ないのだが、今回のようにS3クローンのみを使うにはかなり巨大なコードベース、かつコードもあんまり読みやすくないので、正直なところ使いたくなかったが、他のS3に特化したgemではAWS4-HMAC-SHA256、通称V4と呼ばれる方式に対応しているものが見つけられず、かつMinioはこのV4を要求する。そのため、公式のSDKを使うのが最も手っ取り早いようである。もしかしたら、Minioの設定でV4をオフに出来るのかも知れないが、調べるのが面倒で調べていない。

なんらかの任意の方法でaws-sdkをインストールするが、とりあえずbundlerとpryを使って簡単にテストするには、次のようなコードが一番楽だと思う。

```shell-session
$ mkdir minio_ruby && cd minio_ruby # 適当にディレクトリを作る
$ bundle init # Gemfileを作る
$ echo "gem 'aws-sdk'\ngem 'pry'" >> Gemfile # aws-sdk と pry をGemfileに追加
$ bundle install --path tmp/bundle # gemのインストール
```

```ruby
$ bundle exec pry
[1] pry(main)> require 'aws-sdk'
=> true
[2] pry(main)> credentials = Aws::Credentials.new('your_access_key_id', 'your_access_secret_key')
=> #<Aws::Credentials access_key_id="7GMXOL9P8J0YR5F237SE">
[3] pry(main)> c = Aws::S3::Client.new(credentials: credentials,
[3] pry(main)* region: 'us-east-1',
[3] pry(main)* endpoint: 'http://localhost:9000',
[3] pry(main)* force_path_style: true
[3] pry(main)*)  
=> #<Aws::S3::Client>
[4] pry(main)> c.list_buckets
=> #<struct Aws::S3::Types::ListBucketsOutput buckets=[#<struct Aws::S3::Types::Bucket name="foo", creation_date=2016-03-07 02:40:25 UTC>, #<struct Aws::S3::Types::Bucket name="hoge", creation_date=2016-03-06 03:21:54 UTC>], owner=#<struct Aws::S3::Types::Owner display_name="minio", id="minio">>
[5] pry(main)> c.list_objects(bucket: 'foo')
=> #<struct Aws::S3::Types::ListObjectsOutput
 is_truncated=false,
 marker="",
 next_marker="",
 contents=
 [#<struct Aws::S3::Types::Object key="memtest86 -5.01.bin", last_modified=2016-03-07 02:39:54 UTC, etag="", size=150024, storage_class="STANDARD", owner=#<struct Aws::S3::Types::Owner display_name="minio", id="minio">>,
 #<struct Aws::S3::Types::Object key="unetbootin-608-1.fc20.x86_64.rpm", last_modified=2016-03-07 02:40:25 UTC, etag="", size=565400, storage_class="STANDARD", owner=#<struct Aws::S3::Types::Owner display_name="minio", id="minio">>],
 name="foo",
 prefix="",
 delimiter="",
 max_keys=1000,
 common_prefixes=[],
 encoding_type="">
[6] pry(main)> c.get_object(
[6] pry(main)* response_target: './something.tar',
[6] pry(main)* bucket: 'foo',
[6] pry(main)* key: 'memtest86+-5.01.bin'
[6] pry(main)*)
=> #<struct Aws::S3::Types::GetObjectOutput
 body=#<Seahorse::Client::ManagedFile:./something.tar (closed)>,
 delete_marker=nil,
 accept_ranges="bytes",
 expiration=nil,
 restore=nil,
 last_modified=2016-03-07 02:39:54 +0000,
 content_length=150024,
 etag=nil,
 missing_meta=nil,
 version_id=nil,
 cache_control=nil,
 content_disposition=nil,
 content_encoding=nil,
 content_language=nil,
 content_range=nil,
 content_type="application/octet-stream",
 expires=nil,
 website_redirect_location=nil,
 server_side_encryption=nil,
 metadata={},
 sse_customer_algorithm=nil,
 sse_customer_key_md5=nil,
 ssekms_key_id=nil,
 storage_class=nil,
 request_charged=nil,
 replication_status=nil>

```

見づらい、が。

Aws::Credentialsクラスをわざわざ作っているが、どうせS3の機能しか使わないので、Aws::S3::Clientを作るときに直接指定しても良いかも知れない。

重要なのは、Aws::S3::Clientをnewするときに、endpointというオプションで 'http://localhost:9000' というアドレスを指定しているところで、これがAWSの繋ぎ先を変更し、ローカルのMiniに向けているところである。

また、おそらくURIを構築するときに何かあるのだろうが、force_path_styleオプションをtrueにしないと、Objectの取得が getaddrinfo: Name or service not known というエラーで終了してしまう。

そして作成されたクライアントに対してlist_bucketsのメッセージを送ると、先ほどWebUIで適当に作ったBucketsが返される。

list_objectでObjectの一覧の取得にも成功しているし、get_objectで、指定したローカルファイルにオブジェクトをコピーすることもできた。もちろん、MD5を取ってみたが、元のファイルと一致している。


## すごいぞMinio


ざっと触ってみたが、個人ユースのS3を使っているプロダクトのバックエンドをまるっと置き換えても、そこそこ使えそうな雰囲気が素敵だ。

何より、最近はDockerを使ったり、作ってるものをなるべくポータブルにするように心がけていたりするので、何かしら永続的なストレージが必要だけど、S3ほど大げさなものは必要ないという場合にはとても強力な選択肢になりそうだ。

すべての機能は試していないが、Rubyのaws-sdkのgemでそこそこ動くので、他の言語に用意されているS3用のクライアントでも、比較的簡単に切り替えが出来るような気がする。これはかなり嬉しいことで、開発中は適当にMinioを使って、プロダクションにのせるときにS3に変更したい時も、ライブラリ構成を変更せずに、設定一つで切り替えられてしまうということだ。

とりあえず、目下は自分のしょうもないプロダクトのバックエンドに使ってみるのと、このブログもDocker上で動いているので、ファイルストレージをMinioに変更してスケールが出来るようにしてみたい。
