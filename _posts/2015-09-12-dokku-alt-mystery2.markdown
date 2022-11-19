---
author: kinoppyd
comments: true
date: 2015-09-12 17:00:05+00:00
layout: post
link: http://tolarian-academy.net/dokku-alt-mystery2/
permalink: /dokku-alt-mystery2
title: dokku-alt の謎2
wordpress_id: 293
categories:
- dokku
- Rails
---

## 正確には、dokkuが使っているHeroku buildpacksの謎


Railsのデータベースアダプタとして、mysql2を使っているのに、何故かdokku-altにデプロイすると、mysqlをrequireして起動の時に死ぬ。なんでだ！？


## Heroku buildpacks


Herokuにアプリをデプロイすると、自動的にビルドを実行してくれるすごいやつ。オープンソースなので、dokkuも使っている。

で、こいつは恐ろしいことに、Railsアプリをデプロイすると、dokkuのコンテナ単位の設定を元にconfig/database.ymlを書き換える。便利だけど恐ろしい。

Railsの場合、Railsのコンテナに設定しているDATABASE_URLの設定を読み込み、それをURIとしてパースする。その後、スキーマを取得して、そのスキーマをadapterとして設定する。だいたいの場合は、MySQLを使うならDATABASE_URLはこんな感じの設定になると思う。

    
    mysql://user:pass@db.domain.tld/database_name


普通なら別に良いのだが、Railsのadapterはそのまま起動時にrequireされるgem名として使用するので、mysqlの部分がそのままadapterにセットされて、mysql2を使いたいのに使えない状況になる。

解決策は、単にスキーマ部分をmysql2にすれば良い

    
    mysql2://user:pass@db.domain.tld/database_name


良いのだが、非常に気持ち悪い気がする……
