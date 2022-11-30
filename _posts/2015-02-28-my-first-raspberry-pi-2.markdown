---
author: kinoppyd
date: 2015-02-28 10:46:19+00:00
layout: post
image: /assets/images/icon.png
title: Raspberry Pi 2 に通電
---

## ****
Raspberrypi2


買ったは買ったけど、色々時間がつらくてしばらく放置していたので、3週間越しでやっと通電できた。


## NOOBS


[raspberrypi.orgのヘルプ](http://www.raspberrypi.org/help/noobs-setup/)に従い、NOOBSを使ってRaspbianを導入。なんかよくわからないテンションアゲアゲのおばちゃんが丁寧に説明してくれるので、特につまづく点はなし


## Raspbian


ラズパイ用にカスタムされたDebianらしい。だったらとりあえず

```shell-session
sudo aptitude update
sudo aptitude upgrade
```

まあ当たり前だけど、普通のPCよりかなり遅い


## Wi-Fi


無線でつなげれば多分最強な気がして、テキトーにやすかったBuffaloの無線LANアダプタを買ってきた。普通にデバイスとして認識するし、ちゃんと繋がるのも確認した。が、何故かケータイのテザリングのAPは見えるのに、ステルスモードにしてある自宅のルーターのAPには繋げない。追々調べるとしても、とりあえず今は有線接続で我慢。


## 何をしよう


さあ、このラズパイは何に使おう。とりあえず、会社の人に色々おすすめしてもらったセンサ類を買ってきてつないでみよう。
