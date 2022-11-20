---
author: kinoppyd
date: 2015-05-17 09:10:53+00:00
layout: post
title: ConoHaとさくらのVPSにdokku-altを入れて、ブログと開発環境を柔軟に
excerpt_separator: <!--more-->
---

## Dokku-alt をConoHaVPSに入れて、個人PaaS環境を充実させた話


このブログは、今のところさくらVPSのWebインスタンスと、ConoHaVPSのDBインスタンスで動いている。動いてはいるが、さくらVPSの方が3年くらい前に右も左もよく分かってない状態で立ち上げたNginx+Apache+Wordpress構成で、いい加減メンテが不可能な状態に陥っており、Wordpressのバージョンを上げることすらままならなくなっていた。

そこで、さくらVPSのインスタンスを一回全部消して、Ubuntu+Dokku-altを立てて、そこでブログをはじめとするいろんな開発環境を集約してしまおうと考えた。


## まずはConoHaVPSで予行練習


ConoHaVPSの素晴らしいところは、このはちゃんが<del>あざとい</del>清楚可愛いだけじゃなくて、VPSを簡単に立てたり落としたり出来る、まるでさくらクラウドのような使い勝手にある。そのため、一個インスタンスを立てるためになんだか面倒なさくらVPSでなにかする前に、ConoHaVPSを使って予行演習を行った

<!--more-->

### Dokku? Dokku-alt？


