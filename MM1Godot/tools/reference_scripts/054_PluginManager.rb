class PluginManager
  
  def initialize()
    @pluginRegistDataBase = {}
    @pluginDataBase = {}
  end
  
  def have_plugin?(registName)
    return @pluginRegistDataBase.keys.include?(registName)
  end
  
  def getPluginRegistDataBase()
    return @pluginRegistDataBase
  end
  
  def getPluginDataBase()
    return @pluginDataBase
  end
  
  def addPlugin(registName, plugin)
    @pluginDataBase[registName] = plugin
  end
  
  def getPluginByName(registName)
    return @pluginDataBase[registName]
  end
  
  def deletePluginByName(registName)
    @pluginDataBase.delete(registName)
  end
  
  def addRegistPlugin(registName, plugin)
    @pluginRegistDataBase[registName] = plugin
    $game_plugin_states[registName] = plugin.state
  end
  
  def getRegistPluginByName(registName)
    return @pluginRegistDataBase[registName]
  end
  
  def deleteRegistPluginByName(registName)
    @pluginRegistDataBase.delete(registName)
    $game_plugin_states.delete(registName)
  end
  
  def clearPluginRegistInformation()
    @pluginDataBase.clear
    @pluginRegistDataBase.clear
  end
  
  def setPluginStateByName(pluginName, state)
    @pluginRegistDataBase[pluginName].setState(state)
    $game_plugin_states[pluginName] = state
  end
  
  def refreshPlugins()
    keysAry = @pluginRegistDataBase.keys
    for i in 0...keysAry.size
      key = keysAry[i]
#      p key, @pluginRegistDataBase[key].iniFilePath
      if !FileTest.exist?(@pluginRegistDataBase[key].iniFilePath)
        @pluginRegistDataBase.delete(key)
        @pluginDataBase.delete(key)
        $game_plugin_states.delete(key)
      end
    end
  end
  
end