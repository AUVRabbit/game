module Socket
  
  #--------------------------------------------------------------------------
  # ● API聲明
  #--------------------------------------------------------------------------
  Start_As_Server = Win32API.new("winsock.dll", "Start_As_Server", "ii", "i")
  Start_As_Client = Win32API.new("winsock.dll", "Start_As_Client", "pi", "i")
  RequireClientSocket = Win32API.new("winsock.dll", "RequireClientSocket", "i", "i")
  Send = Win32API.new("winsock.dll", "Send", "ipi", "i")
  Recv = Win32API.new("winsock.dll", "Recv", "ipi", "i")
  CloseSocket = Win32API.new("winsock.dll", "CloseSocket", "i", "i")
  BreakOff = Win32API.new("winsock.dll", "BreakOff", "v", "i")
  
  #--------------------------------------------------------------------------
  # ● 模塊方法
  #--------------------------------------------------------------------------  
  module_function
  
  #--------------------------------------------------------------------------
  # ● Start_As_Server
  # const unsigned short Listen_Port : 端口
  # const UINT Link_Count            : 最大連接數
  #
  # 返回值                           : 监听套接字
  #--------------------------------------------------------------------------
  def start_as_server(port, link_count)
    return Start_As_Server.call(port, link_count)
  end
  
  #--------------------------------------------------------------------------
  # ● Start_As_Client
  # const char * const Server_IP     : Server連接IP
  # const unsigned short Server_Port : 端口
  #
  # 返回值                           : 服務通信套接字
  #--------------------------------------------------------------------------
  def start_as_client(ip, port)
    return Start_As_Client.call(ip, port)
  end
  
  #--------------------------------------------------------------------------
  # ● RequireClientSocket
  # int ClinetCount                  : 連接客戶索引
  #
  # 返回值                           : 客户通信套接字
  #--------------------------------------------------------------------------
  def require_client_socket(index)
    return RequireClientSocket.call(index)
  end
  
  #--------------------------------------------------------------------------
  # ● Send
  # SOCKET socket                    : 通信套接字
  # const char * lpBuffer            : 發送的消息
  # int nBufferLen                   : 消息長度
  #
  # 返回值                           : 0：失敗 1：成功
  #--------------------------------------------------------------------------
  def send(socket, message, length)
    Send.call(socket, message, length)
  end
  
  #--------------------------------------------------------------------------
  # ● Recv
  # SOCKET socket                    : 通信套接字
  # const char * lpBuffer            : 發送的消息
  # int nBufferLen                   : 消息長度
  #
  # 返回值                           : 0：失敗 1：成功
  #--------------------------------------------------------------------------
  def recv(socket, message, length)
    Recv.call(socket, message, length)
  end
  
  #--------------------------------------------------------------------------
  # ● close_socket
  # SOCKET socket                    : 通信套接字
  #
  # 返回值                           : 0：失敗 1：成功
  #--------------------------------------------------------------------------
  def close_socket(socket)
    return CloseSocket.call(socket)
  end
  
  #--------------------------------------------------------------------------
  # ● Recv
  # 返回值                           : 0：失敗 1：成功
  #--------------------------------------------------------------------------
  def break_off()
    return BreakOff.call()
  end
end