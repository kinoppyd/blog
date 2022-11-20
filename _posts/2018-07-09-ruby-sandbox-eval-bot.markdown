---
author: kinoppyd
date: 2018-07-09 16:04:56+00:00
layout: post
title: Rubyのサンドボックスを作って、evalするBotを作った
excerpt_separator: <!--more-->
---

## 注意：安全じゃありません




## RubyのSnadbox環境


Sansbox環境とは、外部から入力されたプログラムを安全に実行する環境のことです。任意のコードを入力可能な場所で、いきなり system("rm -rf ~/) とか入力されて、それが本当に実行されたら困りますよね？　自分は困ります。ですが、外部から入力されたコードを安全に実行する環境というのはそれなりに需要があり、最もわかりやすいところではJavaScriptを実行するブラウザ、わかりにくいところでは今回作ろうとしているeval用のbotです。

ブラウザに関しては、インターネットという非常に治安の悪い場所から送られてくるコードを自分の環境で実行するので、サンドボックスが必要です。同じように、会社のSlackで公開するRubyの任意のコードを実行してくれるBotでも、社内の邪悪な人から投げ込まれたコマンドで自分の環境を破壊されると困るわけです。競技プログラミングの採点サーバーなどで、送られてきたコードを実行するときに邪悪な奴だったら困りますよね？　そういう邪悪なコードから身を守るために、サンドボックスは必要です。

その一方で、Rubyは結構自由すぎる言語で、任意の入力に対する安全なコードの実行というのはなかなか難しいです。Rubyには、汚染マークと[セキュリティレベル](https://docs.ruby-lang.org/ja/latest/doc/spec=2fsafelevel.html)という、外部からの入力を安全に扱う機構があり、これは[メタプログラミングRuby](https://amzn.to/2u4TY78)でも紹介されています。詳細はリンク先のページを見てもらえると解りますが、しかしこの機構には一つ大きな問題があり、それは**汚染された文字列をevalすることができないということです**。そのため、汚染された文字列を自分の手で安全だとマークしない限り、evalの引数に渡して実行することができないのです。それはつまり、セキュリティレベルで保護されている内容と同じレベルの安全性であることを自分で保証しなくてはならないということです。それって、セキュリティレベルを自分でもう一度チェックしなくちゃいけないということなので、ハッキリ言って意味が無いです。

なので、セキュリティレベルに頼ることなく、危険なコードを事前に実行できないように、サンドボックス環境を用意する必要があります。

<!--more-->

## 安全に邪悪なRubyコードを実行するには？


邪悪なコードというのは、概ねファイルをどうこうしたり、任意の外部コードを実行しようとするものです。冒頭の system("rm -rf ~/") もその類いです。なので、危険なコードを実行できるような機能を片っ端から潰していけばいいわけです。

Rubyのセキュリティレベルでは、Dir, File, IO, FileTestモジュールへのアクセスを禁止しています。また、任意のコードを実行するKernel系のメソッドも禁止しています。

幸い、Rubyは非常に強力なメタプログラミング機構を持っているので、このようなモジュールのアクセスに対するフックを用意することも容易です。また、Refinementという機能を使い、特定のスコープのみでそのフックを有効にすることも可能です。

具体的には、Dirなどのモジュールのクラスメソッドに対して、実行すると例外を投げるメソッドを定義し、すべてのメソッドのエイリアスとして設定します。

実際のコードは次のようなものになりました。

```ruby
module Sandbox
  [File, Dir, IO, FileTest].each do |klass|
    refine klass.singleton_class do
      def banned_method(*_); raise SecurityError.new; end
      klass.methods.each do |m|
        alias_method(m, :banned_method)
      end
    end
  end

  refine Object do
    def banned_method(*_); raise SecurityError.new; end
    allowed = [:Array, :Complex, :Float, :Hash, :Integer, :Rational, :String, :block_given?, :iterator?, :catch, :raise, :gsub, :lambda, :proc, :rand]
    Kernel.methods.reject { |name| allowed.include?(name.to_sym) }.each do |m|
      alias_method(m, :banned_method)
    end
  end
end
```

File, Dir, IO, FileTestの全メソッドに加えて、Kernelの使っても問題なさそうなメソッド以外を、すべて例外を投げるようにaliasします。

まず各モジュールに対してbannned_methodという、コールすると例外を投げるメソッドを用意し、各モジュールのメソッド一覧で得られたすべてのメソッドに対して、このbannned_methodへのエイリアスを張ります。そうすることで、ちょっとでも危険そうな動作をすると、例外を投げるようになります。

Kernelのコードも結構塞いでいるので心配になりますが、ちょっとevalするのにKernelのメソッドが必要になるケースの方がイレギュラーなので、無視します。

これを実際に利用するには、次のようにします。

```ruby
code = ARGV[0] # たぶん邪悪なコード

# Sandboxモジュールで包んだCleanroomを用意
safe_code = <<"CLEANROOM"
module CleanRoom
  using Sandbox
  #{code}
end
CLEANROOM

# 実行する
res = begin
  eval(safe_code)
rescue SecurityError, SyntaxError => e
  e.message
rescue Error => e
  e.message
end

puts res
```

evalするために渡されるコードを、Sandboxモジュールを適用したCleanRoomモジュールの中で実行し、その結果を得て出力します。

たとえば、 `rm -rf ~/` みたいに非常に邪悪な文字列を入れて実行すると、SecurityErrorが投げられます。

これを利用したRubyのeval用botは、次のリポジトリを参照してください。Mobbをつかって非常に簡素に書くことができました。

[https://github.com/kinoppyd/ruby-eval-bot](https://github.com/kinoppyd/ruby-eval-bot)


## 実際これは安全なんですか？


正直よくわかりません。概ねの場合において安全だと思いますが、Rubyはいかんせん自由度が高い言語なので、なんかこれくらいなら回避して邪悪なことができそうな気もします。

真に安全なSandbox環境がほしいので、是非これを読んだ人の意見を聞かせてほしいです。


## 他の安全な方法


もう一つ思いついた方法としては、evalするときにDockerコンテナを起動する方法です。

コンテナの中で実行されるRubyのコードが本当にホストから見て安全なのかどうかという確信はいまいち有りませんが、少なくとも自分でこねくり回したSandboxよりは安全な気がします。

しかし安全とはいえ、コンテナの中で実行できるすべてのことができてしまうと言えばできてしまうので、これもまあまあ怖いなあと思い、今回はSandboxを手で作ってみました。


## みんなの考えた最強のSandboxを教えてほしい


実際、Rubyのサンドボックスは需要は少ないと思いますが必要となるケースが無いわけでは無いと思います。

そのため、みなさんが作った最強のサンドボックスのコードを、教えてほしいなと思います。


## 追記1


会社のSlackで動かしたところ、早速邪悪なコードを放り込んでくれた隣の席の人がいました。こういうコードです。

```shell-session
ruby: end; begin; `echo "foo" > xxx.txt`
```

なるほど、実際CleanRoomの中に入力されたコード文字列をペタッと貼っているだけなので、SQLインジェクションみたいなことができるわけですね……あんまり深く考えていなかった。

対策として、入れられた文字列がRubyのシンタックスとして正当かどうかをチェックするようにしました。少なくともRubyのシンタックスとして正当であれば、周りをCleanRoomで囲えば安全なはずです。

[https://github.com/kinoppyd/ruby-eval-bot/commit/a1ae3efaefc7cc9b1d57197a59ff07fc4e774c24](https://github.com/kinoppyd/ruby-eval-bot/commit/a1ae3efaefc7cc9b1d57197a59ff07fc4e774c24)

RubyVMを使って、渡された文字列からASTを作成できるかどうかをチェックしています。先程の例のような文字列が渡されるとSyntaxErrorがスローされるので、評価部分に入ることはありません。

ありがとう、隣の席の邪悪な人。


## 追記2


斜め後ろの席に座ってる邪悪なRubyコミッタの人がまたろくでもないコードを投げつけてくれました。こういうコードです。

```shell-session
ruby: ENV.inspect
```

MobbはENVに入っているSlackTokenを参照しているので、この一撃でTokenのRegenerateが必要になりました。Regenerateしたとはいえ、Tokenがいきなり公衆の面前にさらされるのは結構精神的ダメージでかいので、これはへこみました。

putsとかの副作用系は封じていたので平気だったと思っていましたが、よく考えたらinspectとかto_sとかの方法で出力は得られるので、盲点でした。

対策として、ENVにアクセスしようとするコードは一律排除することにしました。結構力技で排除しているので、これはなんかいろいろこねくり回したら回避できる気もしますが、一旦入れておきます。

[https://github.com/kinoppyd/ruby-eval-bot/commit/c90a1d24125a816b2490b95375ce839b8a44e76b](https://github.com/kinoppyd/ruby-eval-bot/commit/c90a1d24125a816b2490b95375ce839b8a44e76b)

ありがとう、斜め後ろの席の邪悪な人。


## 追記3


下のフロアで働いてる邪悪なセキュリティマニアが、邪悪なコードを優しく送ってくれました。こういうコードです。

```shell-session
ruby: RubyVM::InstructionSequence.new("1+1").eval
```

なるほどね、そういえばASTはevalできるんだよね……という気持ちになりました。

[https://github.com/kinoppyd/ruby-eval-bot/commit/5125b409ae22bd985c4c077e3a4900f90e0563cf](https://github.com/kinoppyd/ruby-eval-bot/commit/5125b409ae22bd985c4c077e3a4900f90e0563cf)

ありがとう、下のフロアの邪悪な人。


## 追記4


TD社で働いている素敵な人から、はてブのコメント経由で指摘をいただきました。Object空間のKernel系は塞いているけど、Kernelを直接呼ぶとダメじゃない？ ということです。つまり、こういうことです。

```shell-session
ruby: Kernel.system("ls")
```

完全にうっかりしていたので、慌てて塞ぎました。GitHubが落ちててPushできなくて辛かったです。

[https://github.com/kinoppyd/ruby-eval-bot/commit/d35e1589616b50823d17c956c13e062871217168](https://github.com/kinoppyd/ruby-eval-bot/commit/d35e1589616b50823d17c956c13e062871217168)

ありがとう、TD社の素敵な人。


## 追記5


にょろにょろした素敵なアイコンの人から、TwitterでProcessが塞がれてないという指摘をいただきました。こういうことです。

```shell-session
ruby: Process.spawn("ls")
```

うっかりです。というか、モジュールが多すぎて見逃しがたくさんあります。

[https://github.com/kinoppyd/ruby-eval-bot/commit/977ab403cdff493c33101ed35426550c75e037d3](https://github.com/kinoppyd/ruby-eval-bot/commit/977ab403cdff493c33101ed35426550c75e037d3)

ありがとう、にょろにょろしたアイコンの素敵な人。