[dokku](https://github.com/progrium/dokku)は、Herokuで使われている技術を応用して、dockerを使った個人PaaSを作れるソフト。ドキュメントには、Docker powerd mini-Herokuと書いてある。

[dokku-alt](https://github.com/dokku-alt/dokku-alt#deploy-an-app)は、そのdokkuをベースに、いろんなプラグインや設定を最初から有効にしてある、でかいけどあんまり何も考えずに使える拡張。

ひとまず両方とも入れていろいろ試してみたが、どうもdokkuの方はセットアップ時にいろいろと躓くことが多くて、困った。

[dokku + VirtualBoxで自分のHerokuを作る](http://blog.coiney.com/2013/08/10/create-my-own-heroku/)

[DockerでミニHeroku！「Dokku」をさくらのクラウドで試す](http://knowledge.sakura.ad.jp/tech/2356/)

たぶん有名なこの二つのエントリを参考にした。dokkuのインストール自体は、作りたてのUbuntu14.04のVPSに入って、

```shell-session
wget https://raw.github.com/progrium/dokku/v0.3.18/bootstrap.sh
sudo DOKKU_TAG=v0.3.18 bash bootstrap.sh
```

というコマンドを実行するだけ（ワンライナーにもできる）なのだが、こんな感じで躓いた



	
  1. Ubuntuをセットアップするときに、Dokkuというユーザーを作ってはいけないらしい

	
  2. Dokkuをセットアップするときに、セットアップするユーザーのホームディレクトリにdokkuというディレクトリがあってはいけないらしい

	
  3. ワンライナー実行でインストールできるが、何故か一回途中でこけて、二回実行すると上手くインストールされる（さくらのブログにも同じ記述があった）

	
  4. そもそも、bootstrap.shの中身を見てみると、最後まで実行されてない（最後のechoが出てない）

	
  5. Webを使って設定できる画面があるらしいのだけど、どうやってアクセスできるのか分からずに、結局 [http://progrium.viewdocs.io/dokku/advanced-installation#user-content-configuring](http://progrium.viewdocs.io/dokku/advanced-installation#user-content-configuring) を見て最後のセットアップをするはめに


こんな感じで、4回くらいUbuntuを再インストールしてトライアンドエラーしてしまった。

とりあえず当初の目的は、Wordpressをdokku環境に移すことだったので、なにも考えずに使えそうなdokku-altとdokku-alt用のWordpressコンテナを使うことにした。

[romaninsh/docker-wordpress](https://github.com/romaninsh/docker-wordpress)

dokku-altは、dokkuのつまずきポイントが嘘のように簡単にインストールできた。ただ、最後のWeb画面を使ってセットアップのところは、突然シェルがWebrik起動して待機のまま固まったので、少しだけびっくりした。

セットアップ後、http://your-domain.tld:2000 でアクセスできるページで、自分の公開鍵と、ホスト名の設定を行う。


### ドメインベースのサービス


dokkuもdokku-altも、基本的にはドメインが必要になる。IPでのアクセスは出来ない。

dokku.me という、どんなサブドメインにアクセスしても127.0.0.1を返すサービスも存在するが、VPSで使う以上localhostでは困るので、元々持っていたドメインのサブドメインにdokku.を切って使った。

注意しなくてはいけないのは、ルーティングは app-name.your-domain.tld になるので、DNSのAレコードに*.dokku のようにdokkuよりも更に下のサブドメインに対するワイルドカードを忘れないようにしなくてはいけない。

不思議なことに、dokkuはUbuntuのホスト名をそのまま/home/dokku/VHOSTに書き出していたため、Ubuntuのセットアップ時に正しくホスト名を指定してしまえば特に問題はなかったが、dokku-altは設定画面で再入力が必要だった。


### デプロイ


アプリケーションのデプロイは、Herokuとあまり変わらない

```shell-session
git remote add dokku dokku@dokku.your-domain.tld:app-name
git push dokku master
```

のように、dokku-altでデプロイ出来るユーザーとホスト情報、そしてアプリの名前（サブドメインとして使われる）をgit のリモートホストに追加して、あとはpushするだけだ。

pushすると、アプリの種類にもよるが、Herokuのようなデプロイ時のSTDOUTがずらーっと流れてくるので、お茶でも飲みながら眺める。


### Wordpressのデプロイ


[doker-wordpress](https://github.com/romaninsh/docker-wordpress)の READMEを読んで進める。

pushしてデプロイした後は、まずVolumeを確保する。このVolumeが、dokkuではプラグイン扱いなのに対して、dokku-altではデフォルトで用意されているので簡単に使える。

```shell-session
# dokku volume:create wordpress-volume /data
# dokku volume:link wordpress wordpress-volume
```

こうして作成したボリュームがアプリと紐付けられたので、

```shell-session
# dokku logs wordpress
Linking wp-content..
```

というログが出ていることを確認する。このボリュームには、wp-content以下が納められていて、アップロードしたファイル類がすべて保存される。しかし、Dockerはデプロイのたびにボリュームを破棄して新しいコンテナを作るので、このdocker-wordpressではvolume-init.shというシェルを起動させて、毎回volume:createで作ったpersistent volumeに逃がして再度リンクを張っている

次に、作成したDocker内のボリュームを、直接触れるようにリンクを張る

```shell-session
# ls -l /var/lib/docker/vfs/dir/
drwxr-xr-x 3 root   root   4096 May 17 04:07 <your-id>
drwxr-xr-x 4 root   root   4096 May 17 02:58 <some-id>
...作ったボリュームの数だけファイルが出てくるので、作成時間を見てwordpress用を特定する...
# ln -s /var/lib/docker/vfs/dir/<your-id-here> /home/deploy/wordpress
```

上のコマンドだと、deployというユーザーのホームディレクトリにリンクを作っているが、適宜変えて便利な感じにしてほしい。これで、Dockerコンテナ内のボリュームにアクセスできるようになったため、次はwp-config.phpと.htaccessを設置する

```shell-session
# cd /home/deploy/wordpress
# cp some/path/wp-config.php wp-config-production.php
# cp some/path/.htaccess .
# cp -r some/path/wp-contents/* wp-contents
# chown -R www-data:www-data .
```

今まで使っていたWordpressのwp-config.phpや.htaccess、それにwp-contents以下のディレクトリをどこかにコピーしてきて、それを/home/deploy/wordpress 配下のものと置き換えている。おそらく、wordpressディレクトリより下はroot権限では無ければ操作できないので、コピーした後にユーザーとグループをwww-dataに変更しておく。

/home/deploy/wordpress配下（に張ったリンク）は、dockerのボリュームを直接参照しているため、ここにファイルを設置すると、コンテナを破棄して再デプロイしたときに先述のvolume-init.shが良い感じに置き換えてくれる。wp-config.phpはwp-config-production.phpという名前にリネームし、.htaccessはそのままの名前で、デプロイ時に自動的にそれらを使用して設定を行ってくれる。ログを見て、きちんと使われているかを確認する。

```shell-session
# dokku logs wordpress
Linking wp-content..
Using wp-config-production.php..
Using .htaccess..
```

間違っても、/data配下を直接操作してはいけない。というか、操作しても意味が無い。volume-init.shを見ると分かるが、デプロイ時に真っ先に消える運命にある。


### テスト時のドメイン名


作成したdokku-alt上でwrodpressが動くようになったので、表示のテストを行う。dokku-altは、domainsというコマンドを使って、内部で動いているNginxのホスト名を自動で書き換えてくれるので、次のように設定すると、app-name.dokku.you-domain.tld のようなdokkuのサブドメインでは無く、tolarian-academy.netのようなホスト名でアクセスが出来るようになる。

```shell-session
# dokku domains:set wordpress tolarian-academy.net
```

もちろん、tolarian-academy.netがdokku-altの動いているIPを返さないと意味は無いが、Nginxのホスト名解決はこれで出来るようになる。/etc/hostsを書き換えて、ドメインの向き先を一時的に変えてアクセスしてみると、dokku-alt上で動くWordpressにアクセス出来ていることが確認できる。

ただ、これでは単なる置き換えで、テストにならないので、test-tolarian-academy.netのようなドメインをセットして、/etc/hostsを書き換え、DBもダンプから作ったコピーにアクセスするようにwp-config.phpを書き換えてテストを行った。


## ひとまず予行練習は完了


ConoHaVPS上で、dokku-altを使ったWordpressのデプロイは完了した。だが、まだこのブログはさくらVPSで動いている。

次は、さくらVPS上で同じ事を行い、実際に運用を切り替えてみる。ダウンタイムをゼロで行うのであれば、ConoHaVPSにLBを立てて、一時的にドメインの向き先を切り替えて行うべきだと思うが、めんどくさいのでどっかでブログを止めようと思う


### 開発環境は


また、ConoHaVPS上に立てたdokku-altを使って、Railsのアプリもデプロイしてみた。これもいろいろと躓きが多くて長くなりそうなので、別のエントリにまとめる。

ひとまずこれで、dokku-altを使ってブログと開発環境をひとまとめにする準備が整った
