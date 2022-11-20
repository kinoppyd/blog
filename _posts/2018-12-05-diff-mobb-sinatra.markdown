---
author: kinoppyd
date: 2018-12-05 17:52:08+00:00
layout: post
title: Mobbの実装とSinatraの実装の比較
excerpt_separator: <!--more-->
---

このエントリは、Mobb/Repp Advent Calendar の六日目です





## Mobbの実装の元ネタ


これまで何度も出てきましたが、Mobbの実装はSinatraから非常に強烈な影響を受けています。しかし、はっきりと宣言しておきますが、強烈な影響を受けているなんていう生易しいものではありません。Mobbのコードは、ほとんどSinatraをコピペして作られていると言っても過言ではありません。

Mobbの文法やDLSのIFは、ほぼSinatraの形を踏襲しています。そしてその形を受け継ぐのであれば、どうやってもSinatraと同じコードが頻出することが最適解になっていきます。なにせSinatraは10年以上の歴史があるフレームワークで、その歴史の中でコードが無駄なく洗練され続け、その後追いをするならば必然的に同じコードが頻出することになります。なぜなら、Sinatraはわずか2000行ほどのコードで構成され、どうしてもそれ以上コードを削ることが難しいためです。


## Sinatraと全く同じコード


昨日のエントリでも書きましたが、helpers/registerは全く同じコードが出現します。

