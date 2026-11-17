#==============================================================================
# ■ EasyConv
#------------------------------------------------------------------------------
#   轉碼用的模塊。
#==============================================================================
module EasyConv

  #--------------------------------------------------------------------------
  # ● 常量定义
  #--------------------------------------------------------------------------
  CP_ACP = 0
  CP_UTF8 = 65001

  #--------------------------------------------------------------------------
  # ● 模块函数
  #--------------------------------------------------------------------------
  module_function
  
  #--------------------------------------------------------------------------
  # ● 转码
  #--------------------------------------------------------------------------
  def s2u(text)

    m2w = Win32API.new('kernel32', 'MultiByteToWideChar', 'ilpipi', 'i')
    w2m = Win32API.new('kernel32', 'WideCharToMultiByte', 'ilpipipp', 'i')

    len = m2w.call(CP_ACP, 0, text, -1, nil, 0)
    buf = "\0" * (len*2)
    m2w.call(CP_ACP, 0, text, -1, buf, buf.size/2)

    len = w2m.call(CP_UTF8, 0, buf, -1, nil, 0, nil, nil)
    ret = "\0" * len
    w2m.call(CP_UTF8, 0, buf, -1, ret, ret.size, nil, nil)
    ret[-1] = ""
    
    return ret
  end

  #--------------------------------------------------------------------------
  # ● 转码
  #--------------------------------------------------------------------------
  def u2s(text)
   
    m2w = Win32API.new('kernel32', 'MultiByteToWideChar', 'ilpipi', 'i')
    w2m = Win32API.new('kernel32', 'WideCharToMultiByte', 'ilpipipp', 'i')

    len = m2w.call(CP_UTF8, 0, text, -1, nil, 0)
    buf = "\0" * (len*2)
    m2w.call(CP_UTF8, 0, text, -1, buf, buf.size/2)

    len = w2m.call(CP_ACP, 0, buf, -1, nil, 0, nil, nil)
    ret = "\0" * len
    w2m.call(CP_ACP, 0, buf, -1, ret, ret.size, nil, nil)
   
    return ret
  end
end