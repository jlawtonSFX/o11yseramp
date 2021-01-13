#!/usr/bin/env ruby -rrubygems

require 'sinatra'
require 'opentracing'
require 'jaeger/client'
require 'rack/tracer'

puts ENV['SIGNALFX_SERVICE_NAME']
puts ENV['SIGNALFX_INGEST_URL']


OpenTracing.global_tracer = Jaeger::Client.build(
  service_name: 'service_name',
  reporter: Jaeger::Reporters::RemoteReporter.new(
    sender: Jaeger::HttpSender.new(
      url: ENV['SIGNALFX_INGEST_URL'],
      headers: { 'key' => 'value' }, # headers key is optional
      encoder: Jaeger::Encoders::ThriftEncoder.new(service_name: ENV['SIGNALFX_SERVICE_NAME'])
    ),
    flush_interval: 10
  )
)

use Rack::Tracer


get '/' do
  "#{hello} world"
end


def hello
  client = Net::HTTP.new("localhost",4567)
  req = Net::HTTP::Get.new("/")
  OpenTracing.inject(env['rack.span'].context, OpenTracing::FORMAT_RACK, req)
  client.request(req).body
end

