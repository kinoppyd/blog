---
author: kinoppyd
date: 2016-05-03 03:46:35+00:00
layout: post
title: blink(1)を買ったので、雑にGemを作ってSlack監視botを作った
excerpt_separator: <!--more-->
---

## blink(1)


[http://blink1.thingm.com/](http://blink1.thingm.com/)

プログラマブルなLED。同僚が社内の有志を募って共同購入して遊んでいたのを見て面白そうだったので、余ったものを売ってもらった。

たくさんの[言語用のライブラリ](http://blink1.thingm.com/libraries/)が用意されていて、大抵の人は好きな言語を使って開発できると思う。


### 用途


面白いなぁとおもって購入し、とりあえず一通りチカチカさせて遊んだけれど、特にこれといって用途が思いつかない。

同僚の人たちは、HTTPサーバーを立てて、リクエストに応じてLEDを光らせるAPIを社内公開するというよくわからない遊びに興じていた（しかも攻撃されてすごいことになっていた）が、とりあえず自分はSlackに新しいメッセージが投稿されたらチカチカ光るようにした。ついでに自分の名前がSlack上で呼ばれたら激しく光るようにして、誰かがリアクションをするとまた激しく光るようにした。

とはいえ、どちらかと言うとSlackだけではなく、HTTPサーバーを立ててリクエストで光るようにして、色んなサービスのリアルタイムAPIを繋げてピカピカ光らせるのが正しい使い方な気がする。

WindowsだとIFTTTと連携したりしていろいろ光らせられるらしいけど、Macにはそのソフトは用意されていない。

ならば自分で作るしか無いと思い、とりあえず予行練習ということで、blink(1)用のDSLを書いてみた。

<!--more-->

### Blinkman


blink(1)となんかしらのadapterを繋げて、DSLで光らせるgemを書いた。

[https://github.com/kinoppyd/blinkman](https://github.com/kinoppyd/blinkman)

とりあえず、今のところ存在しているadapterは、デフォルトのshellとSlack用のみ。暇があったらほかのも書こうかと思う。

[https://github.com/kinoppyd/blinkman-slack](https://github.com/kinoppyd/blinkman-slack)

使い方は、Gemfileにblink-slackへの依存を書いて、簡単なDSLを書いて起動するだけ。

```ruby
source "https://rubygems.org"
gem "blinkman-slack"
```


```ruby
require 'blinkman'

bot = Blinkman::Bot.new do
  blink blue 2.times, during(250), when_if { |message| message.type == 'message' }
end

bot.listen
```


```shell-session
$ bundle install --path tmp/bundler
$ SLACK_TOKEN='your_slack_token' bundle exec ruby test.rb
```

DSLの構成としては、blink blue の様に blink hoge で発光する色を指定し（現状で有効な色はred, green, blueのみ）、その後に 2.times で2回チカチカ、durin(250) で250 millisec で実行する、と指定する。

when_if のブロックは、どのメッセージを受信した時に発光するかを指定するブロックで、今回はSlackのRTMが返すJSONをパースしたオブジェクトがそのまま渡ってくる。そのうち、typeが'message'の場合、つまりSlackの自分が所属してるチャネルに何かしら新しいメッセージが投稿された場合に true を返して、発光するようにした。


### 今後


とりあえず、blinkmanは練習のつもりで書いたので、適当にメンテしていく。

ひとまずは、messageの中身がSlackのJSONそのままなので、IDとかの解釈がめんどくさい。それらをラップしたMessage Object を定義して、扱いやすくしていきたい。

blink(1)自体は、Raspberry Pi に繋いで、色んなサービスの通知に応じてチカチカさせるマシーンを作ろうと思っている。
