---
author: kinoppyd
comments: true
date: 2017-01-02 06:59:04+00:00
layout: post
link: http://tolarian-academy.net/elixir-patternmatch-immutable-type-ops-with/
permalink: /elixir-patternmatch-immutable-type-ops-with
title: Elixirのパターンマッチ、不変性、型、演算子とwith式
wordpress_id: 456
categories:
- Elixir
---

教本は「[プログラミングElixir](http://amzn.to/2iSf6FO)」です


## Elixirのパターンマッチ


Elixirでは、変数代入ではなく変数名にパターンマッチを使って値を束縛します。同じ関数型言語のHaskellや、Scalaのvalと同じような感じ。

    
    iex(1)> a = 1
    1
    iex(2)> [x, y, z] = [7, 8, 9]
    '\a\b\t'
    iex(3)> x
    7
    iex(4)> y
    8
    iex(5)> z
    9
    iex(6)> z + y + z
    26


束縛した変数と異なるマッチを行うと、例外が飛ぶ

    
    iex(1)> a = 1
    1
    iex(2)> 2 = a
    ** (MatchError) no match of right hand side value: 1
    


変数aに1を束縛しているので、2とマッチさせようとして例外が飛んでいる。ただ、Haskellとは違って、変数に再度の束縛は可能

    
    iex(1)> a = 1
    1
    iex(2)> a = 2
    2
    iex(3)> 1 = a
    ** (MatchError) no match of right hand side value: 2
    


なんかユルくない？　とおもうけど、まあこういうもんだと思ってスルー。束縛を維持したままマッチに利用するには、pin演算子(^)を利用する。pin演算子を使うことで、変数に値を再度束縛すること無く、束縛されている値とのパターンマッチを行う。

    
    iex(1)> a = 1
    1
    iex(2)> a = 2
    2
    iex(3)> ^a = 1
    ** (MatchError) no match of right hand side value: 1


パターンマッチなので、左辺と値が一致してないマッチは例外が飛ぶ。何にでもマッチして値を利用しない記号は、_を使う。

    
    iex(1)> list = [1, 2, 3]
    [1, 2, 3]
    iex(2)> [1, a, 3] = list
    [1, 2, 3]
    iex(3)> a
    2
    iex(4)> [2, 2, 3] = list
    ** (MatchError) no match of right hand side value: [1, 2, 3]
    
    iex(4)> [b, _, _] = list
    [1, 2, 3]
    iex(5)> b
    1




## 不変性


Elixirは、immutableな値を扱う言語である。データが不変であるので、元の値から新しい値を作る時にコピーを取るが、Elixirは値が不変であることを知っているので、不必要なコピーを作成しないようにしてオーバーヘッドを抑えている。

例えば、リストはhead（配列の先頭要素）とtail（先頭以降の要素のリスト）に分かれていて、既存のリストに対して新しい要素をheadに加えたリストを作る場合は、このように書く。

    
    iex(1)> list = [1, 2, 3]
    [1, 2, 3]
    iex(2)> new_list = [0 | list]
    [0, 1, 2, 3]


この時Elixirは、listの値が不変だと知っているので、new_listには新しいhead要素である0を、tailにはlistへの参照を持つリストを作ることで、不要なデータのコピーを避けている。

Elixirにおけるデータの操作は、データの変換と捉えるとわかりやすい。

    
    iex(1)> str = "elixir"
    "elixir"
    iex(2)> String.capitalize str
    "Elixir"
    iex(3)> str
    "elixir"


オブジェクト指向言語を習得した後に  String.capitalize str という式は微妙に感じるし、特に自分はRubyから来たので、 str.capitalize というメソッド呼び出しで元のstrを変更せずに変更した値を戻り値として受け取ることに違和感が無いが、それでもオブジェクトのメッセージ呼び出しは、オブジェクトに対してどんな影響を及ぼすのかが不確定で、プログラマに余計なことを考えさせる余地が多いので、Elixirや他の関数型言語では String.capitalize str のように明確にデータを変換するという書き方が良しとされる。


## 型


Elixirの型は、次のようなものがある



 	
  * 値型

 	
    * 任意の大きさの整数(integer)

 	
    * 浮動小数点数(float)

 	
    * アトム(atom)

 	
    * 範囲(range)

 	
    * 正規表現(regular-expression)




 	
  * システム型

 	
    * PIDとポート(port)

 	
    * リファレンス(reference)




 	
  * コレクション型

 	
    * タプル(tuple)

 	
    * リスト(list)

 	
    * マップ(map)

 	
    * バイナリ(binary)





これに加えて関数も型らしいが、教本ではここの一覧に入っていなかったのでとりあえず置いておく。文字列や構造体は、これらの基本的な型から組み立てられるらしいので、ここでは書かれていない。


### IntegerとFloat


この2つに関しては、他の言語のそれらとよく似ているので特筆することは無さそう。整数に関しては、最大値というものは無いらしい。


### Atom


アトムは、何かの名前を表現する型。説明をざっと読んだ感じ、Rubyのシンボルに近いのではないかと思う。コロンで始まる単語か、Elixirの演算子がアトムに該当する。コロンで始まり、ダブルクォートに囲まれた文字列も、アトムとして解釈される。

    
    iex(1)> i :atom
    Term
      :atom
    Data type
      Atom
    Reference modules
      Atom
    iex(2)> i :readable?
    Term
      :readable?
    Data type
      Atom
    Reference modules
      Atom
    iex(3)> i :val@3
    Term
      :val@3
    Data type
      Atom
    Reference modules
      Atom
    iex(4)> i :"Ping Pong"
    Term
      :"Ping Pong"
    Data type
      Atom
    Reference modules
      Atom




### Range


start..end で表現される、範囲

    
    iex(1)> i 1..100
    Term
      1..100
    Data type
      Range
    Description
      This is a struct. Structs are maps with a __struct__ key.
    Reference modules
      Range, Map




### Regular-expression


正規表現のリテラルで、~rで始まり、対になるセパレータで囲まれた文字列と、セパレータのあとに付けるオプションから構成される。セパレータは、正規表現の慣習で/が使われることが多いが、エスケープなどの手間で{}を使った方が読みやすい。が、個人的には//で囲まれていれば正規表現という共通認識がかなり強いので、ケースバイケースな気がする。Elixirの正規表現は、Perl5のPCREに準拠している。強い。

    
    iex(1)> i ~r/exp/
    Term
      ~r/exp/
    Data type
      Regex
    Description
      This is a struct. Structs are maps with a __struct__ key.
    Reference modules
      Regex, Map
    iex(2)> i ~r{http://example.com}
    Term
      ~r/http:\/\/example.com/
    Data type
      Regex
    Description
      This is a struct. Structs are maps with a __struct__ key.
    Reference modules
      Regex, Map
    iex(3)> i ~r|something|i
    Term
      ~r/something/i
    Data type
      Regex
    Description
      This is a struct. Structs are maps with a __struct__ key.
    Reference modules
      Regex, Map




### PIDとポート


PIDは別プロセスへの参照であり、ポートはIOリソースへの参照。自身のPIDはselfで取得できる。


### リファレンス


この教本では扱わないらしい


### タプル


順番を持ったコレクション。HaskellとかScalaとかでも出て来る。パターンマッチも利用でき、関数の戻り値として成否とリソースを持ったタプルを返すことがよくあるらしい。

    
    iex(1)> {status, code, str} = {:ok, 1234, "Goog luck"}
    {:ok, 1234, "Goog luck"}
    iex(2)> status
    :ok
    iex(3)> code
    1234
    iex(4)> str
    "Goog luck"


最初の要素が、:okというアトムであるタプルを返す関数の例

    
    iex(1)> {status, file} = File.open("hello.exs")
    {:ok, #PID<0.83.0>}
    iex(2)> {status, file} = File.open("goodbye.exs")
    {:error, :enoent}
    iex(3)> {:ok, file} = File.open("goodbye.exs")
    ** (MatchError) no match of right hand side value: {:error, :enoent}
    




### リスト


リストは、[]で要素を囲む。Elixirでのリストは配列ではなく、連結データ構造である。不変性の項目で説明したheadとtailという話が関わってくる。先頭から直線的にデータを参照するのに効率的だが、ランダムアクセスに弱い。

リストには、連結演算子++や、差分演算子--、要素が存在するかを確認する演算子inがある。

    
    iex(1)> [1, 2, 3] ++ [4, 5, 6]
    [1, 2, 3, 4, 5, 6]
    iex(2)> ["a", "b", "c", "d"] -- ["b", "d"]
    ["a", "c"]
    iex(3)> 1 in [1, 2, 3, 4]
    true
    iex(4)> 5 in [1, 2, 3, 4]
    false




#### キーワードリスト


キーと値の対のタプルを持つリスト（マップではない）は多用されるので、シンタックスシュガーが存在する。Rubyとよく似ており、2つの要素を持つタプルの1つ目の要素がアトムである場合は、この2つの式は同じ値を返す。

    
    iex(1)> [ name: "kinoppyd", sex: "male", job: "Programmer" ]
    [name: "kinoppyd", sex: "male", job: "Programmer"]
    iex(2)> [ {:name, "kinoppyd"}, {:sex, "male"}, {:job, "Programmer"} ]
    [name: "kinoppyd", sex: "male", job: "Programmer"]


また、これもRubyと同様に、関数呼び出しの最後の要素がキーワードリストの場合、外側の[]を省略できる

    
    DB.save name: "kinoppyd", sex: "male", job: "Programmer"
    これは
    DB.save([{:name, "kinoppyd"}, {:sex, "male"}, {:job, "Programmer"}])
    と等価




### マップ


マップのリテラルは、 %{key => val} で表現される。マップのキーはすべて同じ型であることが推奨されるが、異なっても構わない。ユルい気がするが、まあそういうものなのだろう。

    
    iex(1)> %{ :name => "kinoppyd", {1,2} => "ping" }
    %{:name => "kinoppyd", {1, 2} => "ping"}


キーがアトムの場合、リストと同じシンタックスシュガーが使える。また、キーには式が使用できる。

    
    iex(1)> %{ name: "kinoppyd", sex: "male", job: "Programmer" }
    %{job: "Programmer", name: "kinoppyd", sex: "male"}


マップへのアクセスは[]を使用するが、キーがアトムの場合はドット演算子のシンタックスシュガーが使える。

    
    iex(1)> map = %{ name: "kinoppyd", sex: "male", job: "Programmer" }
    %{job: "Programmer", name: "kinoppyd", sex: "male"}
    iex(2)> map.name
    "kinoppyd"
    iex(3)> map.job
    "Programmer"
    iex(4)> map[:sex]
    "male"


マップとキーワードリストは非常によく似ているが、マップはキーがユニークであるのに対し、キーワードリストは同じキーを複数持つことが出来る。一般的に、マップは連想配列がほしい時に利用し、キーワードリストは関数やコマンドラインの引数に利用する。


### バイナリ


バイナリリテラルは、<<>>で囲む。なんかこのへんはちょっとややこしそうなので、一通り学習してからまた考える。

    
    iex(1)> i <<1, 2>>
    Term
      <<1, 2>>
    Data type
      BitString
    Byte size
      2
    Description
      This is a string: a UTF-8 encoded binary. It's printed with the `<<>>`
      syntax (as opposed to double quotes) because it contains non-printable
      UTF-8 encoded codepoints (the first non-printable codepoint being `<<1>>`)
    Reference modules
      String, :binary




### 真偽値


Elixirにおける真偽値は、true, false, nilの3つである。nilは、ブール演算においてはfalseと同じ働きをする。


## 演算子


演算子はたくさんあるらしいので、教本で取り上げられているものだけを見る


### 比較演算子



    
    # 比較
    a === b # 厳密な同値性、1===1.0 はfalse
    a !== b  # 厳密な非同値性、1!==1.0はtrue
    a == b   # 同値性、1==1.0はtrue
    a != b    # 非同値性、1!=1.0はfalse
    a > b     # 標準の比較
    a => b   # 標準の比較
    a < b     # 標準の比較
    a <= b  # 標準の比較
    




### ブール演算子



    
    # ブール演算、左辺にはbool値が来ることが期待される
    a and b   # aがfalseならfalse、そうでなければb
    a or b     # aがtrueならtrue、そうでなければb
    not a      # aがtrueならfalse、そうでなければtrue
    
    # ゆるいブール演算、どんな型でも受け取り、nilとfalse以外はtrueとして扱われる(true以外のtrueとして扱われる値を、truthyと呼ぶ）
    a && b # aがtruthyであればb、そうでなければb
    a || b     # aがtruthyであればa、そうでなければb
    !a          # aがtruthyであればfalse、そうでなければtrue




### 算術演算子


算術演算子は、+, -, *, /, div, rem がある。
/は浮動小数点数を返し、divは除算の整数値、remは除算のあまりを返す。


### 連結演算子



    
    binary1 <> binari2 # 2つのバイナリを連結する（文字列はバイナリである）
    list1 ++ list2           # 2つのリストを連結する
    list1 -- list 2            # list1からlist2の要素を取り除く




### in演算子



    
    n in list  # list の中にnの要素が存在するかを確かめる




## with式


Elixirのスコープはレキシカルスコープで、幾つかの構造はスコープを生み出す。内包表記で使われるforと、ここで出てくるwithは、それぞれスコープを作る。（forは後ろの章ででてくるらしい）

言語名、公開された年、現在の最新バージョンが書かれた次のようなCSVから、Elixirの項目を取り出す関数は、このように書ける。

    
    # languages.csv
    Perl,1987,5.24.0
    Ruby,1995,2.4.0
    Elixir,2012,1.3
    
    # languages.exs
    value = "Out of scope"
    
    elixir = with {:ok, file} = File.open("languages.csv"),
                  value = IO.read(file, :all),
                  :ok = File.close(file),
                  [_, _, version] = Regex.run(~r{Elixir,(\d+),([\.\d]+)}, value)
            do
              "Elixir version is #{version}"
            end
    
    IO.puts elixir
    IO.puts value


実行結果

    
    $ elixir languages.exs
    Elixir version is 1.3
    Out of scope


当たり前だが、外側のスコープのvalueが、withの中のvalueで書き換えられていることはない。with式の中で宣言された変数束縛は、doブロックの中でのみ有効になる。

上のスクリプトの中で、いくつか使われているパターンマッチのどれか一つでも失敗すると、MatchError例外が飛ぶ。例えば、languages.csvのオープンに失敗するとこうなる。

    
    $ elixir languages.exs
    ** (MatchError) no match of right hand side value: {:error, :enoent}
        languages.exs:3: (file)
        (elixir) lib/code.ex:363: Code.require_file/2


まあこれは良いとして、Elixirのエントリを探すパターンマッチでコケてこの例外が出るのはちょっと違和感があるので、with式の中のパターンマッチでは=の代わりに<-を使うことで、マッチできなかった時にマッチできなかった値を返す。

    
    iex(1)> with [a|_] <- [1,2,3], do: a
    1
    iex(2)> with [a|_] <- nil, do: a
    nil


さっきの関数の、最後のパターンマッチを<-で書き換える。

    
    value = "Out of scope"
    
    elixir = with {:ok, file} = File.open("languages.csv"),
                  value = IO.read(file, :all),
                  :ok = File.close(file),
                  [_, _, version] <- Regex.run(~r{Python,(\d+),([\.\d]+)}, value)
            do
              "Elixir version is #{version}"
            end
    
    IO.puts elixir
    IO.puts value


実行結果は、例外ではなくnilを出力する

    
    $ elixir languages.exs
    
    Out of scope


これは、Regex.runのマッチが失敗したときの戻り値がnilだかららしい。

また、with式は関数やマクロのような呼び出しらしく、with式と同じ行に式を書くか、もしくは括弧が必要となるらしい。

    
    list = [1,2,3]
    
    # これは失敗する
    IO.puts(with
                    [a|_] <- list
                 do: a
    )
    
    # これは動く
    IO.puts(with  [a|_] <- [1,2,3],
                 do: a
    )
    
    # これも動く
    IO.puts( with(
            [a|_] <- list,
            [_,b,_] <- list
          )
          do
            a + b
          end
    )


教本のP34では、doの前ではなくendのあとに閉じ括弧が書いてあったが、多分誤植だと思う。丸写ししたけど動かなかった。withがマクロなので、withの引数としてマッチをとり、それを閉じたあとにdoが続くと考えれば違和感が無い。


## 次回


4章までおわったので、次は5章からやっていきます。
