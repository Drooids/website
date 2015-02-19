require 'redcarpet'
require 'pygments'

module Cucumber
  class Reference < Redcarpet::Render::HTML
    def block_code(code, language)
      Pygments.highlight(code, lexer: language)
    end
  end
end