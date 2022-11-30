---
author: kinoppyd
date: 2018-12-25 15:01:12+00:00
layout: post
image: /assets/images/icon.png
title: Mobb 0.5 and Repp 0.4 out now
---

このエントリは Mobb/Repp Advent Calendar の二十五日目です


## Mobb 0.5.0 out now


🎉

クリスマスなので、超急ぎでリリースしました。Ruby 2.6.0 も出たし。

Mobb 0.5.0では、Advent Calendar で予告していたいくつかの機能がリリースされます。

[Mobbのメソッド呼び出しをチェーンする、 chain/trigger シンタックス](http://tolarian-academy.net/mobb-chain-trigger/)

[BotはBotと会話するべきかどうか？](http://tolarian-academy.net/bot-and-bot-each-other/)

[Mobbの正規表現解釈と、MatchDataの行方](http://tolarian-academy.net/mobb-regexp-match-datta/)

[Mobb製のBotになにか処理をさせたが、何も反応を返したくないときはどうするのか](http://tolarian-academy.net/mobb-returns-nothing/)

[Mobbにおけるマッチのパッシング](http://tolarian-academy.net/mobb-pass-matching/)

これらの機能の新規実装により、 chain/trigger, react_to_bot/include_myself, matched, say_nothing/silent, pass キーワードが新たにMobbに追加されました。

```ruby
require 'mobb'

# chain/trigger
on 'hello' do
  chain 'chain1', 'chain2'
  'yo'
end

trigger 'chain1' do
  chain 'chain3'
  'yoyo'
end

trigger 'chain2' do
  'yoyoyo'
end

trigger 'chain3' do
  'yoyoyoyo'
end

# react_to_bot/include_myself
on /i'm (\w+)/, react_to_bot: true do |name|
  "hello #{name}"
end

on /yo (\w+)/, react_to_bot: true, include_myself: true do |name|
  "yo #{name}"
end

# matched
on /taks (?<task_name>\w+)/ do
  "act #{matched[:task_name]}"
end

# say_nothing/silent
on /do (\w+)/ do |task|
  say_nothing if task == 'slow_task'
  "act #{task}"
end

on 'bad!', silent: true do
  $stderr.puts("#{@env.user.name} is bad")
end

# pass
on 'yo' do
  pass
  'yo'
end

on 'yo' do
  'yoyo'
end
```

また、次の機能は予告していましたが0.5.0には入りませんでした。

[MobbのLogger](http://tolarian-academy.net/tmp-mobb-logger/)

[Mobbのcronを秒単位で動かす](http://tolarian-academy.net/kick-cron-every-second-in-mobb/)

[Mobbのマッチングにどれもヒットしなかった場合のフック](http://tolarian-academy.net/mobb-matches-not-register-pattern/)

理由としては、実装そのものは概ね出来ているのですが、大きな機能追加が入りきちんとリリース前の検証が出来なかったからです。この機能は、検証が終わり次第リリースします。


## Happy Mobb


25日間なんとかACを完走できました、これからもMobbをよろしくおねがいします。
