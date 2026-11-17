module PluginModule
  
  #DEFAULT_
  DEFAULT_APPKEY = "_common"
  DEFAULT_REGISTNAME = "_common"
  DEFAULT_EDITLANGUAGE = "ruby"
  
  #REGISTTYPE_EXECUTE_
  REGISTTYPE_EXECUTE = "Execute"
  
  #INIFILE_
  INIFILE_MAINSECTIONNAME = "MainSection"
  INIFILE_PLUGINTYPENAME = "PluginType"
  INIFILE_VERSIONNAME = "Version"
  INIFILE_SCRIPTFILEPATH = "ScriptFilePath"
  INIFILE_PLUGINNAME = "PluginName"
  INIFILE_AUTHORNAME = "AuthorName"
  INIFILE_RELEASEDATE = "ReleaseDate"
  
  #PLUGINSTATE_
  PLUGINSTATE_ON = 0
  PLUGINSTATE_OFF = 1
  
  MD5 = Win32API.new("MD5.DLL", "GetFileMD5", "pp", "n")
  
  module_function
  
  def md5Verify(fileName)
    buffer = " " * 32
    result = MD5.call(fileName, buffer)
    if result == 1
      return true, buffer
    else
      return false, buffer
    end
  end
  
  def registPlugins()
    $game_plugins.clearPluginRegistInformation()
    folderDir = Dir.open("Plugin")
    while folderName = folderDir.read()
      fileDir = Dir.open("Plugin/" + folderName)
      haveIniFile  = false
      while fileName = fileDir.read()
        if("set.ini" == fileName)
          haveIniFile = true
          break
        end
      end
      if haveIniFile == true
        plugin = RegistPlugin.new(DEFAULT_APPKEY, DEFAULT_REGISTNAME, DEFAULT_EDITLANGUAGE)
        plugin.initIniFile("Plugin/" + folderName + "/" + fileName)
        plugin.installPlugin("Plugin/" + folderName + "/")
        eval(plugin.scriptData)
        if $game_plugin_states[plugin.registName] != nil
          $game_plugins.setPluginStateByName(plugin.registName, $game_plugin_states[plugin.registName])
        else
          $game_plugin_states[plugin.registName] = plugin.state
        end
      end
    end
    keys = $game_plugin_states.keys
    for registName in keys
      if !$game_plugins.have_plugin?(registName)
        $game_plugins.delete(registName)
      end
    end
  end
  
  def installPlugins()
    @registPlugin = $game_plugins.getPluginRegistDataBase()
    keys = @registPlugin.keys.sort!
    for key in keys
      plugin = $game_plugins.getRegistPluginByName(key)
      if plugin.state == PLUGINSTATE_ON
        eval(plugin.scriptData)
        if plugin.typeName == REGISTTYPE_EXECUTE
          registName = plugin.registName
          plugin = $game_plugins.getPluginByName(registName)
          plugin.main()
        end
      end
    end
  end
  
end