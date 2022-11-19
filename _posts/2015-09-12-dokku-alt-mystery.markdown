---
author: kinoppyd
comments: true
date: 2015-09-12 10:11:09+00:00
layout: post
link: http://tolarian-academy.net/dokku-alt-mystery/
permalink: /dokku-alt-mystery
title: dokku-alt の謎
wordpress_id: 290
categories:
- Debian
- dokku
---

## デプロイ出来ない


dokku-alt のサーバーは[以前に](http://tolarian-academy.net/dokku-alt-on-conoha-and-sakura/)作ったが、何故かしばらくデプロイしないうちに、デプロイが出来なくなっていた

調べていると、どうもsshでdokkuユーザーに繋げていないことが分かったので、解決策を探す


## dokkuユーザーでの接続に問題


dokku-alt（というか、dokku）は、デプロイ時にdokkuというユーザーにssh接続し、authorized_keysに書かれている設定に従ってコマンドを実行するため、git pushだけでデプロイが完了する

具体的にはこんな感じに書かれていて、最初のcommandでssh接続してきた場合に実行するコマンドを指定している。/home/dokku/.sshcommandには、dokkuのパスが書かれており、ssh経由でdokkuユーザーで実行される全てのコマンドは、dokkuとして実行されることになる

    
    command="FINGERPRINT=YOUR_PUBLICKEY_FINGERPRINT NAME=admin `cat /home/dokku/.sshcommand` $SSH_ORIGINAL_COMMAND",no-agent-forwarding,no-user-rc,no-X11-forwarding,no-port-forwarding ssh-rsa YOUR_PUBLICKEY


問題だったのは、その後に付いている他のオプションで、ssh dokku -v を実行してみると、次のエラーが出た

    
    debug1: Remote: Forced command: FINGERPRINT=YOUR_PUBLICKEY_FINGERPLINT NAME=admin `cat /home/dokku/.sshcommand` $SSH_ORIGINAL_COMMAND
    debug1: Remote: Agent forwarding disabled.
    debug1: Remote: Bad options in /home/dokku/.ssh/authorized_keys file, line 3: no-user-rc,no-X11-forwarding,no-port-forwarding ss


全然理由が分からないが、とりあえずエラーが出ている箇所の `no-user-rc` オプションを削除してみると、問題なく公開鍵でsshができた。

sshで接続できると、git push も上手くいくようになり、こうして再びデプロイする権利を取り戻した


## どうしてそうなったのか？


全く分からない。dokku-altが動いているサーバーでman sshd を見ても、普通に許可されているオプションだし、そもそもdokku-altのコードを見ると動的に生成されている訳でも無く、おそらく最初から普通に付いていた。

それがどうして今まで普通に動いていて、急に動かなくなったのか、完全に謎である。

そもそも、authorized_keysの設定を削って「治った！」と喜んでいても全然根本解決になっていないし、つらい。

クライアント側の問題でもなさそうだし、全く意味不明。困っている。
