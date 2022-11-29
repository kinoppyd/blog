---
author: kinoppyd
layout: post
title: hello jekyll
date: 2022-12-01 00:00 +0900
excerpt_separator: "<!--more-->"
---
このエントリは、[SmartHR Advent Calendar 2022](https://qiita.com/advent-calendar/2022/smarthr)の1日目です。

## Hello Jekyll

ブログをWordpressからJekyllにお引っ越ししました。3年くらい前からWordpressから静的サイトジェネレーターに乗り換えたいなぁと思ってたけど、大分腰が重かったです。めちゃめちゃ重かったです。移行したことを褒めてほしい。すげえ気持ちが大変だった。

いっっっっっちばん腰が重かった理由はMySQLで、ブログを始めた当時の自分はブログ以外にもいろんなプロダクトとDBインスタンスを共有しようと思っていたので、Wordpress用のサーバーとは別にMySQL専用のVPSを借りました。そしてWordpressとMySQLはインターネット経由でつなぐため、SSLで通信していました。ブログにも書きましたね。なんですが、2014年にHeartbleed脆弱性が見つかり、各OSが古いバージョンのOpenSSLを使った通信を拒否するようになりました。なので、2018年とか2019年頃に「Wordpress移行してえなぁ……」と思っても、Wordpress用のDBからJekyll用のファイルに直接エクスポートツールがMySQLとSSL経由で通信できなくなり、いろいろな手を講じてエクスポートするのがとにかくめんどくさくてめんどくさくて……2022年11月まで放置することになりました。まあ結局、Wordpress側にXMLエクスポート機能がついていることに気づき、XMLをJekyllのMarkdownに変換するためのツールもあったので、それを使うことによって今までのSSLに関する努力は全部無駄になりましたが。

## Why Jekyll

ブログの移行先は静的サイトジェネレーターを使うことは決めていました。Webアプリケーションとして動いているブログは、アップデートに追従するのが精神的負担すぎると感じたためです。デプロイなどの自動化を行うというのもありますが、その自動化をメンテするコストもバカにならないし、自動化されたシステムを維持するのって金銭的コストもかかるんですよね。お金を生んでくれるシステムならいいんですが、単なるブログに月に数千円払うのはだいぶ経済的な負荷が高いなと感じます。それならば、単純な静的ファイルを生成してくれるジェネレーターの方が良いなというのが理由です。コメント欄がなくなるくらいしかデメリットないですしね。

<!--more-->

Jekyllを選んだ理由は、おそらく一番余計なことを考えなくて良いためです。最近話題なAstroも興味はありましたが、そもそも静的サイトジェネレーターのためにJSXのコードを書きたくなかった(書かなくてもできるとは思いますが、そうなるとますます選ぶ理由がない）し、GatsbyやNextも同様です。Hugoもいいなとは思いましたが、何かあったときに自分で原因を突き止められるほどGoのコードを読めないので、自分で解決できるRubyで書かれているJekyllが一番いいかなという考えです。

## Wordpress => Jekyll

WordpressからJekyllにデータを移行するには、大きく分けて2つの方法があります。一つは、jekyll-importerを使って直接MySQLのDBからデータを引き抜いてくる方法です。

[jekyll-import • Import your old & busted site to Jekyll — jekyll-import • Import your old & busted site to Jekyll](https://import.jekyllrb.com/)

何年か前に移行を試みた際にはこの方法を使おうとして、先述のSSLの問題にぶち当たり挫折しました。一応SSLの問題を解決してエクスポートを試みたこともあるのですが、なんかわりとWordpressのプラグインによる不思議構文との相性が悪かったりして、jekyll-importerに修正の[プルリク](https://github.com/jekyll/jekyll-import/pull/401)を出したりもしてました。とはいえ、何度かやってもいい感じにデータを抜けずに、結局また諦めました。

もう一つの方法は、Wordpressの管理画面のToolsメニューからXMLをエクスポートし、それをツールを使ってMarkdownに変換する方法です。なぜか[jekyll-importのWordpress.comに関するページ](https://import.jekyllrb.com/docs/wordpressdotcom/)で、代替手段として紹介されています。わかりづらい。[Exitwp](https://github.com/some-programs/exitwp)というツールがpublic archiveになっていますが、一番使い方がわかりやすかったのでこれを選択しました。

[some-programs/exitwp: Exitwp is tool primarily aimed for making migration from one or more wordpress blogs to the jekyll blog engine as easy as possible.](https://github.com/some-programs/exitwp)

動かした感想としては、特に難なく変換ができました。設定しているパーマリンクなどもFront Matterでちゃんと出力されており、便利でした。linkやwordpress_idなど、別にいらないFront Matterも含まれていたので、そういうのはsedで消したりしました。

他にも、Wordpressの独自の記法やプラグインなどの謎出力が残っていましたが、そういうものもsedでどうにか書き換えてちゃんとビルドできるように整形していきます。大体は数十行のスクリプトで自動的に解決できましたが、唯一解決できなかったのはコードブロックの言語指定です。スクリプトではコードブロックの中に何の言語が書かれているか判断できないので、これだけ頑張って手で補完しました。

## Jekyll w/ Tailwind

CSSはTailwindを選びました。凝ったデザインをする気は無いし、Tailwindのエコシステムにすべて乗ってしまう覚悟があったからです。少しでもTailwindの考えを逸脱したサイトを作ろうと思うと地獄だと思いますが、逆にすべてをTailwindに任せると心から決めていたので、迷いはありませんでした。流れに身を任せましょう。Tailwindに関しては人によっていろいろ思うところはあるようですが、個人的には好きです。Tailwindの流儀に従っている限りは優しいですし、レスポンシブやダークテーマへの対応も非常にやりやすい方法が用意されています。

JekyllにTailwindを入れるには、このサイトを参考にしました。

[mzrnsh › Starting a blank Jekyll site with Tailwind CSS in 2022](https://mzrn.sh/2022/04/09/starting-a-blank-jekyll-site-with-tailwind-css-in-2022/)

基本的には、 `tailwind.config.js` を用意して、jekyll-postcssプラグインを入れた上で `postcss.config.js` でTailwindを動かすように指示するだけです。ただ、この方法は一つ問題があって、現在jekyll-postcssプラグインで使われているjekyll-sass-converterというjekyll用のSass変換ライブラリの中で使われているSassライブラリが、デフォルトでsasscというものを使うようになっています。このsasscは、LibSassというC実装のSassコンパイラのRubyバインドだったが、LibSassは現在は開発が止まっており、最新のSCSS構文に対応しておらず、結果Tailwindのバージョン3系をビルドしようとすると失敗するという不具合が発生しています。現在のSassライブラリの世の中的標準はDart Sassというもので、Rubyではsass-embeddedというGem経由で利用できます。jekyll-sass-converterもv2.2.0で対応していますが、デフォルトではない。そのため、次のような設定を `_config.yml` に入れて、有効化することでやっとTailwind3系でpostcssビルドができるようになります。

[Jekyll Sass Converter 2.2.0からsassc(libsass)を外せるけど注意が必要 (2022-04-30)  あーありがち](https://aligach.net/diary/2022/0430/jekyll-sass-converter/)

なお、jekyll-sass-converter側でも、[次のバージョンでsass-embeddedを標準にしようとして](https://github.com/jekyll/jekyll-sass-converter/issues/141)いるので、この設定はそのうち必要なくなるかもしれないですね。

## Pagination v2

Jekyllには、標準でついてるjekyll-paginateというプラグインと、さらに進化したjekyll-paginate-v2という2つのページネーション用プラグインがあります。最初は特に難しいことしないのでjekyll-paginateでいいかなーと思っていたのですが、どうやらjekyll-paginateはパーマネントリンクに対応していないということがわかったので、泣く泣くjekyll-paginate-v2を使うことにしました。

[Pagination（ページ分け）  Jekyll • シンプルで、ブログのような、静的サイト](http://jekyllrb-ja.github.io/docs/pagination/)

もとのWordpressのブログの方でパーマネントリンクを使っていたため、移行にあたり全部のリンクを書き換えるわけにも行かず、パーマネントリンクを使い続けることができるv2しか選択がなかったのが悲しいです。また、当初 GitHub Pagesにブログをホストしようと思っていたのですが、jekyll-paginate-v2は GitHub Pages が対応していないらしく、ホスト先もまた別で考えることになりました。

## Hosting

当初は GitHub Pages にする予定でした。しかし、ページネーション用プラグインの対応がなされていないということで、他のホスティングを考える必要がありました。

ブログ移行の理由と同じく、動いている環境のアップデートなどを極力避けたいため、まずはS3の静的ホスティング機能を使おうと思いました。S3の静的ホスティングではHTTPSに対応していないので、CloudFrontを使ってHTTPS化も行います。しかし、ある程度まで環境を構築して気づいたのが、証明書の問題です。CloudFrontにCertificateManagerで作成した証明書を使おうとしたところ、証明書のACMEチャレンジにCNAMEを使う必要がありました。ドメインはGoogle Domainsで管理していたため、普通にCNAMEを登録しようとしたところ、ルードドメインにはCNAMEを設定できないことがわかりました。これはRFCの仕様によるもので、どうしようもありません。一応、Route53を使うか、もしくはドメインのDNSをRoute53に変更することでこの問題には対応できるのですが、わざわざこのためにドメイン移管やDNSの変更をやりたくなかったので、別の方法を模索することにしました。

[Route 53ならドメイン名そのものへのCNAME設定ができる (ただし、AWSのサービスに限る) - 株式会社ネディア │ネットワークの明日を創る│群馬](https://www.nedia.ne.jp/blog/2019/05/14/14118)

[AWS でホストしているサービスのエイリアスレコードを作成](https://aws.amazon.com/jp/premiumsupport/knowledge-center/route-53-create-alias-records/)

いくつか方法を調べていると、GCPのCertificateManagerがマネージしてくれる証明書は、DNSのAレコードにCloud LoadBalancerのIPが設定されていればACMEチャレンジを成功させてくれることがわかりました。そのため、S3 + CloudFrontを諦め、GCS + Cloud Load Balancing でホスティングを行うことにしました。

Cloud Load Balancing の設定はこれはこれでめちゃくちゃ難しかったので、後日またブログにします。

## suffix "/"

Cloud　Load Balancing でGCSのファイルをホスティングして気づいたのですが、たとえば `https://kinoppyd.dev/blog/zoom-gacha` のようなURLにアクセスすると、404になってしまいます。これは単純な問題で、 `zoom-gacha` というファイルが存在せず、実際に書き出されているのは `zoom-gacha.html` というファイルだからです。Jekyllの `_config.yml` では、次のような Permalink設定を入れていました。

```yaml
url: "https://kinoppyd.dev"
baseurl: ""
title: "kinoppyd.dev"
lang: "ja"
timezone: "Asia/Tokyo"
permalink: /blog/:title
```

この場合、`_posts/YYYY-MM-DD-zoom-gacha.md` というファイルは、`zoom-gacha.html` というファイルに変換されます。ですが、GCSで配信を行う際、 `/zoom-gacha` というURLで配信を行いたい場合、 `/zoom-gacha/index.html` というファイルを生成し、 `/zoom-gacha/` にアクセスすることで暗黙的に `index.html` を参照させるという方法をとる必要があります。これはGCSで静的ホスティングを設定する際に、デフォルトファイルとして `index.html` を指定することで、ディレクトリ名を指定すると自動で `index.html` を読みに行くという挙動を利用したものです。この問題の解決はPermalinkの設定方法で対応しました。

[Jekyll and S3 permalink problems? Here's how to fix it · Eric Kozlowski (He/Him)](http://www.ekozlowski.com/2017-11-12/permalink-debugging/)

デフォルトで最後に `/` を入れておくという方法ですね。実際のdiffは次のようになりました。

```diff
diff --git a/_config.yml b/_config.yml
index 69cb880..1b528ed 100644
--- a/_config.yml
+++ b/_config.yml
@@ -3,7 +3,7 @@ baseurl: ""
 title: "kinoppyd.dev"
 lang: "ja"
 timezone: "Asia/Tokyo"
-permalink: /blog/:title
+permalink: /blog/:title/
 
 plugins:
   - jekyll-postcss
```

これで、 `https://kinoppyd.dev/blog/zoom-gacha/` というURLでPermalinkを作成することができました。

## Bad Jekyll

Jekyllを使ってWordpressのブログを静的サイトに変換してみて、とても心理的な負担は減りました。ソフトウェアアップデートなどにマインドシェアを奪われることなく、これからは快適にブログを書けそうです。マークダウンが使えることも、好きなエディタで書けることもとてもうれしいです。

一方で、Jekyllを選んでちょっとつらいなと感じることもあります。それはLiquidです。実際、Liquidのコードはほとんど書くことがありません。ページネーションの動的コードを出すために使っている程度です。ですが、せっかく自力でどうにかできる言語で書かれたツールを選んだのに、なんだこのテンプレートエンジンは……という気持ちです。Pythonっぽい何かが書かれていて、なぜこれがJekyllの標準なのかよくわかりません。多分、テンプレートエンジンの部分をLiquidからERBに変える方法とかありそうな気がしているので、試してみたいなと思ってみたりもします。できるのかどうかはわかりませんが……

## The blog is dead, long live the blog!

4年くらいずっと重い腰をあげずにいたブログ移行を、ついに今年は成し遂げました。やったー。とはいえ、腰が重いのには重いなりの理由があり、やっぱりこの移行作業は半月くらいかかる大がかりな移行作業となってしまいました。大変だった。

ブログの環境が新しくなり、すこし肩の荷が下りた気がするので、またちょこちょこブログ書いていけるように頑張ります。