class IniFile
  
  attr_reader :filePath
  
  def initialize(filePath)
    @filePath = filePath
    @sectionHash = {}
  end
  
  def iniFileAnalyse()
    unless verifyIniFile()
      return false
    end
    file = File.open(@filePath)
    while text = file.gets()
      text = text.delete("\n")
      if /\[.*\]/ =~ text
        nowSection = text.delete("[").delete("]")
        @sectionHash[nowSection] = {}
      end
      
      if /(.*)=(.*)/ =~ text
        @sectionHash[nowSection][$1] = $2
      end
    end
    file.close
    return true
  end
  
  def verifyIniFile()
    return true
  end
  
  def getValueBySectionAndKey(sectionName, keyName)
    return @sectionHash[sectionName][keyName]
  end
  
end