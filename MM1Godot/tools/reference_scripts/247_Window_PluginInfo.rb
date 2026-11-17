class Window_PluginInfo < Window_Base
  include MM_DataBase
  
  def initialize
    super(60, 5, 540, 120)
    self.back_opacity = 0
    self.opacity = 0
    self.contents = Bitmap.new(width - 32, height - 32)
  end
  
  def refresh_plugin(plugin)
    return if plugin == nil
    
    if self.contents != nil
      self.contents.dispose
      self.contents = nil
    end
    self.contents = Bitmap.new(width - 32, height - 32)
    
    name = plugin.pluginName
    author = plugin.pluginAuthorName
    version = plugin.version
    type = plugin.typeName
    date = plugin.releaseDate
    self.contents.draw_text(0, 0, 120, 32, "插件名：")
    self.contents.draw_text(0, 24, 120, 32, "作者：")
    self.contents.draw_text(0, 48, 120, 32, "版本：")
    self.contents.draw_text(260, 0, 120, 32, "发布时间：")
    self.contents.draw_text(260, 24, 120, 32, "插件类型：")
    
    self.contents.draw_text(0 + 84, 0, 120, 32, name)
    self.contents.draw_text(0 + 84, 24, 120, 32, author)
    self.contents.draw_text(0 + 84, 48, 120, 32, version)
    self.contents.draw_text(260 + 120, 0, 120, 32, date)
    self.contents.draw_text(260 + 120, 24, 120, 32, type)
  end
end