[https://github.com/kinoppyd/mobb/blob/6c089f5aee4763c6cf374905e5ce8ca8813e54d6/lib/mobb/base.rb#L250-L253](https://github.com/kinoppyd/mobb/blob/6c089f5aee4763c6cf374905e5ce8ca8813e54d6/lib/mobb/base.rb#L250-L253)

[https://github.com/sinatra/sinatra/blob/ba63ae84bd52174af03d3933863007ca8a37ac1c/lib/sinatra/base.rb#L1403-L1406](https://github.com/sinatra/sinatra/blob/ba63ae84bd52174af03d3933863007ca8a37ac1c/lib/sinatra/base.rb#L1403-L1406)

```ruby
def helpers(*extensions, &block)
  class_eval(&block)   if block_given?
  include(*extensions) if extensions.any?
end
```

[https://github.com/kinoppyd/mobb/blob/6c089f5aee4763c6cf374905e5ce8ca8813e54d6/lib/mobb/base.rb#L255-L262](https://github.com/kinoppyd/mobb/blob/6c089f5aee4763c6cf374905e5ce8ca8813e54d6/lib/mobb/base.rb#L255-L262)

[https://github.com/sinatra/sinatra/blob/ba63ae84bd52174af03d3933863007ca8a37ac1c/lib/sinatra/base.rb#L1410-L1417](https://github.com/sinatra/sinatra/blob/ba63ae84bd52174af03d3933863007ca8a37ac1c/lib/sinatra/base.rb#L1410-L1417)

```ruby
def register(*extensions, &block)
  extensions << Module.new(&block) if block_given?
  @extensions += extensions
  extensions.each do |extension|
    extend extension
    extension.registered(self) if extension.respond_to?(:registered)
  end
end
```

この2つは本当に全く同じコードを使っています。そのおかげで、Sinatraの資産をそのまま流用できる箇所でもあります。例えば、mobb-activerecordなどです。

他にも、before/afterフィルタや、invokeメソッド、デバッグ用にスタックトレースを追跡するコードや、デリゲータのコードなど、全く同じものが出てくる箇所がいくつもあります。

<!--more-->

## Sinatraに存在しないコード


MobbはSinatraのコードを可能な限り再利用していますが、しかしそれでもSinatraには存在しないコードを書かなくてはいけないケースが存在します。その一つが、cronです。

cronは、Mobbに定期実行を可能とするDSLですが、Sinatraの世界には存在しないものです。

[https://github.com/kinoppyd/mobb/blob/6c089f5aee4763c6cf374905e5ce8ca8813e54d6/lib/mobb/base.rb#L197-L205](https://github.com/kinoppyd/mobb/blob/6c089f5aee4763c6cf374905e5ce8ca8813e54d6/lib/mobb/base.rb#L197-L205)

```ruby
def cron(pattern, options = {}, &block) event(:ticker, pattern, options, &block); end
alias :every :cron

def event(type, pattern, options, &block)
  signature = compile!(type, pattern, options, &block)
  (@events[type] ||= []) << signature
  invoke_hook(:event_added, type, pattern, block)
  signature
end
```

eventは、Sinatraのrouteと同じ機能を持っています。しかしその一方で、cronに対応するものはありません。HTTPの世界観に、定期実行という概念は存在しないからです。しかし、その定期実行という概念も、MobbはSinatraのrouteに相当する概念として取り込んでいます。そのため、eventとrouteはほぼ同じコードです。実際の挙動としては、eventの第一引数に渡されるtypeによって、実行時の処理を切り分けているにすぎません。


## Sinatraとわずかに違うコード


MobbはSinatraを模倣していますが、それでも完全に同じというわけにはいきません。なぜなら、MobbとSinatraでは手法は同じですが関心事が異なるためです。それは、先にでてきた。「Sinatraに存在しないコード」と密接に関わっているものがほとんどすべてを占めます。

細部が違うコードはたくさんありますが、大きな意味を持って違うコードはhandle_eventメソッドだと思います。これは、Sinatraではroute!という名前のメソッドです。

[https://github.com/kinoppyd/mobb/blob/6c089f5aee4763c6cf374905e5ce8ca8813e54d6/lib/mobb/base.rb#L111-L121](https://github.com/kinoppyd/mobb/blob/6c089f5aee4763c6cf374905e5ce8ca8813e54d6/lib/mobb/base.rb#L111-L121)

```ruby
def handle_event(base = settings, passed_block = nil)
  if responds = base.events[@env.event_type]
    responds.each do |pattern, block, source_conditions, dest_conditions|
      process_event(pattern, source_conditions) do |*args|
        event_eval do
          res = block[*args]
          dest_conditions.inject(res) { |acc, c| c.bind(self).call(acc) }
        end
      end
    end
  end
end
```

[https://github.com/sinatra/sinatra/blob/ba63ae84bd52174af03d3933863007ca8a37ac1c/lib/sinatra/base.rb#L987-L1007](https://github.com/sinatra/sinatra/blob/ba63ae84bd52174af03d3933863007ca8a37ac1c/lib/sinatra/base.rb#L987-L1007)

```ruby
def route!(base = settings, pass_block = nil)
  if routes = base.routes[@request.request_method]
    routes.each do |pattern, conditions, block|
      returned_pass_block = process_route(pattern, conditions) do |*args|
        env['sinatra.route'] = "#{@request.request_method} #{pattern}"
        route_eval { block[*args] }
      end

      # don't wipe out pass_block in superclass
      pass_block = returned_pass_block if returned_pass_block
    end
  end

  # Run routes defined in superclass.
  if base.superclass.respond_to?(:routes)
    return route!(base.superclass, pass_block)
  end

  route_eval(&pass_block) if pass_block
  route_missing
end
```

この2つのコードは非常によく似ていますが、明確に違う処理が行われている部分が存在します。それは、Sinatra側はprocess_routeで条件に一致したブロックをroute_evalで実行するだけであることに対して、Mobbはprocess_eventで一致したブロックをeval_eventで実行する際に、dest_conditionsというフィルタを通過させている点です。

コードで見るとたった一行だけの違いですが、この違いはSinatraとMobbの扱っている関心ごとの違いを明確に表しています。それは、SinatraはHTTPのリクエスト/レスポンスが常に対になる世界を関心としていることに対して、Mobbはメッセージ/レスポンスという対の世界だけではなく、定期実行/レスポンスというSinatraやHTTPの世界には存在していない関心事を扱っているためです。

dest_conditionsは、実際のところは虚無から発生したアクション（正確には定時実行のタイマーが発火したイベント）に対して、正しいレスポンス先を示すために使われます。これは、Sinataの世界には全く存在しない概念です。


## Sinatraであり、SinatraではないMobb


このように、MobbはSinaraから多くのコードを受け継いでいます。その一方で、Sinatraの世界観には存在しない概念を、うまく拡張して追加しています。
