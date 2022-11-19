---
author: kinoppyd
comments: true
date: 2015-09-24 09:55:01+00:00
layout: post
link: http://tolarian-academy.net/diff-command-returns-1-but-success/
permalink: /diff-command-returns-1-but-success
title: diffコマンドの exit code って、差分がなければ0、差分が有れば1、失敗したら2なんだね
wordpress_id: 302
categories:
- Ruby
---

## T/O


タイトルの通り


## 悲しみ


いま書いてるRubyのコードで、シェルコマンドを実行する必要がある場所は、Open3を介して実行するようにしているんだけど、Open3#capture3メソッドは（というか、[Rubyのprocess.c](https://github.com/ruby/ruby/blob/09cbe9d64088b825a520fcba279cbca3df5c4035/process.c#L836)が）exit codeが1の場合、success?メソッドをfalseで返すようにしているらしく、普通のコマンドと挙動が違う

shellコマンドの実行を共通化していると、diffコマンドだけこの特殊な挙動を切り分けなくてはいけなくて辛すぎて泣きそう

diffyとかのライブラリとは違い、ディレクトリ構造の違いを取得したいケースなので、つらい


## 補足


自分で確認していないけど、チャットでもらった情報だとcmpとdiff3もそうらしい
