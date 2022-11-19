---
author: kinoppyd
comments: true
date: 2018-12-21 14:32:58+00:00
layout: post
link: http://tolarian-academy.net/mobb-service-gateway/
permalink: /mobb-service-gateway
title: Mobbを使った複数サービス間のゲートウェイを実現する方法
wordpress_id: 622
categories:
- 未分類
---

このエントリは、 Mobb/Repp Advent Calendar の二十一日目です





## サービス間ゲートウェイ


Slackの発言をIRCに転送したり、HTTPアクセスを受け取ってSlackに投稿するIncomming Webhook のようなものをMobbで書きたい場合にはどうすれば良いでしょうか？


## Mobbのロジックに書く


一つ目の答えは、Mobbアプリケーションのロジックに、転送先のサービスのクライアントを記述して、入力をすべてそちらに飛ばし、ブロックの戻り値はnilにして入力元のサービスには何も返さない方法です。多分これは一番直感的で楽だと思います。


## Reppハンドラを書く


もう一つの手段は、専用のReppハンドラを用意してしまうことです。デフォルトのハンドラでは、入力と出力のソースが同じため、容易にゲートウェイの動作をさせることはできません。しかし、入力と出力を別々にもつReppハンドラを記述することはできます。
