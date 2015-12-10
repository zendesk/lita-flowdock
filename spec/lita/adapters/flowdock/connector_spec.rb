require 'spec_helper'

describe Lita::Adapters::Flowdock::Connector, lita: true do
  def with_eventsource(subject, queue)
    thread = Thread.new { subject.run(url, queue) }
    thread.abort_on_exception = true
    yield queue.pop
    subject.shut_down
    thread.join
  end

    subject {
      described_class.new(robot, api_token, organization, flows, fd_client)
    }

  let(:registry) { Lita::Registry.new }
  let(:source) { instance_double('Lita::FlowdockSource', private_message?: false, message_id: message_id) }
  let(:robot) { Lita::Robot.new(registry) }
  let(:api_token) { 'a8f828cfe7efc65b53b3de06761e83e9' }
  let(:organization) { 'lita-test' }
  let(:flows) { ['testing'] }
  let(:fd_client) { instance_double('Flowdock::Client') }
  let(:users) { [ user_hash(1), user_hash(2) ] }
  let(:flows) { [ flow_hash(1) ] }
  let(:queue) { Queue.new }
  let(:url) { "http://example.com" }

  describe "#new" do
    subject { described_class }

    it "creates users" do
      expect(fd_client).to receive(:get).with('/users').and_return(users)
      allow(fd_client).to receive(:get).with('/flows').and_return([])
      expect(Lita::Adapters::Flowdock::UsersCreator).to receive(
        :create_users
      ).with(users)
      subject.new(robot, api_token, organization, flows, fd_client)
    end

    it "stores flows" do
      allow(fd_client).to receive(:get).with('/users').and_return([])
      allow(fd_client).to receive(:get).with("/flows").and_return(flows)
      expect(Lita.redis).to receive(:set).with("flows/#{flows[0]['parameterized_name']}", flows[0]['id'])
      expect(Lita.redis).to receive(:set).with("flows_id/#{flows[0]['id']}", flows[0]['parameterized_name'])
      subject.new(robot, api_token, organization, flows, fd_client)
    end
  end

  describe "#run" do
    before do
      allow(fd_client).to receive(:get).with('/users').and_return([])
      allow(fd_client).to receive(:get).with('/flows').and_return([])
    end

    it "starts the reactor" do
      with_eventsource(subject, queue) do
        expect(EM.reactor_running?).to be_truthy
      end
    end

    it "creates the event source" do
      with_eventsource(subject, queue) do |source|
        expect(source).to be_an_instance_of(EventMachine::EventSource)
      end
    end
  end

  describe "#send_messages" do
    let(:target) { source }
    let(:message) { 'foo' }
    let(:message_id) { 1234 }

    before do
      allow(fd_client).to receive(:get).with('/users').and_return(users)
      allow(fd_client).to receive(:get).with('/flows').and_return(flows)
      allow(source).to receive(:room).and_return('testing:lita-test')
      allow(source).to receive(:private_message).and_return(false)
    end

    it "sends messages" do
      expect(fd_client).to receive(:chat_message).with(flow: target.room, message_id: message_id, content: message)
      subject.send_messages(target, [message], true)
    end
  end
end
