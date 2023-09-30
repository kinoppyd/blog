---
layout: post
title: Reject on Rails 2023 に応募するから Kaigi on Rails 2023 でRejectされたCFP置いときます
date: 2023-09-30 17:10 +0900
---
## 何

タイトルの通りなんですけど、[Kaigi on Rails 2023](https://kaigionrails.org/2023/) のCFPがRejectだったので Reject on Rails 2023 に応募しようと思い、せっかくなんでRejectされたCFPも置いておこう的な奴です。応募するときに楽かなと思ったので。でも応募フォーム開いたら特にどういうCFP送ったか書く場所無かったんで、公開する意味ないやんとか思ったけどもうブログ書いちゃった後だったんで……

{% cardlink https://gotanda-rb.connpass.com/event/297591/ %}

## CFP

### Abstract

Ruby on Rails, Sinatara, Grape, Hanami など、Rubyには多くのWeb Application Framework があります。これらは方法は違えど、全てRackというインターフェイスを満たすフレームワークです。このセッションでは、RubyのWebフレームワーク共通のインターフィスであるRackの仕様を満たす、自分だけののWeb Application Frameworkの作り方を通して、Rackとはなにか、自己流のDSLをどのように作っていくかを学びます。

#### For Review Committee

##### Details

Rackのインターフェイスのお話と、主にSinatraで使われているテクニックを解説しながら、独自のDSLで実用的？なWeb Application Frameworkを実装するための知識について話します。

想定する聴講者は、Railsで仕事や趣味の開発はできるけれど、Web Application Frameworkがなんで動いているのかは知らない、という初心者から中級者の間を想定しています。メタプログラミングの話がでてくるので、初学者向けでは無いと思います。

具体的には、最初に「ぼくのかんがえる最強のWAF」のDSLを示し、それを本物のWAFとして実装するためにはどんな知識が必用なのかを順を追って話していく形になると思います。例えば、次のようなDSLが使えるWAFが欲しいです、どうやって作りましょう？　みたいなお話になると思います。

```ruby
require 'oreno_kangaeta_saikyou_no_waf'

# あくまで今考えてる適当な例なので、どんなDSLになるかはわからんですが

get_root do
  'hellow world'
end

post_users do |request|
  user = User.new(name: request['body']['name'])
  user.save ? user.id : raise
end
```

このDSLを実現するためには、 / や /users にリクエストが来たときに、反応するブロックをどう定めるか？　戻り値はどの様に変換してRackに渡すか？　いや、Rackってなに？　エラーのハンドリングをどうするか？　そもそもどうやって起動するのか？　など様々なことを考える必用があります。それらをSinatraやRailsのコードを見ながら、こうやって実装すると動きますと示していく予定です。

あくまで決め打ちのコードのエッセンスを伝える感じにするので、ライブコーディングなどは予定していません。もしかしたら、最後にちょっと動かす程度はあるかも知れませんが。

##### Pitch
30分で伝えられる量には限りはあると思いますが、RailsでWebアプリを作ることは出来るけど、それ以上のことはできないという方々の好奇心に刺激を与えます。普段使っているツールの動作原理を知ることで、より高い解像度でツールを使えたり、新しい何かを作ったりすることの手助けができれば良いなと思います。
