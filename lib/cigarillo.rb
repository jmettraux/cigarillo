
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

  flush_error($!, $@) if $!

  body = RESPONSE[:body].join("\n")

  header :length, body.bytesize
  #header 'Connection', 'close'

  c = RESPONSE[:status]

  m =
    RESPONSE[:message] ||
    (WEBrick::HTTPStatus.reason_phrase(c) rescue nil) ||
    "Unknown Code #{c.inspect}"

  puts "Status: #{c} #{m}"
  RESPONSE[:headers].each do |k, v|
    puts "#{k}: #{v}"
    puts "x-#{k}: #{v}" if k == 'Content-Length'
  end
  puts "x-cgi: cigarillo #{CIG_VERSION}"
  #puts "x-error: #{$!.inspect}" if $!
  #puts "x-error-at: #{caller.inspect}" if $!

  puts
  print body
end

def flush_error(err, trc)

  RESPONSE[:status] = 500
  RESPONSE[:message] = nil
  RESPONSE[:headers] = {}

  header :type, 'text/plain'

  b = []
  b << '500'
  b << ''
  b << err.inspect
  b << ''
  b.concat(trc)

  RESPONSE[:body] = b
end

def halt(code, message=nil, &block)

  RESPONSE[:status] = code
  RESPONSE[:message] = message
  RESPONSE[:headers] = {}

  header :type, 'text/plain'

  RESPONSE[:body] = [ (block ? block.call : '') ]

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

at_exit do

  flush

  exit 0
end

