class Server
  include Socket
  
  def initialize
    @port = 0
    @server_socket = 0
    @link_count = 0
    @linker_sockets = []
    @messages = []
  end
    
  def get_message(client_index)
    message = ""
    for i in 0...@messages[client_index].size
      message += @messages[client_index][i]
    end
    return message
  end
  
  def start(port, link_count)
    @port = port
    @link_count = link_count
    @server_socket = start_as_server(@port, @link_count)
    return @server_socket == 0 ? false : true
  end
  
  def get_all_linkers
    for i in 0...@link_count
      socket = require_client_socket(i)
      if socket != 0 && !@linker_socekts.include?(socket)
        @linker_sockets.push(socket)
        @messages.push([]) if @messages[i] != nil
      end
    end
  end
  
  def close_socket(socket)
    result = close_socekt(socket)
    if result == 1
      @linker_sockets.delete(socket)
    end
    return result
  end
  
  def close_all_sockets
    @linker_sockets.each do |socket|
      close_socket(socket)
    end
  end
  
  def send_message(client_index, message)
    message += "\t"
    result = send(@linker_sockets[client_index], message, message.size)
    return result
  end
  
  def recieve_message(client_index)
    @messages[client_index] = []
    recieve(@linker_socekts[client_index], message, 100)
    @messages[client_index].push(message) if message != ""
    while message != ""
      recieve(@linker_socekts[client_index], message, 100)
      @messages[client_index].push(message) if message != ""
    end
  end
  
  def recieve_all_messages
    for i in 0...@linker_sockets.size
      recieve_message(@linker_sockets[i])
    end
  end
  
  def server_break_off
    @port = 0
    @server_socket = 0
    @link_count = 0
    @linker_sockets = []
    @messages = []
    return break_off
  end
end