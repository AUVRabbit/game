class Client
  include Socket
  
  def initialize
    @port = 0
    @client_socket = 0
    @messages = []
  end
  
  def get_message
    message = ""
    for i in 0...@messages.size
      message += @messages[i]
    end
    return message
  end
  
  def start(ip, port)
    @port = port
    @ip = ip
    @client_socket = start_as_client(@ip, @port)
    return @client_socekt == 0 ? false : true
  end
    
  def send_message(message)
    message += "\t"
    result = send(@client_socket, message, message.size)
    return result
  end
  
  def recieve_message
    message = ""
    @messages = []
    recieve(@client_socket, message, 100)
    @messages.push(message) if message != ""
    while message != ""
      recieve(@client_socket, message, 100)
      @messages.push(message) if message != ""
    end
  end
  
  def client_break_off
    @port = 0
    @client_socket = 0
    @messages = []
    return break_off
  end
end