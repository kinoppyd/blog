---
layout: post
title: 今年もRubyKaigiのCFP通らなかったので公開します
date: 2024-02-23 22:03 +0900
---
今年もRubyKaigiのCFP通りませんでした。やっぱり結構へこみますね。送ったプロポーザルの内容を共有しておくので、何かの役に立てばと思います。もしくは誰か添削でもしてください。

---

## Art of metaprogramming

### Abstract

Not a Black Magic. Metaprogramming is powerful and useful part of Ruby. This talk describe real world metaprogramming technics with code of famous gems. For example, How RSpec define their DSL, How Rack plugins (e.g. Puma, thin) register itself and how Rack find it, et al. Enjoy white magic metaprogramming world.

## For Review Committee

### Details
このセッションの目的は、著名Gemで使われるメタプログラミングの妙技を知ることで、聴講者の方々が書くコードの引き出しを増やすことです。そのために、Rubyの強力な武器であるメタプログラミングを、多くのユーザーが利用しているGemのコードを実際に見て挙動を追跡しながら紹介します。多くの人は、メタプログラミングを「メタプログラミングRuby第二版」という名著で学んだと思いますが、Gemを書く人でなければそのテクニックが現実世界でどのように生かされているかを目にする機会はあまり無いと思います。そのため、このセッションではメタプログラミングの力を実例とともに知ることで、聴講者の方々が書くことのできるコードの幅が広がることを期待しています。

まず最も有名な利用例であるDSLは、RSpecとminitestのコードを紹介しようと思います。普段多くのWeb開発者が用いているあの不思議な文法は、どのようにしてメタプログラミングで実現されているのかを紹介します。RSpecはRubyとは思えない構文を実現するためのテクニック、minitestは特定のメソッド名だけをフックする挙動や、autorunの仕組みなどを知ることができます。

次にプラグインの機構を、RackとActiveRecordのコードを見ながら紹介します。Rackのhandlerは、RackのHandlerモジュールを再オープンしてregisterメソッドを呼ぶというワイルドな方法が使われますが、ActiveRecordではActiveSupportの力を借りてロードされたときにフックするというマイルドな方法を使っています。それぞれ、プラグインを本体に登録するときの挙動やそのルックアップ、そして注意すべき点を知ることができます。

最後に、いくつかの光のメタプログラミングをお見せしようと思っています。これはまだProposalを書いている時点ではどのGemのコードを解説するか未定の内容ですが、メタプログラミングを使ってビックリするくらい感心する問題解決を行っているコードをいくつか紹介したいと思っています。例えばですが、ActiveRecordがどのようにカラム名のメソッドを自動生成するかなど、おもわず唸るようなテクニックを探して紹介したいと思っています。現実のメタプログラミングがRubyの便利さをここまで高めてくれるのか、と思えるようなコードを探して共有し、メタプログラミングの素晴らしさを皆で分かち合えたらと思います。

このセッションによって知ったメタプログラミングの奥深さを、実際の業務でも生かせる引き出しとして記憶に残していただけるような内容にしたいと思います。

### Pitch
RubyKaigiの参加者層は、コロナによるオンライン期間を経てかなりの入れ替わりがあったと感じています。実際にスポンサー各社が公開しているアンケートや、自分で聞いて回った感覚などから、オフラインのRubyKaigiに初めて参加するという方の数は事実として相当多い様です。新しくRubyKaigiに参加される方々の中には、フィヨルドをはじめとするプログラミングスクールの卒業生であったり、会社の新卒であったり、転職を機にRubyに触れたりなど、しっかりとしたプログラミングの知識と実力を持ちつつもRubyでの実務に携わった時間で見るとまだ若手という方が多く居るように感じました。

まだRubyの経験が浅い方々にとっては、メタプログラミングの便利さや楽しさを感じるよりも、よく知らない怖い何かというイメージの方が強いかもしれません。そんな方々に対して、メタプロの楽しさを伝え、よりRubyを使いこなすための道具を手に入れて欲しいと思い、Proposalを書きました。より多くの人がRubyの深い機能に注目し使いこなすことで、Rubyの世界がさらに広がっていくことにつながれば良いなと思います。

メタプログラミングは、Rubyの素晴らしい特徴の一つではありますが、ここ数年のRubyKaigiではそこにフォーカスしたセッションはそんなに多く採択されていません。事実、メタプログラミングは素晴らしい機能であるものの、毎年そんなに劇的な変化を見せたり新たな発明があるような類いの機能ではなく、常磐木のような機能です。だからこそ、その強力さを改めて伝えたいと思いました。また、RubyKaigiではTracePointやASTを使って黒魔術的な楽しみ方をする方も多く、自分も黒魔術大好きですし、それはそれでとても良いのですが、たまには光の白魔術も見せたいなぁ！　と思ったのが主たるモチベーションです。

### Spoken language in your talk
Japanese

## Speaker Information
kinoppyd
Engineer at SmartHR
