---
author: kinoppyd
date: 2018-12-14 18:04:57+00:00
layout: post
image: /assets/images/icon.png
title: MobbのLogger
---

このエントリは、 Mobb/Repp Advent Calendar の十五日目です





## MobbのLogger


ネタ切れを起こしたので、時間を稼ぎます。

MobbのLoggerは、当然SinatraのLoggerを参考にして実装されました。そしてSinatraのLoggerは、RackのLoggerがそのままrequest経由で渡されてくるものでした。

MobbはSinatraをベースにしているので、当然Loggerに関してもRackをベースにしたReppから渡ってくるものです。

残念ながらというかなんというか、Loggerの存在を完全に忘れて今まで実装を進めてしまったので、Loggerに関する実装は次のバージョンでどうにかしようと思っています。その時は、MobbだけではなくReppにもそれなりの変更が入るでしょう。

```ruby
require 'mobb'

on /hello/ do
  logger.info('call hello')
  'hi'
end
```

Sinatraと同じ、こういう使い方ができることを想定しています。
