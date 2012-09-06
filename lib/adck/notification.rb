module ADCK
  class Notification
    extend Forwardable
    attr_accessor :device_token, :message
    def_delegators :message, :alert, :badge, :sound, :other, :as_json

    def initialize(device_token, message)
      self.device_token = device_token
      self.message = Message.build(message)
    end

    def packaged_notification
      pt = packaged_token
      pm = message.package
      [0, 0, 32, pt, 0, pm.bytesize, pm].pack("ccca*cca*")
    end

    def packaged_token
      [device_token.gsub(/[\s|<|>]/,'')].pack('H*')
    end

    def packaged_message
      message.package
    end

  end
end
