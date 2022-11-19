---
author: kinoppyd
comments: true
date: 2017-01-01 10:20:49+00:00
layout: post
link: http://tolarian-academy.net/install-elixir-to-ubuntu/
permalink: /install-elixir-to-ubuntu
title: Elixirのインストール
wordpress_id: 454
categories:
- Elixir
---

## Elixir


Erlang上に実装された、Ruby likeのシンタックスを持つ言語。強力な並行性を持つ関数型言語。

[http://elixir-lang.org/](http://elixir-lang.org/)


## Install to Ubuntu


Unix likeのシステムは、だいたいのディストリに関して[インストールガイド](http://elixir-lang.org/install.html)が用意されている。意外と、Ubuntuが一番インストールの手順が多くて、なんか微妙な感じがする。

    
    $ wget https://packages.erlang-solutions.com/erlang-solutions_1.0_all.deb && dpkg -i erlang-solutions_1.0_all.deb
    $ apt-get update
    $ apt-get install esl-erlang
    $ apt-get install elixir


すべてrootで実行したので、 sudoは省いた。

ユーザー領域にインストール出来ないのかな、とは思ったが、面倒なのでとりあえず入れて試したかったので突っ込んだ。

同じページに、rbenvのようなElixirのバージョン管理システムも載っていたが、何故か4つも選択肢があって比較するのに時間がかかりそうなので、一旦無視した。

[http://elixir-lang.org/install.html#compiling-with-version-managers](http://elixir-lang.org/install.html#compiling-with-version-managers)

っていうか、全部の解説が 「install and manage different Elixir and Erlang versions」 で、違いがさっぱりわからん。Erlangの扱いあたりに差があるのだろうか？


## REPL


ElixierのREPLは、iexというコマンド

    
    $ iex
    Erlang/OTP 19 [erts-8.2] [source-fbd2db2] [64-bit] [async-threads:10] [hipe] [kernel-poll:false]
    
    Interactive Elixir (1.3.4) - press Ctrl+C to exit (type h() ENTER for help)
    iex(1)>


最新のバージョンは、1.3。REPLの抜け方は、Ctrl-Cの二回押しが一番早いっぽい。

REPLで便利なコマンドは、hとiらしいので、試してみる。

hはヘルプコマンドで、iexの使い方や、引数に取ったモジュールや関数などの使い方を教えてくれる。iは値の内容を確認するコマンドで、渡された値の型や説明をしてくれる。

    
    $ iex
    Erlang/OTP 19 [erts-8.2] [source-fbd2db2] [64-bit] [async-threads:10] [hipe] [kernel-poll:false]
    
    Interactive Elixir (1.3.4) - press Ctrl+C to exit (type h() ENTER for help)
    iex(1)> h
    
                                      IEx.Helpers
    
    Welcome to Interactive Elixir. You are currently seeing the documentation for
    the module IEx.Helpers which provides many helpers to make Elixir's shell more
    joyful to work with.
    
    This message was triggered by invoking the helper h(), usually referred to as
    h/0 (since it expects 0 arguments).
    
    You can use the h function to invoke the documentation for any Elixir module or
    function:
    
    ┃ h Enum
    ┃ h Enum.map
    ┃ h Enum.reverse/1
    
    You can also use the i function to introspect any value you have in the shell:
    
    ┃ i "hello"
    
    There are many other helpers available:
    
      • b/1           - prints callbacks info and docs for a given module
      • c/1           - compiles a file into the current directory
      • c/2           - compiles a file to the given path
      • cd/1          - changes the current directory
      • clear/0       - clears the screen
      • flush/0       - flushes all messages sent to the shell
      • h/0           - prints this help message
      • h/1           - prints help for the given module, function or macro
      • i/1           - prints information about the given data type
      • import_file/1 - evaluates the given file in the shell's context
      • l/1           - loads the given module's beam code
      • ls/0          - lists the contents of the current directory
      • ls/1          - lists the contents of the specified directory
      • nl/2          - deploys local beam code to a list of nodes
      • pid/1         - creates a PID from a string
      • pid/3         - creates a PID with the 3 integer arguments passed
      • pwd/0         - prints the current working directory
      • r/1           - recompiles the given module's source file
      • recompile/0   - recompiles the current project
      • respawn/0     - respawns the current shell
      • s/1           - prints spec information
      • t/1           - prints type information
      • v/0           - retrieves the last value from the history
      • v/1           - retrieves the nth value from the history
    
    Help for all of those functions can be consulted directly from the command line
    using the h helper itself. Try:
    
    ┃ h(v/0)
    
    To learn more about IEx as a whole, just type h(IEx).
    
    iex(2)> h Map
    
                                          Map
    
    A set of functions for working with maps.
    
    Maps are key-value stores where keys can be any value and are compared using
    the match operator (===). Maps can be created with the %{} special form defined
    in the Kernel.SpecialForms module.
    
    iex(3)> i 123
    Term
      123
    Data type
      Integer
    Reference modules
      Integer
    iex(4)> i "hoge"
    Term
      "hoge"
    Data type
      BitString
    Byte size
      4
    Description
      This is a string: a UTF-8 encoded binary. It's printed surrounded by
      "double quotes" because all UTF-8 encoded codepoints in it are printable.
    Raw representation
      <<104, 111, 103, 101>>
    Reference modules
      String, :binary
    iex(5)> i "ほげ"
    Term
      "ほげ"
    Data type
      BitString
    Byte size
      6
    Description
      This is a string: a UTF-8 encoded binary. It's printed surrounded by
      "double quotes" because all UTF-8 encoded codepoints in it are printable.
    Raw representation
      <<227, 129, 187, 227, 129, 146>>
    Reference modules
      String, :binary
    iex(6)>


ブログ上では分からないが、実際は出力にいい感じに色がついてて見やすい。

iコマンドは、"hoge"と"ほげ"のそれぞれのバイト数や、実際のバイナリ値などを教えてくれて、便利な予感がある。


## Version 1.3


教本にしている「[プログラミングElixir](http://amzn.to/2iSf6FO)」は1.2を基準にしているらしいので、何が変わったのかはリリースノートを読む。

[http://elixir-lang.org/blog/2016/06/21/elixir-v1-3-0-released/](http://elixir-lang.org/blog/2016/06/21/elixir-v1-3-0-released/)


<blockquote>Elixir v1.3 brings many improvements to the language, the compiler and its tooling, specially Mix (Elixir’s build tool) and ExUnit (Elixir’s test framework). The most notable additions are the new Calendar types, the new cross-reference checker in Mix, and the assertion diffing in ExUnit. We will explore all of them and a couple more enhancements below.</blockquote>


一応、トピックとなるのはCalendarモジュールの追加と、Mixの相互参照チェッカ、ユニットテストのdiffingアサーションの追加っぽい。全文をさらっと読んでみたが、とりあえずコア機能にそこまで破壊的な変更はなく、あとはMixとかのまだ未学習の自分にはよくわからない機能なので、とりあえず気にせず1.3で勉強を始めることにする。


## VimでElixir


各種エディタのサポートが、公式で用意されている。全ては[ドキュメントの右ペイン](http://elixir-lang.org/docs.html)に載っているが、用意されているのは今のところ下記の通り。



 	
  * emacs

 	
  * vim

 	
  * sublime text

 	
  * atom

 	
  * intellij

 	
  * gedit

 	
  * Visual Studio


あとは、バンドル版とかArchemist対応もあるらしい。

vimの場合はこれ。

[https://github.com/elixir-lang/vim-elixir](https://github.com/elixir-lang/vim-elixir)

プラグイン管理にはDeinを使っているので、Deinのプラグイン管理部分に次の行を加えてインストールするだけ。

    
    call dein#add('elixir-lang/vim-elixir')




## Hello, World!


Elixirファイルには、2つの拡張子がある。.exと、.exsで、それぞれ.exはコンパイルして実行、.exsはスクリプト言語的に実行するものに付けられることが慣習になっているらしい。Hello worldは別にコンパイルする必要がないので、.exsで記述する。

    
    $ vim hello.exs
    IO.puts "Hello, World!"
    
    $ elixir hello.exs
    Hello, World!


動いた。やったぜ。iexのなかでも、cコマンドを使ってコンパイル実行できるらしい。

    
    $ elixir hello.exs
    Hello, World!
    elixir@ubuntu:~/tmp/elixir$ iex
    Erlang/OTP 19 [erts-8.2] [source-fbd2db2] [64-bit] [async-threads:10] [hipe] [kernel-poll:false]
    
    Interactive Elixir (1.3.4) - press Ctrl+C to exit (type h() ENTER for help)
    iex(1)> c "hello.exs"
    Hello, World!
    []


動いた。最後の[]は、多分cコマンドの戻り値で、ソースの中にモジュールが含まれていると、ここにモジュール名のリストが入るらしい。


## やっていく気持ち


ここまでで、プログラミングElixirの1章がおわった。今年は、Elixirを頑張っていく気持ちです。
