---
author: kinoppyd
date: 2015-02-08 18:06:03+00:00
layout: post
image: /assets/images/icon.png
title: Homebrewのbundleコマンドが終わっていたことに初めて気づいた
---

### 久々にMacをクリーンにして、環境構築


自分の環境構築系は、全部Githubにあげてある。だから、その中においてあるシェルスクリプトをたたくだけで、終わるはずだったのに、恐ろしいメッセージが出た。

```
Error: Unknown command: budle
```

ない。マジでか。

最後に環境構築をやったのは、仕事で新しいMacをもらった去年の6月。正確にいつなくなったのかはわからないけれど、その直後のリリースあたりから消えたらしい。

[brew bundleが使えなくなったのでとりあえず使えるようにした](http://qiita.com/matsu_chara/items/78d0d0299a2f45270046)

なんか、メンテできなくなったらしい。なら仕方ない。


#### 急場をしのぐ


こんなエントリを見つけた

[Brewfileで管理するのはもうオワコン](http://unasuke.com/info/2014/brewfile-is-outdated/)

このエントリに書いてあった、BrewfileをShellScriptに変換するスクリプトで、とりあえず一名をとりとめる。しかし、どうしたものか。


### 代替手段


Ciderというものがあるらしい

[brew bundleできなくなったのでciderに乗り換えた](http://qiita.com/keitaoouchi/items/e5594279810b62538909)

ただ、よく調べていない点と、Pythonが必要になる点が気になって、今のところすぐに置き換えてみるつもりはない。

ただですらHomebrewはRubyで書かれていて、さらにそれを動かすためにPythonとpipが必要となると、それらを管理するシェルスクリプトのメンテがまためんどくさいことになりそうだから。

そのうち本気出して調べてなんとかする。
