class RegistPlugin
  
  include PluginModule
  
  attr_reader :appKey
  attr_reader :registName
  attr_reader :editLanguage
  attr_reader :iniFile
  attr_reader :typeName
  attr_reader :version
  attr_reader :scriptData
  attr_reader :state
  attr_reader :iniFilePath
  attr_reader :pluginName
  attr_reader :pluginAuthorName
  attr_reader :releaseDate
  
  def initialize(appKey, registName, editLanguage)
    @appKey = appKey
    @registName = registName
    @editLanguage = editLanguage
    @state = PLUGINSTATE_ON
  end
  
  def setRegistInformation(appKey, registName, editLanguage)
    @appKey = appKey
    @registName = registName
    @editLanguage = editLanguage
  end
  
  def initIniFile(filePath)
    
    @iniFilePath = filePath
    @iniFile = IniFile.new(filePath)
    @iniFile.iniFileAnalyse()
    
    initPluginType(@iniFile.getValueBySectionAndKey(INIFILE_MAINSECTIONNAME, INIFILE_PLUGINTYPENAME))
    initPluginVersion(@iniFile.getValueBySectionAndKey(INIFILE_MAINSECTIONNAME, INIFILE_VERSIONNAME))
    setPluginName(@iniFile.getValueBySectionAndKey(INIFILE_MAINSECTIONNAME, INIFILE_PLUGINNAME))
    setAuthorName(@iniFile.getValueBySectionAndKey(INIFILE_MAINSECTIONNAME, INIFILE_AUTHORNAME))
    setReleaseDate(@iniFile.getValueBySectionAndKey(INIFILE_MAINSECTIONNAME, INIFILE_RELEASEDATE))
  end
  
  def initPluginType(typeName)
    @typeName = typeName
  end
  
  def initPluginVersion(version)
    @version = version
  end
  
  def installPlugin(basePath)
    unless verifyPlugin()
      return false
    end
    $game_plugins.addRegistPlugin(@registName, self)
    readPluginData(basePath)
  end
  
  def verifyPlugin()
    return true
  end
  
  def readPluginData(basePath)
    @scriptData = ""
    file = File.open(basePath + @iniFile.getValueBySectionAndKey(INIFILE_MAINSECTIONNAME, INIFILE_SCRIPTFILEPATH))
    @scriptData = EasyConv.s2u(file.read())
    file.close
  end
  
  def setState(state)
    @state = state
    $game_plugin_states[@registName] = state
  end
  
  def setPluginName(name)
    @pluginName = name
  end
  
  def setAuthorName(name)
    @pluginAuthorName = name
  end
  
  def setReleaseDate(date)
    @releaseDate = date
  end
  
end