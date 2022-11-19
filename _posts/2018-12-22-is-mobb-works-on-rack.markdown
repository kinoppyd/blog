---
author: kinoppyd
comments: true
date: 2018-12-22 14:40:51+00:00
layout: post
link: http://tolarian-academy.net/is-mobb-works-on-rack/
permalink: /is-mobb-works-on-rack
title: MobbアプリケーションをRack上で起動できるか？
wordpress_id: 625
categories:
- 未分類
---

このエントリは Mobb/Repp Advent Calendar の二十二日目です




## Mobbアプリケーション is Rackアプリケーション？


結論から言うと、動きません。

試しにこんなアプリを書いて起動してみました。

app.rb

    
    require 'mobb/base'
    
    class MyApp < Mobb::Base
      before do
        p @env
      end
    end


config.ru

    
    require './app'
    
    run MyApp.new


起動

    
    bundle exec rackup


MobbはRackのアプリケーションとほぼ互換なので、理屈の上では動きそうなものですが、動きませんでした。理由としては、Mobbがサービスからの情報を受け取ったときに処理するfilterやhandle_eventメソッドの中で使われている、process_eventメソッドにありました。

process_event の中身は次のようなメソッドです。

    
    def process_event(pattern, conditions, block = nil, values = [])
      res = pattern.match?(@env.body)
      catch(:pass) do
        conditions.each { |c| throw :pass unless c.bind(self).call }
    
        case res
        when ::Mobb::Matcher::Matched
          block ? block[self, *(res.matched)] : yield(self, *(res.matched))
        when TrueClass
          block ? block[self] : yield(self)
        else
          nil
        end
      end
    end


この中で、 @env.body を参照している箇所に問題がありました。Reppと違い、Rackの送ってくるenvオブジェクトには、bodyというメソッドが存在しないからです。

比較のために、Mobbが参考にしているSinatraのprocess_routeメソッドを見てみましょう。

    
    def process_route(pattern, conditions, block = nil, values = [])
      route = @request.path_info
      route = '/' if route.empty? and not settings.empty_path_info?
      route = route[0..-2] if !settings.strict_paths? && route != '/' && route.end_with?('/')
      return unless params = pattern.params(route)
    
      params.delete("ignore") # TODO: better params handling, maybe turn it into "smart" object or detect changes
      force_encoding(params)
      original, @params = @params, @params.merge(params) if params.any?
    
      regexp_exists = pattern.is_a?(Mustermann::Regular) || (pattern.respond_to?(:patterns) && pattern.patterns.any? {|subpattern| subpattern.is_a?(Mustermann::Regular)} )
      if regexp_exists
        captures           = pattern.match(route).captures.map { |c| URI_INSTANCE.unescape(c) if c }
        values            += captures
        @params[:captures] = force_encoding(captures) unless captures.nil? || captures.empty?
      else
        values += params.values.flatten
      end
    
      catch(:pass) do
        conditions.each { |c| throw :pass if c.bind(self).call == false }
        block ? block[self, values] : yield(self, values)
      end
    rescue
      @env['sinatra.error.params'] = @params
      raise
    ensure
      @params = original if original
    end


最初に参照しているのが、 @request.path_info というメソッドで、これはどう考えてもHTTPに存在し、チャットボットに存在しない概念です。

残念ながら、MobbをRackで動かすという試みは、このRackとReppの微妙な世界観の違いで頓挫しました。


## MobbをRackで動かせるべきか？


答えはNoです。MobbはSinatraを最大限にリスペクトしていますが、Sinatraの世界観とは違うものです。もちろん動かせれば面白いとは思いますが、MobbをRackに対応させる理由は全くありません。
