---
author: kinoppyd
date: 2018-12-09 17:35:19+00:00
layout: post
title: Rubyを使って秒でBotを作るなら、秒でActiveRecord使えなきゃ話にならないですよね？
excerpt_separator: <!--more-->
---

このエントリは、 [Mobb/Repp Advent Calendar 2018 ](https://qiita.com/advent-calendar/2018/mobb-repp)の十日目です


## ActiveRecord


ここ数日書いているエントリで、Mobbがいかに秒でBotを作れるすごいやつかというのは伝わったかと思います。しかし、世の中には秒で複雑で素敵なBotのアイディアが思い浮かぶ人もいます。そして、そういう人の多くは「いやいや、いくら秒でロジック書けても、DB使えないと話にならんでしょ」という人もいます。

そうです、Botのロジックは会話的なものが多いため、状態を記録したりデータを保持したりという行動を行いたいケースが非常に多いです。それでは、DBを使いましょう。RubyでDBといえば、ActiveRecordですね。ActiveRecord、使いたくないですか？

Mobbは、秒でBotを作るエンジニアを本気で応援するフレームワークです。当然、ActiveRecordも使えなくては話になりません。

安心してください、使えますActiveRecord。たった一つのgemを追加するだけで。

[https://github.com/kinoppyd/mobb-activerecord](https://github.com/kinoppyd/mobb-activerecord)


## Usage

<!--more-->

秒で使えるとは言いましたが、流石にActiveRecordは何も考えずに突っ込むことは出来ません。しかし、可能な限り何も考えずに突っ込めるようには準備をしています。

まず、bundlerを使っている場合は次のgemをGemfileに記述してください。使っていなければ普通にインストールしてください。

```ruby
# frozen_string_literal: true
source "https://rubygems.org"

gem "mobb"
gem "mobb-activerecord"
gem "rake"
gem "sqlite3"
```

rakeはなくてもいいですが、あったほうが楽です。ここからさきはRakeがある前提で書きます。また、sqlite3のところは適宜好きなDBに読み替えてください。

その後、まずRakefileを作成して編集します。

```ruby
require "mobb/activerecord/rake"

namespace :db do
  task :load_config do
    require "./app"
  end
end
```

5行目の require "./app" は、Mobbアプリケーションの名前がapp.rbであることを前提としているので、適宜変更してください。

次に、Mobbアプリケーションを作ります。

```ruby
require 'mobb'
require 'mobb/activerecord'

set :database, { adapter: "sqlite3", database: "test.sqlite3" }

class User < ActiveRecord::Base
end

on /add user (\w+)/ do |user|
  u = User.find_by(name: user)
  if u
    "user #{user} already exists"
  else
    User.create!(name: user)
    "user #{user} created"
  end
end

on 'list users' do
  User.all.map(&:name).join("\n")
end
```

set :database の記述で、ActiveRecordにDB接続情報を渡しています。これはsqlite3の場合ですが、他のDBを使う場合は適宜必要な情報を渡してください。

ActiveRecordのクラスは、Userクラスを用意しました。これは、userというフィールドを持っています。

アプリケーションそのものは、add userという呼びかけでユーザーを追加したり、list usersという呼びかけで登録されてるユーザー一覧を見たりするものです。

それでは、DBを作成しましょう。まずRakeタスクで、DBの作成とマイグレーションファイルを作成します。

```shell-session
bundle exec rake db:create
bundle exec rake db:create_migration NAME=users

```

ここまでくると、もうRailsでよく見るやつですね。DBの作成と、マイグレーションファイルの作成を行います。その後、作成される db/migrate/xxxxxxxx_user.rb というファイルを編集します。

```ruby
class Users < ActiveRecord::Migration[5.2]
  def change
    create_table :users do |t|
      t.column :name, :string
      t.timestamp
    end
  end
end
```

usersテーブルを作成し、nameというカラムを持つように定義します。

あとは、DBをマイグレーションしましょう。

```shell-session
bundle exec rake db:migrate
== XXXXXXX Users: migrating ============================================
-- create_table(:users)
   -> 0.0005s
== XXXXXXX Users: migrated (0.0005s) ===================================
```

無事マイグレーションされました。

それでは、アプリを起動してみます。

```shell-session
bundle exec ruby app.rb
```

実際に操作してみましょう。

```shell-session
== Mobb (v0.4.0) is in da house with Shell. Make some noise!
add user kinoppyd
D, [2018-12-10T02:12:36.215524 #54963] DEBUG -- :   User Load (0.1ms)  SELECT  "users".* FROM "users" WHERE "users"."name" = ? LIMIT ?  [["name", "kinoppyd"], ["LIMIT", 1]]
D, [2018-12-10T02:12:36.216977 #54963] DEBUG -- :    (0.0ms)  begin transaction
D, [2018-12-10T02:12:36.217548 #54963] DEBUG -- :   User Create (0.3ms)  INSERT INTO "users" ("name") VALUES (?)  [["name", "kinoppyd"]]
D, [2018-12-10T02:12:36.218448 #54963] DEBUG -- :    (0.8ms)  commit transaction
user kinoppyd created
list users
D, [2018-12-10T02:12:45.580979 #54963] DEBUG -- :   User Load (0.2ms)  SELECT "users".* FROM "users"
kinoppyd
```

これは、Shellアダプタでadd userコマンドとlist usersコマンドを実行してみた例です。develpmentモードで動いているため、ActiveRecordのログが出力されているのがわかります。

以上が、MobbでActiveRecordを使うためのチュートリアルです。Rakeタスクの作成さえ行えば、あとはRailsでよく見る操作方法なので、特に迷うことも無いと思います。


## sinatra-activerecord


mobb-activerecordというgemには、明確な元ネタが存在します。sinatra-activerecordです。元ネタどころか、mobb-activerecordはsinatra-activerecordのforkです。

[https://github.com/janko-m/sinatra-activerecord](https://github.com/janko-m/sinatra-activerecord)

もともと、Sinatraにはsinatra-activerecordというSinatraでActiveRecordを使うためのgemが存在しました。そして、MobbはSinatraのエッセンスを完全に受け継いだフレームワークであり、特に拡張部分であるhelpers/extendsに至ってはSinatraと全く同じコードが書かれているということを数日前のエントリでも解説しました。

これはすなわち、SinatraのHTTP以外の資産を、ほぼそのままMobbでも活用できるということを意味します。実際、mobb-activerecordをforkしたとき、私のやった作業はSinatraという名前空間をMobbに変更しただけです。このコミットを見てもらえれば、本当にそのとおりだということがわかってもらえると思います。

[https://github.com/kinoppyd/mobb-activerecord/commit/c46f31964a9903a44036b1dae96fba6858421ecc](https://github.com/kinoppyd/mobb-activerecord/commit/c46f31964a9903a44036b1dae96fba6858421ecc)

これは本当に強力な資産で、Mobbは100%その恩恵に預かっています。

もちろん、HTTPの関心事の資産は流用できません。クッキーであったりセッションであったりという話や、CORSやCSRFのようなものは、Mobbの世界観にそもそも存在しないため、それらを助けるgemは流用してもなんの意味も持ちません。

その一方で、ミドルウェアをより使いやすくするgemは、まるごとそのままの恩恵をうけることができます。今回のActiveRecordがまさにその真骨頂です。


## 秒で作れるBot、秒で扱えるActiveRecord


さあ、この解説を読んだあなたは、もう秒でActiveRecordを使ったBotを書くことができます。無限のアイディアを、秒でBotに実装しましょう！
