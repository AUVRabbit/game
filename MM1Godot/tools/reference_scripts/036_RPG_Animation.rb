#==============================================================================
# ■ RPG
#------------------------------------------------------------------------------
#    RPG模塊動畫音樂播放追加定義
#------------------------------------------------------------------------------

module RPG
  class Sprite < ::Sprite
    def animation_process_timing(timing, hit)
      if (timing.condition == 0) or
         (timing.condition == 1 and hit == true) or
         (timing.condition == 2 and hit == false)
        if timing.se.name != ""
          se = timing.se
          $game_system.se_play(se)
        end
        case timing.flash_scope
        when 1
          self.flash(timing.flash_color, timing.flash_duration * 2)
        when 2
          if self.viewport != nil
            self.viewport.flash(timing.flash_color, timing.flash_duration * 2)
          end
        when 3
          self.flash(nil, timing.flash_duration * 2)
        end
      end
    end
  end
end