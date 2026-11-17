#==============================================================================
# ■ Game_System
#------------------------------------------------------------------------------
#     重寫音樂播放的方法，在這裡考慮到效率問題，在初次播放音樂的時候就將其實地
# 址存入了一個Hash之中，加快以後的訪問效率。
#==============================================================================

if FmodSoundSystem::REWRITE == true && $init_result != 0
  class Game_System
    include FmodSoundSystem
    #--------------------------------------------------------------------------
    # ● 定义实例变量
    #--------------------------------------------------------------------------
    attr_accessor :bgm_hash
    attr_accessor :bgs_hash
    attr_accessor :se_hash
    attr_accessor :me_hash
    
    #--------------------------------------------------------------------------
    # ● 初始化对像
    #--------------------------------------------------------------------------
    alias :old_initialize :initialize
    def initialize
      old_initialize
      @bgm_hash = {}
      @bgs_hash = {}
      @se_hash = {}
      @me_hash = {}
    end
    
    #--------------------------------------------------------------------------
    # ● 演奏 BGM
    #     bgm : 演奏的 BGM
    #--------------------------------------------------------------------------
    def bgm_play(bgm)
      @playing_bgm = bgm
      return if @sound == nil
      if FmodSoundSystem.me_is_playing == 1
        Thread.new do
          while FmodSoundSystem.me_is_playing == 1
            bgm_stop if FmodSoundSystem.bgm_is_playing == 1
          end
          bgm_play(@playing_bgm)
        end
      end
      if bgm != nil and bgm.name != ""
        if @bgm_hash[bgm.name] == nil
          name_ary = Dir.glob("Audio/BGM/*.*")
          for i in 0...name_ary.size
            temp_name_ary = name_ary[i].split(/\//)
            bgm_name = temp_name_ary[temp_name_ary.size - 1]
            bgm_name = "" if bgm_name == nil
            if /#{bgm.name}\..+/ =~ bgm_name
              break
            end
          end
          if bgm_name == nil
            bgm_name = ""
          end
          if /#{bgm.name}\..+/ =~ bgm_name
            @bgm_hash[bgm.name] = bgm_name if bgm_name != ""
          else
            bgm_name = ""
          end
        else
          bgm_name = @bgm_hash[bgm.name]
        end
        if bgm_name == ""
          Audio.bgm_play(RTP + "/Audio/BGM/" + bgm.name + ".mid",\
                         bgm.volume, bgm.pitch)
        else
          Audio.bgm_play("Audio/BGM/" + bgm_name,\
                        bgm.volume, bgm.pitch)
        end
      else
        Audio.bgm_stop
      end
      Graphics.frame_reset
    end

    #--------------------------------------------------------------------------
    # ● 演奏 BGS
    #     bgs : 演奏的 BGS
    #--------------------------------------------------------------------------
    def bgs_play(bgs)
      @playing_bgs = bgs
      return if @sound == nil
      if bgs != nil and bgs.name != ""
        if @bgs_hash[bgs.name] == nil
          name_ary = Dir.glob("Audio/BGS/*.*")
          for i in 0...name_ary.size
            temp_name_ary = name_ary[i].split(/\//)
            bgs_name = temp_name_ary[temp_name_ary.size - 1]
            bgs_name = "" if bgs_name == nil
            if /#{bgs.name}\..+/ =~ bgs_name
              break
            end
          end
          if bgs_name == nil
            bgs_name = ""
          end
          if /#{bgs.name}\..+/ =~ bgs_name
            @bgs_hash[bgs.name] = bgs_name if bgs_name != ""
          else
            bgs_name = ""
          end
        else
          bgs_name = @bgs_hash[bgs.name]
        end
        if bgs_name == ""
          Audio.bgs_play(RTP + "/Audio/BGS/" + bgs.name + ".ogg",\
                         bgs.volume, bgs.pitch)
        else
          Audio.bgs_play("Audio/BGS/" + bgs_name,\
                         bgs.volume, bgs.pitch)
        end
      else
        Audio.bgs_stop
      end
      Graphics.frame_reset
    end

    #--------------------------------------------------------------------------
    # ● ME 的演奏
    #     me : 演奏的 ME
    #--------------------------------------------------------------------------
    def me_play(me)
      return if @sound == nil
      if me != nil and me.name != ""
        if @me_hash[me.name] == nil
          name_ary = Dir.glob("Audio/ME/*.*")
          for i in 0...name_ary.size
            temp_name_ary = name_ary[i].split(/\//)
            me_name = temp_name_ary[temp_name_ary.size - 1]
            me_name = "" if me_name == nil
            if /#{me.name}\..+/ =~ me_name
              break
            end
          end
          if me_name == nil
            me_name = ""
          end
          if /#{me.name}\..+/ =~ me_name
            @me_hash[me.name] = me_name if me_name != ""
          else
            me_name = ""
          end
        else
          me_name = @me_hash[me.name]
        end
        if me_name == ""
          Audio.me_play(RTP + "/Audio/ME/" + me.name + ".mid",\
                        me.volume, me.pitch)
        else
          Audio.me_play("Audio/ME/" + me_name,\
                        me.volume, me.pitch)
        end
      else
        Audio.me_stop
      end
      Graphics.frame_reset
    end

    #--------------------------------------------------------------------------
    # ● SE 的演奏
    #     se : 演奏的 SE
    #--------------------------------------------------------------------------
    def se_play(se)
      return if @sound == nil
      if se != nil and se.name != ""
        if @se_hash[se.name] == nil
          name_ary = Dir.glob("Audio/SE/*.*")
          for i in 0...name_ary.size
            temp__name_ary = name_ary[i].split(/\//)
            se_name = temp__name_ary[temp__name_ary.size - 1]
            se_name = "" if se_name == nil
            if /#{se.name}\..+/ =~ se_name
              break
            end
          end
          if se_name == nil
            se_name = ""
          end
          if /#{se.name}\..+/ =~ se_name
            @se_hash[se.name] = se_name if se_name != ""
          else
            se_name = ""
          end
        else
          se_name = @se_hash[se.name]
        end
        if se_name == ""
          Audio.se_play(RTP + "/Audio/SE/" + se.name + ".ogg",\
                        se.volume, se.pitch)
        else
          Audio.se_play("Audio/SE/" + se_name,\
                        se.volume, se.pitch)
        end
      end
    end
  end
end