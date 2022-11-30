---
author: kinoppyd
date: 2018-12-18 06:50:08+00:00
layout: post
image: /assets/images/icon.png
title: Mobb+GitQueueでバージョン管理付きのTODO Botを作る
---

このエントリは Mobb/Repp Advent Calendar の十八日目です


## Mobb + GitQueue = バージョン管理つきTODO bot


ちょうど一年くらい前、Gitをバックエンドとしたスタックを実装した話をしました。

[http://tolarian-academy.net/task-manage-bot-with-git/](http://tolarian-academy.net/task-manage-bot-with-git/)

これを実際にMobbと組み合わせたBotを作成してみます。

```ruby
require 'mobb'
require 'git_queue'

STORAGE = './storage'

set :service, 'slack'
set :name, 'YOUR BOT NAME'

helpers do
  def stack
    @stack ||= begin
                 GitQueue::Storage.create(STORAGE) unless File.exists?(STORAGE)
                 GitQueue::Queue.new(STORAGE)
               end
  end
end

set(:channel_filter) { |name| condition { @env.channel == name } }

on /add (.+)/, ignore_bot: true, reply_to_me: true, channel_filter: 'CXXXXXXX' do |task|
  stack.push(task)
  "#{task} を追加した"
end

on /now/, ignore_bot: true, reply_to_me: true, channel_filter: 'CXXXXXXX' do
  task = stack.queue.first
  "#{task} をやれ"
end

on /done/, ignore_bot: true, reply_to_me: true, channel_filter: 'CXXXXXXX' do
  task = stack.pop
  "#{task} が終わった"
end

# TODO: Fix Mobb capture bug
on /switch \d+\s+\d+/, ignore_bot: true, reply_to_me: true, channel_filter: 'CXXXXXXX' do
  target = /(\d+)\s+(\d+)/.match(@env.body).captures
  t1 = target[0].to_i
  t2 = target[1].to_i
  queue = stack.queue
  return "そんなにタスクは無い" if queue.size <= t1 || queue.size <= t2
  task1 = queue[t1]
  task2 = queue[t2]
  stack.switch(t1, t2)
  "#{task1} と #{task2} を入れ替えた"
end

on /ls/, ignore_bot: true, reply_to_me: true, channel_filter: 'CXXXXXXX' do
  "タスク一覧\n" + stack.queue.map { |t| "- #{t}" }.join("\n")
end
```

GitQueueというGemを使ってスタックを作り、それをMobb経由で操作しています。

[![スクリーンショット 2018-12-18 15.45.18]({{ site.baseurl }}/assets/images/2018/12/スクリーンショット-2018-12-18-15.45.18.png)]({{ site.baseurl }}/assets/images/2018/12/スクリーンショット-2018-12-18-15.45.18.png)

まあまあ便利です。
