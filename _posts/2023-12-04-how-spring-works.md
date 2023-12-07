---
layout: post
title: Springは何をしているのか？
date: 2023-12-04 15:38 +0900
image: "/assets/images/2023/12/3/spring.jpeg"
---
このエントリは、[SmartHR Advent Calendar 2023](https://qiita.com/advent-calendar/2023/smarthr) のシーズン2の3日目です。なんすかシーズン2って。

Spring、使っていますか？　Rails4.1から追加された新しいRailsの起動を早くするやつです。べつに新しくないですね。なんならRails7からは `rails new` のときにデフォルトで追加されなくなっちゃいました。DHH曰く「最近はコンピュータの性能上がったから別に起動とか大したことないっしょ」らしいですが、本当にそうか？　と思います。Springは大量のGemをロードしたりinitializerとかに大量のコードが書かれている大きなアプリケーションを起動する上で未だに一定の効果を発揮してくれる一方で、なんだかよくわからない謎の機能くらいのイメージしか持っていない方も多いと思います。僕もそうでした。なんとなく別プロセスでRails立ち上げて……みたいな仕組みを耳にしたことはありましたが、えぇなんか怖いとかRailsのリロードとかがうまく動かないのってこいつのせいでは……みたいな印象を持っていて、なんかバグったなと感じたらとりあえず `bin/spring stop` とかあまり意味のないことをしていました。

<!--more-->

今回は、このよくわからんSpringを知るためにコードを読んで知ったSpringの姿をお伝えします。なお、この内容は Qiita Rails Night で登壇したLTの内容の詳細版です。

{% cardlink https://increments.connpass.com/event/297116/ %}

## リポジトリ

{% cardlink https://github.com/rails/spring %}

デフォルトでは採用されなくなりましたが、Public Archiveとかでもなく今でも時々コードが取り込まれているので、まだ元気な方なんじゃないでしょうか。

このポスト内で紹介しているコードは、全て2023-12-04時点で最新の `378e0ce` のコミットのものを参照しています。

## Springの仕組み

まず最初に簡潔にSpringの仕組みを説明すると、Springは `Spring::Server` というサーバーが動いているプロセスを立ち上げ、その中で `Spring::ApplicationManager` というクラスが事前にRailsをロードし、サーバーに接続してきたクライアントに対してそのフォークを接続することでRailsの起動時間を短縮するという手法をとっています。また、このSpringが動いているサーバーに接続するのは `console`, `runner`, `generate`, `destroy`, `test` のコマンドのみで、`server` は対象ではありません。なので、アプリケーションがなんか様子おかしいからSpring再起動したろは実はあまり効果が望めないのです。どちらかというと、consoleでデバッグしてるときになにか変だと感じたら再起動したほうが良いかも知れません。

`Spring::ApplicationManager` は、`Spring::Server` の内部で実行環境ごとに異なるプロセスを保持していて、開発環境かテスト環境かを区別しています。`Spring::ApplicationManager` の内部では、 `Spring::Application` オブジェクトがロードしたRailsアプリケーションをデフォルトでポーリングしながら監視しており、Gemfileやアプリケーションコードの変更があるとリロード用のコールバックが実行されます。

以上がSpringの大まかな仕組みですが、それがどの様に普段のRails開発で介入してくるのかを追ってみましょう。

## Springのインストール

Rails7以降はSpringのインストールは任意なので、自分でコマンドを実行する必要があります。READMEに従うと、Gemfileにspringを追加して、以下のコマンドを実行します。

```shell
bundle install
bundle exec spring binstub --all
```

このコマンドを実行すると、Springは bin 配下に spring の binstub を作成すると同時に、既存の rails と rake の binstub にもSpringのbinstubを読み込むようにフックが挿入されます。

```diff
diff --git a/bin/rails b/bin/rails
index efc0377..c8b5338 100755
--- a/bin/rails
+++ b/bin/rails
@@ -1,4 +1,5 @@
 #!/usr/bin/env ruby
+load File.expand_path("spring", __dir__)
 APP_PATH = File.expand_path("../config/application", __dir__)
 require_relative "../config/boot"
 require "rails/commands"
diff --git a/bin/rake b/bin/rake
index 4fbf10b..7327f47 100755
--- a/bin/rake
+++ b/bin/rake
@@ -1,4 +1,5 @@
 #!/usr/bin/env ruby
+load File.expand_path("spring", __dir__)
 require_relative "../config/boot"
 require "rake"
 Rake.application.run
 ```

このフックによって、rails と rake のコマンドはどちらも必ずspringのコードを事前に実行するようになります。なお、 bundler 経由で `bundle exec rails` のように呼び出しても、Railsのアプリケーションローダーが自動で binstub を探して実行してくれるので、問題ありません。

[rails/railties/lib/rails/app_loader.rb at 79c3cef444bf783e15f6b3928e69d53fcf933acf · rails/rails](https://github.com/rails/rails/blob/79c3cef444bf783e15f6b3928e69d53fcf933acf/railties/lib/rails/app_loader.rb#L45-L76)
```ruby
def exec_app
  original_cwd = Dir.pwd

  loop do
    if exe = find_executable

## 中略

def find_executable
  EXECUTABLES.find { |exe| File.file?(exe) }
end
```

フックと同時に作成される `bin/spring` の内容は、 `Spring::Client::Binstub` 内に書かれています。

[spring/lib/spring/client/binstub.rb at 378e0ce8741bd9e599a435a523bbcf0633392c91 · rails/spring](https://github.com/rails/spring/blob/378e0ce8741bd9e599a435a523bbcf0633392c91/lib/spring/client/binstub.rb#L20-L35)
```ruby
SPRING = <<~CODE
  #!/usr/bin/env ruby

  # This file loads Spring without loading other gems in the Gemfile in order to be fast.
  # It gets overwritten when you run the `spring binstub` command.

  if !defined?(Spring) && [nil, "development", "test"].include?(ENV["RAILS_ENV"])
    require "bundler"

    Bundler.locked_gems.specs.find { |spec| spec.name == "spring" }&.tap do |spring|
      Gem.use_paths Gem.dir, Bundler.bundle_path.to_s, *Gem.path
      gem "spring", spring.version
      require "spring/binstub"
    end
  end
CODE
```

RAILS_ENV が development か test か nil のときに、`spring/binstub` を読み込むような動作をしています。

## Springサーバーの起動

[spring/lib/spring/binstub.rb at 378e0ce8741bd9e599a435a523bbcf0633392c91 · rails/spring](https://github.com/rails/spring/blob/378e0ce8741bd9e599a435a523bbcf0633392c91/lib/spring/binstub.rb)
```ruby
command  = File.basename($0)
bin_path = File.expand_path("../../../bin/spring", __FILE__)

if command == "spring"
  load bin_path
else
  disable = ENV["DISABLE_SPRING"]

  if Process.respond_to?(:fork) && (disable.nil? || disable.empty? || disable == "0")
    ARGV.unshift(command)
    load bin_path
  end
end
```

rails や rake コマンドから起動するときはelseに入るので、 `Process` が `fork` メソッドを持っていることを確認した上で ARGV にコマンド名を追加して `bin/spring` を起動します。余談ですが、 `DISABLE_SPRING` という環境変数に0以外の何かを入れると Spring の介入を避けることがきるんですね。

`bin/spring` の中では、 `Spring::Client.run(ARGV)` を呼び出しています。

[spring/bin/spring at 378e0ce8741bd9e599a435a523bbcf0633392c91 · rails/spring](https://github.com/rails/spring/blob/378e0ce8741bd9e599a435a523bbcf0633392c91/bin/spring#L46-L49)
```ruby
lib = File.expand_path("../../lib", __FILE__)
$LOAD_PATH.unshift lib unless $LOAD_PATH.include?(lib) # enable local development
require 'spring/client'
Spring::Client.run(ARGV)
```

`Spring::Client.run` では、先程のARGVに追加したコマンドによって、 `Spring::Client::Command` のサブクラスが選択されます。ここでは rails で起動しているので、 `Spring::Client::Rails` が選択されます。ちなみに、なぜかここに rake が一覧にないため、 rake コマンドって Spring の対象じゃないの？　と思うのですが、どうなってるんでしょうね。よくわからないです。少なくともCommandsにはいるので、対象だとは思うのですが……なぜでしょう。とにかく、 `Spring::Client::Rails` 内では、 Spring の対象になるコマンドの一覧が定義されています。最初に概要でお話した対象のコマンド一覧はここで決まっています。

[spring/lib/spring/client/rails.rb at 378e0ce8741bd9e599a435a523bbcf0633392c91 · rails/spring](https://github.com/rails/spring/blob/378e0ce8741bd9e599a435a523bbcf0633392c91/lib/spring/client/rails.rb#L1-L12)
```ruby
module Spring
  module Client
    class Rails < Command
      COMMANDS = %w(console runner generate destroy test)

      ALIASES = {
        "c" => "console",
        "r" => "runner",
        "g" => "generate",
        "d" => "destroy",
        "t" => "test"
      }
```

ここで適切なコマンドを選んでいると、今度は `Spring::Client::Run` に渡され、ここで `Spring::Server` のプロセスの有無をチェックした上で接続に行きます。かなり長いクラスなので要点をかいつまんで説明していきます。

まず `Spring::Client::run` に処理が渡ると、 `UNIXSocket` を開きに行き、成功すれば接続を、失敗したらサーバーの立ち上げを行います。

[spring/lib/spring/client/run.rb at 378e0ce8741bd9e599a435a523bbcf0633392c91 · rails/spring](https://github.com/rails/spring/blob/378e0ce8741bd9e599a435a523bbcf0633392c91/lib/spring/client/run.rb#L29-L53)
```ruby
def call
  begin
    connect
  rescue Errno::ENOENT, Errno::ECONNRESET, Errno::ECONNREFUSED
    cold_run
  else
    warm_run
  end
ensure
  server.close if server
end
```
この `begin ... rescue ... else` の制御構文を使っているコードを初めてみてまあまあびっくりした記憶があります。

<blockquote class="twitter-tweet"><p lang="ja" dir="ltr">begin<br>rescue<br>else<br>end<br><br>ってはじめて見た気がするな</p>&mdash; kinoppyd (@GhostBrain) <a href="https://twitter.com/GhostBrain/status/1724078921594163225?ref_src=twsrc%5Etfw">November 13, 2023</a></blockquote> <script async src="https://platform.twitter.com/widgets.js" charset="utf-8"></script>


cold_run の場合は、サーバーの立ち上げを行います。

[spring/lib/spring/client/run.rb at 378e0ce8741bd9e599a435a523bbcf0633392c91 · rails/spring](https://github.com/rails/spring/blob/378e0ce8741bd9e599a435a523bbcf0633392c91/lib/spring/client/run.rb#L73-L94)
```ruby
def boot_server
  env.socket_path.unlink if env.socket_path.exist?

  pid     = Process.spawn(gem_env, env.server_command, out: File::NULL)
  timeout = Time.now + BOOT_TIMEOUT

  @server_booted = true

  until env.socket_path.exist?
    _, status = Process.waitpid2(pid, Process::WNOHANG)

    if status
      exit status.exitstatus
    elsif Time.now > timeout
      $stderr.puts "Starting Spring server with `#{env.server_command}` " \
                   "timed out after #{BOOT_TIMEOUT} seconds"
      exit 1
    end

    sleep 0.1
  end
end
```

ここで分かる通り、 `Process.spawn` を使って別のプロセスを起動しています。これがSpringサーバーの本体です。 `server_command` には、デフォルトで `"#{File.expand_path("../../../bin/spring", __FILE__)} server --background"` の値が使われます。これ以降、SpringサーバーとRailsのプロセスはUNIX Socketを使って通信しますが、socketファイルは `SPRING_SOCKET` や `SPRING_TMP_PATH`, `SDG_+RUNTIME_DIR` などの環境変数で介入しない限りは、`Dir.tmpdir` と `"spring-#{Process.uid}"` のをあわせたパスになります。これらの値は、 `Spring::Env` で管理されています。 

{% cardlink https://docs.ruby-lang.org/ja/latest/method/Dir/s/tmpdir.html %}
{% cardlink https://docs.ruby-lang.org/ja/latest/class/Process.html %}

`Spring::Server` 側は、バックグラウンドモードで起動すると、loop メソッドを使ってクライアントからの接続を待ち続けます。

[spring/lib/spring/server.rb at 378e0ce8741bd9e599a435a523bbcf0633392c91 · rails/spring](https://github.com/rails/spring/blob/378e0ce8741bd9e599a435a523bbcf0633392c91/lib/spring/server.rb#L46-L51)
```ruby
def start_server
  server = UNIXServer.open(env.socket_name)
  log "started on #{env.socket_name}"
  loop { serve server.accept }
rescue Interrupt
end
```

サーバーが起動すると、`Spring::Client::Run` はUNIXSocketを使ってサーバーに接続を試みます。

[spring/lib/spring/client/run.rb at 378e0ce8741bd9e599a435a523bbcf0633392c91 · rails/spring](https://github.com/rails/spring/blob/378e0ce8741bd9e599a435a523bbcf0633392c91/lib/spring/client/run.rb#L61-L71)
```ruby
def run
  verify_server_version

  application, client = UNIXSocket.pair

  queue_signals
  connect_to_application(client)
  run_command(client, application)
rescue Errno::ECONNRESET
  exit 1
end
```

`Spring::Client::Run` から `Spring::Server` にソケット通信がつながると、接続を待ち受けていたサーバー側のコードに動作が移ります。 `Spring::Server` は、起動すると loop メソッドでSocketの接続を待ち続け、接続があると `serve` メソッドを呼び出します。

[spring/lib/spring/server.rb at 378e0ce8741bd9e599a435a523bbcf0633392c91 · rails/spring](https://github.com/rails/spring/blob/378e0ce8741bd9e599a435a523bbcf0633392c91/lib/spring/server.rb#L53-L74)
```ruby
def serve(client)
  log "accepted client"
  client.puts env.version

  app_client = client.recv_io
  command    = JSON.load(client.read(client.gets.to_i))

  args, default_rails_env = command.values_at('args', 'default_rails_env')

  if Spring.command?(args.first)
    log "running command #{args.first}"
    client.puts
    client.puts @applications[rails_env_for(args, default_rails_env)].run(app_client)
  else
    log "command not found #{args.first}"
    client.close
  end
rescue SocketError => e
  raise e unless client.eof?
ensure
  redirect_output
end
```

## Spring::Application の起動とRailsの実行

通信用のソケットのやり取りを行ったあと、起動したいコマンドのチェックなどを行い、 `@applications[rails_env_for(args, default_rails_env)].run(app_client)` を実行します。`@applications` は `Spring::ApplicationManager` が `rails_envs_for` ごとにセットされているハッシュで、developmentとかtestごとにマネージャーが存在します。マネージャーは、mutexをつかった排他制御の管理を主に行っています。そして、内部でさらにもう一つプロセスをspawnして管理しています。

[spring/lib/spring/application_manager.rb at 378e0ce8741bd9e599a435a523bbcf0633392c91 · rails/spring](https://github.com/rails/spring/blob/378e0ce8741bd9e599a435a523bbcf0633392c91/lib/spring/application_manager.rb#L93-L116)
```ruby
def start_child(preload = false)
  @child, child_socket = UNIXSocket.pair

  Bundler.with_original_env do
    bundler_dir = File.expand_path("../..", $LOADED_FEATURES.grep(/bundler\/setup\.rb$/).first)
    @pid = Process.spawn(
      {
        "RAILS_ENV"           => app_env,
        "RACK_ENV"            => app_env,
        "SPRING_ORIGINAL_ENV" => JSON.dump(Spring::ORIGINAL_ENV),
        "SPRING_PRELOAD"      => preload ? "1" : "0"
      },
      "ruby",
      *(bundler_dir != RbConfig::CONFIG["rubylibdir"] ? ["-I", bundler_dir] : []),
      "-I", File.expand_path("../..", __FILE__),
      "-e", "require 'spring/application/boot'",
      3 => child_socket,
      4 => spring_env.log_file,
    )
  end

  start_wait_thread(pid, child) if child.gets
  child_socket.close
end
```

`spring/application/boot` を実行していますが、これは内部で `Spring::Applicaiton` を起動しています。この様に、Springは実行されるために最低でも2つのプロセスを必要とするので、springを使ったアプリケーションがいる環境で ps などを見てみると、いかにもゾンビになりそうなプロセスがこんな感じで存在します。

```shell
% ps aux | grep spring
kinoppyd 57044   3.3  1.1 410289872 367808   ??  Ss    9:59AM  20:15.90 spring app    | my_app | started 4 hours ago | development mode
kinoppyd 19810   0.0  0.0 409132736   4048 s001  S    金02PM   0:00.33 spring server | my_app | started 71 hours ago
kinoppyd 99569   0.0  0.0 408628368   1664 s001  S+    2:22PM   0:00.00 grep --color spring
```

57044のプロセスが `Spring::Application` で、19810のプロセスが `Spring::Server` ですね。

`spring/application/boot` は、こんな感じで `Spring::Application` を起動しています。

[spring/lib/spring/application/boot.rb at 378e0ce8741bd9e599a435a523bbcf0633392c91 · rails/spring](https://github.com/rails/spring/blob/378e0ce8741bd9e599a435a523bbcf0633392c91/lib/spring/application/boot.rb)
```ruby
# This is necessary for the terminal to work correctly when we reopen stdin.
Process.setsid

require "spring/application"

app = Spring::Application.new(
  UNIXSocket.for_fd(3),
  Spring::JSON.load(ENV.delete("SPRING_ORIGINAL_ENV").dup),
  Spring::Env.new(log_file: IO.for_fd(4))
)

Signal.trap("TERM") { app.terminate }

Spring::ProcessTitleUpdater.run { |distance|
  "spring app    | #{app.app_name} | started #{distance} ago | #{app.app_env} mode"
}

app.eager_preload if ENV.delete("SPRING_PRELOAD") == "1"
app.run
```

`Spring::Application` もまた長いクラスなのですが、最終的にはこの中にrailsコマンドなどが接続するためのプロセスの正体があります。あまりにも長いので該当箇所だけを見てみると、こんな感じです。

[spring/lib/spring/application.rb at 378e0ce8741bd9e599a435a523bbcf0633392c91 · rails/spring](https://github.com/rails/spring/blob/378e0ce8741bd9e599a435a523bbcf0633392c91/lib/spring/application.rb#L153-L246)
```ruby
def serve(client)
  log "got client"
  manager.puts

  @clients[client] = true

  _stdout, stderr, _stdin = streams = 3.times.map { client.recv_io }
  [STDOUT, STDERR, STDIN].zip(streams).each { |a, b| a.reopen(b) }

  if preloaded?
    client.puts(0) # preload success
  else
    begin
      preload
      client.puts(0) # preload success
    rescue Exception
      log "preload failed"
      client.puts(1) # preload failure
      raise
    end
  end

  args, env = JSON.load(client.read(client.gets.to_i)).values_at("args", "env")
  command   = Spring.command(args.shift)

  connect_database
  setup command

  if Rails.application.reloaders.any?(&:updated?)
    Rails.application.reloader.reload!
  end

  pid = fork {
    # Make sure to close other clients otherwise their graceful termination
    # will be impossible due to reference from this fork.
    @clients.each_key { |c| c.close if c != client }

    Process.setsid
    IGNORE_SIGNALS.each { |sig| trap(sig, "DEFAULT") }
    trap("TERM", "DEFAULT")

    unless Spring.quiet
      STDERR.puts "Running via Spring preloader in process #{Process.pid}"

      if Rails.env.production?
        STDERR.puts "WARNING: Spring is running in production. To fix "         \
                    "this make sure the spring gem is only present "            \
                    "in `development` and `test` groups in your Gemfile "       \
                    "and make sure you always use "                             \
                    "`bundle install --without development test` in production"
      end
    end

    ARGV.replace(args)
    $0 = command.exec_name

    # Delete all env vars which are unchanged from before Spring started
    original_env.each { |k, v| ENV.delete k if ENV[k] == v }

    # Load in the current env vars, except those which *were* changed when Spring started
    env.each { |k, v| ENV[k] ||= v }

    connect_database
    srand

    invoke_after_fork_callbacks
    shush_backtraces

    command.call
  }

  disconnect_database

  log "forked #{pid}"
  manager.puts pid

  wait pid, streams, client
rescue Exception => e
  log "exception: #{e}"
  manager.puts unless pid

  if streams && !e.is_a?(SystemExit)
    print_exception(stderr, e)
    streams.each(&:close)
  end

  client.puts(1) if pid
  client.close
ensure
  # Redirect STDOUT and STDERR to prevent from keeping the original FDs
  # (i.e. to prevent `spring rake -T | grep db` from hanging forever),
  # even when exception is raised before forking (i.e. preloading).
  reset_streams
end
```

ちょっとめちゃめちゃ長いのですが、ここにSpringの大事な動作が全部詰まっているので引用しました。serve メソッドが接続を受け付けると、まずRailsアプリのロードを試みます。すでにロードされている場合は必要なリロードだけですが、初回はすべてをロードします。この初回だけロードする仕組みが、Springが2回以降早くRailsを起動できる理由です。Railsをロードすると、今度は自身をforkします。forkは、メモリをすべてコピーするので、一度ロードしたRailsアプリを何度も使い回すことができます。

forkしたプロセスの中では、`Spring.command` によって特定されたクラス、今回の rails コマンドの場合であれば `Spring::Commands::Rails` クラスの call メソッドを呼び出し、これで初めてRailsのアプリケーションが実行されます。長かったですが、ここまでが rails コマンドを実行したあと、 spring がどの様に振る舞うかという詳細な解説でした。最終的に `Spring::Commands::Rails.call` は、 `bin/rails` の binstub を呼び出します。これは内部的に再び bin/spring を呼び出しますが、今度は `Spring` がすでにロードされているので、一連の処理はすべて無視され、通常通りRailsが起動します！ ここでは、すでに読み込んでおいたRailsのコードをforkして使うため、SpringはRailsの起動を早くすることができるんですね。

また、ここで作成されたPIDが、このあと `Spring::Applicaiton` -> `Spring::ApplicationManager` -> `Spring::Server` -> `Spring::Client::Run` に戻っていき、Ctrl-Cなどのシグナルハンドラをセットするので、まったくの別プロセスにも関わらずCtrl-Cでコンソールなどを終了することができるのです。

## まとめ

以上が、Springのコードを読んだ結果わかった、SpringがどうやってRailsアプリを早く起動させているかの全てです。

`Spring::Server` プロセスと、`Spring::ApplicationManager` を介して複数立ち上がっている `Spring::Application` のそれぞれ独立したプロセスが、`Spring::Client::Run` によってコンソールと接続され、予め温められていたRailsアプリケーションを参照することがわかりました。

最初にも書いた通り、Springは現在のところデフォルトでバンドルされなくなり、オプション扱いです。DHHも「マシン十分速いからいらんくね？」みたいなことを言っていますが、それでも数十万行のコードベースを持つ巨大なモノリスアプリを開発しているチームには、これからも良い選択肢であり続けるでしょう。Springの仕組みを解説して広くSpringへの理解が広がることで、Springがなんかよくわからん怖いやつから、なんとなく知ってる便利なやつになってくれると嬉しいです。
