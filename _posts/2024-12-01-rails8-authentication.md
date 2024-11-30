---
layout: post
title: Rails8の認証機能と、俺たちのアイデンティティ
date: 2024-12-01 00:00 +0900
image: "/assets/images/2024/12/1/account-has-many-users-has-one-user-credential.png"
---
かかってこいよ、クリスマス。そうです、私がkinoppydです。

> この記事は、[SmartHR Advent Calendar 2024](https://qiita.com/advent-calendar/2024/smarthr) Day1 のエントリーです

## Rails8の認証機能

Rails8では、新たにユーザーの認証機能のジェネレーターが追加されています。これは何かというと、これまで多くのユーザーがdeviseやrodauthというGemを使って実現してきたユーザーの認証機能を、Railsの標準機能として生成できるものです。とはいっても、もちろんdeviseやrodauthのようにユーザーの認証に関わる広く高度な機能を提供するわけではありません。提供されるのはユーザー名とパスワードの組み合わせでログインセッションを作成するための一通りの機能のみです。例えば、MFAであったり、データの認可機能、テストヘルパーの提供などはありません。なんなら、ユーザーを新たにサインアップする機能すらありません。デフォルトのままでは、データベースにコンソールから直接ユーザー登録が必要です。

<!--more-->

コードジェネレーターは、次のコマンドで実行できます。

```shell
bin/rails g authentication
```

実行すると、認証に必要なモデルやコントローラーを一通り作成してくれます。パスワードリセット用のActionMailerとかも作成されますね。

素も素なこのユーザー認証機能は、UserモデルとSessionモデルを提供してくれます。それぞれこんな感じのマイグレーションが実行されます。

```ruby
class CreateUsers < ActiveRecord::Migration[8.0]
  def change
    create_table :users do |t|
      t.string :email_address, null: false
      t.string :password_digest, null: false

      t.timestamps
    end
    add_index :users, :email_address, unique: true
  end
end

class CreateSessions < ActiveRecord::Migration[8.0]
  def change
    create_table :sessions do |t|
      t.references :user, null: false, foreign_key: true
      t.string :ip_address
      t.string :user_agent

      t.timestamps
    end
  end
end
```

メールアドレスとパスワードだけを保持した非常にシンプルなusersテーブルと、ログインセッションを保管するsessionsテーブルが作成されます。また、User has_many Sessions のリレーションが設定されています。

ログインにはSessionControllerを使います。

```ruby
class SessionsController < ApplicationController
  allow_unauthenticated_access only: %i[ new create ]
  rate_limit to: 10, within: 3.minutes, only: :create, with: -> { redirect_to new_session_url, alert: "Try again later." }

  def new
  end

  def create
    if user = User.authenticate_by(params.permit(:email_address, :password))
      start_new_session_for user
      redirect_to after_authentication_url
    else
      redirect_to new_session_path, alert: "Try another email address or password."
    end
  end

  def destroy
    terminate_session
    redirect_to new_session_path
  end
end
```

`start_new_session` はAuthentication concernに定義されているヘルパーで、CurrentAtributesを使ってセッションを保持します。

```ruby
    def start_new_session_for(user)
      user.sessions.create!(user_agent: request.user_agent, ip_address: request.remote_ip).tap do |session|
        Current.session = session
        cookies.signed.permanent[:session_id] = { value: session.id, httponly: true, same_site: :lax }
      end
    end
```

```ruby
class Current < ActiveSupport::CurrentAttributes
  attribute :session
  delegate :user, to: :session, allow_nil: true
end
```

CurrentAttributeに関しては、[Railsの`CurrentAttributes`は有害である（翻訳）｜TechRacho by BPS株式会社](https://techracho.bpsinc.jp/hachi8833/2024_01_25/43810) のように、非常に危険なグローバルステートを作成してしまう機能だという批判もありますが、まあこの認証機能でユーザーを設定しておくくらいならまあ……という感想です。CurrentAttributeの問題は何にでも使えてしまうという点で非常に厄介ですが、用法用量を守れば……いや、守る方法が無いから問題なんですね。うーん、まあ、はい。という感じです。

{%cardlink https://techracho.bpsinc.jp/hachi8833/2024_01_25/43810 %}

ただ、この悩みポイントに関しても、DHHはある程度の裁量を我々にくれています。それは、[この機能がマージされたPRの本文](https://github.com/rails/rails/pull/52328)にも書かれています。

{%cardlink https://github.com/rails/rails/pull/52328 %}

![](/assets/images/2024/12/1/screenshot-dhh-1.png)

DHH曰く「何でもできるモノを作ったわけじゃ無い、ただ独自の認証システムを構築するのが奇妙な冒険ってワケでは無いことを明らかにしたいだけだ」

独自の認証システムを作るための簡単なガイドを置いておくから、後は自分で気に入るようにやてくれってことですね。コードジェネレーターである理由も、暗黙的に呼び出されるコードが無いようするためかと思います。この認証システムのコードが気に入らなければ、自分で良いように修正すれば良いという事でしょう。

##  俺たちのアイデンティティ

そういえば、ありましたよね、Kaigi on Rails 2024が。そこで食らっちゃったわけ何ですよ、私は。アイデンティティとは何なのかという話に。

<iframe class="speakerdeck-iframe" frameborder="0" src="https://speakerdeck.com/player/b9b2650a1f6945389cea7553b92989ee" title="Identifying User Idenity" allowfullscreen="true" style="border: 0px; background: padding-box padding-box rgba(0, 0, 0, 0.1); margin: 0px; padding: 0px; border-radius: 6px; box-shadow: rgba(0, 0, 0, 0.2) 0px 5px 40px; width: 100%; height: auto; aspect-ratio: 560 / 315;" data-ratio="1.7777777777777777"></iframe>

かいつまむと、Userモデルというのは利用者のアイデンティティそのものであり、余計な情報は無くて良い。それに関連する情報は別テーブルに保存するべき、という内容です。で、スライドの中でも触れられてますよね。26ページで、Rails8の生成するコードについて。Rails8のUserテーブルは、emailとpasswordを持っています。はい。

確かに、これは一体どう両立すればいいんだろうな？　という話ではあります。一方で、DHHは先に紹介したPRでこんなコメントもしています。

![](/assets/images/2024/12/1/screenshot-dhh-2.png)

user.rbをaccount.rbに変えるのはどう？　ビジネスの世界ではアカウントが主流だよ、という質問に対して、DHH曰く「なんでもできるシステムでは無い。userは、認証情報を保持する最も一般的なモデル名で、account has_may user なモデルを追加するのはプログラマがやるべき事だ」とのこと。質問者の意図と若干ズレている気がしないでも無いですが、重要なのはUserは認証情報を保持するモデルだと言っているところかなと思いました。つまり、アイデンティティと認証情報は違うとも考えられるということです。

![](/assets/images/2024/12/1/identity-has-many-users.png)

こんな感じのモデル関係も考えられるという事でしょうか。一人のユーザーが認証情報を複数持っているのは、OAuthを使っている場合によくある現象ですし、ペルソナごとに認証情報が変わることもあるでしょう。まあ、そもそもがusersテーブルをuser_credentialsテーブルに改名してしまう方が速い気もしますが……

## ONCEの答え

ONCEとは、37signalsが開発する売りきり形態のサービスです。一度課金すると、サービスのソースコードが渡され、それ以上課金されることはありません。また、渡されたソースコードは自己学習などに使うことも想定されており、なかなか面白いサービスです。

{%cardlink https://once.com/ %}

さて、私が所属しているSmartHRでは、ONCEのCampfireというプロダクトを学習目的で購入しています。つまり、DHHイズムで書かれたソースコードが、お手本として閲覧できるのです。それでは、Campfireの中では、Userモデルは一体どうなっているのでしょうか？

まずその前に、Campfireの認証機構はどうなっているのでしょうか？　なんと、Rails8で生成されるコードとほぼ同様のコードが利用されています。ONCEのコードとRails8のコードのどちらが先に書かれたのかはわかりませんが、どちらにせよDHHの頭の中にはこの認証コードとRailsでの生成をするアイディアがずいぶん前からあったのでしょう。

それでは、Campfireの認証テーブル周りがどうなっているのかというと、次の図のようになっています。さすがにCampfireはオープンソースではないので、コードは掲載できませんが、図で何となくのニュアンスは伝わると思います。

![](/assets/images/2024/12/1/account-has-many-users.png)

Oh……Userモデルが色々持ってしまっていますね。つまり、DHHはアイデンティティの概念はあんまり気にしない派みたいです。ちなみに、Accountというモデルは組織全体を表すモデルで、このAccountという名前空間にたくさんのユーザーが参加するという様なイメージです。テナントとかカンパニーに近い概念ですね。手元のファーストリリースのコードだと、このAccountは初回起動時に決め打ちで一つ作られて、全員がそれを利用する想定の様です。
## 我々は何者なのか

![](/assets/images/2024/12/1/account-has-many-users-has-one-user-credential.png)

我々が欲しいのは、こういう関係図のはずです。Account（あるいはテナントやカンパニー）には、ユーザーのアイデンティティであるUserが複数所属し、それらのUserは各々一つのUserCredentialという認証情報を持っている、という関係です。実際には、マルチテナントアプリケーションにおける一人のユーザーのアイデンティティはもっと複雑な関係で、一人のユーザーが複数のテナントに所属していたりするので、Userとは、UserCredentialとは、という問いにはより難しく複雑な回答が必要になります。とはいえ、いまそれを考えるのは大変なので、一旦こういう形が欲しいとします。

まず、生成されるコードのUserモデルを、UserCredentialモデルに改名してしまい、新しくUserモデルを作り直します。Userモデルの中身はまっさらでよいので特に何もありませんが、`has_one :user_credential` 関係だけは持っておきます。

次に、SessionControllerのなかでID/PASSのチェックを行う部分を、UserからUserCredentialに変更します。

やることは以上。diffはこんな感じです。

```diff
diff --git a/app/controllers/sessions_controller.rb b/app/controllers/sessions_controller.rb
index 9785c92..c3ff04c 100644
--- a/app/controllers/sessions_controller.rb
+++ b/app/controllers/sessions_controller.rb
@@ -6,8 +6,8 @@ class SessionsController < ApplicationController
   end

   def create
-    if user = User.authenticate_by(params.permit(:email_address, :password))
-      start_new_session_for user
+    if user_credential = UserCredential.authenticate_by(params.permit(:email_address, :password))
+      start_new_session_for user_credential.user
       redirect_to after_authentication_url
     else
       redirect_to new_session_path, alert: "Try another email address or password."
diff --git a/app/models/user.rb b/app/models/user.rb
index c88d5b0..edf550b 100644
--- a/app/models/user.rb
+++ b/app/models/user.rb
@@ -1,6 +1,3 @@
 class User < ApplicationRecord
-  has_secure_password
   has_many :sessions, dependent: :destroy
-
-  normalizes :email_address, with: ->(e) { e.strip.downcase }
 end
diff --git a/app/models/user_credential.rb b/app/models/user_credential.rb
new file mode 100644
index 0000000..69758ab
--- /dev/null
+++ b/app/models/user_credential.rb
@@ -0,0 +1,6 @@
+class UserCredential < ApplicationRecord
+  has_secure_password
+  belongs_to :user
+
+  normalizes :email_address, with: ->(e) { e.strip.downcase }
+end
diff --git a/db/migrate/20241130132458_create_users.rb b/db/migrate/20241130132458_create_users.rb
index 2075edf..58f590c 100644
--- a/db/migrate/20241130132458_create_users.rb
+++ b/db/migrate/20241130132458_create_users.rb
@@ -1,11 +1,15 @@
 class CreateUsers < ActiveRecord::Migration[8.0]
   def change
     create_table :users do |t|
+      t.timestamps
+    end
+
+    create_table :user_credentials do |t|
       t.string :email_address, null: false
       t.string :password_digest, null: false
+      t.references :user, null: false

	   t.timestamps
     end
-    add_index :users, :email_address, unique: true
+    add_index :user_credentials, :email_address, unique: true
   end
 end
```

あとは、Currentからセッションと同時にUserが引き出せるので、操作対象のリソースが正しくユーザーの権限下にあるかどうかをチェックするだけです。`@post.user == Current.session.user` みたいな感じですね。この動作をチェックするために、ScuffoldでPostを作成して、なんとなーくチェックしてみたリポジトリがこちらです。

{%cardlink https://github.com/kinoppyd/rails8-auth-test %}

ユーザーは次の方法で追加できるので、まあ何となく雰囲気を味わえるのではないでしょうか。

```ruby
auth-test(dev)> u = User.build
auth-test(dev)> u.build_user_credential(email_address: 'test@example.com', password: 'test')
auth-test(dev)> s.save
```

## まとめ

Rails8から新たに追加された、認証コードジェネレーターを触ってみました。そして、アイデンティティの表現と認証情報を分けてみるということをやってみました。

生成される認証コードは、何一つ暗黙的な動作が無い、明示的なコードです。そのため、今回のように気に入らない場合は自分で簡単に書き換える事ができます。Railsの中に溶け込んでいるコードだったり、gem化されたライブラリだと、こうはいかないですよね。

DHHも言っているとおり、これはあくまで認証コードは魔法じゃ無いという事を示すだけの非常に簡素な存在です。ONCEのようにシチュエーションが決め打ちされている場合以外では、実際にプロダクションで使うのは避け、deviseやrodauthを使うのが無難でしょう。ですが、生成された認証コードは私をとてもわくわくさせてくれるモノでした。やっぱりRailsは楽しいぜ。
