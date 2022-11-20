---
author: kinoppyd
date: 2018-12-02 15:23:45+00:00
layout: post
title: Mobbの基本的な書き方
excerpt_separator: <!--more-->
---

このエントリは、[Mobb/Repp Advent Calendar](https://qiita.com/advent-calendar/2018/mobb-repp) の三日目です


## Mobbの基本的な機能


Mobb/Reppがなんなのかは昨日までのエントリで書いたので、今回はMobbで書ける基本的な機能を紹介します。

以下に上げるのは、Mobbのほとんどすべての機能なので、これを知っていれば秒でBotが作れます！


### 特定の文字列との完全マッチ



```ruby
receive 'テクテクテクテク' do
  # テクテクテクテク という発言があったらこのブロックに入る
end

on 'ポッポポッポハトポッポ' do
  # on は receive のエイリアス
end
```

<!--more-->


### 正規表現とのマッチ



```ruby
on /^ほげほげ/ do
  # ほげほげで始まる行の発言があったらこのブロックに入る
end

on /(\w+) is 何/ do |something|
  # ほげ is 何 のような発言があったらこのブロックに入る
  # パターンマッチの結果は、ブロック引数で受け取れる
end
```



### 定期実行



```ruby
cron '0 0 * * * * ' do
  # cronのシンタックスをパースして、指定された時間にこのブロックに入る
  # 上の例では、毎日0時にこのブロックに入る
end

every '0 0 1 * * *' do
  # every は cron のエイリアス
end

every 1.day, at: '12:00' do
  # Whenever(https://github.com/javan/whenever) の文法も使用できる
  # 上の例では、毎日12：00にこのブロックに入る
end
```



### モジュラースタイル



```ruby
require 'mobb/base'

class Bot < Mobb::Base
  # ignore_botフィルタは、次のバージョンから廃止され、デフォルトとなる
  on /Yo/, ignore_bot: true do |name|
    'Yo'
  end
end
```



### モジュラースタイルでのヘルパーメソッド



```ruby
# モジュラースタイルでは、ヘルパーメソッドを定義することで各ブロック内で独自のメソッドを呼び出せる

require 'mobb/base'

class Bot < Mobb::Base
  helpers do
    def hello(name)
      "hello #{name}"
    end
  end

  on /My name is (\w+)/ do |name|
    hello(name)
  end
end
```



### 条件フィルタ



```ruby
on /Yo/, reply_to_me: true do
  # 自身へのリプライメッセージかつ、/Yo/の正規表現にマッチするときにこのブロックにはいる
  # 自身の名前は、`set :name` で設定する
end

# 独自のフィルタは、このように定義する
set :end_with do |value|
  condition do
    # ここでは@envで飛んできた発言にアクセスしているが、次のバージョンからは非推奨とされるので注意
    @env.body.end_with?(value)
  end
end
```



### Botの設定



```ruby
set :name, 'smart bot'
set :environment, :production
```



### その他


他にも拡張を追加する extention などがありますが、これは例が難しく、普通に使う分にはhelpersで十分代用可能なので、別のエントリで紹介します
