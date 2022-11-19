---
author: kinoppyd
comments: true
date: 2018-12-13 17:32:30+00:00
layout: post
link: http://tolarian-academy.net/mobb-regexp-match-datta/
permalink: /mobb-regexp-match-datta
title: Mobbの正規表現解釈と、MatchDataの行方
wordpress_id: 587
categories:
- 未分類
---

このエントリは、 Mobb/Repp Advent Calendar の十四日目です





## Mobbの扱う正規表現


Mobbでは、 on/receive メソッドの引数として正規表現を渡すことが出来ます。

    
    require 'mobb'
    
    on /add user (\w+)/ do |name|
      # name には、正規表現のキャプチャ結果が入る
    end


この部分は現在、次のようなコードで解釈がされています。

    
    def process_event(pattern, conditions, block = nil, values = [])
      res = pattern.match?(@env.body)
      catch(:pass) do
        conditions.each { |c| throw :pass unless c.bind(self).call }
    
        case res
        when ::Mobb::Matcher::Matched
          block ? block[self, *(res.matched)] : yield(self, *(res.matched))
        when TrueClass
          block ? block[self] : yield(self)
        else
          nil
        end
      end
    end


Reppからの入力が正規表現に一致した場合、 Mobb::Matcher::Matched オブジェクトが作成され、その中のキャプチャ結果を on/receive のブロックに対して引数として渡しています。

このように、Mobbは正規表現のマッチ結果を受け取れる能力はあるのですが、あるひユーザーのひとりに「名前付きキャプチャを使いたいから、RegexpのMatchDataをそのまま触らせって欲しい」という要望を伝えられました。

そのような用途もあることは理解できるので、どうにかMatchDataをユーザーが触れるように提供してみようと思い、次のような構文を考えています。

    
    require 'mobb'
    
    on /(?<word>\w+) \k<word> \k<word>/ do
      matched[:word]
    end


このBotに対して、 "hey hey hey" と呼びかけると、 "hey" という文字列が返ってくるようにしたいとおもっています。つまり、 on/receive の引数に正規表現をとった場合、matchedというアクセサがブロックの中で利用でき、呼び出すとRegexp#matchの戻り値が得られるような構文を考えています。

これらは、Sinatraでいうところの request/response/params といったアクセサと同じ扱いになりますが、SinatraがRackからの呼び出しの直後にこれらの変数を初期化するのに対し、Mobbでは初期化のタイミングがすこし遅くなることが変更点となるでしょう。


## 機能追加のリクエストお待ちしてます


Mobbの次のバージョンは、年内にリリース予定です。よろしくおねがいします。
