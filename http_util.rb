require "net/https"
require "json"

# net/http
# https://docs.ruby-lang.org/ja/latest/library/net=2fhttp.html
#
# Net::HTTPResponse
# https://docs.ruby-lang.org/ja/latest/class/Net=3a=3aHTTPResponse.html

class HttpUtil
  class << self
    def hash_to_query(hash)
      return URI.encode_www_form(hash)
    end

    def response_to_result(http_response)
      headers = Hash[http_response]
      return [http_response.code, headers, http_response.body]
    end

    # str_url: URL（文字列）
    # data:    クエリパラメータ（ハッシュ）
    # debug_port: デバッグ出力先（例：$stderr）
    # 戻り値: レスポンスオブジェクト。res.body, res.status, res.headers
    def get(str_url, data=nil, debug_port: nil)
      uri = URI.parse(str_url)
      http = Net::HTTP.new(uri.host, uri.port)

      http.set_debug_output(debug_port) if debug_port

      if uri.scheme == "https"
        http.use_ssl = true
        http.verify_mode = OpenSSL::SSL::VERIFY_NONE
      end

      path = uri.path
      if data
        path += "?" + hash_to_query(data)
      end
      res = http.get(path)
      if res.code.to_s[0] != "2"
        raise "http error: url = #{str_url}, res.code = #{res.code}, res.body = #{res.body}, data = #{data}"
      end
      return response_to_result(res)
    end

    # x-www-form-urlencodedでPOSTする
    # str_url: URL（文字列）
    # data:    ポストするデータ（ハッシュ）
    # debug_port: デバッグ出力先（例：$stderr）
    # 戻り値: レスポンスオブジェクト。res.body, res.status, res.headers
    def post(str_url, data, content_type: :form_urlencoded, debug_port: nil)
      uri = URI.parse(str_url)
      http = Net::HTTP.new(uri.host, uri.port)

      http.set_debug_output(debug_port) if debug_port

      if uri.scheme == "https"
        http.use_ssl = true
        http.verify_mode = OpenSSL::SSL::VERIFY_NONE
      end

      req = Net::HTTP::Post.new(uri.path)

      case content_type
      when :json
        req["Content-Type"] = "application/json"
        req.body = data.to_json
      when :form_urlencoded
        req.set_form_data(data)
      else
        raise "#{__method__}: Unsupported content_type: [#{content_type}]"
      end

      res = http.request(req)
      if res.code.to_s[0] != "2"
        raise "http error: url = #{str_url}, res.code = #{res.code}, res.body = #{res.body}, data = #{data}"
      end
      return response_to_result(res)
    end

    # JSONをPOSTする
    # str_url: URL（文字列）
    # data:    ポストするデータ（ハッシュ）
    # 戻り値: レスポンスオブジェクト。res.body, res.status, res.headers
    def post_json(str_url, data)
      return post(str_url, data, content_type: :json)
    end
  end
end

if $0 == __FILE__
  status, headers, body = HttpUtil.post_json("http://httpbin.org/post", { hoge: 123, moge: "jjj" })
  p status    # => "200"
  p headers   # => Hash

  puts
  puts body   # => String
end
