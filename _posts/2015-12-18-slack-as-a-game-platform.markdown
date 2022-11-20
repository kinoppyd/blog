---
author: kinoppyd
date: 2015-12-18 19:28:39+00:00
layout: post
title: ゲームプラットフォームとしてのSlack
excerpt_separator: <!--more-->
---

この記事は、[ Slack Advent Calendar](http://qiita.com/advent-calendar/2015/slack) の19日目です。


## Slackは、ゲームプラットフォームだ


最近、よくSlackをチームのチャットツールだと誤解されている方をお見受けしますが、皆本質を見誤っていると言わざるを得ません。Slackがチャットツールではなく、ゲームプラットフォームだという理由は、次の点から明らかです。



	
  * Emojiという美麗なグラフィックのアセッツ、しかもどれだけ登録しても無料

	
  * Emojiのサイズが統一的で、ドットとしての役割も果たす

	
  * テキストベースの複雑なコマンドも入力可能なコントローラ

	
  * ユーザー識別も可能なので、複数のコントローラでマルチプレイも可能

	
  * 画面描写がシンプルなので、難しいことを考えずにただ更新前と更新後の画面を用意するだけ

	
  * あといろいろと


以上のように、Slackがゲームプラットフォームだということは疑いようのない事実ですが、その反面ゲームプラットフォームとしてはやや機能が不足していると思われる面も少なくありません

	
  * 音を鳴らせない

	
  * FPSが低い

	
  * Directなんとかとまではいかないものの、なんか微妙に不便でよくわからないAPI

	
  * あといろいろ


まあなんというか、Slackはゲームプラットフォームなのに割とゲームを作る能力としては低いです。むしろ最近は、副産物としてのチャットツールの方を成長させようと躍起になり、ゲームプラットフォームとしての本分を忘れ去っているように見えます。


<!--more-->

## Slack Game


そんなSlackを、ゲームプラットフォームとして活用するために足りないのは何かと考えたところ、どうやら啓蒙活動が足りないように思えました。そう、Slackをゲームプラットフォームとして便利に利用するフレームワークが無いのです。

そこで、作りました。

[slack-game](https://github.com/kinoppyd/slack-game)

Slack上でゲームを作ることを支援する、RubyGemです。


## How to use


とりあえず、手っ取り早く説明するために、デフォルトでデモとして入っているライフゲームを動かします。

```shell-session
echo "source 'https://rubygems.org'\ngem'slack_game" >  Gemfile
bundle install --path tmp/bundle
export SLACK_TOKEN=your_slack_token
export CHANNEL=you_slack_channel
export LIFE_ALIVE=:black_large_square:
export DEFAULT_SPACER=:white_large_square:
echo "require 'slack_game'; SlackGame::Game::Lifegame.new(ENV['CHANNEL'], 20).main_loop" > test.rb
bundle exec ruby test.rb

```

[![lifegame]({{ site.baseurl }}/assets/images/2015/12/lifegame.gif)]({{ site.baseurl }}/assets/images/2015/12/lifegame.gif)

なんとなく、雰囲気はつかめてもらえたのでは無いでしょうか？

次に、最も簡単なサンプルをGistに用意しました。SlackGameのgemの中に用意されている、Demoというゲームを解説するために、適当に作りました

```shell-session
git clone https://gist.github.com/kinoppyd/00f50bb4eee7ad8c62ae game_example
cd game_example
export SLACK_TOKEN=your_slack_token
export DEFAULT_SPACER=:fog:
export CHANNEL=bot_test
bundle install --path tmp/bundle
bundle exec ruby run.rb
```

コード自体はこんな感じ





簡単な解説も付け加えておきます



	
  * SlackGame::Controllerクラスを継承して、commandに識別子と正規表現を渡す

	
    * 正規表現にマッチするmessageが入力されると、識別子がControllerに記憶される

	
    * takeメソッドを使って、その識別子を取り出す




	
  * SlackGame::Canvasクラスを継承して、dotに識別子と、その識別子に対応するemojiを渡す

	
    * Canvasクラスは、NxMのドットマトリクスを持っていて、drawメソッドでemojiの文字列に変換できる

	
    * それを、Slackに書き出すことで、NxMのドットのキャンバスを作成する

	
    * ENV['DEFAULT_SPACE']に設定したものが、デフォルトの空白emojiになる




	
  * 適当なクラス内で、先に作ったControllerとCanvasをインスタンス化する

	
    * main_loopメソッドで、Controller.takeを呼び出し、入力されたコマンドを得る

	
    * コマンドに対応し、Canvasを操作し、再描写する





このデモでは、l(left), r(right), u(up), d(down)の入力をSlackへの入力から取得し、キャラクターを動かして画面を再描写する簡単なゲームです

このように、SlackGameを使うことで、ドットを使った簡単なゲームを作成することが可能です。


## 免責


SlackGameは、基本的にSlackAPIを連打します。RateLimitに引っかかってなにか泣きを見ても、私は一切の責任を負いません。


## 言い訳


1ヶ月ほど前に、お酒を飲みながら作ったコードなので、いろいろと内部は綺麗ではありません。あまり参考になるコードは無いと思います。

これからは心を入れ替えて、真面目にコードを整備するので、いつの日かきちんとしたコードになると思います。


## 他の頭おかしい方々


[Vim scriptによるゲームの新アーキテクチャの考察](http://www.kaoriya.net/blog/2015/12/13/)
