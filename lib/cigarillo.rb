
require 'uri'
require 'webrick'

PARAMS = URI.decode_www_form(ENV['QUERY_STRING'])

def halt(code, message=nil, &block)

  message =
    case message
    when String then message
    when nil then (WEBrick::HTTPStatus.reason_phrase(code) rescue nil)
    else nil
    end
  message ||=
    "Unknown code #{code.inspect}"

  puts "Status: #{code} #{message}"
  puts "Content-Type: text/plain"
  puts
  puts block ? block.call : ''

  exit 0
end

