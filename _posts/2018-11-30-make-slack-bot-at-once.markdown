---
author: kinoppyd
date: 2018-11-30 15:11:37+00:00
layout: post
image: /assets/images/icon.png
title: アイディアが閃いた？　それすぐにSlackBotにしましょう。秒で。
excerpt_separator: <!--more-->
---

この記事は、[Slack Advent Calendar](https://qiita.com/advent-calendar/2018/slack)と[Mobb/Repp Advent Calendar](https://qiita.com/advent-calendar/2018/mobb-repp) 共通の1日目の記事です





## Slack Bot を秒で作る方法


日常生活を送っていると、突然身の回りで何かが流行ることがありませんか？　私はよくあります。例えば、ある日突然絵文字をシャッフルすることが流行ったり、ちょっと昔には「Yo」と言ったら「Yo」と返すのが突然流行ったりしました。

何かが流行ったとき、それはbotを作るチャンスです。幸いあなたはプログラマで、流行った何かを更に面白くするアイディアとロジックは一瞬で頭に浮かびます！

けれど、そのロジックを実装するのは簡単ですが、実際にその機能をbotとしてSlackの野に放つのは簡単でしょうか？　私はあまり簡単ではないと思います。

例えば、多くの言語にはBot用のフレームワークが存在します。RubyであればRuboty、JSであればHubot、Pythonであればslackbot、JavaであればJBotなどが存在しますし、そもそも各言語のSlack用ライブラリが必ず存在するので、それを使えばフレームワークすら必要とせずにBotを作れます。

しかし、それらは本当に簡単でしょうか？　楽しいアイディアを思いついて、それをBot化するまでの間に情熱が冷めてしまうほど時間がかかりませんか？　そして他の人が似たアイディアのBotをSlackに先に放ち、「俺の考えてたアイディアのほうが面白いのに、先を越された」なんていう愚痴をSlackで吐いたりするようなことになってしまいやしませんか？

Botのアイディアは、秒で形に出来なくてはいけません。そして毎秒クソボットを作れるくらいのスピード感が必要なのです。けど、そんなこと本当に可能なのでしょうか？

可能です。あなたがRubyプログラマであれば。

<!--more-->

## Mobb


[Mobb](https://github.com/kinoppyd/mobb)は、秒でクソボットを生産するためのBot用フレームワークです。どれくらい秒か。体感してみましょう。

例えば、誰かが「テクテクテクテク」と言ったら、その文字列をシャッフルして返すbotのアイディアを思いついたとしましょう。ちなみに、テクテクテクテクは私が務めているドワンゴという会社が11/28にリリースしたゲームで、写真の深度分析をDeepLearningで行いキャラを上手に合成する機能がウリです。

さて、Botを作りましょう。まずMobbをインストールします。

```shell-session
gem install mobb
```

次に、以下のようなbotの内容を app.rb というファイル名で保存します。

```ruby
require 'mobb'

set :service, 'slack'

on 'テクテクテクテク' do
  'テクテクテクテク'.split("").shuffle.join
end
```

そして、環境変数でSlackトークンを渡しながら起動します。

```shell-session
SLACK_TOKEN=xxxxxxxxx ruby app.rb
```

以上。これで、指定したトークンを持っているBotがjoinしているチャネルで、誰かが「テクテクテクテク」という文字列を発言すると、botは「テクテクテクテク」をシャッフルして返答します。たとえば、「ククテテクテテク」みたいに。

どうですか、秒じゃないですか？　これがMobbを使ってBotを作る方法です。


## Mobbの仕掛け


Rubyプログラマの方はもうわかっていると思いますが、Mobbは[Sinatra](http://sinatrarb.com/intro-ja.html)のクローンと言っていいプロダクトで、SinatraがHTTPに対するWebアプリケーションを提供するように、Mobbはチャットサービスに対するBotアプリケーションを提供します。

まず、一行目ではmobbを読み込んでいます。これによって、app.rbというファイルそのものがMobbアプリケーションとして認識されます。

次に、setで利用するサービスを slack に指定します。Mobbには、SinatraにおけるRackのように、[Repp](https://github.com/kinoppyd/repp)というアプリケーションを使ってチャットサービスとの接続を行います。そのため、どのサービスに接続するかをここで指定します。

そして、onというメソッドの引数に渡された 'テクテクテクテク' の文字列ですが、この文字列と完全一致するメッセージがSlackから届くことによって、続くブロックを実行するトリガになります。

ブロックの中身は、 'テクテクテクテク' という文字列をシャッフルして、その値を返しています。Mobbでは、Sinatraと同様に、ブロックの戻り値をレスポンスとして扱います。このため、よくBotフレームワークで見る、引数で受け取ったMessageのようなオブジェクトに対してreplyメソッドを呼んで、などという煩雑な手順を踏まず、ただ値を返してやるだけでいいのです。


## もう少し複雑なMobbアプリケーション


Mobbで作れるBotは、先に出たテクテクテクテクのような一発ネタ以外にも、もう少し複雑な事もできます。たとえば、次のようなアプリケーションです。

```ruby
require 'mobb/base'

class CoolBot < Mobb::Base
 set :service, 'slack'
 set :bot_name, 'cool bot'

 helpers do
   def greet(target)
     "hi, I'm #{settings.bot_name}. How's it going #{target}?"
   end
 end

 on /I'm (\w+)/ do |target|
   greet(target)
 end

 every day, at: '15:00', dest_to: 'times_kinoppyd' do
   "Hey kinoppyd waz up? need coffee?"
 end
end

CoolBot.run!
```

このbotは、I'm ほげほげと挨拶してきた人に返答し、毎日15時になると自分にコーヒーを勧めてくれるbotです。簡単で単純なように思えますが、意外に難しい機能の実装が、たったこの数十行で完了します。

また、Sinatraと同じくモジュラースタイルにも対応しています。


## みんなも秒でBotを作ろう！


皆さんに秒でBotを作れる方法を紹介したところで、このエントリは終わります。もしもMobbに対して興味があれば、[Mobb/Repp Advent Calendar](https://qiita.com/advent-calendar/2018/mobb-repp) が存在するので、そちらの方でもう少し踏み込んだ機能や実装に触れていく予定です。

それでは、来年も楽しいSlackBotライフを。
