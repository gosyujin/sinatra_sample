require 'rubygems'
require 'sinatra'
require 'pit'
require 'uri'
require 'net/http'
require 'simplejsonparser'
require 'kconv'

class Ril
  def initialize()
    # RIL取得用のURL
    @add = "https://readitlaterlist.com/v2/add"
    @get = "https://readitlaterlist.com/v2/get"
    @send = "https://readitlaterlist.com/v2/send"
    
    # ユーザ情報など読み込み
    @core = Pit.get("ril", :require => {
      "username" => "your username",
      "password" => "your password",
      # apikey
      "apikey" => "your apikey"
    })
  end
  
  def add(url)
    rils = ""
    title = ""
    uri = URI.parse(url)
    proxy_class = Net::HTTP::Proxy(ENV["proxy"], 8080)
    http = proxy_class.new(uri.host)
    http.start do |http|
      title = http.get(uri.path).body.tosjis.scan(/<title>(.*)<\/title>/i).to_s
    end
    puts title
    uri = URI.parse(@add)
    proxy_class = Net::HTTP::Proxy(ENV["proxy"], 8080)
    http = proxy_class.new(uri.host)
    http.start do |http|
      param = @core
      param["url"] = escape(url)
      param["title"] = escape(title.gsub!(" ", ""))
      param = param.map{|i|i.join("=")}.join("&")
      res = http.get(uri.path + "?#{param}")
      if res.code == "200" then
        res.code
      else
        res.code
      end
    end
  end
  
  def get()
    rils = ""
    uri = URI.parse(@get)
    proxy_class = Net::HTTP::Proxy(ENV["proxy"], 8080)
    http = proxy_class.new(uri.host)
    http.start do |http|
      param = @core
      param["format"] = "json"
      param = param.map{|i|i.join("=")}.join("&")
      res = http.get(uri.path + "?#{param}")
      if res.code == "200" then
        JsonParser.new.parse(res.body)
      else
        res.code
      end
    end
  end
  
  def send(url)
    uri = URI.parse(@send)
    proxy_class = Net::HTTP::Proxy(ENV["proxy"], 8080)
    http = proxy_class.new(uri.host)
    http.start do |http|
      param = @core
      param["read"] = "{\"1\":{\"url\":\"#{url}\"}}"
      param = param.map{|i|i.join("=")}.join("&")
      res = http.get(uri.path + "?#{param}")
      if res.code == "200" then
        puts res.code
      else
        puts res.code
      end
    end
  end
  
  def get_ril()
    json = get()
    
    # 追加時間でソート(asc)
    list = json["list"].sort do |a, b|
      a[1]["time_added"] <=> b[1]["time_added"]
    end
    # desc
    list = list.reverse
    
    rils = "<ul>"
    list.each do |k, v|
      if v["state"] == "0" then 
        url = "read?url=#{escape(v["url"])}"
        rils += "<li>"
        rils += "<span>#{u_to_g(v["time_added"])}</span>" + 
                "<span> | </span>" + 
                "<span><a href=#{url}>U</a></span>" + 
                "<span> | </span>" + 
                "<a href=\"#{v["url"]}\">#{v["title"]}</a>" +
                "</li>"
      else
        #rils += "R"
      end
    end
    return rils += "</ul>"
  end
  
  def escape(value)
    URI.escape(value, Regexp.new("[^a-zA-Z0-9._-]"))
  end
  
  def u_to_g(time)
    Time.at(time.to_i).strftime("%Y/%m/%d %H:%M:%S")
  end
end

get '/' do
  ril = Ril.new()
  htm = ril.get_ril()
  return '<form method="post" action="/add">' + 
         '<input type="text" name="url" />' + 
         '<input type="submit" value="read it" />' + 
         '</form>' + 
         htm
end

post '/add' do
  ril = Ril.new()
  ril.add(params["url"])
  redirect "/"
end

get '/read?*' do
  ril = Ril.new()
  ril.send(params["url"])
  redirect "/"
end
