---
layout: post
title: 大阪Ruby会議04のプロポーザルが採択されたので公開します
date: 2024-08-25 13:54 +0900
---
## 【重要】

これはあくまでCFPの話であり、大阪Ruby会議のブログはまた別で書きます

## 何

タイトルの通りですが、大阪Ruby会議のプロポーザルが採択されたので、誰かの参考になればと思い公開します。

落ちたCFPは、いつも不採択がわかった瞬間に公開するのですが、採択されたCFPは実際に登壇するまでに公開してしまうとネタバレになるので、登壇後に公開する感じでやっていきます。

## CFP

### タイトル

RubyKaigi公式スケジュールアプリ開発で得た、Hotwireの使い方

### 概要

2021年から提供しているRubyKaigi公式スケジュールアプリを、2024年に全面Hotwireで書き直しました。Hotwireを使った開発体験の良いところと、良くないところ、そして実地で得たモバイル環境でのフィードバックなどをお話しします。主なトピックはTurbo関連で、Stimulusに関しては少なめです。

### 詳細

RubyKaigi公式のスケジュールアプリを2021年からSmartHR社のスポンサーとして提供しており、今年はReact製だったフロントを全てHotwireで書き直しました。Hotwireで実際にどれほどのモノが作れるのかというベンチマークとして、Hotwireを触ったことがない人、少し触ったけど実際のアプリに組み込むことを躊躇している人などを対象としたトークを予定しています。

以下のURLは、実際のスケジュールアプリのリポジトリです。
https://github.com/kufu/mie

主にTurboFrames、TurboStreamsを使った、SPAライクな挙動をするHotwireアプリケーションの構築について話します。
まず、TurboFramesを用いたDialog系の操作が難しいことに触れます。TurboFramesは、画面の一部を置き換えてページ遷移を避ける技術なので、モーダルなどのDialog系の操作とは相性が良くなく、それをいかにうまく見せるかを話します。また、37SignalsのCampfireがどのようにモーダルを実装しているかにも触れ、実装を比較します。
次に、Tableタグの操作をいかにTurboで変更するかが難しい話をします。Tableは、特定のセルだけでは無く周囲の行列にも影響を及ぼす変更が多いので、単純にTurboFramesで対処することができません。そのため、TurboStreamsで書き換える方法を提案します。
最後に、Turboがいかにサーバー側のレイテンシに影響されるかを話します。実際にモバイル環境では、レイテンシが大きくなるケースが多く、その場合に単純にTuborを使っているとユーザーが操作フィードバックを受ける事ができず、混乱してしまいます。そのため、できるだけ先にHTML要素を用意してTurboを使うか、またTurboのイベントを利用して通信中だということを示すかの重要性を説明します。

前のページでトークの長さが15分と30分両方選べたので両方選んでしまいましたが、どちらでも大丈夫です。

### ピッチ

Hotwireはとても良くできた技術で、特にプロトタイプのアプリケーションなどを立ち上げる際に強力なツールとなります。そのため、全てのRails開発者に手段の一つとしてHotwireを選択できるくらいHotwireの良さを伝えたいなというのがプロポーザルの主な動機です。
RubyKaigiでスケジュールアプリを実際に触ってくれた人も多いと思うので、自分が触ったモノがHotwireでできている、ちゃんと動くんだということを実感してもらう事が、このトークの説得力になると考えており、自分がこのトークをするのにふさわしい理由だと思います。
