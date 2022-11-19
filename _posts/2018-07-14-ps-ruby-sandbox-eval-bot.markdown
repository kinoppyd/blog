---
author: kinoppyd
comments: true
date: 2018-07-14 11:38:30+00:00
layout: post
link: http://tolarian-academy.net/ps-ruby-sandbox-eval-bot/
permalink: /ps-ruby-sandbox-eval-bot
title: 追伸：Rubyのサンドボックスを作って、evalするBotを作った
wordpress_id: 517
categories:
- Ruby
---

## 注意：安全じゃないです




## あらすじ





 	
  * 入力されたRubyのコード文字列を安全にEvalするBotを作ったと主張する

 	
  * 次々と安全ではないことがわかる

 	
  * ちょっとずつ安全に向けて改良したが、まだまだ安全じゃない


詳細はここ↓

http://tolarian-academy.net/ruby-sandbox-eval-bot/


## たくさん届いた指摘


前回の最後の追伸から一夜明けて、またいくつかの指摘を頂いた。それぞれに関して対策を講じていく。


### refine CleanRoomできる




<blockquote>

> 
> [@GhostBrain](https://twitter.com/GhostBrain?ref_src=twsrc%5Etfw) 'refine CleanRoom do system("ls") end' とかでusing無視できるっぽい！
> 
> 
— GTO (@mtgto) [2018年7月10日](https://twitter.com/mtgto/status/1016832546766635008?ref_src=twsrc%5Etfw)</blockquote>




こういう指摘がきたので実行してみたところ、確かに壊れた。

検証のためにこういうコードを書いてみると、確かにusingしているオブジェクトの中で自身をrefineすると、すでに効いているusingが無効になるようだった。


    
    module Sandbox
      refine String do
        def to_s; "override"; end
      end
    end
    
    module CleanRoom
      using Sandbox
      puts "string".to_s
      refine CleanRoom do
        puts "string".to_s
      end
    end
    
    puts "string".to_s
    
    # => override
    # => string
    # => string



試しにusingのなかのrefileのなかで self を見てみると、#<refinement:CleanRoom@CleanRoom> というオブジェクトが得られた。CRubyのコードを追うのは大変なのでこれがどういうものなのかがよくわからないけれど、ここに書かれた仕様を読むと、特定のスコープでrefinementという匿名オブジェクトを継承クラスに加えているだけなので、どうしてusingの内容が無効化されるのかはよくわかりません。

[https://magazine.rubyist.net/articles/0041/0041-200Special-refinement.html](https://magazine.rubyist.net/articles/0041/0041-200Special-refinement.html)

他にもいろいろ検証コードを書いてみた途中で思い出しましたが、RubyにはModule#ancestorsなどでは参照できない隠れたオブジェクトが存在することを、メタプログラミングRubyで読んだ気がします。オフィスに置きっぱなしで今手元にないので、後日確認して追記します。

ともあれ、対策はModule#reineを呼び出させないことで、こういう対応になりました。

[https://github.com/kinoppyd/ruby-eval-bot/commit/7d67df5853c302aad168c6df94e80fd470a780d5](https://github.com/kinoppyd/ruby-eval-bot/commit/7d67df5853c302aad168c6df94e80fd470a780d5)

Sandboxモジュールの先頭でselfに名前をつけて、Moduleのrefineの中でprivate_methodsをbannned_methodにaliasしました。

ただ、このやり方一つ問題があって、どこかでbannned_methodの呼び出しが無限ループし、SystemStackErrorが発生します。どっちにしろ例外でCleanRoomの外に出るのでいいんですが、あまり健康的ではない解決策なので、無限ループの対応をする必要があります。



### const_getできる




<blockquote>
[Rubyのサンドボックスを作って、evalするBotを作った](http://b.hatena.ne.jp/entry/367247096/comment/rinsuki)

const_get("\x45NV")

[2018/07/11 05:42](http://b.hatena.ne.jp/rinsuki/20180711#bookmark-367247096)
</blockquote>




文字列のエスケープは、以前にENVのアクセスを封じてたときにすでにリスクとして認識していましたが、const_getの存在を忘れていました。なので、Moduleのメソッドへのアクセスを禁止しました。

[https://github.com/kinoppyd/ruby-eval-bot/commit/3953b1b252057ffbeca4e34acfb9f5f312b0297c](https://github.com/kinoppyd/ruby-eval-bot/commit/3953b1b252057ffbeca4e34acfb9f5f312b0297c)


### TOPLEVEL_BINDINGに触れる




<blockquote>

> 
> [@GhostBrain](https://twitter.com/GhostBrain?ref_src=twsrc%5Etfw) に mention しないと気づかれてない気がするので、mention 付きで態度ツイートしておくと、 TOPLEVEL_BINDING.eval で抜けられそうです。
> 
> 
— Kazuhiro NISHIYAMA (@znz) [2018年7月11日](https://twitter.com/znz/status/1017028168262168577?ref_src=twsrc%5Etfw)</blockquote>



なるほどって感じでした、グローバル変数もかなりマズイです。

RubyのObjectに定義されたグローバル関数は、モジュール定義内で上書きすることができます。よく考えたら、ENVとかもここで書き換えておけば安全（なはず）なので、ENVの文字列チェックをやめこっちに移行しました。

[https://github.com/kinoppyd/ruby-eval-bot/commit/8f0d06bc19d4d30ceca68723589391b6868604b8](https://github.com/kinoppyd/ruby-eval-bot/commit/8f0d06bc19d4d30ceca68723589391b6868604b8)


## 気軽にSandboxということの楽しさとつらさ


社内で気軽にRubyのコードを実行できるBotが欲しくて、ものすごいマズイことが起きなければいいかなくらいの気持ちで作った実装を公開したら、思った以上の反響と邪悪な人たちと素敵な人達に反応してもらいました。もらった指摘はとても役立つもので、原因や対応策を考えるのはとても楽しかったです。

しかし、気軽なSandboxは当然気軽なものでしかなく、無限に襲ってくる脆弱性に対応するのはやっぱり大変です。ちょっと仕事の時間に遊びすぎたと反省しました。

願わくば、このエントリに追記が増えていきませんように。
