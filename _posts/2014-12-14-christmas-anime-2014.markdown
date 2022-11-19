---
author: kinoppyd
comments: true
date: 2014-12-14 16:03:09+00:00
layout: post
link: http://tolarian-academy.net/christmas-anime-2014/
permalink: /christmas-anime-2014
title: クリスマスに安心して一日中アニメを見るために録画鯖を作る技術
wordpress_id: 197
categories:
- Debian
- アニメ
- プログラミング
---

このエントリは、[ドワンゴ Advent Calendar 2014 - Qiita](http://qiita.com/advent-calendar/2014/dwango) の15日目のエントリです。昨日は[kokuyou](http://blog.kokuyouwind.com/archives/808)さん、明日はsaitenさんです。


### 要約


Ansibleを使って、Chinachuがインストールされた録画サーバーを自動でセットアップするPlaybook作りました。<!-- more -->


### 安心してアニメが観たい。


世の中の大抵の人は、安心してアニメが観たいはずです。そして世の中の大抵の人は、普通のテレビと普通のBDレコーダーを使い、安心してテレビを観たり録画しているはずです。よっぽど変なテレビやレコーダーを買わない限り、普通にアニメを観てアニメを録画できる機能が備わっています。安心ですね。

しかし世の中には、宗教的な理由や金銭的な理由で、テレビやレコーダーを買うことを拒む人が居ます。私もその1人です。このエントリでは、訳があってテレビやレコーダーを買えないけれど、クリスマスはどうせ暇だから一日中アニメを観たいという人のために、クリスマスまで安心してアニメを録画し続けることが出来る、録画サーバーの作り方を解説します。


### 安心とは


難しいテーマだ……安全とは一体なんなのか。

高可用？ 耐障害？ 冗長性……とかそういうのが安全な気がしますが、**このエントリで言う安全とは、「壊れてもすぐに治せる」**ことです。普通のテレビと普通のレコーダーは、仮に物理的に壊れても、同じものを買えばすぐに治ったと同じ状態です（HDDとかが壊れたら別ですが）。では、自分で作った録画サーバーはどうでしょう……？


### つらさ


これまで、自宅サーバーやVPSを含めて、いくつものサーバー的なモノを運用してきましたが、大抵は「その場で対応した再現法のわからない謎のレシピの積み重ね」がさらに積み重なり、確実に再現できない上に、この設定を作った時の俺は何を考えていたのかすら理解できない。明日の他人は今日の自分、お前は俺で俺はお前状態のモノを大量に作ってきました。嫌いな言葉は環境依存です。生きててすみません。


### 再現可能な環境を作る


環境に依存したつらい環境はなく、壊れてもすぐに同じ状態を再現するために、構成管理ツールを使いましょう。代表的なものは、ChefとかPuppetなどがありますが、あれらは何百台ものサーバーを常に管理し続けるためのツールです。一年に一回、壊れるかどうかもわからないような録画サーバーを管理するために存在しているわけではありません。

そこでおすすめの構成管理ツールが、[Ansible](http://www.ansible.com/home)です。Python製ですが、設定の記述にYAMLを使い、特定の言語に依存しない簡単な記述で構成管理が可能ということで、今年ブレイクした（多分）ツールです。テンプレートエンジンにはPythonのJinja2というライブラリを使っているため、ほんの少しだけPythonの記述に依存する場所がありますが、学習コストは非常に低いです。似たような哲学を共有する構成管理ツールとしてFabricというものもありますが、少なくとも国内ではFabricよりもAnsibleの方が流行っていると思います。

また、年に一回壊れるかどうか、と言いましたが、サーバーを一回クリアにして再度セットアップしたくなる状況は、年に何度か出てくると思います。例えば私の場合、録画サーバー上で複数の仮想サーバーを運用しているため、物理メモリを増やしたくなったとか、USB3.0のカードを追加したくなったなどという事態が年に数度起きます。そんな場合でも、構成管理を使えば、物理環境を変えた後にでも、以前と全く同じ設定を自動で作り出すことが可能です。


### やってみよう


私が作った録画サーバーの環境を、そのまま紹介します。作りたかった録画サーバーの条件として、



	
  1. ファンレス

	
  2. ゼロスピンドル

	
  3. 多めのメモリ

	
  4. 3番組以上の同時録画


という要求が自分の中でありました。自室で24h動くサーバーなので、うるさいと気になって眠れないし、仮想マシンをいくつか動かすので、メモリは多めに欲しいという判断からです。3番組以上の録画に関しては、実際に今年の春頃に、3番組が重なって絶望感を覚えたからです。

そこで、実際にとった構成は次のようになりました

	
  * CPU&MB　[ASRock Q1900M](http://www.asrock.com/mb/Intel/Q1900M/index.jp.asp)

	
  * 2.5インチHDD （妥協した）

	
  * PT3 x 2

	
  * ACアダプタのATX電源


まず、ASRockのQ1900は、CeleronのJ1900をオンボードで載せたSoCで、ファンレスのボードです。クアッドコア搭載で、**ePCIが3枚**刺せ、何より同じJ1900の中でもメモリも**最大16G**と十分な拡張性を持っているため、選択しました。PT3の二枚刺しは、3番組同時録画の要件を満たすためです。また、電源もファンレスのためにACアダプタタイプを選択しました。J1900のTDPは10Wで、PT3を二枚刺してもまだ電力的な余裕は十分です。残念ながら、テレビを録画するという事自体が非常に容量を食う問題であったため、サーバー自身にもある程度のストレージは欲しいと思い、SSDは一旦見送り2.5インチの静音HDDを選択しました。

これらのパーツは、決して特殊なものではありません。もし物理的に壊れても、すぐに電気屋に買いに行くことで、構成管理を使い自動的に復帰が可能です。安心ですね。


### サーバーに何を選択するか


録画サーバー機能そのものには、[Chinachu](http://chinachu.akkar.in/)というソフトを使います。Linux用の録画サーバーを構築するソフトとしては、メジャーなものに[folita](http://foltia.com/ANILOC/)や[EPGrec](http://www.mda.or.jp/epgrec/)などがあります。他のソフトと比較した時のChinachuの特徴は、インストールの容易さ、癖のあるUI、そしてWebAPIのエンドポイントが用意されており、ほぼすべてをAPI経由で操作できるなどの設計もさておき、「世界で一番キュートな録画システム」という可愛らしく魅力的な謳い文句です。かわいい。

他には、これはとても重要なことですが、作者の方が積極的にコミケでChinachuの設計方針や扱い方などを書いた**同人誌**を売っていたり、あとはDBなどのミドルウェアに依存が無くNode.jsだけ有ればいいなど、とにかく扱いやすく解決策を探しやすいという点が選択した理由です。ただし、Chinachu自身が生成する設定なども含めて、ほぼすべてがJSONで 記述されており、一回壊れると手作業での修復はほぼ不可能です。とはいえ、壊れたら再構成すればいいのです。安心ですね。


### 録画サーバーを構成管理する


AnsibleのPlaybookをGithubにあげてあります。すべてのコードはこっちを見てもらうとして、重要な部分を解説します

[YasuhiroKinoshita/chinachu_ansible](https://github.com/YasuhiroKinoshita/chinachu_ansible)


####  ディレクトリ構成


[ペストプラクティス](http://docs.ansible.com/playbooks_best_practices.html)を採っています。ロールは6つに分解してあり、それぞれ



	
  1. 共通設定

	
  2. PT3のドライバと録画コマンドのインストール

	
  3. Chinachuのインストール前確認

	
  4. Chinachuのインストール

	
  5. Sambaのインストール

	
  6. VagrantとVirtualBoxのインストール


に分かれています。Chinachuのサーバー構築に必要なのは1から4までで、5と6は自分が家のサーバーに欲しかった機能を入れているものです。また、1、5、6は、他のプロジェクトにも使えそうなので、Gitのサブモジュール化を行っています。このレポジトリを作った当初は、サブモジュール化を進めて色々応用させることに意欲を持っていたのでしょうが、これはこれで管理がつらいです。

Chinachuのロールが前後に分解されているのは、ユーザーの切り替えが面倒だったからです。事前準備はrootで行い、インストールはchinachuユーザーで行うためです。


#### 設定（変数）


基本的に、次の2つのファイルの変数を書き換えるだけです

_roles/chinachu/vars/main.yml_

    
    ---
    chinachu_dir: "/home/chinachu" # chinachuを実行するユーザーのホームディレクトリを設定します。基本的に、勝手に作られるのでこのまま
    chinachu_root_dir_name: "chinachu" # ChinachuをCloneするディレクトリ名
    chinachu_symlink: "chinachu_cmd" # Chinachuの実行ファイルへのシンボリックリンク名
    chinachu_video_dir: "video" # 録画したファイルを保存する場所のディレクトリ名
    
    chinachu_user: "chinachu" # WebUIを使う際の、ログインユーザー名
    chinachu_password: "chinachu" # WebUIを使う際の、パスワード
    
    # Twitterの通知を使用する場合に使うトークン。この行を削除すると、Twitterの設定は作成されません
    ceinachu_twitter_consumer_key: "your_consumer_key"
    chinachu_twitter_consumer_secret: "your_consumer_secret"
    chinachu_twitter_access_token: "your_access_token"
    chinachu_twitter_access_token_secret: "your_access_token_secret"
    
    # 録画対象の物理チャンネルIDのリスト
    chinachu_channel_list:
      - 18
      - 20
      - 21
      - 22
      - 23
      - 24
      - 25
      - 26
      - 27
      - 28
      - 30


_roles/pre-chinachu/vars/main.yml_

    
    pre_chinachu_private_key: "~/.ssh/id_rsa.pub" # chinachuユーザーにログインする際に使用する公開鍵<span style="font-family: Georgia, 'Times New Roman', 'Bitstream Charter', Times, serif; font-size: 13px; line-height: 19px;">&nbsp;</span>


また、SambaやVagrantのインストールが必要ない場合は、次の行をコメントアウトしてください

_chinachu.yml_

    
    ---
    - hosts: chinachu-server
      user: root
      roles:
        - common
        - pt
        - pre_chinachu
        #- vm # この二行をコメントアウトする
        #- samba
    
    - hosts: chinachu-server
      user: chinachu
      roles:
        - chinachu<span style="font-family: Georgia, 'Times New Roman', 'Bitstream Charter', Times, serif; font-size: 13px; line-height: 19px;"> </span>




#### マシンの再起動


PT3のドライバを入れた後など、どうしても物理的にマシンを再起動する必要が出てきますが、せっかく自動化しているので手動でやるのはアホらしいです。なので、次のような記述でマシンを再起動し、再びsshで接続できるよう待機します。[去年のAdvent Calendar](http://qiita.com/volanja/items/d38fe0678848bae6902f)を参考にしました。

_roles/pt/tasks/main.yml_

    
    - name: reboot
      shell: sleep 2s && /sbin/reboot &
    
    - name: wait for the server to go down (reboot)
      local_action: wait_for host={{ inventory_hostname }} port=22 state=stopped
    
    - name: wait for the server to come up
      local_action: wait_for host={{ inventory_hostname }} port=22 delay=60


ただし、この設定では、仮想環境での実行がうまくいきません。基本的に録画サーバーは物理サーバーだと思うので、特に配慮はしませんが、仮想環境でPlaybookの実行テストを行う場合には注意が必要です。


#### Chinachuユーザーの作成


ユーザーの作成と鍵の登録は、userモジュールとauthorized_keyモジュールを使用しています

_roles/pre_chinachu/tasks/main.yml_

    
    - name: create chinachu user
      user: name=chinachu
            password='$6$rounds=100000$t9cFLWAcHkPD2awG$alBfg4PJPCwARrxceQRB5rANzq8QvZwzdCyANDfa5SNTgruKIvhwXGziVopDHU64R7Zl7Fsf44ZEiN56H4fyj/'
            home=/home/chinachu
            shell=/bin/bash
            groups=sudo
      tags: chinachu_user
    
    - name: add authorized keys
      authorized_key:
          user=chinachu
          key="{{ lookup('file', '~/.ssh/id_rsa.pub') }}"
      tags: chinachu_user


userモジュールのpasswordオプションは、SHAでハッシュ化した値を渡さなくてはなりません。上のコードでは、'chinachu'という文字列をハッシュ化しています。詳細は公式FAQの[ここ](http://docs.ansible.com/faq.html#how-do-i-generate-crypted-passwords-for-the-user-module)を参照。 


#### Chinachuのインストーラー実行


chinachuは、git cloneをしてきた後に、ディレクトリルートに居るchinachuコマンドを実行するだけで、自動的にインストールされます。ですが、何故かそのコマンドが対話的で、引数を使った動作の制御が出来ないので、expectスクリプトを使って自動でインストールします。

_roles/chinachu/files/chinachu_installer.sh_

    
    #!/usr/bin/expect
    spawn ./chinachu_cmd installer # シンボリックリンクを貼ったchinachuコマンド
    expect "what do you install? >"
    send "1\n"
    interact


このファイルをリモートにコピーし、chinachuコマンドへのシンボリックリンク経由で実行します。chinachuは、シンボリックリンクからでも正しくパスを認識して実行することが可能です。できれば、インストールも引数で制御出来るようになればいいのですが……

_roles/chinachu/tasks/main.yml_

    
    - name: create symlink
      file: src={{ chinachu_dir }}/{{ chinachu_root_dir_name}}/chinachu dest={{ chinachu_symlink }} state=link
      tags: chinachu
    
    - name: copy file
      copy: src=chinachu_installer.sh dest={{ chinachu_dir }} mode=0744
      tags: chinachu
    
    - name: install chinachu
      command:
          ./chinachu_installer.sh
          chdir={{ chinachu_dir }}
      tags: chinachu




####  PT3のドライバに関して


怖いのであまり触れません


### 実行する


Chinachuは、[Debian](http://www.debian.or.jp/)上で動作させることを推奨されています。なので、まずはDebian Wheezyをサーバーにインストールします。このとき、root以外にユーザーを作製することを求められますが、**chinachuというユーザーは作らないでください**。Ansibleによって、自動的に作成されます。このDebianのインストール自体も自動化したかったのですが、手順的に特に難しいものでも無いことと、メンテのコストを考えると、手動でもいいかと思い特に何もしていません。開発用の最小構成でインストールしてください。また、Ansibleを実行するマシンと、Debianをインストールした録画サーバーのrootが、sshで公開鍵認証を行えるように、サーバー側に公開鍵の追加も行います（これも自動化したかったけどできなかった）

あとは、次のコマンドで修了です

    
    ./init.sh


このスクリプトは、単に次のコマンドを実行しているだけです

    
    ansible-playbook -i production site.yml


毎回タイプするのが面倒なので、作っただけです。Vagrantなどで作成したDebianのマシンで、試してみると何が起こるのか解ると思います。（ただし、VagrantやVirtualBoxでの起動では、PT3用のドライバ等をインストールしている最後のRoleで行う再起動のタスクがうまく行きません。このPlaybookは実機を前提としているので、そこの部分をコメントアウトして自分で再起動を試してください）

録画サーバーとの通信さえ問題なければ、これであとは勝手にchinachuサーバーが作成されるはずです。指定した公開鍵を使って、chinachuユーザーとしての公開鍵を使ったログインも可能です。また、chinachuユーザーのデフォルトのパスワードはchinachuなので、sudoなどの際に必要であれば指定してください。


### まとめ


以上の手順で、Ansibleを使った録画サーバーのプロビジョニングが完了します。あとは、Chinachuのドキュメントを参照して、初回の番組取得や起動スクリプトの作成など、自動化できないChinachuのオペレーションを開始してください。

物理マシンへのOSのインストールと、セットアップ後のChinachuの運用を除いて、ほぼすべて自動化しました。これで仮にどこかで故障が起きても、すぐに同じ環境を再度作製することが出来ます。安心してアニメが見れます。

このプロビジョニングで作成した録画サーバーを使って、私は2014年冬のアニメをほぼ無事にすべて録画しています。最近引っ越したので、正確なアップタイムは忘れましたが、少なくとも三ヶ月近くは無停止で稼働し続けました。

いくつか観れていないものがあるので、クリスマスに安心して観ようと思っています。

みんなで安心して、クリスマスはずっとアニメを観よう。
