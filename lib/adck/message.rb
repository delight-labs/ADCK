module ADCK
  class Message
    ALERT_FIELDS = [
      :body, :action_loc_key, :loc_key, :loc_args, :launch_image
    ]
    FIELDS = ALERT_FIELDS+[
      :alert, :badge, :sound, :other
    ]
    attr_accessor *FIELDS
    attr_accessor :connection

    def initialize(message)
      if message.is_a? Hash
        @validate = message[:validate]
        @freeze = message[:freeze]
      end

      set_values_from_arg(message)

      self.other ||= {}
    end

    def alert
      a = {}

      a[:body] = body if body

      if action_loc_key # is not false or nil
        a[:'action-loc-key'] = action_loc_key
      elsif action_loc_key == false
        a[:'action-loc-key'] = nil
      end

      a[:'loc-key'] = loc_key unless loc_key.nil?
      a[:'loc-args'] = loc_args unless loc_args.nil?
      a[:'launch-image'] = launch_image unless launch_image.nil?

      a
    end

    def alert=val
      set_values_from_arg val, ALERT_FIELDS
    end

    def action_loc_key=val
      # A nil action-loc-key is significant so set to false for later
      # detection
      @action_loc_key = val.nil? ? false : val
    end

    def aps
      a = {}
      _alert = alert
      a[:alert] = _alert unless _alert.empty?
      a[:badge] = badge if badge
      a[:sound] = sound if sound
      a
    end

    def payload(options={})
      other.merge(aps: aps)
    end
    alias as_json payload

    def validate!
      return to_json if @validate == false

      if loc_args && !loc_args.is_a?(Array)
        raise InvalidAttribute, 'loc-args should be an array'
      end

      if body && !body.is_a?(String)
        raise InvalidAttribute, 'body needs to be a string'
      end

      if action_loc_key && (action_loc_key != false || !action_loc_key.is_a?(String))
        raise InvalidAttribute, 'action-loc-key needs to be set to false/nil/string'
      end

      if badge && !badge.is_a?(Integer)
        raise InvalidAttribute, 'badge needs to be a number or nil'
      end

      json = to_json

      if json.bytesize > 255
        raise PayloadTooLarge, "Payload must be less than 256 bytes, is #{json.bytesize}bytes"
      end

      json
    end

    def bytesize
      @package ? @package.bytesize : to_json.bytesize
    end

    def to_json(options={})
      MultiJson.dump(payload(options))
    end

    def package
      if @freeze == false
        validate!
      else
        unless @package
          @package = validate!
          freeze
        end
        @package
      end
    end

    def self.build(opts)
      opts.is_a?(self) ? opts : new(opts)
    end

    def send_to(device_tokens)
      conn = connection || Connection.new

      notifications = Array(device_tokens).collect do |token|
        Notification.new(token,self)
      end

      conn.send_notifications(notifications)
    end

    def dup
      m = super()
      m.instance_variable_set :@package, nil
      m
    end

  private

    def set_values_from_arg val, fields=nil
      if val.is_a?(String)
        self.body = val
      elsif val.is_a?(Hash)
        (fields || FIELDS).each do |key|
          if val.has_key?(key)
            send("#{key}=",val[key])
          end
        end
      else
        raise "Message needs to have either a hash or string"
      end
    end

    class PayloadTooLarge < RuntimeError; end
    class InvalidAttribute < RuntimeError; end
  end
end