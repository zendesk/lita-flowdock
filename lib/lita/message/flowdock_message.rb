module Lita
  class FlowdockMessage < Message

    attr_reader :data

    def initialize(robot, body, source, data)
      @data = data
      super(robot, body, source)
    end

    def tags
      binding.pry
      @data['tags'].any? ? data['tags'] : body.scan(/(?<=\s|\A)#(.*?)(?=\s|\z)/).flatten
    end

    def thread_id
      @data['thread_id']
    end

    def new_thread?
      @data['id'] == @data['thread']['initial_message']
    end
  end
end
