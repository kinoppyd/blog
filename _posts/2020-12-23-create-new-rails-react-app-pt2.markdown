---
author: kinoppyd
date: 2020-12-23 14:59:41+00:00
layout: post
image: /assets/images/icon.png
title: 大急ぎでRails+Reactのアプリケーションを作るときにやったこと後編
excerpt_separator: <!--more-->
---

## ある日突然、大慌てでWebアプリを作らなくてはいけなくなった

このエントリは、[第二のドワンゴ Advent Calendar 2020](https://qiita.com/advent-calendar/2020/dwango2)の23日目です。

このエントリは、[大急ぎでRails+Reactのアプリケーションを作るときにやったこと前編](http://tolarian-academy.net/create-new-rails-react-app-pt1/)の続きです

このエントリは、**自分は仕事でRails+ReactのAPI+SPAプロジェクトをいくつか経験してきたが、0からその環境を作ったことがないということに気づいてしまった私の記録です。**多くの躓きを経て、非常に非常にかんたんな機能しか持たないアプリをつくるのにのべ20時間ほどの時間を要しまし、自分はReact+Railsエンジニアになったつもりでいたという反省文、その話の後編です。これから書くことは、0からRails+React環境を用意したことのない人に向けて書く、まさに書くは一時の恥、書かぬは一生の恥のエントリです。

## 前回までにやったこと


前編では、サンプルアプリ「ねこねこかわいい」を作るために以下の工程を説明しました。



 	
  * rails new

 	
  * DBの用意

 	
  * Webpackerの設定

 	
  * RailsとReactのインテグレーション

 	
  * UI FrameworkとしてSmartHR UIの導入


後編のこのエントリでは

 	
  * axiosのクライアントを用いてReactからRailsに通信

 	
  * Google OAuthでユーザー登録

 	
  * S3に画像の投稿

 	
  * Herokuへのデプロイ


までを解説します。


## axiosクライアントの作成

<!--more-->

ReactからRailsのAPIに通信するためには、axiosを使う。なんでaxioかというと、手でFetchAPIを書くよりはだいぶ書き心地が良いことと、将来的にOpenAPIなどでスキーマ定義を作成して通信クライアントを自動生成するときにaxiosを使ったクライアントを選択できるからと考えたから。自動生成されたaxiosのクライアントに切り替えるときに、大きなショックが無いようにということですね。それ以外は特に積極的な理由はないです。

axiosをインストール。ついでに、Cookieもいい感じに処理してほしいので、axios-cookiejar-supportとtouch-cookieも入れる。ただ、入れてから気づいてまだ検証してないけど、Cookie系はもしかしたら必要ない可能性もある（とはいえ、最終的にSPAに持っていくときにはいると思うので入れておいて悪いことはないんじゃないかな、くらいに思っている）。

```shell-session
yarn add axios @types/axios 
yarn add axios-cookiejar-support tough-cookie @types/tough-cookie
```


[[yarn add axios @types/axios · kinoppyd/nekonekokawaii@8a9e5fd](https://github.com/kinoppyd/nekonekokawaii/commit/8a9e5fd309ea72f77998b93a598ebe034f8f5053)]

[[yarn add axios-cookiejar-support tough-cookie @types/tough-cookie · kinoppyd/nekonekokawaii@6c0a6cd](https://github.com/kinoppyd/nekonekokawaii/commit/6c0a6cd2ec1f0fcf5c2d04c02f0b7cd6786c0034)]

入れたら、どこのコンポーネントからでも使えるClientクラスをつくておく。また、Railsとの通信ではCSRFで保護してほしいので、CSRFトークンも送れるようにしておく。ここでのCSRFトークンは、Rails側のViewレンダリングでheaderに埋め込まれたものを取得して使う。つまり、いまはRailsのViewにReactコンポーネントを埋め込んでいるので対応可能だが、完全SPAなどにシフトしていくためには、また違う方法をとる必要がでてくるということになる。が、とりあえず今はこれで十分。

```typescript
 import axios from 'axios'
 import axiosCookieJarSupport from 'axios-cookiejar-support'
 import { CookieJar } from 'tough-cookie'
 
 axiosCookieJarSupport(axios)
 const element: HTMLMetaElement =  document.getElementsByName('csrf-token')[0] as HTMLMetaElement
 axios.defaults.headers.common['X-CSRF-Token'] = element.content
 const cookieJar = new CookieJar()
 
 const client = axios.create({jar: cookieJar})
 
 export default client
 ```


これを実際に利用するときには、各API用のクラスを作成して分割しておくと、後々ごちゃごちゃしなくて良いと思う。ひとまず簡単に、/postsにPOSTするだけのクライアントを作る。

```typescript
import { AxiosInstance } from 'axios'
import client from './client'

export const createPost = (title: string, body: string) => {
  return client.post('posts', {title, body})
}
```


[[Add api client · kinoppyd/nekonekokawaii@56b9d11](https://github.com/kinoppyd/nekonekokawaii/commit/56b9d11b5db74e7b590634c212dad771a1a579d8)]

もちろん、Rails側にこのリクエストに対応するエンドポイントもはやしておく必要がある。

```ruby
class PostsController < ApplicationController
  def index
    @posts = Post.all.order(created_at: :desc)
  end

  def show
    @post = Post.find(params[:id])
  end

  def create
    post = Post.create(create_params)
    post.save!
    render json: post
  end

  private

  def create_params
    params.permit(:title, :body)
  end
end
```


[[Add Create post action · kinoppyd/nekonekokawaii@cb536da](https://github.com/kinoppyd/nekonekokawaii/commit/cb536dad6ad29839a73bd83d200bf828dfb3357d)]

最後に、フロント側に非常に雑ではあるがAPI Clientを使ってPOSTを実行するコードを追加して、動作を確認する。非常に雑な感じではあるが、フォームの内容はStateで覚えておき、ボタンのクリックハンドラでAPIを呼び出すときに投げる。成功したらページリロード。

```typescript 
import React, { useState } from 'react'
import styled from 'styled-components'
import { Input, PrimaryButton, Textarea } from 'smarthr-ui'

import Post, { PostProps } from '../../organisms/Post'
import { createPost } from '../../../../api/posts'

export interface PostsTemplateProps {
  posts: PostProps[]
}

const PostsTemplate: React.FC<PostsTemplateProps> = ({posts}) => {
  const [title, setTitle] = useState("")
  const [body, setBody] = useState("")

  const handleSubmit = () => {
    createPost(title, body)
    .then(() => {document.location.reload()})
  } 

  return(
    <Content>
      <List>
        <li>
          <p>タイトル</p>
          <Input type="text" onChange={(e) => setTitle(e.target.value)}/>
        </li>
        <li>
          <p>本文</p>
          <Textarea onChange={(e) => setBody(e.target.value)}/>
        </li>
        <li>
          <PrimaryButton onClick={handleSubmit}>submit</PrimaryButton>
        </li>
      </List>
      {posts.map(post => (
        <Post {...post} />
      ))}
    </Content>
  )
}

const Content = styled.div`
  margin: 32px 10%;
  min-width: 800px;
`
const List = styled.ul`
  padding: 0 24px;
  list-style: none;

  & > li:not(:first-child) {
    margin-top: 16px;
  }
`
```

export default PostsTemplate


[[Add new post form for index · kinoppyd/nekonekokawaii@eca716b](https://github.com/kinoppyd/nekonekokawaii/commit/eca716bac36e4bfeefc549cf18dc7d65809cea56)]

ここまでで、axiosを使ってRails側のAPIを呼び出して、Reactから新しいPOSTを作れるまでの一連の流れが完成した。


## GoogleのOAuthでユーザー登録


ここはあまり真面目に読む必要はない。[Google API Console](https://console.developers.google.com/)からOAuth2の認証情報を追加して、OmniAuthを使ってGoogleアカウントからEmailなどの情報の認可を受け、それをもとにユーザー登録などを行うだけだ。正直、ググったほうがここより詳しい解説が出てくると思う。

ここでは、単にエッセンシャルなユーザーログインだけを書いていく。

まずは、email, display_name, avator の3つのフィールだけを持ったUserモデルを作成する。

```shell-session
rails g model user email:string display_name:string avatar:string
rails db:migrate
```


[[rails g model user email:string display_name:string avatar:string · kinoppyd/nekonekokawaii@8ba68dc](https://github.com/kinoppyd/nekonekokawaii/commit/8ba68dcb9d9ed77256d009371e48e905e0e7d7c8)]

Userモデルは、OAuthのコールバックのハッシュをもとにユーザーを作成するつもりで、次のようなユーザー作成ヘルパを書いておく。

```ruby
class User < ApplicationRecord
  class << self
    def find_or_create_from_auth_hash(auth_hash)
      find_or_create_by(auth_hash_to_entity(auth_hash))
    end

    private

    def auth_hash_to_entity(auth_hash)
      {
        display_name: auth_hash["extra"]["id_info"]["name"],
        email: auth_hash["extra"]["id_info"]["email"],
        avatar: auth_hash["extra"]["id_info"]["picture"]
      }
    end
  end
end
```


[[Create User from oauth hash · kinoppyd/nekonekokawaii@891b186](https://github.com/kinoppyd/nekonekokawaii/commit/891b186de0c02c54e21fe1aec7360e3359a9415d)]

次に、omniauthとomniauth-google-oauth2を導入する

```
bundle add omniauth omniauth-google-oauth2
```

[[bundle add omniauth omniauth-google-oauth2 · kinoppyd/nekonekokawaii@22afc7c](https://github.com/kinoppyd/nekonekokawaii/commit/22afc7c5817a711370d0ea3d0d44bb21e3d12100)]

Omniauthの設定は、config/initializers/omniauth.rb 内に記述する。

```ruby
Rails.application.config.middleware.use OmniAuth::Builder do
  provider :google_oauth2, ENV['GOOGLE_CLIENT_ID'], ENV['GOOGLE_CLIENT_SECRET'], {
    scope: 'userinfo.email, userinfo.profile',
    prompt: 'select_account',
    image_aspect_ratio: 'square',
    image_size: 50
  }
end
```

[[Add omniauth initializer · kinoppyd/nekonekokawaii@70880d6](https://github.com/kinoppyd/nekonekokawaii/commit/70880d609e50bc66db1e02935f7d823c42be7072)]

そして、OAuthからのコールバックを受けてUserの作成を行う、セッションコントローラの作成と、ルーティングの追加を行う。

```ruby
 class SessionsController < ApplicationController
 
   def create
     @user = User.find_or_create_from_auth_hash(auth_hash)
     session[:email] = @user.email
     redirect_to '/'
   end
 
   def destroy
     session[:email] = nil
   end
 
   protected
 
   def auth_hash
     request.env['omniauth.auth']
   end
 end
```


```ruby
Rails.application.routes.draw do
  resources :posts
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html

  get '/auth/:provider/callback', to: 'sessions#create'
  delete '/session', to: 'sessions#destroy'
end
```

[[Add sessions controller and routes · kinoppyd/nekonekokawaii@a1ef697](https://github.com/kinoppyd/nekonekokawaii/commit/a1ef697162300a8fb6294e852130248094d3cfa3)]

最後に、React側にログインボタンを追加して、 /auth/google_oauth2/ にリンクを貼れば、ユーザーの作成とログインまでの流れが完成する。

簡単に言ったが、これはController側でユーザーのログインをチェックしたり、状態によってUIを出し分けたりする処理が入るので、そう簡単にはできないし分量が多い。下記のコミットを参照してほしい。

[[User login interface · kinoppyd/nekonekokawaii@410e365](https://github.com/kinoppyd/nekonekokawaii/commit/410e365ca58aee5534803b8e626eec21cdd4c8ca)]

何をやったかを簡単にまとめておくと、OAuthの認可情報を取れていればUserモデルをセッションという名前でReact側に渡して、それによって処理を切り分けるようにしている。Sessionがなければログインボタンを出し、あればユーザーアイコンとPostようのフォームを表示している。とにかくしちめんどうなことが書かれているので、コミットの方を参考にしてほしい。


## S3に画像の投稿


ねこが可愛いことを伝えるために、画像も投稿したい。当然そう思うので画像も投稿できるようにするには、ActiveStorageを使う。

まず、S3のバケット作成とIAM設定を行う。これは手順が本質的じゃない話なので、いくつか参考になるブログを見てほしい。

[[ActiveStorageでファイルの保存先にAWS S3を利用するための準備 - Qiita]](https://qiita.com/NaokiIshimura/items/b5fabc4b8bd9f54de3b4)

この準備ができたら、まずActiveStorageを使えるようにする。今回はあえてrails newするときに省いたので、次のコマンドで使えるようにしていく。

```shell-session
bundle exec rails active_storage:install
bundle exec db:migrate
bundle add aws-sdk-s3
```

[[rails active_storage:install · kinoppyd/nekonekokawaii@46ae493]](https://github.com/kinoppyd/nekonekokawaii/commit/46ae49370b1601b31e60c09984c93530381e38cd)

[[bundle add aws-sdk-s3 · kinoppyd/nekonekokawaii@9ac7424]](https://github.com/kinoppyd/nekonekokawaii/commit/9ac7424265b2368d36b42db99da53c89e7ec5aa3)

これにによって、ActiveStorageの使うDBのテーブルが作成され、S3と通信するようのGemも入る。

次に、config/storage.ymlを編集してS3を使うようにする。

```yaml
amazon:
  service: S3
  access_key_id: <%= ENV.fetch('AWS_ACCESS_KEY') %>
  secret_access_key: <%= ENV.fetch('AWS_SECRET_ACCESS_KEY') %>
  region: ap-northeast-1
  bucket: nekonekokawaii
```


面倒なので本番環境でも開発環境でもS3を触るようにする。本来ならばバケットを分けるべきだが、これはチュートリアルなので気にしない。

```diff
diff --git a/config/environments/development.rb b/config/environments/development.rb
index 5ac4cd0..7cd289c 100644
--- a/config/environments/development.rb
+++ b/config/environments/development.rb
@@ -29,7 +29,7 @@ Rails.application.configure do
   end

   # Store uploaded files on the local file system (see config/storage.yml for options).
-  config.active_storage.service = :local
+  config.active_storage.service = :amazon

   # Print deprecation notices to the Rails logger.
   config.active_support.deprecation = :log
diff --git a/config/environments/production.rb b/config/environments/production.rb
index 9b7a9c3..94ef36e 100644
--- a/config/environments/production.rb
+++ b/config/environments/production.rb
@@ -30,7 +30,7 @@ Rails.application.configure do
   # config.action_dispatch.x_sendfile_header = 'X-Accel-Redirect' # for NGINX

   # Store uploaded files on the local file system (see config/storage.yml for options).
-  config.active_storage.service = :local
+  config.active_storage.service = :amazon

   # Force all access to the app over SSL, use Strict-Transport-Security, and use secure cookies.
   # config.force_ssl = true
```

さらに、PostモデルにもActiveStorageのBlobを扱えるようにリレーションを書いておく。

```diff
diff --git a/app/models/post.rb b/app/models/post.rb
index b2a8b46..7140e3e 100644
--- a/app/models/post.rb
+++ b/app/models/post.rb
@@ -1,2 +1,3 @@
 class Post < ApplicationRecord
+  has_many_attached :pictures
 end
```diff


[[Add ActiveStorage configures and relations · kinoppyd/nekonekokawaii@8554224]](https://github.com/kinoppyd/nekonekokawaii/commit/8554224cf6af262203be8b6c294e17dd3bc20678)

これで、PostにActiveStorageで保存した画像を紐付ける準備ができた。

最後に、Reactから画像を受け取りそれを保存するControllerと、更にReact側からどうやって画像を送るのかのコードを追加していく。ActiveStorageは、Railsのエコシステムとがっちり組み合わさって動くため、本来であればViewHelperを使ってファイルをアップロードする専用のフォームを作るのだが、フロントは全部Reactで書きたい。であれば、どのようにしてReactから送られてくるリクエストをもとに、ActiveStorageでBlobを作成すればよいのか？　最も手っ取り早い方法は、input type="file" のフォームを用意し、Base64をJSONに入れて送り、それをController内でデコードしてStringIOに詰め直すことだ。

```diff
diff --git a/app/controllers/posts_controller.rb b/app/controllers/posts_controller.rb
index d8f802e..21f44c5 100644
--- a/app/controllers/posts_controller.rb
+++ b/app/controllers/posts_controller.rb
@@ -12,6 +12,13 @@ class PostsController < ApplicationController

   def create
     post = Post.create(create_params)
+    if params[:picture]
+      blob = ActiveStorage::Blob.create_after_upload!(
+        io: StringIO.new(decode(params[:picture][:data]) + "\n"),
+        filename: params[:picture][:name]
+      )
+      post.pictures.attach(blob)
+    end
     post.save!
     render json: post
   end
@@ -21,4 +28,8 @@ class PostsController < ApplicationController
   def create_params
     params.permit(:title, :body)
   end
+
+  def decode(str)
+    Base64.decode64(str.split(',').last)
+  end
 end
```

このように、リクエストパラメータにpictureが詰まっていれば、その中のdataというBase64エンコードされた文字列を、Base64.decode64でもとに戻してStringIOに詰める。それだけだ。フロントから送られてくるときは、Base64の文字列の先頭にファイル属性などの文字列が付いているので、カンマでスプリットしてデータ部分のみを取り出す（これは別にフロントでやっても良い処理だが、Rubyのほうが楽だった）。

フロント側は、このように変更を加えている。

```diff
diff --git a/client/src/components/templates/Posts/Index.tsx b/client/src/components/templates/Posts/Index.tsx
index fff36aa..1054625 100644
--- a/client/src/components/templates/Posts/Index.tsx
+++ b/client/src/components/templates/Posts/Index.tsx
@@ -14,12 +14,27 @@ export interface PostsTemplateProps {
 const PostsTemplate: React.FC<PostsTemplateProps> = ({posts, session}) => {
   const [title, setTitle] = useState("")
   const [body, setBody] = useState("")
+  const [img, setImg] = useState({data: "", name: ""})

   const handleSubmit = () => {
-    createPost(title, body)
+    createPost(title, body, img)
     .then(() => {document.location.reload()})
   }

+  const handleImageSelect = (e: React.FormEvent) => {
+    const reader = new FileReader()
+    const files = (e.target as HTMLInputElement).files
+    if (files) {
+      reader.onload = () => {
+        setImg({
+          data: reader.result as string,
+          name: files[0] ? files[0].name : "unknownfile"
+        })
+      }
+      reader.readAsDataURL(files[0])
+    }
+  }
+
   return(
     <Content>
       {
@@ -33,6 +48,9 @@ const PostsTemplate: React.FC<PostsTemplateProps> = ({posts, session}) => {
               <p>本文</p>
               <Textarea onChange={(e) => setBody(e.target.value)} />
             </li>
+            <li>
+              <input type="file" accept="image/*;capture=camera" onChange={handleImageSelect} />
+            </li>
             <li>
               <PrimaryButton onClick={handleSubmit}>submit</PrimaryButton>
             </li>
```

FileReaderを使って、inputから渡されたファイルをBase64化した上でStateに保持し、リクエスト時にクライアントに渡している。クライアントはコードを次のように変えた。

```diff
diff --git a/client/api/posts.ts b/client/api/posts.ts
index 29f7c9b..bb9b41c 100644
--- a/client/api/posts.ts
+++ b/client/api/posts.ts
@@ -1,6 +1,6 @@
 import { AxiosInstance } from 'axios'
 import client from './client'

-export const createPost = (title: string, body: string) => {
-  return client.post('posts', {title, body})
+export const createPost = (title: string, body: string, picture?: {data: string, name: string}) => {
+  return client.post('posts', {title, body, picture})
 }
\ No newline at end of file
```

また、Postモデルが画像を扱えるようになったことで、Rails側のViewではこうやって画像情報を渡している。

```diff
diff --git a/app/views/posts/index.html.erb b/app/views/posts/index.html.erb
index 95406d7..53a2326 100644
--- a/app/views/posts/index.html.erb
+++ b/app/views/posts/index.html.erb
@@ -1 +1,7 @@
-<%= react_component("templates/Posts/Index", { posts: @posts, session: @current_user }) %>
+<%= react_component(
+  "templates/Posts/Index",
+  {
+    posts: @posts.map { |post| post.pictures.attached? ? post.attributes.merge({picture: url_for(post.pictures.first)}) : post },
+    session: @current_user
+  })
+%>
```


React側では、受け取ったURLを表示する。

```diff
diff --git a/client/src/components/organisms/Post.tsx b/client/src/components/organisms/Post.tsx
index c7aa768..ade21b0 100644
--- a/client/src/components/organisms/Post.tsx
+++ b/client/src/components/organisms/Post.tsx
@@ -7,13 +7,16 @@ import styled from "styled-components";
 export interface PostProps {
   title: string
   body: string
+  picture?: string
+
 }

-const Post: React.FC<PostProps> = ({title, body}) => {
+const Post: React.FC<PostProps> = ({title, body, picture}) => {
   return(
     <Base>
       <Title type='blockTitle' tag='h1'>{title}</Title>
       <div>{body}</div>
+      { picture ? <div><img src={picture} /></div> : null }
     </Base>
   )
 }
```

全体的にやや雑な実装だが、これはプロトタイプなので気にしない。本気になったときにブラッシュアップしてほしい。

ここまでの流れで、Reactから渡した画像はRails経由でS3にアップロードされ、それを参照することも可能になった。

[[Implements API and Front · kinoppyd/nekonekokawaii@2ae89d0]](https://github.com/kinoppyd/nekonekokawaii/commit/2ae89d0809e3e696f34b6dc7bf4a772e5a0e87d3)


## Herokuにデプロイ


ここまでくれば、あとはアプリケーションをデプロイするだけだ。といっても、Herokuを使えば何も問題なくすべてが終わる。ちょっともう時間がないので、こればっかりは自分で調べてほしい。GCPのキーとAWSのキーを設定するのを忘れないように。


## 完成したアプリ


[https://nekonekokawaii.herokuapp.com/posts](https://nekonekokawaii.herokuapp.com/posts)


## おわりに


React+Railsのアプリケーションを0から作って形にする一連の流れを解説した。なるべく、いくらでも拡張が効くようにしっかりとしたベースを作るつもりでコードを書けたと思う。これさえわかれば、あとはいつも仕事でやっているように、自分の好きなようにアプリを拡張できるようになると思う。

これでようやく、RailsとReactは書けるけど自分では何も生み出せないという疑念から自分を開放できた気がする。気持ちが凄く楽になった。
