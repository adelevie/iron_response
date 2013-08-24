module IronResponse
  class Log
    def initialize(text)
      @text = text
    end

    def to_s
      @text
    end
  end
end