---
author: kinoppyd
date: 2017-12-03 15:00:10+00:00
layout: post
image: /assets/images/icon.png
title: Gitをバックエンドにしたタスク管理bot
excerpt_separator: <!--more-->
---

この記事は、[ドワンゴ Advent Calendar 2017](https://qiita.com/advent-calendar/2017/dwango) の4日目の記事です。


## TL; DR


すごい簡単なゆるいタスク管理のバックエンドに、内容アドレスファイルシステムとしてのGit使うのもまあいいんじゃないの？ とおもって[Gem](https://rubygems.org/gems/git_queue)を作った。


## ゆるいタスク管理システムが必要だった


通常、仕事のタスク管理はJIRAとかRedmineとかGithubとかTorelloとかなんかそういう専用のやつを使うと思います。とはいえ、「もう今日は帰ってるけど、明日こののプルリク見てください」とかSlackで伝えたり、「このプルリクレビュー通ってるんで、明日マージしといて」とかSlackで伝えたり、その程度のことをチケットにするのも妙な感じです。デイリーミーティングや口頭やSlackで伝えれば良い気もしますが、まあそういうのって大抵忘れます。そもそも言っても忘れ去られるし。Slackのリマインダも使いづらい。そういう、なんか忘れるけど伝えときたいことを忘れないようにしたいなと思ったら、とりあえずbotを作ります。

botを作ることの理由を問われても、まあなんとなくとしか言いようが無いですが、Slack上のbotだったらまあ大体みんな見てるだろうという程度の理由です。

<!--more-->

## 簡単なタスク管理システムってなんだろう


頭にぽわっと思いついた程度の要件です



 	
  1. FIFO型のキュー

 	
  2. キューの操作履歴の参照

 	
  3. Slack上からキューを操作可能


普通の配列操作とSlack botじゃんと思いましたが、肝心なのはキューの操作履歴の参照です。

キューの操作履歴、例えば新しいタスクをキューに追加したとか、先頭のタスクを完了したとか、n番目とm番目のタスクを入れ替えたとか、そういう類の操作履歴を残そうと思うと、これはなかなか厄介な気がしました。なにせ、方法がパッと思いつくだけで5個くらいあり、そのどれもが概ね「DBかファイルに操作履歴を残す」という方法です。ただ、DBを使うのは大掛かりで嫌だし、ファイルに書き出すのはロックの問題や破損の問題に立ち向かうのが億劫です。

もう少し何か手軽でいい感じの無いかと考えたところ、GitのようなVCSをキューのバックエンドに使えば、操作の履歴を完全に残して参照も手軽なタスクシステムが作れるのではないかと思いました。


## libgit2を使おう


キューのバックエンドにGitを使うアイディアを出したは良いものの、普通にSlack botからGitの操作をすると、次のような点で困ります。



 	
  1. Botを動かす場所にGitコマンドが必要

 	
  2. GitはChatBotのような並列操作で同時に扱うとワークスペースを壊す

 	
  3. 遅い


これらの問題に立ち向かう方法は、libgit2を使うことです。

[https://libgit2.github.com/](https://libgit2.github.com/)

libgit2は、Cで書かれた組み込み用のGitライブラリで、たくさんの言語へのバインディングとともに配布され、Gitコマンドに依存せずにGitの操作が可能です。また、通常のGitコマンドと違い、Gitの内部コマンドを直接呼び出すため、動作も高速です。それだけでなく、通常開発者が使うGitのコマンドの裏に隠されたアトミックな操作を直接行うため、完全とは言いませんが、ある程度の並列実行にも耐えられる安全性を持っています（ワークスペースが壊れて、Git操作を受け付けなくなるとかが起こらなくなる）。

libgit2を使うことで、Botを動かす場所にGitコマンドが必要なく、並列操作にある程度耐え、本来のGitよりも早く処理を実行することが出来ます。

しかしその一方で、大きな欠点もあります。それは、libgit2で扱えるGitの世界は、我々が普段使っているGitコマンドとは大きく違う点です。libgit2を使ってGitリポジトリを操作するには、非常に複雑で手間のかかる手順と、Gitの裏側の世界への理解が必要です。


## 本当のGitの世界


最初に書いておきますが、この段落の内容に関してより詳しく理解したい場合は、[Pro Gitの10章](https://git-scm.com/book/ja/v2/Git%E3%81%AE%E5%86%85%E5%81%B4-%E9%85%8D%E7%AE%A1%EF%BC%88Plumbing%EF%BC%89%E3%81%A8%E7%A3%81%E5%99%A8%EF%BC%88Porcelain%EF%BC%89)を読んで下さい。

Gitの世界には、通常開発者が利用する add や checkout や push などの磁器（Porcelain）と呼ばれるコマンドの裏で、隠された配管（Plumbing）と呼ばれるコマンドが複雑に呼び出され、操作されています。

簡単に、Gitには表側の世界と裏側の世界があると考えてください。表側の世界は、我々開発者が普段見ている、VCSとしてのGitです。ファイルに変更を加え、ステージし、コミットして変更履歴を記録する。それが、裏側の世界のGitです。一方で、裏側の世界のGitは、内容アドレスファイルシステムです。内容アドレスファイルシステムは、少なくともGitの世界観ではほぼほぼKVSシステムとほぼ同じようなものと理解して問題ないです。ざっくり言うとGitはKVSです。

表側の世界を操作するのが、先にも出てきた普段みなさんが慣れ親しんでいるGitコマンドです。そして、裏側の世界を操作するのが、今回つかったlibgit2です。もちろん我々のよく知るGitコマンドでも、裏の世界を操作することは出来ますし、そのためのコマンドが（普段は使わないけど）用意されています。しかし、libgit2は完全に裏の世界のために存在するライブラリで、表の世界のような使用方法は出来ません。


### 内容アドレスファイルシステムとしてのGit


例えば、Gitのワークスペースにあるファイル「something.txt」を追加して、内容を編集しコミットすることを考えてください。通常の我々の操作では、次のようなことを行います。

```shell-session
$ touch something.txt
$ vim something.txt # edit file
$ git add something.txt
$ git commit -m 'add something file'
```

ファイルを編集し、git add コマンドでファイルをステージし、git commit コマンドで新しいコミットを作成します。それでは、その時にGitの裏側の世界では何が起こっているかを見てみましょう。


#### git add


あるファイルに対して add を行った時、Gitの裏側の世界では次のようなことが起こります。



 	
  1. add されたファイルの中身と、ファイルのメタ情報のSHA1ハッシュ値を計算する

 	
  2. ファイルのメタ情報と中身をNULL文字で連結し、zlibでその情報を圧縮する

 	
  3. 圧縮した内容を、1で計算したSHA1の値のファイル名に書き出す

 	
    1. 正確には、SHA1値の先頭2文字のディレクトリ下に、末尾38文字のファイルを作り、そこに書き出す

 	
    2. ex. ハッシュ値が d670460b4b4aece5915caf5c68d12f560a9fe3e4 であれば、.git/objects/d6/70460b4b4aece5915caf5c68d12f560a9fe3e4 というファイルに内容を書き出す




 	
  4. ワークスペースのファイルとディレクトリの構成をもとに、ツリーオブジェクトを更新する


ここで重要なのは、**Gitではあるファイルのある時点の状態に、そのファイルのSHA1値でアクセスできるKVSだということです。**

Gitの裏側の世界では、ありとあらゆるファイルとディレクトリは、オブジェクトとして扱われます。上の例では、addされたファイルはblobと呼ばれるオブジェクトです。オブジェクトには、その内容と属性で一意のSHA1値が振られていて、Gitの裏側の世界ではこのSHA1値を使うことによってファイルにアクセスすることが可能です。

blobオブジェクトは、あるファイルのある時点での完全な内容をzlibで圧縮したもので、Gitはその内容にSHA1の値のキーでアクセスできる状態です。これが、Gitが内容アドレスファイルシステムと呼ばれる理由です。ファイルのSHA1値というキーを知っていれば、そのファイルの内容にアクセスすることができます。それでは、今現在のワークスペースの内容を、SHA1値のキーで表現するには、どうすればいいでしょうか？　その仕組が、ツリーオブジェクトです。

ツリーオブジェクトとは、Linuxのディレクトリ構成に似た情報が書かれたファイルです。参照ツリーの内容の例として、次のようなものが挙げられます。

```
100644 blob a906cb2a4a904a152e80877d4088654daad0c859      README
100644 blob 8f94139338f9404f26296befa88755fc2598c289      Rakefile
040000 tree 99f1a6d12cb4b6f19c8655fca46c3ecf317074e0      lib
```

各行の最初のブロックがファイルのアクセス権限、次のブロックがオブジェクトのタイプ、その次のブロックがアクセスすべきオブジェクトのSHA1値で、最後のブロックがファイル名です。これは、Linuxのシェルで ls -la コマンドを打った時の情報によく似ています。blobをファイル、treeをディレクトリと置き換えれば、ほぼおなじ情報が得られます。これらの各行がファイルの情報と参照先を表しています。

参照ツリーは入れ子構造にすることが出来ます。つまり、ルートの参照ツリーの下に、サブディレクトリとしての参照ツリーを入れることも可能です。これによって、ファイルのディレクトリ構成を表現しています。

このように、Gitの裏側の世界では、すべてのファイルとディレクトリにはSHA1値が割り振られ、その値を入れることでファイルとディレクトリの内容を参照することができます。


#### git commit


add コマンドでステージングしたファイルを変更履歴としてコミットするには、 git commit コマンドを使います。コミットに関しては、Gitの表の世界のコマンドと大きな違いはありません。Gitは次の情報を集め、**コミットオブジェクト**を作ります。



 	
  * Author

 	
  * Committer

 	
  * Message

 	
  * ルートのツリーオブジェクト

 	
  * Parent（一番最初のコミットのときは、この値は含まれない）


AuthorやCommitterやMessageは、通常の git commit コマンドでもよく見るので、何かわかると思います。Parentは新しくつるコミットの前のコミットで、git log コマンドで見ることができるコミットの並びで親に該当するものです。

目新しい情報は、ルートのツリーオブジェクトです。これは、git add コマンドの裏側で作られた、ツリーオブジェクトです。ステージングで作られたツリーオブジェクトは、現在のステージングの内容のすべての内容にアクセスできるSHA1値が記録されていて、Linuxのディレクトリのようにたどることが出来ます。ステージングの際に作成されたツリーオブジェクトの情報をコミットに入れることで、ステージングの内容を、コミットとして確定させることができるのです。

Gitのコミットとは、**ある地点のツリーオブジェクトのSHA1値に対して親のコミットオブジェクトのSHA1値とコミッターの情報を与えたものです**。そしてコミットオブジェクトも当然オブジェクトであり、SHA1値でアクセスが可能です。Gitの表の世界でも、コミットのSHA1値はよく目にすると思います。あの値は、Gitの内容アドレスファイルシステムの世界では、コミットオブジェクトを参照するためのキーであり、ファイルやツリーのオブジェクトを参照することとほぼ同じなのです。


## 改めて、libgit2を使おう


Gitの裏側の世界を理解すれば、libgit2を使ってgitリポジトリの操作が可能です。それでは、libgit2のRubyバインディングである[Rugged](https://github.com/libgit2/rugged)を使って、実際にリポジトリを操作してみましょう。

Ruggedを使ってgitリポジトリするには、次のようにします。

```ruby
require 'rugged'

Rugged::Repository.init_at("PATH_TO_REPOSITORY") # git init されていない状態では初期化が必要
repo = Rugged::Repository.new("PATH_TO_REPOSITORY")
```

これで、リポジトリオブジェクトが作成できます。先程まで説明していたGitの内容アドレスファイルシステムの挙動を実際に見てみましょう。

```ruby
require 'rugged'

# カレントディレクトリをgitリポジトリとして扱う
repo = Rugged::Repository.new(".")

＃ Gitのblobオブジェクトを作成し、object_id(SHA1値）を取得する
oid = repo.write("Content of blob file", :blob)
＃ => "2d339c7cd8ba8f8a327e541ed03970c9d1fa9821"

# object_idで、Gitのファイルシステムに保存した内容を参照する
repo.exists?("2d339c7cd8ba8f8a327e541ed03970c9d1fa9821")
# => true
obj = repo.read("2d339c7cd8ba8f8a327e541ed03970c9d1fa9821")
# => #<Rugged::OdbObject:0x007fc892ae2c68>
obj.data
# => "Content of blob file"
```

writeメソッドでリポジトリにblobオブジェクトを書き込み、exists?メソッドでGitのオブジェクトの中に作成したオブジェクトが存在するか確認しています。そしてその後、readメソッドでオブジェクトを読み込み、そのオブジェクトのdataメソッドでblobの中身を読み取りました。

このように、Gitリポジトリをlibgit2で操作すると、まるでKVSのようにblobファイルを保存できるデータベースとして扱えます。同じように、コミットも見てみましょう。

```ruby
# 上のコードの続きです

# indexとはステージングのことであり、ステージングの参照ツリーに先程のblobを追加する
# 参照ツリーに追加する時に、ファイル名とファイルモードを指定
repo.index.add(path: "test.txt", oid: oid, mode: 0100644)
# => nil

# ステージングの参照ツリーをオブジェクトとして書き出し、object_idを計算する
tree = repo.index.write_tree(repo)
=> "7464bdfe6184a4c66f7ae00554d0762cf5822bbd"

# コミットを作成
Rugged::Commit.create(
  repo, 
  tree: tree, # 作成した参照ツリーのオブジェクトID
  author: { email: "admin@example.com", name: "kinpppyd", time: Time.now },
  committer: { email: "admin@example.com", name: "kinpppyd", time: Time.now },
  message: "initial",
  parents: [] # 一番最初のコミットなので、parentは誰もいない
)
=> "d98b01bb7e2a47f473db567ec077df5d16aacf89"
```

先ほど作成したblobをステージング（index）の参照ツリーに追加し、その状態をtreeオブジェクトとしてGitのに記録します。そして、その時に発行されたSHA1を利用して、コミットオブジェクトを作成しました。当然、コミットもオブジェクトで、SHA1のオブジェクトIDが発行されます。

この後も同じように、新しいblobオブジェクトを作成し、ステージングしてtreeオブジェクトを作成し、そのtreeと先に作成したコミットのオブジェクトIDを元に次のcommitオブジェクトを作成します。これが、Gitで行われているバージョン管理の最も根本的な部分です。


## libgit2を使って、Gitをバックエンドにしたキューを作成する


全体のコードは長いので、[GitQueue](https://rubygems.org/gems/git_queue)というGemを作りました。次のコードは、簡単な使い方のスニペットです。

```ruby
require 'git_queue'

# リポジトリの初期化、すでにあれば必要ない
Rugged::Repository.init_at("/tmp/tasks")

task = GitQueue::Queue.new("/tmp/tasks")

# 明日の予定を作る
task << "朝起きる"
task << "シャワーを浴びる"
task << "Advent Calendarを書く"
task << "コーヒーを淹れる"

# 予定の一覧を見る
puts "task list =================="
puts task.queue.join("\n")
puts "task list =================="

# 起きた
task.pop
# シャワーを浴びた
task.pop

# Advent Calendarがなかなか書き上がらないので、先にコーヒーを淹れる
task.up(1)

# コーヒーがはいった
task.pop

# Advent Calendarが書き終わった
task.pop

# 操作履歴を参照する
puts "task history =================="
puts task.history.join("\n")
puts "task history =================="
```

出力は次の通り

```
task list ==================
朝起きる
シャワーを浴びる
Advent Calendarを書く
コーヒーを淹れる
task list ==================
task history ==================
Pop item Advent Calendarを書く
Pop item コーヒーを淹れる
Switch コーヒーを淹れる with Advent Calendarを書く
Pop item シャワーを浴びる
Pop item 朝起きる
Add item コーヒーを淹れる
Add item Advent Calendarを書く
Add item シャワーを浴びる
Add item 朝起きる
task history ==================
```

Arrayのようなインターフェイスを持っていますが、Arrayとは違いFIFOの処理を邪魔するようなメソッドは生えていません。例外的にタスクの順序入れ替えは出来ますが、末尾挿入と先頭取り出し以外の方法でタスクを出し入れすることは出来ません。

また、今回の実装では入っていませんが、Ruggedではlibgit2のバックエンドに、OSのファイルシステム以外にもRedisなどのKVSを選択することも可能です。普通にGitのバックエンドをKVSにすると書くとよく意味がわかりませんが、Gitという内容アドレスファイルシステムのバックエンドを本物のKVSにすると考えると、すんなりわかりやすいと思います。libgit2のバックエンドを本物のKVSにすることによって、より堅牢で様々な場所からアクセスできるGitQueueの運用などの夢も膨らみそうです。


## Slack bot を作る


このエントリの目的はGitをバックエンドとした履歴記憶機能付きキューでタスク管理botを作ることなので、スニペット程度ですが簡単にbotを実装してみます。

```ruby
require "slack-ruby-client"
require "git_queue"

Slack.configure do |config|
  config.token = "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
end
Slack::RealTime::Client.config do |config|
  config.websocket_ping = 42
end

ADMINISTRATORS = [
  "UXXXXXXXXXXXXXXXXX",
]

IGNORE_CHANNELS = [
  "general",
  "random",
]

@client = Slack::Web::Client.new
@rtm = Slack::RealTime::Client.new

def users(refresh = false)
  refresh ? @users = @client.users_list.members : @users ||= @client.users_list.members
end


@rtm.on :message do |data|
  if ADMINISTRATORS.include?(data.user)
    case data.text
    when /^ユーザーを追加[ |　]+(.+)$/
      target = users.find { |u| u.name == $1 }
      if target
        GitQueue::Storage.create("/tmp/#{target.id}")
        @client.chat_postMessage(channel: data.channel, text: "#{$1} を追加したような気がするよ")
      else
        @client.chat_postMessage(channel: data.channel, text: "ちょっと誰かわからなかった")
      end
    end

    case data.text
    when /^(.+)にタスクを追加[ |　]+(.+)$/
      begin
        target = users.find { |u| u.name == $1 }
        queue = GitQueue::Queue.new("/tmp/#{target.id}")
        tasks = queue.push($2)
        @client.chat_postMessage(channel: data.channel, text: "タスク #{tasks.last} を追加したよ")
      rescue
        @client.chat_postMessage(channel: data.channel, text: "ちょっと誰かわからなかった")
      end

    when /^taskueue タスク(が)?終わったよ$/
      begin
        user = users.find { |u| u.id == data.user }
        queue = GitQueue::Queue.new("/tmp/#{user.id}")
        done = queue.pop
        tasks = queue.queue
        @client.chat_postMessage(channel: data.channel, text: "タスク #{done} が完了したよ、次のタスクは#{tasks.first}だよ")
      rescue
        @client.chat_postMessage(channel: data.channel, text: "あなた誰？")
      end
    when /^taskueue タスクの一覧/
      begin
        user = users.find { |u| u.id == data.user }
        queue = GitQueue::Queue.new("/tmp/#{user.id}")
        tasks = queue.queue
        @client.chat_postMessage(channel: data.channel, text: "タスクの一覧だよ\n#{tasks.map { |task| "- #{task}" }.join("\n")}")
      rescue
        @client.chat_postMessage(channel: data.channel, text: "あなた誰？")
      end
    end
  end
end

loop do
  begin
    @rtm.start!
  end
end
```

色々と処理が雑ですが、スニペットなので許してください。

このbotの機能としては



 	
  * Adminユーザーが、タスク管理を行うユーザーを追加できる

 	
  * 各ユーザーごとに、GitQueueを使ってタスクのキューを作成する

 	
  * ユーザーは、タスクの追加とタスクの完了ができる

 	
  * ユーザーは、タスクの一覧を見ることができる


です。

肝心の操作履歴をどこに使ってんだって気はしますが、概ね操作履歴なんていうのは何かしら問題が合った時の調査に使うものなので、別にbotからは見えなくていいと思います。実際にリポジトリにアクセスすれば、使い慣れたGitコマンドでキューの変更履歴を参照することができます。


## まとめ





 	
  * Gitの実態は内容アドレスファイルシステム、つまりほぼKVS

 	
  * GitをFIFOのバックエンドに使うと、操作履歴が全て残って素敵

 	
  * libgit2を使うことによって、少ない依存で強力なGit操作が可能

 	
  * botを作るのは楽しい
