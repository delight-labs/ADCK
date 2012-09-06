require 'forwardable'
require 'socket'
require 'openssl'
require 'json'
require 'adck/version'
require 'multi_json'

module ADCK

  @host = 'gateway.sandbox.push.apple.com'
  @port = 2195
  # openssl pkcs12 -in mycert.p12 -out client-cert.pem -nodes -clcerts
  @pem = nil # this should be the path of the pem file not the contentes
  @pass = nil

  class << self
    attr_accessor :host, :pem, :port, :pass

    def send_notification token, message=nil
      if token.is_a?(Notification)
        n = token
      else
        n = Notification.new(token,message)
      end

      send_notifications([n])
    end

    def send_notifications(notifications)
      Connection.new.open do |sock,ssl|
        notifications.each do |n|
          ssl.write(n.packaged_notification)
        end
      end
    end

    def feedback
      apns_feedback = []

      Connection.feedback.open do |sock, ssl|
        while line = sock.gets   # Read lines from the socket
          line.strip!
          f = line.unpack('N1n1H140')
          apns_feedback << [Time.at(f[0]), f[2]]
        end
      end

      apns_feedback
    end
  end

end

def ADCK val, msg=nil
  if val.is_a?(Array)
    ADCK.send_notifications(val)
  elsif val.is_a?(ADCK::Notification)
    ADCK.send_notifications([val])
  else
    ADCK.send_notification(val,msg)
  end
end

require 'adck/notification'
require 'adck/message'
require 'adck/connection'
