---
author: kinoppyd
comments: true
date: 2018-12-20 16:00:22+00:00
layout: post
link: http://tolarian-academy.net/wxbeacon2-easy-iot/
permalink: /wxbeacon2-easy-iot
title: IoTしてますか？ 難しいですよね？ でもお手軽にWxBeacon2を使って室内環境監視ダッシュボードとか作れますよ？
wordpress_id: 607
categories:
- 未分類
---

このエントリは、 [dwango Advent Calendar](https://qiita.com/advent-calendar/2018/dwango) の二十一日目です





## TL; DR





 	
  * WxBeacon2を使って、簡易室内環境モニタを作ります

 	
  * どこでも確認したいので、DBとフロントはWebに置きます

 	
  * WxBeacon2 + Python + Fluentd + InfluxDB + Grafana + DockerCompose




## お手軽に室内環境を監視したい


世の中IoTとかMakerとかいう言葉が流行り始めて数年が立ちましたが、Raspberry Piは買ったものの特に何を作るわけでもなく完全に腐らせている方は、私の他にも多いのではないでしょうか。電子工作の本とか買ってみて、いろいろなんかやろうとか思ってみはしたものの、本業や趣味のコーディングのほうが楽しくて、あまり真剣に向き合って来ませんでした。

ブレッドボードになんか刺したり、秋月や千石に行ってパーツを探したり、はんだ付けしたり、なんかかっこいいものを作って人にオォーって言われたかったりしたかった人生なんですが、まあそれはそれとして漠然と何かを作れる人に憧れがありました。そんなとき、技術書展5に出た際にブースを手伝ってくれた友人が、何やらカバンに奇妙な物体をつけているのを見ました。話を聞くと、どうやらそいつは気象系のセンサをいろいろ詰め込んだ便利なやつで、スマホアプリと接続して情報を見たり、BLEでPCとつなげたりもできるとのことでした。実際にスマホアプリを見てみると、気温や湿度、気圧に周囲の光量や騒音まで定期的に取得していました。それはなんだと聞くと、WxBeacon2だと言われました。


## WxBeacon2


[WxBeacon2](https://weathernews.jp/smart/wxbeacon2/)とは、Weather News が販売している簡易気象観測器です。Weather News のアプリからポイントを貯めると貰えるらしいですが、まどろっこしいのでお金を払って買うことも出来ます。本体と消費税と送料込みで、5000円しないので、パパっと買ったほうが良いです。

WxBeacon2は、内容としては[オムロン製の2JCIE-BL01](https://www.omron.co.jp/ecb/product-info/sensor/iot-sensor/environmental-sensor)というIoTセンサのOEMです。2JCIEシリーズには、WxBeacon2と同型のバッグ型センサの他に、USBドングルの形をしたセンサや、PCB型のセンサも販売されています。ただ不思議なことに、日本や海外のどのセンサ通販サイトを見ても、USB型やBAG型は軒並み単価10000円を超え（しかもボリュームディスカウントも薄い）、PCB型に至っては売っているサイトすら見つけられません。そんな中、なぜかWeather News は半額以下の5000円未満でBAG型のOEM品を販売していて、ダントツで安く手に入れられるのです。なので、どうしてもUSB型が必要とかいう場合を除いて、Weather News で買うのが最も安く手に入れられる方法です。

そしてWxBeacon2もとい2JCIE-BL01は、なぜかGitHubに通信用のサンプルコードが置かれています。多分公式ではないと思うのですが（他にOmronのリポジトリも無いし、そもそもOrganizationもないので）、ここに載せられているサンプルプログラムだけで十分なので、こちらを参照します。

[https://github.com/OmronMicroDevices/envsensor-observer-py](https://github.com/OmronMicroDevices/envsensor-observer-py)


## 今回作りたいもの


WxBeacon2を使ってお手軽にIoTできるというので、家に死蔵しているRaspberry PiとWxBeacon2を使って、インターネット経由でどこからでも家の環境情報をリアルタイムで監視できるダッシュボードを作りたいと思います。インターネットから見たいので、DBサーバーはAWS Lightsailを利用します。また、Raspberry Piからのデータ転送にはFluentd、時系列データベースにはInfluxDB、ダッシュボードにはGrafanaを使います。Lightsail側のサービスは、全てDockerComposeで動かします。

[![スクリーンショット 2018-12-20 2.25.19](http://tolarian-academy.net/wp-content/uploads/2018/12/スクリーンショット-2018-12-20-2.25.19.png)](http://tolarian-academy.net/wp-content/uploads/2018/12/スクリーンショット-2018-12-20-2.25.19.png)

これが完成イメージです。2018/12/20 02:26:10 から過去七日間の私の部屋の気温室温気圧など各種情報が表示されています。気温の変動で、毎日いつエアコンをオン・オフしたのかがわかりますし、湿度の変化でいつ起床してマットレスを干したかなどもわかります。この画面は、当然パスワードはかかっていますが、グローバルのインターネットに公開されていて、どこからでも部屋の状況を確認することが出来ます。

DockerComposeを利用する理由は、サービス立ち上げの容易さに加えて、InfluxDBやGrafanaの最新版のインストールなどで、環境やOSによる原因で失敗したくないからです。


## WxBeacon2をブロードキャストモードにする


WxBeacon2は、Weather News から送られてきた状態では、デバイスにConnectして、内部に貯められているデータを参照するという方法でしかアクセスが出来ません。もちろん、きちんとConnectすれば良いし、WxBeacon2は内部に観測したデータをきちんと保存しているので、万一定期的に接続できなかった場合はその値を見に行くほうが安全です。しかし、今回作ろうとしているものは、持ち運びするセンサではなく部屋に置いたまま部屋の様子をリアルタイムで監視するダッシュボードなので、わざわざConnect市に行く必要はありません。そのため、まずはWxBeacon2のモードをブロードキャストモードに変更します。

[https://qiita.com/komde/items/7209b36159da69ae79d2](https://qiita.com/komde/items/7209b36159da69ae79d2)

こちらの記事が非常に詳しいです。真面目に2JCIE-BLE01の仕様を読んでも良いのですが、風のうわさに聞くところどうやら難易度高めとのことなので、素直にここに書いてあるとおりの設定をします。

もちろん、ブロードキャストモードではなく個別にConnectしたほうが面白いケースもあります。センサ本体を持ち運び、自分の周辺環境を常にモニタする場合です。しかし、今回はそれには触れません。


## Raspberry Piをセットアップする


WxBeacon2は、BLEを使ってデータをやり取りします。そのため、受信する側の装置にもBLEが必要です。今回選択したのは、 Raspberry Pi Zero WH という、BLEとWi-Fiを乗っけた小型のRaspberry Piです。アキバの秋月で2000円ほどで買いました。

Raspberry Piのセットアップに関しては、他に沢山の記事があるので各自検索してください。私はNoobsを使わずに、SDカードにddでRaspbianを書き込みました。

Raspbianの書き込まれたSDカードが用意されたら、それを一旦MacなりLinuxなりにマウントして、SDカードのルートディレクトリで次のコマンドを実行します。

    
    touch ssh


これで、Raspbianでsshdが有効になります。また、Zeroは有線接続のポートを持たず、最初からWi-Fi接続が必要なので、SDカードのルートディレクトリに wpa_supplicant.conf というファイルを作成し、次のような内容を書き込みます。

    
    # wpa_supplicant.conf
    ctrl_interface=DIR=/var/run/wpa_supplicant GROUP=netdev
    update_config=1
    country=JP
    
    network={
            ssid="接続したいSSID"
            psk="SSIDのパスワード"
    }


これで、通電しただけで指定のWi-Fiにつなぎに行き、かつSSH可能なRaspberry Pi Zero W が完成します。

あとは、通電してIPを確認（ルーターなり何なりを見て）したら、初期ユーザーの pi、パスワードは raspberry でログインします。作業用のユーザーを作成して、sudo権限を与えたら、piユーザーは削除しましょう。

    
    useradd kinoppyd
    usermod -aG adm,dialout,cdrom,sudo,audio,video,plugdev,games,users,input,netdev,spi,i2c,gpio kinoppyd




## 




## DBサーバーをセットアップする


まず兎にも角にもサーバーを用意します。私は、最近めっぽう安くなった AWS Lightsail を使いました。さくらやConohaの同性能帯のマシンよりもだいぶ安いですが、EC2のように便利なエコシステムがあるわけでもない、普通のVPSです。

[https://aws.amazon.com/jp/lightsail/](https://aws.amazon.com/jp/lightsail/)

面白いのは、AWSコンソールを使ってポチポチするのですが、コンソールからLightsailの画面に飛んだときに「これホントにAWSか……？」と困惑するほどポップな画面が出てくることです。

[![スクリーンショット 2018-11-26 0.32.49](http://tolarian-academy.net/wp-content/uploads/2018/12/スクリーンショット-2018-11-26-0.32.49.png)](http://tolarian-academy.net/wp-content/uploads/2018/12/スクリーンショット-2018-11-26-0.32.49.png)

これは朝の四時くらいにAWS LightsailでVPSを立てたときのダッシュボードの画面です。眠すぎて殴ってやりたくなりました。

このLightsailの大きな罠の一つとして、VPSインスタンスの管理画面からファイアウォール設定をする必要があるということです。Ubuntuを入れたので、Ubuntu側のファイアウォール設定を最初はやっていましたが、全然疎通しないのでおかしいなと思ったらコンソールからの設定が必要でした。

[![スクリーンショット 2018-12-20 2.46.36](http://tolarian-academy.net/wp-content/uploads/2018/12/スクリーンショット-2018-12-20-2.46.36.png)](http://tolarian-academy.net/wp-content/uploads/2018/12/スクリーンショット-2018-12-20-2.46.36.png)

こんな感じでポートを設定しています。3000はGrafanaのフロント（リバースプロキシを立てるなら必要ありません）、8086はInfluxDB（これもGrafanaからインターナルアクセスするなら必要ありません）、24224がFluentdです。


## DBサーバーをアグリゲーターにする


セットアップしたDBサーバーをFluentdアグリゲーターにするためには、まずFluentdをインストールする必要があります。また、インターネットを介して通信するので、TLSも有効にしましょう。その後、InfluxDBとGrafanaもインストールします。

今回は、Fluentd-InfluxDB-Grafanaを全部DockerComposeでインストールします。FluentdをDocker Composeでインストールすることは、サービスのグレースフルリスタートのやりづらさやDocker Compose自体になにか問題が起こったときのリスクなどはありますが、まあ面倒なので一気にパパっとやってしまいます。


### Docker Compose起動前の作業


これらのインストールに関しては、このリポジトリに一発でやれる方法を用意しているので、参考にしてください。Ubuntu 16.04 or higher LTS で動きます。

[https://github.com/kinoppyd/bootstrap](https://github.com/kinoppyd/bootstrap)


#### Docker Compose


このリポジトリをクローンして、docker-compose.sh を実行すると、Docker Composeがインストールされます。

    
    apt-get update
    apt-get install -y \
        apt-transport-https \
        ca-certificates \
        curl \
        software-properties-common
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
    add-apt-repository \
       "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
       $(lsb_release -cs) \
       stable"
    apt-get update
    apt-get install -y docker-ce
    
    # Install docker-compose
    curl -L "https://github.com/docker/compose/releases/download/1.23.1/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose
    curl -L https://raw.githubusercontent.com/docker/compose/1.23.1/contrib/completion/bash/docker-compose -o /etc/bash_completion.d/docker-compose


このコードは、Docker for Linux のインストールページをそのまま持ってきています。

[https://docs.docker.com/install/linux/docker-ce/ubuntu/](https://docs.docker.com/install/linux/docker-ce/ubuntu/)

[https://docs.docker.com/compose/install/](https://docs.docker.com/compose/install/)


#### Fluentd


その後、リポジトリのdbディレクトリに入って、create_tls_keys.sh を実行します。これは、FluentdのTLSキーになるので、作成が終わったらセットアップ済みのRaspberry Pi側にもコピーしておきましょう。

    
    openssl req -new -x509 -sha256 -days 1095 -newkey rsa:2048 -keyout ./fluentd/fluentd.key -out ./fluentd/fluentd.crt


実行するとなんかいろいろ聞かれると思うので、適宜値を入れてください。パスワードも聞かれますから、入れておきます。

Fluentdの設定ファイルは次のような内容です。

    
    <source>
      @type forward
      port 24224
      bind 0.0.0.0
    
      <transport tls>
        cert_path /fluentd/etc/certs/fluentd.crt
        private_key_path /fluentd/etc/certs/fluentd.key
        private_key_passphrase PASSWORD
      </transport>
    </source>
    
    <match sensors.wxbeacon2.room1>
      @type influxdb
      host influxdb
      port 8086
      dbname wxbeacon2
      measurement room1
      user root
      password root
    </match>
    
    <system>
      log_level warn
    </system>


TLS用の証明書のパスワードだけ設定してください。

forwarderから飛んできたもののうち、sensors.wxbeacon2.room1のラベルのものをInfluxDBにひたすら入れ続ける設定です。このタグに関しては、forwarder側の設定で出てくるので、今は気にしないでください。また、気になるなら適宜変更してください。

wxbeacon2というデータベースがInfluxDB側に必要ですが、これはDocker Composeの起動後に設定します。


#### Grafana


また、GrafanaをDockerでボリュームマウントしつつ動かすためには、少し特殊なパーミッション設定が必要なので、 grafana_init.sh を実行します。GrafanaのDockerイメージのパーミッションについては、次のリンクで解説されています。

[http://docs.grafana.org/installation/docker/#user-id-changes](http://docs.grafana.org/installation/docker/#user-id-changes)

以上の作業が終わったら、あとは docker-compose up -d をするだけで、FluentdのアグリゲーターとDBサーバーが起動します。

    
    sudo docker-compose up -d




### Docker Compose起動後の作業




#### Influxdb


起動後、InfluxDBにはデータを貯めるデータベースを作成する必要があります。docker ps コマンドでInfluxDBが起動しているコンテナIDを調べ、execコマンドでコンテナにアタッチしてinfluxコマンドからDBを操作します。

    
    root# docker exec -it INFLUXDB_CONTAINER_ID /bin/bash
    root# influx
    Connected to http://localhost:8086 version 1.7.1
    InfluxDB shell version: 1.7.1
    Enter an InfluxQL query
    
    > create database wxbeacon2;
    > exit


これでDBサーバーの設定は終了です。それでは、Raspberry Piに戻ってデータの送信作業をしましょう。


## Raspberry Pi + Python + WxBeacon2 + Fluentdの設定


Raspberry Piに戻ってきました。まずは、Raspberry PiにForwarderのFluentdを立てます。


#### Fluentd


まずはFluentdをインストールします。特に方法は問いませんが、私はRubyのgemコマンドからインストールしました。Native Extentionのコンパイルにかなりの時間がかかるので、他の方法をとっても構いません。

Fluentdはrootユーザーでインストールと実行を行います

    
    apt-get install -y ruby ruby-dev
    gem install fluentd
    fluentd --setup /etc/fluentd


インストール後は、DBサーバー側で作成した証明書をコピーして設置します。必要なのは、作成されたファイルのうち拡張子がcertのものだけです。次のように設置してください。

    
    # tree /etc/fluentd
    /etc/fluentd
    ├── certs
    │   └── fluentd.cert
    ├── fluent.conf
    └── plugin


次に、fluent.confを編集します。

    
    <source>
      @type forward
      port 24224
    </source>
    
    <match sensors.**>
      @type forward
      transport tls
      tls_cert_path /etc/fluentd/certs/fluentd.cert
      send_timeout 10s
      recover_wait 10s
    
      <server>
        name server1
        host YOUR_DB_SERVER_IP_OR_HOSTNAME
        port 24224
        shared_key secret
      </server>
    
      tls_allow_self_signed_cert true
      tls_verify_hostname false
    </match>


sensorsから始まるタグをすべてDBサーバーのアグリゲーターに転送します。

注意点として、fluentdは送信側のforwardと受信側のforwardの設定項目、特にインデントなどが微妙に共通してない点があります。送信側はtls_cert_pathなどをmatchの下に書きますが、受信側はsoruceの下の更にtransportの下に書きます。よくドキュメントを読んで比較しないと、最初のうちは躓くと思います。注意してください。

[https://docs.fluentd.org/v1.0/articles/in_forward](https://docs.fluentd.org/v1.0/articles/in_forward)

[https://docs.fluentd.org/v1.0/articles/out_forward](https://docs.fluentd.org/v1.0/articles/out_forward)

Fluentdの設定は以上で終わりなので、起動しておきましょう。

    
    fluentd -c /etc/fluentd/fluent.conf


systemdへの登録などはお好みでどうぞ（私は面倒なのでtmuxで動かしてます）


#### Python


aptでpythonとpipを入れ、その後サンプルコードの実行に必要なライブラリを入れます。また、サンプルコードを使うにはroot権限が必要なので、rootで実行するかsudoをつけてください。

    
    apt-get install -y python-dev python-pip
    apt-get install python-bluez
    pip install fluent-logger


bluezはBLE用のライブラリで、fluent-loggerはPython用のFluentdクライアントです。今回の構成ではFluentdを使ってLightsail上のサーバーにデータを転送しますが、念の為RaspberryPi上にローカルのInfluxDBも立ててデータを保持しておきたい場合のために、fluent-loggerを入れています。


#### envsensor-observer-py


WxBeacon2をPythonから操作するためのサンプルコードです。まずは、リポジトリをクローンしましょう。

    
    git clone https://github.com/OmronMicroDevices/envsensor-observer-py.git
    cd envsensor-observer-py


conf.pyというファイルがあるので、適宜編集します。

    
    diff --git a/envsensor-observer-py/conf.py b/envsensor-observer-py/conf.py
    index 050fa06..46ea799 100644
    --- a/envsensor-observer-py/conf.py
    +++ b/envsensor-observer-py/conf.py
    @@ -8,7 +8,7 @@ import os
     BT_DEV_ID = 0
    
     # time interval for sensor status evaluation (sec.)
    -CHECK_SENSOR_STATE_INTERVAL_SECONDS = 300
    +CHECK_SENSOR_STATE_INTERVAL_SECONDS = 30
     INACTIVE_TIMEOUT_SECONDS = 60
     # Sensor will be inactive state if there is no advertising data received in
     # this timeout period.
    @@ -21,9 +21,9 @@ CSV_DIR_PATH = os.path.dirname(os.path.abspath(__file__)) + "/log"
    
    
     # use fluentd forwarder
    -FLUENTD_FORWARD = False
    +FLUENTD_FORWARD = True
     # fluent-logger-python
    -FLUENTD_TAG = "xxxxxxxx"  # enter "tag" name
    +FLUENTD_TAG = "sensors.wxbeacon2"  # enter "tag" name
     FLUENTD_ADDRESS = "localhost"  # enter "localhost" or IP address of remote fluentd
     FLUENTD_PORT = 24224  # enter port number of fluent daemon
    
    @@ -35,11 +35,11 @@ FLUENTD_INFLUXDB_DATABASE = "xxxxxxxx"  # enter influxDB database name
    
    
     # uploading data to the cloud (required influxDB 0.9 or higher)
    -INFLUXDB_OUTPUT = False
    +INFLUXDB_OUTPUT = True
     # InfluxDB
    -INFLUXDB_ADDRESS = "xxx.xxx.xxx.xxx"  # enter IP address of influxDB
    +INFLUXDB_ADDRESS = "localhost"  # enter IP address of influxDB
     INFLUXDB_PORT = 8086  # enter port number of influxDB
    -INFLUXDB_DATABASE = "xxxxxxxx"  # enter influxDB database name
    -INFLUXDB_MEASUREMENT = "xxxxxxxx"  # enter measurement name
    +INFLUXDB_DATABASE = "wxbeacon2"  # enter influxDB database name
    +INFLUXDB_MEASUREMENT = "room1"  # enter measurement name
     INFLUXDB_USER = "root"  # enter influxDB username
     INFLUXDB_PASSWORD = "root"  # enter influxDB user password


設定がミスってても特に死ぬことなく普通に動いてしまうので気をつけてください。

FLUENTD_FORWARDの設定をTrueに変更し、TAGを設定します。これは、先程設定した各Fluentdのものと必ず合わせてください。

また、Fluentdが飛ばすInfluxDB用の設定は、FNFLUXDB_OUTPUTまわりの項目で設定します。ちなみに、私の設定はRaspberry Pi 側にもローカルのInfluxDBを立てて、バックアップ用にデータを流し込んでいるため設定が増えていますが、リモートだけであれば INFLUXDB_DATABASE と INFLUX_MEASUREMENT だけで十分のはずです。Measurementというのは、InfluxDBにおけるテーブルのようなものなので、先程アグリゲーター側のFluentdに設定した sensors.wxbeacon2.room1 のroom1の部分だと思ってください。

以上で、データを保存するすべての設定が完了しました。

あとは、スクリプトである envsensor_observer.py に実行権限を与えて、実行するのみです。

    
    chmod +x envsensor_observer.py
    ./envsensor_observer.py




## Grafanaダッシュボードの設定


envsensor_oberver.py を起動すると、Raspberry Pi 上のBLEがWxBeacon2からブロードキャストを受け取り、それをFluentd経由でDBサーバーのInfluxDBに貯蔵し続けます。それでは、そのデータを可視化してみましょう。

DBサーバーにインストールしたGrafanaにアクセスしてみます。用意してあるDocker Composeの設定では、 http://YOUR_HOST_OR_IP:3000 で接続できます。

アクセスすると、ユーザーIDとパスワードを求められるので、Docker Compose の起動時に設定したID/PASSでログインしてください。

ログイン後、まずデータソースの設定が必要です。画面左のペインから歯車の設定ボタンを押すと、Add Data Source というタブが出てくるので選択します。その後、次の画面が出てくるので、Add data source ボタンを押します。

[![スクリーンショット 2018-12-21 0.35.15](http://tolarian-academy.net/wp-content/uploads/2018/12/スクリーンショット-2018-12-21-0.35.15.png)](http://tolarian-academy.net/wp-content/uploads/2018/12/スクリーンショット-2018-12-21-0.35.15.png)

ボタンを押すとDBの設定画面に行くので、InfluxDBの項目を入力します。ServerAccessを行うのであれば、HTTPの項目のURLは、 http://infuluxdb:8086 を設定してください。これは、Docker Compose で設定したネットワーク設定を経由してGrafanaがInfluxDBに接続に行く設定です。AccessをServerではなくBrowserで行う場合には、ここにGrafanaと同じホスト名とポート8086を入力します。

InfluxDB Details には、database にwxbeacon2、UserとPasswordは、特に指定していなければroot、Docker Composeの起動時に環境変数で指定していればその値を入れてください。

[![スクリーンショット 2018-12-21 0.48.00](http://tolarian-academy.net/wp-content/uploads/2018/12/スクリーンショット-2018-12-21-0.48.00.png)](http://tolarian-academy.net/wp-content/uploads/2018/12/スクリーンショット-2018-12-21-0.48.00.png)

最後に、一番下の Save & Test ボタンを押し、問題なくDBにアクセスできることを確認したら、DB設定は終了です。

次に、グラフを追加します。

左のペインの＋ボタンを押すと、新規ダッシュボードの追加画面に移動します。

[![スクリーンショット 2018-12-21 0.51.27](http://tolarian-academy.net/wp-content/uploads/2018/12/スクリーンショット-2018-12-21-0.51.27.png)](http://tolarian-academy.net/wp-content/uploads/2018/12/スクリーンショット-2018-12-21-0.51.27.png)

ここでGraphを選択し、出てきた画面に順次グラフを足していきます。とりあえず試しに、デフォルトで出ているグラフを編集してみます。

[![スクリーンショット 2018-12-21 0.52.11](http://tolarian-academy.net/wp-content/uploads/2018/12/スクリーンショット-2018-12-21-0.52.11.png)](http://tolarian-academy.net/wp-content/uploads/2018/12/スクリーンショット-2018-12-21-0.52.11.png)

編集画面のData Source に、先程追加したInfluxDBを選択し、measurementにroom1を、fieldにtempertureを、GroupByのfillにnoneを設定します。noneを設定しないと、隙間の埋まっていない妙なグラフになり、思っていたものとは違う感じになってしまいます。

[![スクリーンショット 2018-12-21 0.53.28](http://tolarian-academy.net/wp-content/uploads/2018/12/スクリーンショット-2018-12-21-0.53.28.png)](http://tolarian-academy.net/wp-content/uploads/2018/12/スクリーンショット-2018-12-21-0.53.28.png)

これで、部屋の温度を取得するグラフが出来ました。

同じ要領で、自分の欲しいグラフを順次追加していってください。


## お手軽IoTで部屋の気象状況を監視して楽しもう


以上で、WxBeacon2とRaspberry Piを使ったお手軽IoT自室気象監視ダッシュボードが完成しました。IoTとか言った割には、電子工作とか全くせずにひたすらDocker Compose とFluentd の設定を書くだけで完了して、かなりお手軽です。

最後に、お手軽に自室の状況を監視できるようになると、思っていた以上に面白いことがわかりました。例えば、これを使えば明かりがついたり消えたりしたのがわかるため、自分が何時に就寝しようとし、何時に目を覚ましたのかがわかります。また、エアコンが実際にどれくらい部屋の温度を変化させたり、加湿器がどれくらい部屋の湿度を変化させているのかもわかります。Grafanaには通知機能などもあるので、何か自分にとって不快な条件が揃っていたら通知を出したりすることも可能ですし、気圧がわかるのでなんとなく天気の移り変わりなども見えてきます。

たったこれだけの手順で自室環境ダッシュボードの面白さを体験できるので、ぜひ皆さんもやってみてください。
