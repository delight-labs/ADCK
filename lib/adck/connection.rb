module ADCK
  class Connection
    def initialize(opts={})
      @host = opts[:host]||ADCK.host
      @port = opts[:port]||ADCK.port
      @pem  = opts[:pem] ||ADCK.pem
      @pass = opts[:pass]||ADCK.pass

      raise "The path to your pem file is not set. (ADCK.pem = /path/to/cert.pem)" unless @pem
      raise "The path to your pem file does not exist!" unless File.exist?(@pem)

      @context      = OpenSSL::SSL::SSLContext.new
      @context.cert = OpenSSL::X509::Certificate.new(File.read(@pem))
      @context.key  = OpenSSL::PKey::RSA.new(File.read(@pem), @pass)
    end

    def sock
      @sock ||= TCPSocket.new(@host, @port)
    end

    def ssl
      @ssl ||= begin
        ssl = OpenSSL::SSL::SSLSocket.new(sock,@context)
        ssl.connect
      end
    end

    def close
      sock.close if @sock
      ssl.close if @ssl
      @sock = nil
      @ssl = nil
    end

    def open
      is_open = open?

      _sock, _ssl = sock, ssl

      yield(sock,ssl) if block_given?

      if !is_open && block_given?
        close
      end

      return _sock, _ssl
    end

    def open?
      !!(@sock || @ssl)
    end

    def send_notification token, message=nil
      if token.is_a?(Notification)
        n = token
      else
        n = Notification.new(token,message)
      end

      send_notifications([n])
    end

    def send_notifications msgs
      open do |sock,ssl|
        msgs.each do |n|
          ssl.write(n.packaged_notification)
        end
      end
    end

    class << self
      def feedback(opts={})
        opts[:host] ||= ADCK.host.sub('gateway','feedback')
        new(opts)
      end
    end
  end
end