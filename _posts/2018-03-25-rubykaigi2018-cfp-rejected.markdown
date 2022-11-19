---
author: kinoppyd
comments: true
date: 2018-03-25 13:03:49+00:00
layout: post
link: http://tolarian-academy.net/rubykaigi2018-cfp-rejected/
permalink: /rubykaigi2018-cfp-rejected
title: RubyKaigi2018のCFP落ちたので後学のために置いておきます
wordpress_id: 500
categories:
- 未分類
---

タイトルの通り、RubyKaigi2018のCFPに送ったプロポーザルがリジェクトされたので、内容を公開して後学のためになればと思い、自らの反省点込で残しておきます。


## 送った内容




### Title


Reading Sinatra to build Sinatra-ish application


### Abstract


Reading Sinatra code is the best way to learn how to write minimal daemon program by Ruby.
Sinatra was made only of about 2000 lines Ruby code. However, the codes consist of skilled Ruby codes, fundamental metaprogramming techniques, and server programming techniques.
In this session, first I will introduce how I made a Sinatra-ish Bot daemon program. After that, I will explain the whole Sinatra code in 40 minutes.


### Details


Rubyのライブラリを作成/OSSに貢献するにあたって、Rubyの初心者が次の一歩を踏み出すためのトークをしたいと思います。そのためにまず、有名なライブラリのコードを読むことで、最初の一歩の手助けをしたいと思います。
このトークでは、まず最初に私が作成しているSinatraライクなDSLでBotを作るライブラリを紹介します。
その後、そのライブラリを作成するためにSinatraをどう参考にしたかを解説するため、Sinatraの約2000行のすべてのコードリーディングを40分のセッションの中で目指します。
このトークによって、聴講者はSinatraのコードを読んだという実績と、Ruby製のライブラリへの構造への理解を得て、Rubyによる開発によりいっそう親しめるようになることを期待しています。


### Pitch


多くの人がRubyのコードを書くことに親しみ、OSSへの貢献を目指します。
また、Sinatraのコードをまるまる読んだことがある人は意外と少ないと認識しているので、中級者にも新鮮な体験になるのではないかと思っています。


## 反省点


いくつか思いつくので、箇条書きにします


### 自分が作ったもののアピールポイントが少ない


Ruby25thイベントで、「RubyKaigiは自分が作ったものを自慢できるような場であればいい」の旨の発言を、どなたがなさっていたのかは失念しましたがされていたように記憶しています。

その中において、私がプロポーザルに書いたメインは「Sinatraのコードリーディング」の部分で、私が書いたBotのフレームワークに関する話はサラッと流れています。この次の反省点とも関連するのですが、Sinatraをメインに置くのではなく、自分のプロダクトをメインに（例えば、私のコードがどのようにSinatraから影響を受けたのかなど）して送るべきでした。


### 特定のアプリケーションの話をしようとしている


私がRubyKaigiに参加したのは2016年からですが、2回参加しただけでも、RubyKaigiにおける「特定のアプリに関する話はせず、Rubyの話をするべき」という空気は強く感じ取っていました。

その中に置いて、Sinatraという単一のプロダクトに関するコードリーディングをしたいというプロポーザルは、かなり無理筋だったような気がします。


### まだ作っている途中のプロダクトに頼ってプロポーザルを送ってしまった


プロポーザルの中に書かれたBotフレームワークは、まだ開発中です。アイディアレベルから、一応動くかな？ くらいの実装までしかまだ完成していないため、コードはGithubのパブリックリポジトリにはプッシュしていません。

そのため、まだどこにもコードが無いプロダクトに対して、レビュアーも評価の下しようがなかったように思います。自分が作ったプロダクトの話をしたいなら、せめてそのプロダクトのコードなりLPなりDocなりをもってこいと言われて然るべきだと思います。

実際、プロポーザルを送ってからも開発を続けていたところ、「これはプロポーザルに書くべきだったな」と思うようなコードやアピールポイントがどんどん見つかっています。まだアルファ版も完成していないプロダクトでのプロポーザルは、無謀でした。


### DetailとPitchが日本語


これはそんなに気にしていなかったのですが、過去にCFPを送って通った方のブログを見ると、RubyKaigiは国際カンファレンスなので、すべて英語で送ることが望ましいという旨のことを記している方が多いように思われます。なので、これは手抜きせずにきちんと英語で送るべきだったと思いました。


## 今後


反省点をだいたいまとめると、「まだ完成も公開もされていないプロダクトの話を、特定のアプリケーションのコードリーディングでごまかすようなプロポーザルを送ったのが失敗」だったと思います。そのため、来年はきちんと完成したものを元にしてプロポーザルを送るべきでしょう。

めげずに来年もCFPに出せるようにがんばるので、がんばります
