module Lita
  class FlowdockSource < Source
    attr_reader :message_id

    def initialize(user: nil, room: nil, private_message: false, message_id: nil)
      room = room_id_to_room_object(room)
      super(user: user, room: room, private_message: private_message)
      @message_id = message_id
    end

    def room_id_to_room_object(room)
      return room unless Lita.redis.exists("flows_id/#{room}")
      room_name = Lita.redis.get("flows_id/#{room}")
      Room.new(room, {name: room_name})
    end
  end
end
