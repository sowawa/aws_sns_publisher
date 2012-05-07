require 'rubygems'
require 'cgi'
require 'time'
require 'openssl'
require 'base64'  
require 'net/http'

# publisher = AwsSNSPublisher.new(
#   "sns.us-east-1.amazonaws.com",
#   access_key: "hogehoge", 
#   secret_key: "hogehogehoge")
# puts publisher.publish(
#   "Action" => "Publish",
#   "Message" => "hogehoge",
#   "Subject" => "hoge",
#   "TopicArn" => "arn:aws:sns:us-east-1:")

class AwsSNSPublisher
  
  def initialize(host, options = {})
    @secret_key = options[:secret_key]
    raise Exception.new("You must supply a :secret_key") unless @secret_key
    @access_key = options[:access_key]
    @host = host
  end

  def publish params
    uri = 'http://'
    uri << @host
    uri << '/'
    uri << '?'
    uri << self.query_with_signature(params) 
    return Net::HTTP.get(
      URI.parse( uri ))
  end
 
  def query_with_signature(hash)
    return hash_to_query( add_signature(hash)  )
  end
  
  def add_signature(params)
    # supply timestamp, access key
    params["Timestamp"]      = Time.now.iso8601
    params["AWSAccessKeyId"] = @access_key
    # supply signature infomation
    params["SignatureMethod"]  = "HmacSHA256"
    params["SignatureVersion"] = "2"
    
    params.delete("Signature")

    query_string = canonical_querystring(params)
    string_to_sign = string_to_sign(query_string)
    hmac = OpenSSL::HMAC::new(@secret_key, OpenSSL::Digest::SHA256.new)
    hmac.update( string_to_sign )
    # chomp is important! the base64 encoded version will have a newline at the end
    signature = Base64.encode64(hmac.digest).chomp 
 
    params["Signature"] = signature
 
    return params
  end
 
  # RFC3986. 
  def url_encode(string)
    return CGI.escape(string).gsub("%7E", "~").gsub("+", "%20")
  end
 
  # canonical order => sort byte order. 
  def canonical_querystring(params)
    values = params.keys.sort.collect {|key|  [url_encode(key), url_encode(params[key].to_s)].join("=") }
    return values.join("&")
  end

  def string_to_sign(query_string, options = {})
    options[:verb] = "GET"
    options[:request_uri] = "/"
    options[:host] = @host
    return options[:verb] + "\n" + 
        options[:host].downcase + "\n" +
        options[:request_uri] + "\n" +
        query_string
  end
 
  def hash_to_query(hash)
    hash.collect { |k, v|
      url_encode(k) + "=" + url_encode(v)
    }.join("&")
  end
end

