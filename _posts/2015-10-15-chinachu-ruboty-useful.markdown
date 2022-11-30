---
author: kinoppyd
date: 2015-10-15 18:01:33+00:00
layout: post
image: /assets/images/icon.png
title: Chinachu + Ruboty = 超便利
excerpt_separator: <!--more-->
---

## ruboty-chinachuプラグイン作ったよ


[Ruboty](https://github.com/r7kamura/ruboty)という、Rubyで実装されたbotエンジン用のChinachuプラグインを作った

[ruboty-chinachu](https://github.com/YasuhiroKinoshita/ruboty-chinachu)

Chinachuは、Nodeで実装されたLinux用の世界一キュートな録画サーバーだが、キュートなだけではなくAPIが完備されていて、プログラマフレンドリーでサイコーな録画サーバーでもある。前に[導入用のエントリ](http://tolarian-academy.net/christmas-anime-2014/)も書いた。


<!--more-->

### 導入


ruboty-chinachu使い方は、既に動いているRubotyのプラグインにruboty-chinachuを追加して、環境変数としてCHINAHU_API_ENDPOINTを追加する。（BASICログインを有効にしているならば、それも環境変数に追加する。詳細はREADME）

Rubotyの動かしかたそのものは、Qiitaとかで検索するとたくさん出てくるので割愛。

今のところruboty-chinachuで取得できる情報は



	
  * 24時間後までの録画予約リスト

	
  * 24時間前までの録画済みリスト

	
  * 現在放送中の番組リスト

	
  * 現在録画中の番組リスト





### 実際に動かすとこんな感じ


予約リストはこう

[![ruboty-chinachu-reserved]({{ site.baseurl }}/assets/images/2015/10/ruboty-chinachu-reserved.png)]({{ site.baseurl }}/assets/images/2015/10/ruboty-chinachu-reserved.png)

現在放送中はこんな感じ

[![ruboty-chinachu-broadcasting]({{ site.baseurl }}/assets/images/2015/10/ruboty-chinachu-broadcasting.png)]({{ site.baseurl }}/assets/images/2015/10/ruboty-chinachu-broadcasting.png)

これをruboty-cronを組み合わせれば、かわいいbotが定時に今日のアニメ予約リスト一覧を教えてくれる

[![ruboty-chinachu-reserved-cron]({{ site.baseurl }}/assets/images/2015/10/ruboty-chinachu-reserved-cron.png)]({{ site.baseurl }}/assets/images/2015/10/ruboty-chinachu-reserved-cron.png)

これで、毎日何時までに家に帰れば良いのかを把握できる

最高！



## Goraku、Ruby実装のChinachuAPIクライアント


ruboty-chinachuは、内部で[Goraku](https://github.com/YasuhiroKinoshita/goraku)というGemを使っている。これも作った。


### Gorakuができること


ChinachuのAPIにアクセスできるだけですね


### 今現在の問題点





	
  * テストが無い

	
    * これはそのうち書く




	
  * 例外処理が無い

	
    * これは割と緊急でマズい気がするので、手を付ける




	
  * 視聴用APIの実装が無い

	
    * 難しい




	
  * 各々のデータ構造を表すクラスや、バリデーションが無い

	
    * がんばる





視聴用のAPIは、Ruby実装で用意する必要があるのかどうか微妙なのでもしかしたら実装しないかも。あるいはプルリクください



### Gorakuの実装


[Octokit](https://octokit.github.io/)という、Github用のAPIクライアントをかなり参考にしました。Octokitに比べれば機能は少ないので簡略化してあるけど、ほぼそのままと言っていいくらい

Octokitは、コードもすっきりしているし何よりドキュメンテーションがとてもよくされているので、一度通してコードを読む価値ありだと思います
