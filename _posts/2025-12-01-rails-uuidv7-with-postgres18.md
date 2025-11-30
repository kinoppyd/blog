---
layout: post
title: Rails 8.1 + PostgreSQL 18 で UUIDv7 を使おう
date: 2025-12-01 00:29 +0900
---
メリーーーーーーーーーーーまだだね、こんにちはkinoppydです。

この記事は [SmartHR Advent Calendar 2025](https://qiita.com/advent-calendar/2025/smarthr) の1日目です

UUID好きですか？　僕は好きです。いろいろと難点はあるものの、サクッと重複無しのIdentifierを生成できること一点張りで好きです。Rubyだとこんだけ手軽にUUID出せます。

```ruby
require 'securerandom'
SecureRandom.uuid # => "afea036e-3242-42a0-ae91-c0ffcc58a277"
```

便利。

<!--more-->

さて、現在主に使用されているUUIDはUUIDv4と呼ばれ、128ビットの乱数で構成されています。特徴としては、予約された6ビットを除く2の112乗だけ空間があり、毎秒どんだけ生成しても理論的に重複しないという点です。弱点の一つとして、UUIDv4は構成要素がほぼすべて乱数なので、Integerのインクリメントによって出力されるIDなどと比べると、作成された順番に並べることができないなど取り回しに不便がありました。しかしこの不便さは純粋に弱点というわけではなく、そのぶん範囲が広大で予測が難しいIDを生成できるメリットでもあります。

一方で、2の112乗もの巨大な空間が必要無く、かつ生成順に並べたいという要件に対応できるのがUUIDv7です。UUIDv7は、先頭48ビットを生成された時間のミリ秒で表現しているため、文字列としてソートすると生成時間でソートすることができます。その分乱数となる空間は2の74乗まで減ってしまいますが、ほとんどのシステムはこれで十分なはずです。UUIDv4に比べて乱数部分が減るので、UUIDv4に比べると推測がしやすくなったり、生成された時間が露出するので、セキュリティ的な強度は落ちてしまいます。ですが、それでもだいたいのシステムでは問題なく運用できるはずです。[Rubyのドキュメントには記述されていない](https://docs.ruby-lang.org/ja/3.4/class/SecureRandom.html)ですが、Rubyでも3.3.0から次のような方法でUUIDv7を生成可能です。

```ruby
require 'securerandom'
SecureRandom.uuid_v7 # => "019acd87-4a9e-79c8-aa5e-4574893aeae7"
```

ちなみに、 `uuid_v4` というメソッドもあり、互換性のために `uuid` メソッドのエイリアスとして定義されています。

## PostgreSQL 18 の UUIDv7 サポート

PostgreSQL18 からは、組み込みでUUIDv7の生成がサポートされました。

{% cardlink https://www.postgresql.org/docs/current/release-18.html %}

これまでUUIDv4を生成するために `gen_random_uuid` という関数が用意されていましたが、 `uuidv7` という関数が新たに追加され、`gen_random_uuid` には `uuidv4` というエイリアスが用意されました。

これまで、Rails + PostgreSQL でUUIDv7をPKとして使うときは、ActiveRecordのフックを使ってPKにRubyで生成したUUIDv7を埋めていましたが、PostgreSQL側で生成できるようになったことで、通常の自動採番と同じように手軽に使えるようになりました。

## Rails の UUIDv7 サポート

Rails + PostgreSQL のUUIDサポートは、これまではマイグレーション時に `id: :uuid` を指定することによって、自動的に `gen_random_uuid` が呼ばれるようになっていました。

{% cardlink https://github.com/rails/rails/blob/690ec8898318b8f50714e86676353ebe1551261e/activerecord/lib/active_record/connection_adapters/postgresql/schema_definitions.rb %}

また、application.rbに次のように設定することで、自動的にPKをUUIDにすることもできました。

```ruby
config.generators do |g|
  g.orm :active_record, primary_key_type: :uuid
end
```

この設定をすることで、生成されるマイグレーションファイルは、自動で `id: :uuid` が付与され、採番時には `gen_random_uuid` 関数が呼ばれます。

ですが、ここにひとつ大きな問題がありました。`type: :uuid` が付与されたカラムにおいて、PostgreSQLのドライバはデフォルトで `gen_random_uuid` を実行するようにマイグレーションを設定すると説明しましたが、これは先に示したコードの `default` オプションが何も指定されていないときに、自動で `gen_random_uuid` を選択するようになっているからです（defaultのデフォルト値ということですね、ややこしい）。

この問題に対応するためには、以下のようなマイグレーションファイルを用意することで対処することができます。

```ruby
class CreateUser < ActiveRecord::Migration[8.1]
  def change
    create_table :userss, id: :uuid, default: "uuidv7()" do |t|
      t.timestamps
    end
  end
end
```

`create_table` メソッドのオプションとして、 `default: "uuidv7()"` を渡します。こうすることで、defaultのデフォルト値である `gen_random_uuid` ではなく、 `uuidv7` 関数を使用するように指示できます。

ところが問題はさらにあります。先ほどの `application.rb` に書いた、`g.orm :active_record, primary_key_type: :uuid` という設定ですが、なんとここに `default` を指定する方法はありません。つまり、次のような設定を書くことはできないのです。

```ruby
config.generators do |g|
  g.orm :active_record, primary_key_type: :uuid
  g.orm :active_record, primary_key_default: "uuidv7()"
end
```

この指定ができないことで、マイグレーションファイルを作成するときに `default: "uuidv7()"` が付与されず、都度手動で追記する必要があります。手作業で毎回追加しなくてはならないというのは、設定ミスを招きます。そのため自動的に対応したいです。

## 解決策A

一つ目の解決策は、次のような設定を `application.rb` に書くことです。


```ruby
config.generators do |g|
  g.orm :active_record, primary_key_type: ':uuid, default: "uuidv7()"'
end
```

これはいったい何かというと、つまりマイグレーションファイルが生成されるときに、 `type: <%= primary_key_type %>` というERBが解釈されることを逆手にとり、uuidだけではなくdedfaultまで一気に指定してしまう方法です。ジェネレータのテンプレートは `activerecord/lib/rails/generators/active_record/migration/templates/create_table_migration.rb.tt` というファイルで、ただの文字列として `primary_key_type` を埋め込んでいるだけということがわかります。

{% cardlink https://github.com/rails/rails/blob/690ec8898318b8f50714e86676353ebe1551261e/activerecord/lib/rails/generators/active_record/migration/templates/create_table_migration.rb.tt %}

この方法を使うと、生成されるマイグレーションファイルは `type: :uuid, default: "uuidv7()"` という設定が毎回自動で作成され、手作業によるミスを回避することできます。

しかし、この方法にはひとつ問題があり、 `references` などでFKに他のレコードのPKを指定する際に、このような不思議なマイグレーションを生成してしまうというバグを産んでしまいます。

```ruby
# bin/rails g migration create_credentials user:references

class CreateCredentials < ActiveRecord::Migration[8.1]
  def change
    create_table :credentials, id: :uuid, default: "uuidv7()" do |t|
      t.references :user, null: false, foreign_key: true, type: :uuid, default: "uuidv7()"

      t.timestamps
    end
  end
end
```

そうです。単に `primary_key_type`  という変数に格納されている文字列をテンプレートに書き込んでいるだけなので、 `references` のデフォルト値にも影響を及ぼしてしまうのです。 `references` で指定されるFKの型は、 `activerecord/lib/rails/generators/active_record/migration.rb` にメソッドとして定義されていて、 `primary_key_type` を呼んでいることが分かります。

{% cardlink https://github.com/rails/rails/blob/690ec8898318b8f50714e86676353ebe1551261e/activerecord/lib/rails/generators/active_record/migration.rb %}

このマイグレーションは特に問題なく動き、実際 `references` の `default` オプションは特に何の意味も無く動作するのですが、必要の無いデフォルト値が入っているのもなかなか変な気持ちになりますよね。もしAPIの仕様が変わったときに、マイグレーションの同一性を維持できるのかも疑問が残ります。

とはいえこのマイグレーションファイルは、現状では特に何の害もないので、これこそ手で毎回消せば良いモノでもあります。解決策Aとしては上々です。

## 解決策B

Railsにプルリクを出します。ジェネレータのオプションに、新たに `primary_key_default` という項目を受け取れるようにするのです。実際に出したプルリクがこちらです。

{% cardlink https://github.com/rails/rails/pull/56095 %}

このプルリクでは、ActiveRecordのジェネレータのオプションに新しく `primary_key_default` という項目を加え、生成に使うテンプレートでも明確に `primary_key_type` と扱いを分けるようにしています。このオプションの追加により、`reference` の時には `primary_key_type` のみを参照するので不要な `default` を付けないこともできますし、今後 create_table の仕様が変わったとしても問題なく追従できるようになるはずです。

問題点としては、ジェネレータ周辺ってあまりテストがなく、今回の変更点も実際にテストしている既存のコードが見当たらなかったため、テストが追加しづらいという点です。一旦あきらめてプルリクを出しましたが、全く反応されていないのでつまりそういうことかも知れません。

個人的には困っているので取り込んでほしいのですが、ガン無視されているので取り込まれない限りは解決策Bを使えないという根本的欠陥があり、やはり解決策Aに軍配が上がるかなぁ、というのが悲しい現状です。

## まとめ

以上が、 Rails と PostgreSQL18 で UUIDv7 を PostgreSQL の関数から自動で生成できるようにするための方法です。いったんは解決策Aを使用し、もし今後マージされたらRails8.2以降とかで解決策Bに切り替えるのが良いのかなと思います。マージされるかどうかは分かりませんけど。
