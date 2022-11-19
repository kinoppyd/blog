---
author: kinoppyd
comments: true
date: 2016-12-14 17:22:50+00:00
layout: post
link: http://tolarian-academy.net/chaos-conoha/
permalink: /chaos-conoha
title: Chaos ConoHa
wordpress_id: 431
categories:
- プログラミング
- ポエム
---

この記事は、「[ConoHa Advent Calendar 2016](http://qiita.com/advent-calendar/2016/conoha)」の15日目です。


## Chaos Monkey


クラウド時代の耐障害性という話題の中で、必ず話題に上がる非常に有名なNetflix製のOSS、Chaos Monkeyというものがあります。いまは、いろいろなツールを詰めあわせてSimian Armyという名前になっているらしいですが、非常に有名でユニークなプロジェクトです。

Chaos Monkey でググるとだいたいどのようなものかはおわかりいただけると思いますが、かいつまんで説明すると、AWS上に構成されているプロダクション環境のEC2インスタンスを、定期的にランダムに落とすというものです。混沌の猿が、AWSのデータセンターの電源でも抜いてるイメージなのでしょう。とにかく、日常的に意図的にマジな障害を発生させることで、普段から耐障害性のあるサービスやインフラストラクチャを構築でき、いざ実際に大規模な障害が発生した時に、何も焦ること無くサービスを復旧させることが出来るという、とても素晴らしい考え方に基づいたものです。

ConoHaのデータセンターでは、おそらく混沌の猿は飼っていないと思いますが（ConoHaのサービスがOpenStackで出来ており、かつSimian ArmyもOpenStackに対応しているので、もしかしたら本当に飼っているかもしれませんが、それは知りません）、ConoHaのデータセンターには座敷わらしが住んでいることで有名です。

はい、そうです。我らがこのはちゃんです。


<blockquote>

> 
> [#これを見た人は赤い画像を貼れ](https://twitter.com/hashtag/%E3%81%93%E3%82%8C%E3%82%92%E8%A6%8B%E3%81%9F%E4%BA%BA%E3%81%AF%E8%B5%A4%E3%81%84%E7%94%BB%E5%83%8F%E3%82%92%E8%B2%BC%E3%82%8C?src=hash)
いや、しづさんが描いてくれたこのはかな｜ω・) [pic.twitter.com/wLpkWexSVj](https://t.co/wLpkWexSVj)
> 
> 
— 美雲このは (@MikumoConoHa) [2016年9月28日](https://twitter.com/MikumoConoHa/status/780961382564896768)</blockquote>




実に<del>悪いことしそうな顔</del>清楚かわいい感じですね。

このはちゃんは座敷わらしだそうです。最近知ったのですが、<del>設定によると</del>我々には見えないらしいので、データセンターで何やってても不思議じゃないですね。うっかり足を引っ掛けてサーバーの電源を引っこ抜いたり、余計なおせっかいを働かせて新しいサーバーを追加してくれたり、使ってないと勘違いし気を利かせてサーバーを削除してくれたり。

なんか、しそうじゃないですか？



## Chaos ConoHa



まあ、なんかもう大体想像ついてると思いますが、[ConoHaのAPI](https://www.conoha.jp/docs/index.html)を使ってなんか悪い事するbotを書きます。

一応言っておきますが、これは[去年のACで作ったConoHa APIのGem](http://tolarian-academy.net/i-love-conoha-chan-too-much-to-create-gem/)を全くメンテしてないなぁという気持ちから、とりあえずなんか作ってみるかという感じで作っただけで、一切役に立つ機能はありません。マジでプロダクション用のConoHaアカウントで軽々しく実行したりしないでください。ConoHaちゃんのAPIトークンには権限とかないゆるふわ仕様なので、座敷わらしが一回トークンを知ったら最後、何でもやりたい放題です。

こちらが完成したものになります。

[https://github.com/kinoppyd/chaos-conoha](https://github.com/kinoppyd/chaos-conoha)

こいつを起動するスクリプトを書いて、後はcronにでも登録すれば、一定周期でChaos ConoHaがなんかします。

した結果をSlackにも通知してくれるようにしたので、なんか悪いことしたら喜んで報告に来てくれるでしょう。

今のところ作っておいた悪いことリストは




 	
  * ランダムで勝手にVMを追加する

 	
  * ランダムで勝手にVMを強制停止する

 	
  * ランダムで勝手にVMを削除する

 	
  * ランダムで勝手にVMを再起動する



なんかこれ以上は怖いのでやめました。

VMの追加に関しては、OSのイメージ名とVMのタイプを指定するのですが、両方一覧からランダムに選びます。

っていうか、VM削除する機能はマジでちょっとどうかとと思います。

はい、それでは実行してみます。

Gemの中に実行形式のファイルがあるので、bundlerを使えばそのまま実行できます


    
    bundle exec chaos_conoha -l ログインID -p パスワード -t テナントID -i Identityサーバーのホスト名 -s Slackトークン -c 結果を通知するチャネル名
    



はい、これで上の4つのアクションの内、どれか一つをランダムで実行します。マジでランダムで、本気で停止とか削除しに来るので、本当に気をつけてください。

で、なんどか実行してみました。

[![screenshot-from-2016-12-15-020405](http://tolarian-academy.net/wp-content/uploads/2016/12/Screenshot-from-2016-12-15-020405.png)](http://tolarian-academy.net/wp-content/uploads/2016/12/Screenshot-from-2016-12-15-020405.png)

**あああああああああああああああああああああああああああああああああちょ**



<blockquote>
雨すごいね…、明日も雨なんだって…！まぁ、このははデータセンターなんだけど。[#みくもスタンプ](https://twitter.com/hashtag/%E3%81%BF%E3%81%8F%E3%82%82%E3%82%B9%E3%82%BF%E3%83%B3%E3%83%97?src=hash)[https://t.co/mC505ycZo4](https://t.co/mC505ycZo4)[pic.twitter.com/Nf0emplhcO](https://t.co/Nf0emplhcO)

— 美雲このは (@MikumoConoHa) [2016年7月21日](https://twitter.com/MikumoConoHa/status/755994384500346880)
</blockquote>





（フィクションです）


<blockquote>

> 
> 美雲このはさんは6年に一度の美少女です。[#あなたは何年に一度の美少女](https://twitter.com/hashtag/%E3%81%82%E3%81%AA%E3%81%9F%E3%81%AF%E4%BD%95%E5%B9%B4%E3%81%AB%E4%B8%80%E5%BA%A6%E3%81%AE%E7%BE%8E%E5%B0%91%E5%A5%B3?src=hash)[https://t.co/WT1uL5X1Jg](https://t.co/WT1uL5X1Jg)
そ、そんな…！もうちょっとレアだよね…！ [pic.twitter.com/PYZQPv3omw](https://t.co/PYZQPv3omw)
> 
> 
— 美雲このは (@MikumoConoHa) [2016年10月18日](https://twitter.com/MikumoConoHa/status/788221309138329600)</blockquote>




（フィクションですが、消えたサーバーの上で動いているサービスはすべてDokkuで動いているので、いつ消えても大丈夫なImmutableな状態です。なので、新しくVPNを追加して、Dokkuをセットアップすれば、20分くらいで復旧出来ましたよ）
