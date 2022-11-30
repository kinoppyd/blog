---
author: kinoppyd
date: 2015-05-03 18:11:45+00:00
layout: post
image: /assets/images/icon.png
title: psコマンドをStructの配列として扱うRubyのクラスを適当に書いた
---

既にそういうgemがありそうだとはわかってて書いた。

このところ、家の録画サーバーが、おそらくハードウェア的な理由で不安定だったので、定期的にプロセスを監視するスクリプトを書く過程でこんな感じのものが必要になり、とりあえずgistにあげておいた。



Forwardableモジュールとかの知見はEffectiveRubyという本から得たものなので、そのうちまとめたい。

とりあえず、ProcessListクラスをnewすると、newした瞬間のps aux をStruct化したものの配列を得ることが出来る。

```ruby
$ pry
[1] pry(main)> require './ps_test'; ps = ProcessList.new
[2] pry(main)> ps.first.command
=> "/usr/lib/systemd/systemd --switched-root --system --deserialize 23"
```

Fedora20で動作確認はしたが、他の環境で動くのかどうかは全くわからない。
