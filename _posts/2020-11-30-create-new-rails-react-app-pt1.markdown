---
author: kinoppyd
comments: true
date: 2020-11-30 20:04:09+00:00
layout: post
link: http://tolarian-academy.net/create-new-rails-react-app-pt1/
permalink: /create-new-rails-react-app-pt1
title: 大急ぎでRails+Reactのアプリケーションを作るときにやったこと前編
wordpress_id: 663
categories:
- 未分類
---

このエントリは、[SmartHR Advent Calender 2020](https://qiita.com/advent-calendar/2020/smarthr) の1日目です





## ある日突然、大慌てでWebアプリを作らなくてはいけなくなった


先日、勤め先のSmartHR社である奇妙な福利厚生制度が爆誕し、盛り上がった。この福利厚生制度に関してはちょっとした理由で詳しく書けないので、ぜひSmartHR社にカジュアル面談という形で話を聞きに来て確かめてほしい。

で、その福利厚生制度は、あるルールで複数の従業員の組み合わせが条件を満たしたときに効力を発するものだった。その組み合わせの条件はそんなに大変ではないが、自分から能動的に制度を利用しようと思う人でなければなかなか面倒というか、とにかく誰もかもが「制度を使うためにマッチングしてくれるアプリほしいな」と思っていた。私もそう思った。だから、普段仕事で使っているRailsとReactでサクーっと一晩で社内マッチングアプリを作り、社内でのｽｰﾊﾟｰﾊｶｰの名声をほしいままにしようとした私は、早速 rails new した。

そして気づいた。**確かに自分は仕事でRails+ReactのAPI+SPAプロジェクトをいくつか経験してきたが、0からその環境を作ったことがないということに**。薄々気づいていたが、もしかして自分は用意された環境でしか仕事が出来ないのではないか。いやそんなことはない。そういう気持ちを打破するためにも、なかば強迫観念に突き動かされるようにマッチングアプリの作成に取り掛かった。結果として、多くの躓きを経て、非常に非常にかんたんな機能しか持たないアプリは4日後に完成し、なんとのべ20時間ほどの時間を要した。

最終的にアプリは完成したが、この簡単なアプリを作るために20時間を要したという事実は、私の心臓を強く締め付けた。普段社内で「いやー僕RubyとかRailsとかReactとかできまっす」みたいな顔してる自分が急に恥ずかしくなってきた。頬に含羞の色が浮かび、空恥ずかしさに心がざわめき、穴があれば入りたい、生き恥をさらすとはまさにこのことである。しかしだからこそ、これから書くことは同じく0からRails+React環境を用意したことのない人に向けて書く、まさに書くは一時の恥、書かぬは一生の恥のエントリである。


## ねこねこかわいい


突然だが、最近猫を飼い始めた。いろいろあって猫を飼うのが夢だったが、それが叶った形だ。猫は可愛い。本当に可愛い。だから、うちの猫を自慢したくなる。ということで今回は、社内の福利厚生マッチングアプリで得た知見をもとにうちの猫を自慢するためのアプリケーションをRails+React構成で作ってみようと思う。なお、最速で完成させつつアプリを大きく成長させるための土台もしっかり作ることを目指すので、まずはSPAとかのしゃらくさい方法はとらず、Webpackerを使いRailsからReactのコンポーネントをレンダリングするし、RailsはAPIモードとかにはしない。しかし、すぐにでもWebpackerを抜け出し、Webpackでフロントを完全に管理し、RailsはAPIとして機能できるようにする準備もやる。だから、きっちりした構成を最短で作るための、自分がやった最速の構成ということになる。そのため、それなりの分量があるので、前編と後編で分けることにした。

このアプリ「ねこねこかわいい」が目指すのは



 	
  * RailsでバックエンドのAPI作成とWebpackerで作成されたアセットの配信

 	
  * React+TypeScriptでフロントの作成

 	
  * axiosを使用してReactからRailsに通信

 	
  * Google OAuthでユーザー認識

 	
  * S3に画像の投稿

 	
  * Herokuへのデプロイ


の5つの項目となる。S3はActiveStorageを使うのでGCSでもいいし、Herokuも大して変わらんのでBeanstalkやAppEnginでもいい。BeanstalkはEC2のことを考えるのがめんどくさく、AppEngineは無料でFlex環境が使えないからHerokuを使うだけだが、とりあえずこの構成で始める。

また、このエントリの流れをコミットしたリポジトリも用意した。

[https://github.com/kinoppyd/nekonekokawaii](https://github.com/kinoppyd/nekonekokawaii)

各見出しの中では、実際に手順をコミットしたパーマネントリンクも提示する。


## rails new


兎にも角にも、新しいアプリを作るにはここからはじまる。rails newは、新しいバージョンのRailsがリリースされたときに、記念行事のようにポチッとやるだけで、実はそんなに何度もちゃんとやったことがないので、ヘルプをしっかり読んだ。その結果、このコマンドになった。

    
    rails new nekonekokawaii -d postgresql --skip-keeps --skip-action-mailer --skip-action-mailbox --skip-action-text --skip-action-cable --skip-sprockets --skip-turbolinks --webpacker=react


順にオプションの話をしていく



 	
  * DBはPostgreSQLを使うので -d postgresql

 	
  * Git管理をするが、.keepファイルは別にいらないので --skip-keeps

 	
  * ActionMailerもActionMailboxもActionTextもActionCableも使わないので、 --skip-action-mailer --skip-action-mailbox --skip-action-text --skip-action-cable

 	
    * もし必要になったら後から足せる




 	
  * フロントをReact+Webpackerでほぼ全て配信し、スタイリングもStyledComponentsを使うので、Sproketsは不要 --skip-sprockets

 	
  * 将来的にフロントをRailsから離すことを考えると、TurboLinksも不要 --skip-turbolinks

 	
  * Webpackerを使ってReactを書きたいので、 --webpacker=react


edgeはつけようかどうか悩んだが、いまはWebpackのメジャーバージョン移行期であり、かなり混乱がある（webpack-dev-serverがservになったりとかで動かなかった）ので、つけなかった。

[rails new nekonekokawaii -d postgresql --skip-keeps --skip-action-mai… · kinoppyd/nekonekokawaii@fbe4f3c](https://github.com/kinoppyd/nekonekokawaii/commit/fbe4f3ced8c0b0e15ae1cd503a126ee1c6e6369e)


## DBの用意


世の中には、開発はSQLite3で行って本番はPostgreSQLやMySQLでやる、なんて甘い世界は存在しない。[現場Rails](https://amzn.to/3mpFGXN)がそう言ってるし、[SmartHRが用意したRailsのブートキャンプ](https://github.com/kufu/yay)でもその方針でやってきたし、何よりそんな甘っちょろい考えではメキシコで生きてはいけない。

ローカル環境での開発用DBは、もはやDockerComposeでサクッと用意する以外の方法が思いつかない。

DockerComposeは、各自でインストールしておいてほしい。今はLinuxだけでなくMacにもWindowsにも問題なく入る。

[Install Docker Compose | Docker Documentation](https://docs.docker.com/compose/install/)

DBは本番運用に耐えるものならば何でもいいが、HerokuへのデプロイをゴールとしたのでPostgreSQLを用意した。プロジェクトディレクトのルートにdocker-compose.ymlファイルを用意し、中身を書く。

    
    version: "3.8"
    services:
      db:
        image: postgres:13.1
        ports:
          - 5432:5432
        environment:
          POSTGRES_PASSWORD: nekonekokawaii
          POSTGRES_USER: nekonekokawaii
          POSTGRES_DB: nekonekokawaii_development
          PGDATA: /var/lib/postgresql/data/pgdata
        volumes:
            - ./tmp/pgdata:/var/lib/postgresql/data/pgdata


config/database.ymlには、DockerComposeで立ち上げたDBにつなぐための設定を追加する。

    
    diff --git a/config/database.yml b/config/database.yml
    index 70531de..0d9f807 100644
    --- a/config/database.yml
    +++ b/config/database.yml
    @@ -16,4 +16,6 @@
     #
     default: &default
    +  username: nekonekokawaii
    +  password: nekonekokawaii
       adapter: postgresql
       encoding: unicode
    @@ -25,4 +27,5 @@ development:
       <<: *default
       database: nekonekokawaii_development
    +  host: 127.0.0.1
    
       # The specified database role being used to connect to postgres.


これらの設定を用意した後、docker-composeコマンドでDBを立ち上げる。

    
    docker-compose up -d


これで開発用のDBが用意された。

[Add docker-compose file and configure database · kinoppyd/nekonekokawaii@78102e1](https://github.com/kinoppyd/nekonekokawaii/commit/78102e1fc5e1929843df601a80f633e70a2a06bc)


## Webpackerの設定


Webpackerを利用し、React+TypeScript環境を、フロントのコードをRailsの配下から極力分離した形で書いていくことを目標にする。最初のnewコマンドでインストールされるWebpackerは、最新の5系ではなく何故か4系が入る。おそらくedgeオプションを入れなかったからだと思うが、よくわからない。

一応Webpakerについて少し触れておくと、WebpackをRailsから便利に使うためのラッパーだ。WebpackDevServerとかも使えるように用意されている。ユーザーは直接Webpackを扱えずWebpackerを経由するしかないので、Webpackに慣れ親しんだ人やWebpackerを酷使したい人は結構辛いらしい。とはいえ、最初から入っているアドバンテージは大きいので、後々卒業してWebpackに切り替えていくことを視野に入れながら、最初はWebpackerで十分だろうと思う。

まずはTypeScriptを入れる。そして、型チェックをBabelでの変換時ではなく、Webpackのコンパイル時に行うように設定を追加する。

    
    bundle exec rails webpacker:instlal:typescript
    yarn add --dev fork-ts-checker-webpack-plugin


[bundle exec rails webpacker:install:typescript · kinoppyd/nekonekokawaii@4d01262](https://github.com/kinoppyd/nekonekokawaii/commit/4d01262fa8b6c8346d918c692ccd22866fe1d67b)

[yarn add --dev fork-ts-checker-webpack-plugin · kinoppyd/nekonekokawaii@a866f11](https://github.com/kinoppyd/nekonekokawaii/commit/a866f112d9798a8f05e5a2972e9455acf38e4733)

2つのコマンドを実行したら、config/webpack/development.ymlを編集する。

    
    diff --git a/config/webpack/environment.js b/config/webpack/environment.js
    index f10aeb5..86cd25b 100644
    --- a/config/webpack/environment.js
    +++ b/config/webpack/environment.js
    @@ -3,3 +3,16 @@ const typescript =  require('./loaders/typescript')
    
     environment.loaders.prepend('typescript', typescript)
     module.exports = environment
    +
    +const ForkTsCheckerWebpackPlugin = require("fork-ts-checker-webpack-plugin");
    +const path = require("path");
    +
    +environment.plugins.append(
    +    "ForkTsCheckerWebpackPlugin",
    +    new ForkTsCheckerWebpackPlugin({
    +          typescript: {
    +                  configFile: path.resolve(__dirname, "../../tsconfig.json"),
    +                },
    +          async: false,
    +        })
    +);


[Add pre-compile type check settings · kinoppyd/nekonekokawaii@b7e48f8](https://github.com/kinoppyd/nekonekokawaii/commit/b7e48f8052336333c1fc06e34ac2e19b8dbebfc5)

この手順はWebpackerのTypeScript Integrationのヘルプに書かれている。

[webpacker/typescript.md at master · rails/webpacker](https://github.com/rails/webpacker/blob/master/docs/typescript.md)

また、デフォルトで作られているapp/javascript配下のReactコンポーネントはJSXなので、TSXにリネームする。とはいえ自動生成されたHelloReactコンポーネントは使うことは無いので、これは別にやってもやらなくてもいい。

    
    diff --git a/app/javascript/packs/hello_react.jsx b/app/javascript/packs/hello_react.tsx
    similarity index 100%
    rename from app/javascript/packs/hello_react.jsx
    rename to app/javascript/packs/hello_react.tsx


[Rename jsx to tsx · kinoppyd/nekonekokawaii@ccef21c](https://github.com/kinoppyd/nekonekokawaii/commit/ccef21cd1ccfac8fc13722a341933377620672c1)

今度はTypeScriptの設定を行う。せっかく型の恩恵を受けるのだから、ある程度厳しくしておいたほうがいい。

asをたくさん書くのが面倒なのでSyntheticDefaultImportsを有効にする。そしていくつかのstrict系オプションを有効にする。noUnusedLocalsとかnoUnusedParametersとかも有効にしたほうが良いのだろうけど、開発中に機能をつけたり消したりしてると意外と腹が立つのでとりあえず外しておいた。TSあんまり詳しくないけど、productionのビルドのときだけ有効にする方法とかないのかな……とか思ったりする。

    
    diff --git a/tsconfig.json b/tsconfig.json
    index 7425c2b..2206176 100644
    --- a/tsconfig.json
    +++ b/tsconfig.json
    @@ -8,7 +8,15 @@
         "moduleResolution": "node",
         "sourceMap": true,
         "target": "es5",
    -    "jsx": "react"
    +    "jsx": "react",
    +    "allowJs": false,
    +    "allowSyntheticDefaultImports": true,
    +    "removeComments": true,
    +    "strictNullChecks": true,
    +    "strictPropertyInitialization": true,
    +    "noFallthroughCasesInSwitch": true,
    +    "noImplicitAny": true,
    +    "noImplicitThis": true
       },
       "exclude": [
         "**/*.spec.ts",


[Modify tsconfig · kinoppyd/nekonekokawaii@0101fe6](https://github.com/kinoppyd/nekonekokawaii/commit/0101fe61a0c15fc25afccd1194093381e081fdf9)

最後に、今後Webpackerから離れていくことも考えて、Webpackerで管理するファイルをRailsのapp配下から移動させる。名前は好きにしていいが、プロジェクトのルート配下にclientやfrontendという名前のディレクトリを用意し、その中にsrcディレクトリを置いてコードを追加していくのが一般的な気がする。

まず、Webpackerの設定を変える。

    
    diff --git a/config/webpacker.yml b/config/webpacker.yml
    index 352f8b2..985129b 100644
    --- a/config/webpacker.yml
    +++ b/config/webpacker.yml
    @@ -1,7 +1,7 @@
     # Note: You must restart bin/webpack-dev-server for changes to take effect
    
     default: &default
    -  source_path: app/javascript
    +  source_path: client/src
       source_entry_path: packs
       public_root_path: public
       public_output_path: packs


そしてファイルを移動する。

    
    git mv app/javascript/ client


これで、client/srcのディレクトリが、Webpackerの扱うフロントのコードのルートとなる。後々、Webpackに切り替えるときも、app/javascriptよりもここに配置してあるのは自然だと思うので、早めにやっておくに越したことはない。

[Change front-end source code directory · kinoppyd/nekonekokawaii@315446e](https://github.com/kinoppyd/nekonekokawaii/commit/315446e6bb10d751f996f3addeab3fdbc276770d)


## RailsとReactのインテグレーション


WebpackerによってRails内でReactを扱えるようになったので、Reactのコンポーネントに値をバインドするための方法を簡単に実現したい。


Webpakerを使って作成されたReactのページに、Rails側からPropsを渡してレンダリングをするための方法はいくつか方法があるが、[公式の比較表](https://github.com/rails/webpacker/blob/master/docs/react.md)を見ると長期的にReact側をRailsと切り離していくためにはreact_on_railsを選択するのが良さそうに見えた。しかしその一方で、react_on_railsは複数プロセス立ち上げ前提のためにforemanを提示（べつに使わなくてもいいけど）されたり、SSRをHMRでやろうとするとProプランが必要だったりで、最速でいい感じにするには気にすることが多い気がする。




そのため、ここではほぼゼロコンフィグで動かせるreact-railsを使う。ゼロコンフィグというだけの理由で選んだ。react-railsでも最低限SSRできるし、アプリケーションを成長させていく過程で取り外しが楽だというのも見越している。




[reactjs/react-rails: Integrate React.js with Rails views and controllers, the asset pipeline, or webpacker.](https://github.com/reactjs/react-rails)




やることは簡単で、Gemを追加してgenerateするだけ。




    
    diff --git a/Gemfile b/Gemfile
    index 1db5059..36c0dd9 100644
    --- a/Gemfile
    +++ b/Gemfile
    @@ -19,6 +19,8 @@ gem 'jbuilder', '~> 2.7'
     # Use Active Storage variant
     # gem 'image_processing', '~> 1.2'
    
    +gem 'react-rails', '~> 2.6'
    +
     # Reduces boot times through caching; required in config/boot.rb
     gem 'bootsnap', '>= 1.4.2', require: false



    
    bundle install
    bundle exec rails generate react:install


generate react:install コマンドは忘れやすいので注意。

[Add react-rails · kinoppyd/nekonekokawaii@fe7da2c](https://github.com/kinoppyd/nekonekokawaii/commit/fe7da2cf40d137eea34d8879d5cda42335bff71e)

[bundle exec rails generate react:install · kinoppyd/nekonekokawaii@a7d295d](https://github.com/kinoppyd/nekonekokawaii/commit/a7d295d310b2857c590ca2244fea960d35a842cc)


## ここまでの動作確認


ずっと準備をしてきたので、そろそろコードを書いてReactとRailsの動作を確認しないと不安になる。ということで、railsでおなじみのgenerateを使ってPostリソースを追加して表示を確認してみることにする。

    
    bundle exec rails g resource post title:string body:text


[bundle exec rails g resource post title:string body:text · kinoppyd/nekonekokawaii@71f8a3f](https://github.com/kinoppyd/nekonekokawaii/commit/71f8a3f1a2dab7573d3477da98486c896e2496d1)

確認用にSeedデータも用意する。

    
    Post.create!(title: 'test post 1', body: 'miow!')
    Post.create!(title: 'test post 2', body: 'miow! miow!')


DBをマイグレーションして、DockerComposeで用意したDBと疎通していることを確かめつつSeedデータを入れる。

    
    bundle exec rails db:migrate
    bundle exec rails db:seed


データを表示するためのコンポーネントを作っていく。ディレクトリ構成は次のようにする。

    
    client/src/components
    ├── organisms
    │   └── Post.tsx
    └── templates
        └── Posts
            ├── Index.tsx
            └── Show.tsx



    
    import React from 'react'
    
    export interface PostProps {
      title: string
      body: string
    }
    
    const Post: React.FC<PostProps> = ({title, body}) => {
      return(
        <div>
          <h1>{title}</h1>
          <div>{body}</div>
        </div>
      )
    }
    
    export default Post



    
    import React from 'react'
    
    import Post, { PostProps } from '../../organisms/Post'
    
    export interface PostsTemplateProps {
      posts: PostProps[]
    }
    
    const PostsTemplate: React.FC<PostsTemplateProps> = ({posts}) => {
      return(
        <div>
          {posts.map(post => (
            <Post {...post} />
          ))}
        </div>
      )
    }
    
    export default PostsTemplate



    
    import React from 'react'
    
    import Post, { PostProps } from '../../organisms/Post'
    
    export interface PostsTemplateProps {
      post: PostProps
    }
    
    const PostsTemplate: React.FC<PostTemplateProps> = ({post}) => {
      return(
        <div>
          <Post {...post} />
        </div>
      )
    }
    
    export default PostsTemplate


Postの内容をレンダリングするPostと、一覧表示のIndex、詳細表示のShowを用意した。client配下のディレクトリ構成は、なるべくAtomic Desingの推奨するディレクトリ構成を模倣し、コードの分割に耐えるようにしていく。

表示用のコンポーネントはこれで完成。 ./bin/webpack コマンドを実行し、コンパイルできることを確認する。

    
    ./bin/webpack


もちろん、これらのファイルを書きながらシェルでwebpack-dev-serverを動かして、常にファイルの変更を検知しながらコンパイルエラーを確認しても良い。

    
    ./bin/webpack-dev-server


フロントが終わったら、バックエンドのコードを書く。まずは、Controllerの簡単なリソース取得の箇所。

    
    diff --git a/app/controllers/posts_controller.rb b/app/controllers/posts_controller.rb
    index a66e6b8..1cf768f 100644
    --- a/app/controllers/posts_controller.rb
    +++ b/app/controllers/posts_controller.rb
    @@ -1,2 +1,9 @@
     class PostsController < ApplicationController
    +  def index
    +    @posts = Post.all.order(created_at: :desc)
    +  end
    +
    +  def show
    +    @post = Post.find(params[:id])
    +  end
     end


このコードは特に何の変哲もなく、Controller内でindexはPostを全件取得し、showでは特定のIDのものを取得しているだけだ。

問題はViewのファイルで、react-railsによって生えたreact_componentヘルパを使ってControllerで取得したデータをReactのコンポーネントに渡していく。いくのだが、当然渡す先はWebpackがコンパイルした単一JSファイルなので、型情報などは存在しない。そのため、全てがレンダリング時に動的に解決されるため、コンポーネントのIFとViewが渡す変数が本当に正しいバインドなのか、そもそもコンポーネントの指定が正しいのかなど、ありとあらゆる問題がエラー無しで通ってしまう。なので、react-railsの最も難しい点は、Reactの世界とRailsの世界の間を橋渡しするものがなにも無いという点にある。一度慣れてしまえば何となく分かるが、一度躓くとここが一番むずかしい。なにせ何のエラーも表示されないので、試行錯誤するしか無い。このブログに書かれている内容は自分が試行錯誤した結果にうまく行った方法なので、是非真似をして勘を掴んでほしい。

Viewのファイルは次のように用意する。

    
    <%= react_component("templates/Posts/Index", { posts: @posts }) %>



    
    <%= react_component("templates/Posts/Show", { post: @post }) %>
    


それぞれのControllerが標準で使うViewのERBファイルに、react_componentヘルパを書いて、コンポーネントのPropsに該当するハッシュを渡すだけだ。ページのレンダリングは全てReactに任せるので、これだけで良い。

これらのファイルを保存し、rails serverを立ち上げて `/posts` にアクセスすると、Reactで作成された一覧のページが表示される。

[![スクリーンショット 2020-11-30 4.51.13](http://tolarian-academy.net/wp-content/uploads/2020/12/スクリーンショット-2020-11-30-4.51.13.png)](http://tolarian-academy.net/wp-content/uploads/2020/12/スクリーンショット-2020-11-30-4.51.13.png)

特に何のスタイリングもしてないので、こんな感じの表示になると思う。

[Add fetch Post resource · kinoppyd/nekonekokawaii@11833b9](https://github.com/kinoppyd/nekonekokawaii/commit/11833b9822fc5c995fc96a78f56453da1c2939ca)

ここまでで、ReactがRailsのViewとして配信されデータが正しく受け渡しされていることがわかった。


## UI Framework


UI Frameworkには、[SmartHR UI](https://github.com/kufu/smarthr-ui)を使う。これはSmartHR社が公開しているアプリケーション用のコンポーネント集で、React+StyledComponentsで作られている。普通にアプリを作るのであれば、[Material UI](https://material-ui.com/)とかを使うべきなのだろうが、もともとは社内用のアプリを作っていた過程の記録なので、宣伝も兼ねてSmartHR UIを使う。また、スタイリングには[Styled Components](https://styled-components.com/)を使う。CSS in JSには色々思うことが多い人も少なくないだろうが、コンポーネントの中にスタイルを閉じ込められて簡単に管理できるし何よりRails側のCSS配信とかを考える必要がなくなるので、Styled Componentsを利用する。

    
    yarn add smarthr-ui
    yarn add styled-components @types/styled-components


インストール

[yarn add smarthr-ui · kinoppyd/nekonekokawaii@e31da09](https://github.com/kinoppyd/nekonekokawaii/commit/e31da095be91b728720dfbe1b07c4e9ec6e5dec1)

[yarn add styled-components @types/styled-components · kinoppyd/nekonekokawaii@ae8c8f7](https://github.com/kinoppyd/nekonekokawaii/commit/ae8c8f74929d3c53af6e828605378065d6e0c0f4)

次に、client/src/components/atomsディレクトリを作成して、基本となるパーツをimport、プロジェクト用にスタイリングしていく。ディレクトリ構成は次のようになる。Atomic Designにならって、最小の部品はcomponents/atomsディレクトリに置いていく。さっきと違ってindexファイルを置いてimportしやすくしているが、これはやってもやらなくてもいいし、むしろreact-railsの前では無力になるので結局export default書く必要があったりとややこしい。

    
    client/src/components/atoms
    ├── Base
    │   ├── Base.tsx
    │   └── index.ts
    ├── Header
    │   ├── Header.tsx
    │   └── index.ts
    └── Heading
        ├── Heading.tsx
        └── index.ts


ひとまず、BaseとHeadingをSmartHR UIからimportして少しStyledComponentsで加工。HeaderはSmatHR UIのパーツをそのまま使うのは難しいので、適当にCSSを書きます。

    
    import { Heading as SmartHRHeading } from 'smarthr-ui'
    
    export const Heading = SmartHRHeading



    
    import React from 'react'
    import styled from 'styled-components'
    import { Base as SmartHRBase } from 'smarthr-ui'
    
    export const Base = styled(SmartHRBase)`
        margin: 16px 32px;
        padding: 6px 24px 12px 24px;
    `



    
    import React from 'react'
    import styled from 'styled-components'
    
    export const Header: React.FC<{}> = () => {
      return(
        <HeaderArea>
          <Logo>nekonekokawaii</Logo>
        </HeaderArea>
      )
    }
    
    const HeaderArea = styled.header`
      height: 50px;
      padding: 0 4px;
      background-color: #00C4CC;
    `
    
    const Logo = styled.span`
      margin: 0px 4px;
      text-align:center;
      font-weight:normal;
      color:#EEE;
      font-size:42px;
      letter-spacing:-4px;
    `
    
    export default Header


こんな感じで、スタイリングした部品を用意していく。同じように、既存のテンプレートとコンポーネントも書き換えていく。

    
    diff --git a/app/views/layouts/application.html.erb b/app/views/layouts/application.html.erb
    index 2f7a52b..908882c 100644
    --- a/app/views/layouts/application.html.erb
    +++ b/app/views/layouts/application.html.erb
    @@ -9,7 +9,8 @@
         <%= javascript_pack_tag 'application' %>
       </head>
    
    -  <body>
    +  <body style="margin: 0px">
    +    <%= react_component("atoms/Header/Header") %>
         <%= yield %>
       </body>
     </html>



    
    diff --git a/client/src/components/organisms/Post.tsx b/client/src/components/organisms/Post.tsx
    index d2799fa..c7aa768 100644
    --- a/client/src/components/organisms/Post.tsx
    +++ b/client/src/components/organisms/Post.tsx
    @@ -1,5 +1,9 @@
     import React from 'react'
    
    +import { Base }from '../atoms/Base'
    +import { Heading } from '../atoms/Heading'
    +import styled from "styled-components";
    +
     export interface PostProps {
       title: string
       body: string
    @@ -7,11 +11,16 @@ export interface PostProps {
    
     const Post: React.FC<PostProps> = ({title, body}) => {
       return(
    -    <div>
    -      <h1>{title}</h1>
    +    <Base>
    +      <Title type='blockTitle' tag='h1'>{title}</Title>
           <div>{body}</div>
    -    </div>
    +    </Base>
       )
     }
    
    +
    +const Title = styled(Heading)`
    +  background:linear-gradient(transparent 80%, #00C4CC 0%);
    +  margin-bottom: 32px;
    +`
     export default Post



    
    diff --git a/client/src/components/templates/Posts/Index.tsx b/client/src/components/templates/Posts/Index.tsx
    index 6bdf440..8a6580d 100644
    --- a/client/src/components/templates/Posts/Index.tsx
    +++ b/client/src/components/templates/Posts/Index.tsx
    @@ -1,4 +1,5 @@
     import React from 'react'
    +import styled from 'styled-components'
    
     import Post, { PostProps } from '../../organisms/Post'
    
    @@ -8,12 +9,17 @@ export interface PostsTemplateProps {
    
     const PostsTemplate: React.FC<PostsTemplateProps> = ({posts}) => {
       return(
    -    <div>
    +    <Content>
           {posts.map(post => (
             <Post {...post} />
           ))}
    -    </div>
    +    </Content>
       )
     }
    
    +const Content = styled.div`
    +  margin: 32px 10%;
    +  min-width: 800px;
    +`
    +
     export default PostsTemplate


これでなんとなくスタイルがついたはずなので、再び /posts を表示してみるとこうなる。

[![スクリーンショット 2020-12-01 2.18.49](http://tolarian-academy.net/wp-content/uploads/2020/12/スクリーンショット-2020-12-01-2.18.49.png)](http://tolarian-academy.net/wp-content/uploads/2020/12/スクリーンショット-2020-12-01-2.18.49.png)

なんとなーくそれっぽくなってきた。


## 後編に続く


普通に長いので、残りは後編に続きます。

前編では、railsアプリの初期化とWebpackerの設定、DBの準備と基本的な表示用コンポーネントの動作を確認しました。一旦ここまででも、最速かつ長期的な変更に強そうなRails+React+TypeScript構成のアプリケーションの作成をお見せできたかと思います。

後編では、axiosを使ったCRUD、Google OAuthでの認証、S3への画像アップロード、Herokuへのデプロイをやってみましょう。

それでは、よいAdvent Calendarを。
