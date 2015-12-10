require 'spec_helper'

describe Lita::FlowdockSource do
  let(:room){ Lita::Room.new(room_id, {name: "Main"}) }
  let(:room_id) { "123123123" }

  subject{ Lita::FlowdockSource.new(room: room_id) }

  describe "with a room" do
    it "looks up rooms" do
      expect(Lita.redis).to receive(:exists).with("flows_id/#{room_id}").and_return(true)
      expect(Lita.redis).to receive(:get).with("flows_id/#{room_id}").and_return("Main")
      expect(subject.room_object.id).to eql(room_id)
      expect(subject.room_object.name).to eql(room.name)
    end

    describe "if the room doesn't exist" do
      it "defaults to the passed in room" do
        expect(Lita.redis).to receive(:exists).with("flows_id/#{room_id}").and_return(true)
        expect(subject.room).to eql(room_id)
      end
    end
  end

  describe "without a room" do
    subject{ Lita::FlowdockSource.new(user: "Bob") }

    it "skips the room lookup if no room is given" do
      expect(Lita.redis).not_to receive(:get).with("flows/#{room}")
      expect(subject.room).to be_nil
      expect(subject.user).to eql("Bob")
    end
  end


  describe "with a message id" do
    subject{ Lita::FlowdockSource.new(room: room_id, message_id: 123) }

    it "saves the message id" do
      allow(Lita.redis).to receive(:get).with("flows/#{room}").and_return(room_id)
      expect(subject.message_id).to eql(123)
    end
  end
end
