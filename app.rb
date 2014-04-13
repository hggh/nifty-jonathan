require 'erb'
require 'json'
require 'yaml'
require "net/http"
require "uri"
require 'sinatra/base'
require 'sinatra/partial'

module ApplicationHelper
  def status2bootstrap(status)
    case status
      when "UP"
        "success"
      when "DOWN"
        "critical"
      when "OK"
        "success"
      when "WARNING"
        "warning"
      when "CRITICAL"
        "danger"
      else
        "default"
    end
  end
end

class IspApp < Sinatra::Base
  register Sinatra::Partial
  helpers ApplicationHelper
  set :partial_template_engine, :erb
  enable :partial_underscores
  def initialize
    if settings.environment == :development
      config_filename = "conf/development.yml"
    else
      config_filename = "conf/production.yml"
    end
    @settings = YAML.load_file(config_filename)
    super()
  end

  get '/ajax/nagios' do
    nagios_service_group_getter = IspApp::Nagios::Servicegoup.new(@settings["nagios"])
    @nagios_service_group = nagios_service_group_getter.content
    nagios_problems_getter = IspApp::Nagios::Problems.new(@settings["nagios"])
    @nagios_problems = nagios_problems_getter.content
 
    erb :_nagios, :layout => false, :locals => { :nagios_service_group => @nagios_service_group, :nagios_problems => @nagios_problems }
  end

  get '/' do
    @tabs = Array.new
    nagios_service_group_getter = IspApp::Nagios::Servicegoup.new(@settings["nagios"])
    @nagios_service_group = nagios_service_group_getter.content

    nagios_problems_getter = IspApp::Nagios::Problems.new(@settings["nagios"])
    @nagios_problems = nagios_problems_getter.content

    if @settings["tabs"] and @settings["tabs"].count > 0
      isp_tabs = IspApp::Tabs.new(@settings["tabs"])
      @tabs = isp_tabs.tabs
    end
    erb :index
  end
end

class IspApp::Tabs
  def initialize(settings)
    @settings = settings
  end

  def tabs
    tabs = Array.new
    @settings.each do |tab|
      tabs << IspApp::Tab.new(tab)
    end
    tabs
  end
end

class IspApp::Tab
  def initialize(settings)
    @settings = settings
  end

  def name
    @settings["name"]
  end

  def title
    @settings["title"]
  end

  def graphs
    graphs = Array.new
    @settings["graphs"].each do |g|
      graphs << IspApp::Graph.new(g)
    end
    graphs
  end
end

class IspApp::Graph
  def initialize(settings)
    @settings = settings
  end

  def title
    @settings["title"]
  end

  def url
    @settings["url"]
  end
end

class IspApp::Nagios
  def initialize(settings)
    @settings = settings
  end
  
  def fetch(url)
    result = ""
    begin
      uri = URI.parse(url)
      http = Net::HTTP.new(uri.host, uri.port)
      request = Net::HTTP::Get.new(uri.request_uri)
      if @settings["username"]
        request.basic_auth(@settings["username"], @settings["password"])
      end
      response = http.request(request)
      if response.code == "200"
        result = response.body
      end
    rescue Exception => e
      # FIXME: log errors
    end
    result
  end
end

class IspApp::Nagios::Servicegoup
  def initialize(settings)
    @result = false
    url = settings["servicegroup"]["url"]
    nagios = IspApp::Nagios.new(settings)
    response = nagios.fetch(url)
    if response != ""
      @result = JSON.parse(response)
    end
  end

  def content
    @result
  end
end

class IspApp::Nagios::Problems
  def initialize(settings)
    @service_filter = settings["problems"]["service_filter"]
    @result = false
    url = settings["problems"]["url"]
    nagios = IspApp::Nagios.new(settings)
    response = nagios.fetch(url)
    if response != ""
      @result = JSON.parse(response)
    end
  end

  def content
    if @result != false and @service_filter
      rexp = Regexp.new(@service_filter)
      @result["status"]["service_status"].reject! { |service|  rexp.match(service["service_description"]) }
    end
    @result
  end
end

IspApp.run!
