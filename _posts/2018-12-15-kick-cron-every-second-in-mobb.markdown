---
author: kinoppyd
date: 2018-12-15 17:24:17+00:00
layout: post
image: /assets/images/icon.png
title: Mobbのcronを秒単位で動かす
---

このエントリは Mobb/Repp Advent Calendar の十六日目です





## MobbのCronは毎秒実行されない


MobbのCronは、CronのSyntaxをパースするため、最小の実行単位が分までしか設定できません。しかし、世の中には意外と毎秒何かを監視するという行動に需要があり、Mobbで作られたBotも毎秒何かを実行させたいという人は多いので、CronSyntaxを使わず毎秒実行するトリガーを、次のバージョンで追加することにしました。

```ruby
require 'mobb'

every_seconds do
  # act every seconds
end
```

every/cron キーワードはすでに使用されているため、新しいキーワードを設定する必要があります。every_secondsキーワードです。every_secondsに渡されたブロックは、毎秒ブロックの中身を実行します。注意しなくてはいけないのは、every_secondsは1つのBotで1度しか設定できない（複数設定された場合は最初に設定したものが優先される）ということです。

なぜevery_secondsは一つしか設定できないかというと、この設定は任意のn秒で実行されるわけではなく、毎秒実行されることを強制するからです。実際にBotを作成するときに求められる需要は、特定の秒になにかしたいではなく、毎秒なにかをしたい、というケースが想定されるからです。特定の秒に何かをしたい場合は、毎秒実行されている処理の中でその秒を判断すれば、実行できます。

every_secondsの実行でネックになるのは、0秒目、つまりcronが実行される可能性がある毎分の0秒だけ、処理がスキップされるという点です。これは、Mobbが送っている毎秒のトリガーが、先にcronのブロックにマッチするためです。0秒にevery_seconds と every/cron が競合するのは良くないことなので、どちらも実行されるようにはしたいですが、ひとまずミニマルな実装を行うため、0秒には every_seconds が走りません。


## every_secondsは次のバージョンで実装されます


お楽しみに
