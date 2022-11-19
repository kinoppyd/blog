---
author: kinoppyd
comments: true
date: 2017-10-15 15:52:52+00:00
layout: post
link: http://tolarian-academy.net/apt-get-upgrade-breaks-chrome/
permalink: /apt-get-upgrade-breaks-chrome
title: apt-get upgrade したら、Chromeが物故割れたのでなおした
wordpress_id: 477
categories:
- Linux
---

## Chromeがぶっ壊れる


UbuntuのChromeをどういうふうに管理していたのか自分でも忘れていたが、今までは普通にChrome自身のアップデートで、Chromeを再起動するたびに勝手に最新になっていた。しかし、ちょっと必要なパッケージがあり、何も考えず Ubuntu 15.04 vivid 上で apt-get update && apt-get upgrade したら、Chromeが起動しなくなった。

何度起動してもクラッシュするので、シェルから起動してみたところ、次のようなエラーが出て起動しないことが分かった。

    
    [16939:16975:1015/174831.367368:FATAL:nss_util.cc(632)] NSS_VersionCheck("3.26") failed. NSS >= 3.26 is required.


libnss3のバージョンの問題だったので、アップデートをすれば治るかと思ったが、 15.04 ではChromeが必要とするバージョンを入れることができないことが分かった。

[https://launchpad.net/ubuntu/vivid/i386/libnss3/](https://launchpad.net/ubuntu/vivid/i386/libnss3/)

そのため、わけあって 15.04 を使い続けていたが、最新のLTSである 16.04 xenial に入れ替えることにした。

Ubuntuのメジャーバージョンアップは今までやったことがなかったが、  do-release-upgrade というコマンドを使えば、特に難しいこと無くできるらしい。ただし、それは当然ながらサポート期間内のバージョンの話に限る。今回困った15.04は、はるか昔にサポート期限切れになっており、一筋縄では行かなかったので、ブログに書いて忘れないようにしておく。


## do-release-grade が動かない理由と対策


15.04 で do-release-upgrade を実行すると、次のようなエラーが出る。

    
    An upgrade from 'vivid' to 'xenial' is not supported with this tool.


15.04 (vivid) から、 16.04 (xenial) へのアップデートはできないと言われる。んなアホな。

とても困ったが、ググった結果ここのページに答えのほぼ全てと対策法が書いてあった。

[Ubuntu 最新バージョンへのアップグレード](http://server.etutsplus.com/how-to-upgrade-to-the-latest-version-of-ubuntu-with-do-release-upgrade/)

要するに、 vivid と xenial の間には、 wily というもうひとつのバージョンが存在するが、既に wily 自体が Out of date のため、 vivid から wily のアップデートが不可であり、 vivid から xenial への一つ飛ばしのアップデートもできない、というのが理由だ。対策としては、 changelogs.ubuntu.com/meta-release のレスポンスを何らかの方法で乗っ取り（Charlesを使っても良いし、  ダミーサーバーを立てたうえで /etc/update-manager/meta-release の中身を書き換えてもいい）、wilyが有効バージョンであると認識させる。詳しい方法は、リンク先に書いてあるのでそちらを参照。

概ね、この方法ですべてが解決するのだが、最大の問題は wily は既に archive.ubuntu.com からも消えており、上記のサイトの方法ではアップデートができないことだ。

なので、 meta-release の内容を乗っ取るだけでは do-release-upgrade で解決ができない。そのため、 wily のイメージをまだ置いているミラーをミラー一覧から探したうえで、 meta-release の参照先をそっちに向けて、更に /etc/apt/source.list の向け先もそっちにすることで、 do-release-upgrade を利用することができるようになる。

[Official Archive Mirrors for Ubuntu](https://launchpad.net/ubuntu/+archivemirrors)

ほとんどのミラーは、最新の archive.ubuntu.com と同期しているため、 wily のイメージが存在しない。だが、 dely しているミラーを参照することで、 wily のイメージが残ったままのものを見つけることができる。

いろいろと見て回った結果、 Psychz Network のミラーに wily の完全なイメージが残っているのを見つけたので、 meta-release と source.list を次のように書き換えた。

    
    $ diff -u meta-release meta-release.mod 
    --- meta-release	2017-10-16 00:37:32.536194125 +0900
    +++ meta-release.mod	2017-10-15 19:06:51.110240441 +0900
    @@ -237,12 +237,12 @@
     Name: Wily Werewolf
     Version: 15.10
     Date: Thu, 22 October 2015 15:10:00 UTC
    -Supported: 0
    +Supported: 1
     Description: This is the 15.10 release
    -Release-File: http://archive.ubuntu.com/ubuntu/dists/wily/Release
    +Release-File: http://mirror-lax.psychz.net/Ubuntu/dists/wily/Release
     ReleaseNotes: http://changelogs.ubuntu.com/EOLReleaseAnnouncement
    -UpgradeTool: http://archive.ubuntu.com/ubuntu/dists/wily-updates/main/dist-upgrader-all/current/wily.tar.gz
    -UpgradeToolSignature: http://archive.ubuntu.com/ubuntu/dists/wily-updates/main/dist-upgrader-all/current/wily.tar.gz.gpg
    +UpgradeTool: http://mirror-lax.psychz.net/Ubuntu/dists/wily-updates/main/dist-upgrader-all/current/wily.tar.gz
    +UpgradeToolSignature: http://mirror-lax.psychz.net/Ubuntu/dists/wily-updates/main/dist-upgrader-all/current/wily.tar.gz.gpg
     
     Dist: xenial
     Name: Xenial Xerus



    
    $ diff -u sources.list sources.list.mod
    --- sources.list	2017-10-16 00:41:43.129325767 +0900
    +++ sources.list.mod	2017-10-16 00:42:13.044595047 +0900
    @@ -2,39 +2,39 @@
     
     # See http://help.ubuntu.com/community/UpgradeNotes for how to upgrade to
     # newer versions of the distribution.
    -deb http://jp.archive.ubuntu.com/ubuntu/ vivid main restricted
    -deb-src http://jp.archive.ubuntu.com/ubuntu/ vivid main restricted
    +deb http://mirror-lax.psychz.net/Ubuntu/ vivid main restricted
    +deb-src http://mirror-lax.psychz.net/Ubuntu/ vivid main restricted
     
     ## Major bug fix updates produced after the final release of the
     ## distribution.
    -deb http://jp.archive.ubuntu.com/ubuntu/ vivid-updates main restricted
    -deb-src http://jp.archive.ubuntu.com/ubuntu/ vivid-updates main restricted
    +deb http://mirror-lax.psychz.net/Ubuntu/ vivid-updates main restricted
    +deb-src http://mirror-lax.psychz.net/Ubuntu/ vivid-updates main restricted
     
     ## N.B. software from this repository is ENTIRELY UNSUPPORTED by the Ubuntu
     ## team. Also, please note that software in universe WILL NOT receive any
     ## review or updates from the Ubuntu security team.
    -deb http://jp.archive.ubuntu.com/ubuntu/ vivid universe
    -deb-src http://jp.archive.ubuntu.com/ubuntu/ vivid universe
    -deb http://jp.archive.ubuntu.com/ubuntu/ vivid-updates universe
    -deb-src http://jp.archive.ubuntu.com/ubuntu/ vivid-updates universe
    +deb http://mirror-lax.psychz.net/Ubuntu/ vivid universe
    +deb-src http://mirror-lax.psychz.net/Ubuntu/ vivid universe
    +deb http://mirror-lax.psychz.net/Ubuntu/ vivid-updates universe
    +deb-src http://mirror-lax.psychz.net/Ubuntu/ vivid-updates universe
     
     ## N.B. software from this repository is ENTIRELY UNSUPPORTED by the Ubuntu 
     ## team, and may not be under a free licence. Please satisfy yourself as to 
     ## your rights to use the software. Also, please note that software in 
     ## multiverse WILL NOT receive any review or updates from the Ubuntu
     ## security team.
    -deb http://jp.archive.ubuntu.com/ubuntu/ vivid multiverse
    -deb-src http://jp.archive.ubuntu.com/ubuntu/ vivid multiverse
    -deb http://jp.archive.ubuntu.com/ubuntu/ vivid-updates multiverse
    -deb-src http://jp.archive.ubuntu.com/ubuntu/ vivid-updates multiverse
    +deb http://mirror-lax.psychz.net/Ubuntu/ vivid multiverse
    +deb-src http://mirror-lax.psychz.net/Ubuntu/ vivid multiverse
    +deb http://mirror-lax.psychz.net/Ubuntu/ vivid-updates multiverse
    +deb-src http://mirror-lax.psychz.net/Ubuntu/ vivid-updates multiverse
     
     ## N.B. software from this repository may not have been tested as
     ## extensively as that contained in the main release, although it includes
     ## newer versions of some applications which may provide useful features.
     ## Also, please note that software in backports WILL NOT receive any review
     ## or updates from the Ubuntu security team.
    -deb http://jp.archive.ubuntu.com/ubuntu/ vivid-backports main restricted universe multiverse
    -deb-src http://jp.archive.ubuntu.com/ubuntu/ vivid-backports main restricted universe multiverse
    +deb http://mirror-lax.psychz.net/Ubuntu/ vivid-backports main restricted universe multiverse
    +deb-src http://mirror-lax.psychz.net/Ubuntu/ vivid-backports main restricted universe multiverse
     
     deb http://security.ubuntu.com/ubuntu vivid-security main restricted
     deb-src http://security.ubuntu.com/ubuntu vivid-security main restricted
    


secure関連のところはよくわからんかったので何も書き換えていないが、この状態で vivid から sudo do-release-upgrade を実行して wily に更新し、再起動後にもう一度 sudo do-release-upgrade することで xenial に更新することができた。


## Chromeの復活


xenial への更新後、  sudo apt-get install --reinstall libnss3 を実行することで、Chromeは復活した。

正直、Chromeが起動しないくらいだったらいっぺんOS消して再インストールしても良かったんだけど、Chromeの中に入ってるクッキーを様々な理由で取り出す必要があったので、こんだけ必死になって修復した。

そもそもサポート切れのバージョンのOSつかうなって話ではあるけど、まあ何か参考になればと思って書き残しました。
