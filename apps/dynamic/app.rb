require 'yaml'
require 'slim'
require 'redcarpet'
require 'liquid'
require 'tilt'
require 'sinatra/base'
require 'sinatra/assetpack'
require 'less'
require_relative 'page'
require_relative 'config'

Slim::Engine.set_options(pretty: ENV['RACK_ENV'] != 'production')

# Sinatra app that displays a Jekyll app dynamically.
#
# Why? A couple of reasons:
#
# * We have special requirements for the generated docs. Seemed easier to go the dynamic route.
# * We want to have some dynamic content as well as "static".
#
# Supports several template engines: Markdown, Slim and Erb.
# All templates are pre-processed with Liquid.
#
# Markdown can be used to generate reference documentation. Features include:
#
# * Automatic generation of nested left nav based on Markdown headers
# * Uses Bootstrap scroll spy to collapse/expand nav items
# * Mini-smartypants. --- gets converted to an emdash
# * Use [carousel] to create a carousel of code samples for different languages
# * Use {} in headers to create unique anchors when there are clashes
#
module Dynamic
  class App < Sinatra::Application
    set :root,  File.dirname(__FILE__)

    # TODO: do we need these? Won't they be inferred from the root anyway?
    set :public_folder, Proc.new { File.join(root, 'public') }
    set :views, Proc.new { File.join(root, 'views') }

    register Sinatra::AssetPack
    assets {
      css_dir = 'assets/css'
      serve '/css', from: css_dir
      Less.paths << File.join(App.root, css_dir)

      serve '/bower_components', from: 'bower_components'

      # We're listing the other files in main.less rather than here
      css :main, '/css/style.css', ['/css/main.css']
      css_compression :simple

      serve '/js', from: 'assets/js'
      js :main, '/js/main.js', [
        '/bower_components/jquery/dist/jquery.js',
        '/bower_components/bootstrap/dist/js/bootstrap.min.js',
        '/bower_components/slick-carousel/slick/slick.js',
        '/js/*.js'
      ]
      js_compression :jsmin

      serve '/images', from: 'assets/images'
    }

    extend Config
    CONFIG = load_config(ENV['RACK_ENV'])

    pages = Page.all(CONFIG, views)

    CONFIG['site']['posts'] = pages.select(&:post?).sort do |a, b|
      b.date <=> a.date
    end

    CONFIG['site']['events'] = pages.select(&:event?).sort do |a, b|
      b.start_time <=> a.start_time
    end

    pages.each do |page|
      next unless page.primary?

      get page.path do
        headers.merge!(page.headers)

        timestamps = pages.map(&:timestamp) + [File.mtime(__FILE__)]
        last_modified timestamps.max

        page.render(self)
      end
    end

    before do
      cache_control :public
    end

    before /(.*)\.html/ do
      url = params[:captures][0]
      redirect to(url), 301
    end

    helpers do
      def nav_class(slug, name)
        slug == name ? 'active' : nil
      end

      def edit_url(template_path)
        "#{CONFIG['site']['edit_url']}/#{template_path}"
      end
    end
  end
end
