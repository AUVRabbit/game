class Plugin
  
  include PluginModule
  
  attr_reader :appKey
  attr_reader :registName
  attr_reader :editLanguage
  
  def initialize(appKey, registName, editLanguage)
    @appKey = appKey
    @registName = registName
    @editLanguage = editLanguage
    # 如果内核注册失败，不予注册外壳插件
    if $game_plugins.getRegistPluginByName(DEFAULT_REGISTNAME) == nil
      return
    end
    $game_plugins.addPlugin(registName, self)
    registPlugin = $game_plugins.getRegistPluginByName(DEFAULT_REGISTNAME)
    registPlugin.setRegistInformation(@appKey, @registName, @editLanguage)
    $game_plugins.deleteRegistPluginByName(DEFAULT_REGISTNAME)
    registPlugin.setState($game_plugin_states[registPlugin.registName]) if $game_plugin_states[registPlugin.registName] != nil
    $game_plugins.addRegistPlugin(@registName, registPlugin)
  end
  
  def recover()
    return
  end
  
  def main()
    return
  end
  
end