---
author: kinoppyd
comments: true
date: 2018-12-04 16:29:42+00:00
layout: post
link: http://tolarian-academy.net/mobb-helpers-register/
permalink: /mobb-helpers-register
title: Mobbの機能拡張を実現するhelpersとregister
wordpress_id: 567
categories:
- 未分類
---

この記事は Mobb/Repp Advent Calendar の五日目です


## Mobbの機能拡張


これまで見てきたように、MobbにはSinatraとほぼ同じ仕組みが多数存在します。そして今日紹介するhelpers/registerメソッドも、Sinatra由来の機能です。これら2つのメソッドは、Sinatraと全く同じコードが書かれているので、挙動も全く同じです。


### helpers


helpersメソッドは、トップレベルモード(require 'mobb'をしてそのままロジックを書き始めるケース）では暗黙的に作成されるMobbのアプリケーションクラスを、モジュラーモード(require 'mobb/base' して自分でクラスを定義するケース）ではhelpersが呼び出されたクラスをそれぞれコンテキストとして、渡されたブロックをclass_evalで実行します。ブロックではなくモジュールを渡した場合は、そのモジュールがincludeされます。

    
    require 'mobb'
    
    def hoge
      'hoge'
    end
    
    on 'hello' do
      hoge
    end



    
    require 'mobb/base'
    
    class Bot < Mobb::Base
      helpers do
        def hoge
          'hoge'
        end
      end
    
      on 'hello' do
        hoge
      end
    end
    
    Bot.run!


モジュラーモードでは、そもそもhelpersの中で定義しようがクラスの中で定義しようが、クラスのインスタンスメソッドとして定義されるのであまり違いはありません。ですが、トップレベルモードの場合、Rubyのmainクラスで定義したメソッドはObjectのプライベートメソッドとして定義されるので、いろいろなものを汚染しかねません。そのため、暗黙的に作られるMobbアプリケーションのクラスに、helpersを使って直接定義を行います。

[https://docs.ruby-lang.org/ja/latest/class/main.html](https://docs.ruby-lang.org/ja/latest/class/main.html)

やっていることは結局の所include呼び出しとあまり変わりませんが、ブロックを渡せるところが軽量でいいと思います。

helpersメソッドの中身は、Mobb::Baseを継承したアプリケーションを拡張しています。


### register


helpersがclass_evalを行うのに対して、registerはclassにextendをおこないます。もしブロックが渡された場合は、そのブロックの内容で即時的にModuleオブジェクトを作成し、それをextendします。

includeとextendの違いはいくつかありますが、その一つにincludeはクラスを拡張するのに対し、extendはクラスオブジェクトを拡張する、つまりクラスメソッドを定義するという点が挙げられます。

たとえば、次のコードは実際にhelloを受け取ったときに失敗します。

    
    require 'mobb/base'
    
    class Bot < Mobb::Base
     extends do
        def hoge
          'hoge'
        end
      end
    
      on 'hello' do
        hoge # これは失敗する
      end
    end
    
    Bot.run!


なぜならば、helloのブロックが実行されるのは、Botインスタンスのコンテキストですが、registerメソッドが作成するのはBotのクラスメソッドだからです。インスタンスからは、クラスメソッドを参照することは通常できません。正しく動かす場合には、settingsを使ってアプリケーションクラスに対するアクセスが必要です。

    
    require 'mobb/base'
    
    class Bot < Mobb::Base
      register do
        def hoge
          'hoge'
        end
      end
    
      on 'hello' do
        settings.hoge # これは成功する
      end
    end
    
    Bot.run!


また、helpersと大きく違うのは、registerはextendを実行したあとのフックを持っています。

    
    require 'mobb/base'
    
    class Bot < Mobb::Base
      register do
        def self.registered(klass)
          puts "extended to #{klass}"
        end
    
        def hoge
          'hoge'
        end
      end
    
      on 'hello' do
        settings.hoge
      end
    end
    
    Bot.run!
    
    # 実行すると、次の出力が得られる
    # ruby app.rb
    # extended to Bot
    # == Mobb (v0.4.0) is in da house with Shell. Make some noise!


registerを使用すると、Botクラスの各メソッドにアクセスが可能です。つまり、Mobb::Baseクラスを直接機能拡張することが可能なのです。


## helpers or register ?


さて、helpersとextendsですが、面白いことにこの2つのメソッドはそれぞれ互いを互いの中で呼ぶことが出来ます。例えば、このような使い方です。

    
    require 'mobb/base'
    
    class Bot < Mobb::Base
      register do
        def self.registered(klass)
          klass.helpers do
            def hoge
              'hoge'
            end
          end
        end
    
      end
    
      on 'hello' do
        hoge
      end
    end
    
    Bot.run!


registerの中からhelpersを使うには、registeredの引数に渡されたアプリケーションクラスを経由して行います。

    
    require 'mobb/base'
    
    class Bot < Mobb::Base
      helpers do
        register do
          def hoge
            'hoge'
          end
        end
      end
    
      on 'hello' do
        settings.hoge
      end
    end
    
    Bot.run!


helpersの中からregisterを使うのは、わかりやすいですね。コンテキストが特に変わっていないからです。

このように、helpers と register は、使い方によっては別にどちらを使っても良いように思いますが、それぞれ記述の容易さなどから次のように使い分けられます。

helpersは、Mobbアプリケーションの実行時に使いたい機能、すなわち on メソッドや cron メソッドのブロックの中から使いたいヘルパーメソッドを定義するのに使用されます。ユーザーは、自身のビジネスロジックを記述するために、helpersを利用することになると思います。

それに対してregisterは、アプリケーションの起動時、すなわち構築のときに使われるMobbそのものを拡張するケースに用いられます。

Mobbアプリケーションを書くユーザーが最も利用するのは、helpersです。むしろ、registerを利用するケースは殆ど無いでしょう。ですが、Mobbアプリケーションの拡張を書く必要があり、それを再利用するケースでは、registerを使用します。例えば、MobbからActiveRecordを利用する[mobb-activerecord](https://github.com/kinoppyd/mobb-activerecord)というgemは、registerを使った拡張という形で書かれています。

わりと似たような機能ですが、やっていることは歴然と違いそれぞれ用途はっきりとわかれているので、みなさんも自分の必要に応じたほうを利用してください。
