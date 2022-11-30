---
author: kinoppyd
date: 2015-09-22 13:08:49+00:00
layout: post
image: /assets/images/icon.png
title: Gemを初めてRubyGemsにリリースしたよ
---

## <del></del>作ったもの


[wtfpl_init](https://rubygems.org/gems/wtfpl_init)


## 何これ


たまにしょうもないもの（たとえば、[キルミーベイベー画像ジェネレータ](https://github.com/YasuhiroKinoshita/kill-me-baby-image-generator)とか）を作ってGithubにプッシュするけれど、ライセンスとかもうどうでも良いし好きに使って欲しいけど、ライセンスの表記が無いのも使いたい人が戸惑う。そういうときに最高のライセンス[WTFPL](http://www.wtfpl.net/)があるのだが、作ったものにいちいちこいつを入れるのもめんどくさい。

そんなときに、コマンド一つでWTFPLのライセンスファイルを生成してくれるGemです。


## Usage



```shell-session
$ echo 'gem "wtfpl_init" >> Gemfile
$ bundle install
$ bundle exec wtfpl
```

これで、wtfplコマンドを実行したディレクトリにLICENSE.mdファイルが作られて、中にはWTFPLのplain text が入っている。


## Gemの作り方


[RubyG](http://guides.rubygems.org/make-your-own-gem/)[emsのページ](http://guides.rubygems.org/make-your-own-gem/)や[Developers.IO](http://dev.classmethod.jp/server-side/language/how-to-publish-rubygems/)のブログが参考になります。

RubyGemsのページが王道なのだろうけど、Bundlerが大部分を肩代わりしてくれるので、大事な手順は次の二つだけ


#### RubyGemsのAPIキーを手に入れる



```shell-session
$ curl -u YOUR_RUBYGEMS_USER https://rubygems.org/api/v1/api_key.yaml > ~/.gem/credentials; chmod 0600 ~/.gem/credentials
```

このコマンドで、RubyGemsからGemのパブリッシュに必要なAPIキーを手に入れられる。もちろん、先にRubyGemsに登録しておく必要はあるので、サインアップを忘れずに。

curlでアクセスするときにユーザーネームを渡すので、Basic認証がかかり、パスワードを聞かれる。サインアップしたときのパスワードを入れると、APIキーが降りてきて、それを$HOME/.gems/credentials に保存する


#### Gemをビルドしてパブリッシュ


BundlerのRakeタスクを使って、Gemをビルド＆パブリッシュする

```shell-session
$ bundle exec rake spec
$ bundle exec rake build
$ bundle exec rake release
```

とりあえずテスト回して、ビルドして、リリース。rake releaseを実行すると、Githubに対象のタグを勝手に打ってくれるらしい。（Rakeタスクを呼んでないからどういう動作になっているのか分からないので、後日読もう）

この二つの手順だけで、GemをRubyGemsにパブリッシュすることが出来る。実際に作ったものが役に立つのかどうかは知らないけれど、変に名前空間を食いつぶすような名前で無ければ、何か作ったら適当にパブリッシュするのが良いんじゃないかと思う。今後は頑張ろう。
