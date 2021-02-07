
require 'uri'
require 'webrick'

CIG_VERSION = '1.0.0'.freeze

PARAMS =
  URI.decode_www_form(ENV['QUERY_STRING'])
    .inject({}) { |h, (k, v)| h[k] = v; h }

RESPONSE = {
  status: 200, headers: {}, body: [] }


def status(c)

  RESPONSE[:status] = c
end

def header(k, v)

  k1 =
    case k
    when :type then 'Content-Type'
    when :cache then 'Cache-Control'
    when :length then 'Content-Length'
    else k
    end

  RESPONSE[:headers][k1] = v.to_s
end

def emit(s)

  RESPONSE[:body] << s.to_s
end

def flush

  body = RESPONSE[:body].join("\n")

  header :length, body.bytesize
  #header 'Connection', 'close'

  c = RESPONSE[:status]
  m = (WEBrick::HTTPStatus.reason_phrase(c) rescue nil)
  puts "Status: #{c} #{m}"
  RESPONSE[:headers].each do |k, v|
    puts "#{k}: #{v}"
    puts "x-#{k}: #{v}" if k == 'Content-Length'
  end
  puts "x-cgi: cigarillo #{CIG_VERSION}"

  puts
  print body

  exit 0
end

def halt(code, message=nil, &block)

  message =
    case message
    when String then message
    when nil then (WEBrick::HTTPStatus.reason_phrase(code) rescue nil)
    else nil
    end
  message ||=
    "Unknown code #{code.inspect}"

  body = (block ? block.call : '')

  puts "Status: #{code} #{message}"
  puts "Content-Type: text/plain"
  puts "Content-Length: #{body.bytesize}"
  puts "Connectionh: close"
  puts
  print body

  exit 0
end

def emit_env

  emit ''
  ENV.each do |k, v|
    emit "* #{k}: #{v.inspect}"
  end
end

def fetch(fpath, max_age_s=24 * 3600, &block)

  s =
    File.exist?(fpath) &&
    (Time.now - File.mtime(fpath) < max_age_s) &&
    (File.read(fpath) rescue nil)
  return s if s

  s = block.call
  File.open(fpath, 'wb') { |f| f.write(s) }

  s
end

