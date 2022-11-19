---
author: kinoppyd
comments: true
date: 2018-12-19 06:28:43+00:00
layout: post
link: http://tolarian-academy.net/mobb-pass-matching/
permalink: /mobb-pass-matching
title: Mobbにおけるマッチのパッシング
wordpress_id: 604
categories:
- 未分類
---

このエントリは [Mobb/Repp Advent Calendar](https://qiita.com/advent-calendar/2018/mobb-repp) の十九日目です





## マッチのパッシング


この機能は次のバージョンにおいて実装される予定です。

次のようなBotを作成し、「hello Mobb」というメッセージを送った場合、得られる結果は「Yo」です。

    
    require 'mobb'
    
    on /hello (\w+)/ do |name|
      'Yo'
    end
    
    on 'hello Mobb' do
      'Survival of the fittest'
    end


これは、Mobbのパターンマッチは定義した順番にチェックされるので、最初の /hello (\w+)/ がすべての hello で始まるメッセージを吸収してしまい、次に定義されている 'hello Mobb' にマッチすることは決してありません。

この例は非常に極端な例ですが、特定のケースにおいてマッチングをパスしたいことは発生すると思われます。そのため、次のバージョンではpassキーワードが導入されます。

    
    require 'mobb'
    
    on /hello (\w+)/ do |name|
      pass if name.start_with?('M')
      'Yo'
    end
    
    on 'hello Mobb' do
      'Survival of the fittest'
    end


passキーワードは、呼び出されるとその場でブロックの評価を停止し、on/receive キーワードのマッチングを再開します。上のBotでは、nameがMで始まる場合は、 on /hello (\w+)/ のブロックを抜け、次の on 'hello Mobb' にマッチします。その結果、得られる返答は「Yo」ではなく「Survival of the fittest」になります。（もちろんこの例では、Mobb以外のMで始まる名前を送るとすべてのケースでなにも返答しなくなってしまいますが）


## Next Mobb


年内リリースがんばります
