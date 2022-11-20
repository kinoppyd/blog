---
author: kinoppyd
date: 2015-07-26 18:29:02+00:00
layout: post
title: UbuntuでMySQLの通信をSSL化するときは、証明書のディレクトリが重要らしい
---

またDBサーバーを移動させる必要が生じたので、[以前の経験](http://tolarian-academy.net/%E3%83%96%E3%83%AD%E3%82%B0%E3%81%AEdb%E3%82%92%E3%80%81conoha-vps%E3%81%AB%E7%A7%BB%E8%A1%8C%E3%81%97%E3%81%9F%E3%80%82mysql%E3%81%A8ssl%E3%81%A7%E9%80%9A%E4%BF%A1%E3%81%99%E3%82%8B%E3%80%82/)を元に新しくDBサーバーを作った。

前回はCentOSだったが、こんどはUbuntuのLTSに変えてみたところ、前回と同じ方法ではMySQLのSSL化が有効にならなかったので、メモしておく。

最初は、証明書の権限とか、作り方に問題があるのかと思っていたが、どうにも手詰まりになって検索したところ、次のようなフォーラムを見つけた。

[Enabling SSL in MySQL - Ask Ubuntu](http://askubuntu.com/questions/194074/enabling-ssl-in-mysql)

どうやら、UbuntuでMySQLのSSL化を有効にするときは、証明書ファイルとかを全部/etc/mysql の下に置かなくてはいけないらしい。

そんな馬鹿なと思ったけど、実際に/etc/mysql-ssl というディレクトリに作っていた証明書を/etc/mysql に移動してみたところ、何度やってもDISABLEだったSSLのステータスが、YESに変わった。

わけがわからんが、忘れないようにメモしておく。

追記

Wordpressから、MYSQL_CLIENT_SSLフラグをオンにしても動かなかった理由も解決した

[MySQLでSSL接続を有効にする - Qiita](http://qiita.com/toshiro3/items/b7f6842efe9fd97f8c56)

[On connecting to MySQL via SSL getting ERROR 2026 (HY000): SSL connection error: protocol version mismatch - Stack Overflow](http://stackoverflow.com/questions/28694095/on-connecting-to-mysql-via-ssl-getting-error-2026-hy000-ssl-connection-error)

鍵を作った直後にこれをやろう

ただ、何故かファイルに差分は生まれなかったのだが……謎い
