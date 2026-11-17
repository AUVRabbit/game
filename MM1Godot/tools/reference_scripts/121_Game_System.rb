class Game_System
  attr_accessor :information
  attr_accessor :animation
  attr_accessor :sound
  attr_accessor :moneybell
  attr_accessor :have_saved
  attr_accessor :self_file_index
  
  alias :tm_initialize :initialize
  def initialize
    tm_initialize
    @information = 5
    @animation = true
    @sound = true
    @moneybell = 0
    @have_saved = false
    @self_file_index = 0
  end
end