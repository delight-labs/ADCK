require File.dirname(__FILE__) + '/../spec_helper'

describe ADCK::Message do

  context "message is too long" do
    let(:message) {'hello ' *100}

    it "should truncate with dots default" do
      msg = ADCK::Message.new(body: message, truncate: true)
      json = msg.package

      MultiJson.load(json)['aps']['alert']['body'][-3,3].should == '...'
    end

    it "should truncate with defined value" do
      msg = ADCK::Message.new(body: message, truncate: '[end]')
      json = msg.package

      MultiJson.load(json)['aps']['alert']['body'][-5,5].should == '[end]'
    end

    it "should raise error" do
      msg = ADCK::Message.new(body: message)
      expect {msg.package}.to raise_error(ADCK::Message::PayloadTooLarge)
    end
  end

end
