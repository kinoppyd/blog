---
author: kinoppyd
comments: true
date: 2018-12-16 16:18:13+00:00
layout: post
link: http://tolarian-academy.net/mobb-returns-nothing/
permalink: /mobb-returns-nothing
title: Mobb製のBotになにか処理をさせたが、何も反応を返したくないときはどうするのか
wordpress_id: 595
categories:
- 未分類
---

このエントリは Mobb/Repp Advent Calendar の十七日目です





## Botに何も発言をさせたくないとき


Mobbで作られたBotは、ブロックの戻り値の文字列をサービスに投稿します。しかし、ブロックを実行したあとに何も発言したくないときはどうすればいいのでしょうか？　答えは、nilを返せばいいのです。

    
    require 'mobb'
    
    on /.+/ do 
      File.write("#{Time.now}.txt, @env.body)
      nil
    end


このBotは、すべての発言に反応し、その発言をファイルに書き込み、何も投稿せずにそのまま処理を終了します。しかし、このnilを返す方法はやや分かりづらいとの指摘を受けたので、次のバージョンでは say_nothing キーワードと silent コンディションを用意します。

    
    require 'mobb'
    
    on /hello \w+/ do |name|
      say_nothing if name != settings.name
      "hello"
    end
    
    on /.+/, silent: true do
      File.write("#{Time.now}.txt", @env.body)
    end


say_nothing キーワードは、 say_nothing が呼び出された場合に、そのブロックがなんの値を返そうがサービスにポストを行いません。つまり、nilを返したときと同じ挙動をします。

silentはコンディションなので、現時点でも任意で追加可能ですが、Mobbのデフォルトに追加します。内容としては、ブロック実行後の戻り値を見て、何が入っていようがnilで上書きするコンディションを追加します。おそらく、実装としては次のようなコードになるのではないでしょうか？

    
    require 'mobb'
    
    helpers do
      def silent(cond) do
        dest_condition do |res|
          res[0] = nil
        end
      end
    end
    
    on /.+/, silent: true do
      "this string is not post to service"
    end




## 次のバージョンのMobbにご期待下さい


以上です
