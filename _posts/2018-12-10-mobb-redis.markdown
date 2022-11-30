---
author: kinoppyd
date: 2018-12-10 16:40:50+00:00
layout: post
image: /assets/images/icon.png
title: Rubyを使って秒でBotを作るなら、秒でRedisだって使えなきゃ、やっぱり話にならないですよね？
excerpt_separator: <!--more-->
---

このエントリは、 [Mobb/Repp Advent Calendar](https://qiita.com/advent-calendar/2018/mobb-repp) の十一日目です





## mobb-redis


昨日のエントリでは、MobbでActiveRecordを利用する方法を紹介して、Sinatraの資産をMobbが継承できるという話をしました。そして今日はRedisです。こっちは本当に秒でいけます。

[https://github.com/kinoppyd/mobb-redis](https://github.com/kinoppyd/mobb-redis)

まず、検証用のRedisを立てましょう。今ならDockerで秒です。

```shell-session
docker pull redis
docker run --rm -p 6379:6379 redis
```

次に、mobb-redisをインストールします。例ではBundlerを使います。

```ruby
# frozen_string_literal: true
source "https://rubygems.org"

gem "mobb"
gem "mobb-redis"
```

最後にアプリケーションを書きます。

```ruby
require 'mobb'
require 'mobb-redis'

register Mobb::Cache

on 'hello' do
  settings.cache.fetch('great') { "hello world #{Time.now}" }
end
```

はい、秒ですね。起動して動作を見てみましょう。

```shell-session
bundle exec ruby app.rb
== Mobb (v0.4.0) is in da house with Shell. Make some noise!
hello
hello world 2018-12-11 01:36:16 +0900
hello
hello world 2018-12-11 01:36:16 +0900
```

このように、返答の中の時間が変化していないので、Redisを経由していることがわかります。


## redis-sinatra

<!--more-->


mobb-redisの元ネタは、redis-sinatraというgemです。

[https://github.com/redis-store/redis-sinatra](https://github.com/redis-store/redis-sinatra)

これは、redis-storeというWebフレームワーク用のRedisラッパーを使って、SinatraにRedisを提供しているgemです。

昨日のmobb-activerecordと同じく、私がやったことはリネームだけです。このコミットを参照してください。

[https://github.com/kinoppyd/mobb-redis/commit/aca774dd8d17f832d2ee6e9f3d7721a7fb314999](https://github.com/kinoppyd/mobb-redis/commit/aca774dd8d17f832d2ee6e9f3d7721a7fb314999)

それどころか、このgemはforkしてから変更して動作確認してパブリッシュしてこのブログを書くまで、トータルで一時間かかっていません。資産を使うということは素晴らしいことです。


## 秒で作れるBot、秒で扱えるRedis


さて、gemを作るのも秒だったし、みんなが使えるようになるのも秒でした。素晴らしい。これからもどんどんBotを作るときにRedisを使っていきましょう。
