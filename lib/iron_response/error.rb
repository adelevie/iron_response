module IronResponse
  class Error
    def initialize(text)
      @text = text
    end

    def to_s
      "IronWorker error: #{@text}"
    end
  end
end