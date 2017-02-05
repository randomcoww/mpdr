class MpdClient

  attr_accessor :connection

  def self.client
    mpdclient = new
    mpdclient.connection = MPD.new('localhost', 6600, {:callbacks => true})
    mpdclient.connect
    mpdclient
  end

  def connect
    unless connection.connected?
      connection.connect
    end
  end

  def disconnect
    if connection.connected?
      connection.disconnect
    end
  end

  def path_info(path)
    connection.send_command(:lsinfo, path)
  end
end
