#!/usr/bin/env ruby
# -*- coding: utf-8 -*-
# MM1 -> Godot 4.7 data importer.
# Converts RPG Maker XP rxdata + MM system databases into JSON and copies assets.

require 'json'
require 'fileutils'
require 'zlib'

SRC = '/Users/l/Documents/game/重裝機兵一代复刻'
DST = File.expand_path('..', __dir__)
DATA_OUT = File.join(DST, 'data')
ASSET_OUT = File.join(DST, 'assets')
MAP_OUT = File.join(DATA_OUT, 'maps')
MM_OUT = File.join(DATA_OUT, 'mm')

FileUtils.mkdir_p([DATA_OUT, MAP_OUT, MM_OUT])

# ---------------------------------------------------------------- RGSS stubs
class Table
  attr_accessor :xsize, :ysize, :zsize, :data
  def initialize(x = 0, y = 0, z = 0)
    @xsize, @ysize, @zsize = x, y, z
    @data = []
  end

  def self._load(s)
    _dim, x, y, z, size = s.unpack('V5')
    t = Table.new(x, y, z)
    t.data = s[20, size * 2].unpack('s<*')
    t
  end
end

class Color
  attr_accessor :red, :green, :blue, :alpha
  def self._load(s)
    c = Color.new
    c.red, c.green, c.blue, c.alpha = s.unpack('d4')
    c
  end
end

class Tone
  attr_accessor :red, :green, :blue, :gray
  def self._load(s)
    t = Tone.new
    t.red, t.green, t.blue, t.gray = s.unpack('d4')
    t
  end
end

module RPG
  # all nested classes used by the rxdata databases
  class AudioFile; end
  class MoveRoute; end
  class MoveCommand; end
  class EventCommand; end
  class Event
    class Page
      class Condition; end
      class Graphic; end
    end
  end
  class CommonEvent; end
  class Map
    class Encounter; end
  end
  class MapInfo; end
  class Actor; end
  class Class
    class Learning; end
  end
  class BaseItem; end
  class Item; end
  class Weapon; end
  class Armor; end
  class Enemy
    class DropItem; end
    class Action; end
  end
  class Troop
    class Member; end
    class Page
      class Condition; end
    end
  end
  class Animation
    class Frame; end
    class Timing; end
    class Cell; end
  end
  class Skill; end
  class State; end
  class Tileset; end
  class System
    class Words; end
    class TestBattler; end
  end

  # MM system data objects (dynamic attribute bag)
  class Dyn
    def method_missing(name, *args)
      key = name.to_s
      if key.end_with?('=')
        instance_variable_set("@#{key[0..-2]}", args[0])
      elsif args.empty?
        instance_variable_get("@#{key}")
      else
        super
      end
    end

    def respond_to_missing?(_name, _include_private = false)
      true
    end

    def initialize(*); end
  end
  Tank = ::Class.new(Dyn)
  MainCannon = ::Class.new(Dyn)
  SubCannon = ::Class.new(Dyn)
  SE = ::Class.new(Dyn)
  Engine = ::Class.new(Dyn)
  CUnit = ::Class.new(Dyn)
  C_Unit = CUnit
  Underpan = ::Class.new(Dyn)
  SpecialCannonball = ::Class.new(Dyn)
  %w[Item Weapon Armor].each do |n|
    remove_const(n) if const_defined?(n)
    const_set(n, ::Class.new(Dyn))
  end
end

# ------------------------------------------------------------ encoding helper
def utf8(str)
  s = str.to_s.dup.force_encoding('UTF-8')
  return s if s.valid_encoding?
  str.to_s.dup.force_encoding('GBK').encode('UTF-8', invalid: :replace, undef: :replace)
end

# ------------------------------------------------------------- generic to JSON
def plain(obj, depth = 0)
  return nil if depth > 50
  case obj
  when Table
    { 'w' => obj.xsize, 'h' => obj.ysize, 'z' => obj.zsize, 'data' => obj.data }
  when Color
    { 'r' => obj.red, 'g' => obj.green, 'b' => obj.blue, 'a' => obj.alpha }
  when Tone
    { 'r' => obj.red, 'g' => obj.green, 'b' => obj.blue, 'gray' => obj.gray }
  when Array
    obj.map { |v| plain(v, depth + 1) }
  when Hash
    obj.each_with_object({}) do |(k, v), h|
      key = k.is_a?(Symbol) ? k.to_s : k.to_s
      h[key] = plain(v, depth + 1)
    end
  when String
    utf8(obj)
  when Symbol
    obj.to_s
  when Numeric, TrueClass, FalseClass, NilClass
    obj
  else
    ivars = obj.instance_variables
    if ivars.empty?
      obj.to_s
    else
      h = {}
      ivars.each { |iv| h[iv.to_s.sub(/^@/, '')] = plain(obj.instance_variable_get(iv), depth + 1) }
      h
    end
  end
end

def write_json(path, obj)
  File.write(path, JSON.pretty_generate(plain(obj)))
  puts "  #{File.basename(path)}"
end

# ------------------------------------------------------------- 1. raw databases
puts '== Converting rxdata databases'
raw_names = %w[Actors Animations Armors Classes CommonEvents Enemies Items
               MapInfos Skills States System Tilesets Troops Weapons]
raw = {}
raw_names.each do |name|
  file = File.join(SRC, 'Data', "#{name}.rxdata")
  next unless File.exist?(file)
  begin
    obj = Marshal.load(File.binread(file))
    raw[name] = obj
    write_json(File.join(DATA_OUT, "#{name.gsub(/([a-z])([A-Z])/, '\1_\2').downcase}.json"), obj)
  rescue => e
    warn "  FAILED #{name}: #{e.class}: #{e.message}"
  end
end

# ----------------------------------------------------------------- 2. MM data
puts '== Converting MM system databases'
begin
  script_dir = File.join(DST, 'tools', 'reference_scripts')
  scripts = %w[012 013 014 015 016 017 018 019 020 021 022 023 024 025 026 027]
  scripts.each do |num|
    path = Dir.glob(File.join(script_dir, "#{num}_*.rb")).first
    load path if path
  end
  db = Object.new.extend(MM_DataBase)
  mm = {}
  {
    'tanks' => :make_tanks,
    'main_cannons' => :make_main_cannons,
    'sub_cannons' => :make_sub_cannons,
    'ses' => :make_ses,
    'engines' => :make_engines,
    'c_units' => :make_c_units,
    'underpans' => :make_underpans,
    'special_cannonballs' => :make_specialcannonballs,
    'actor_weapons' => :make_actor_weapons,
    'actor_armors' => :make_actor_armors,
    'actor_items' => :make_actor_items,
    'tank_items' => :make_tank_items
  }.each do |key, fn|
    mm[key] = db.send(fn)
  end
  MM_DataBase.constants.sort.each do |c|
    next unless c.to_s.start_with?('DATA_', 'VOCAB_', 'PICTURE_', 'MUSIC_')
    mm[c.to_s.downcase] = MM_DataBase.const_get(c)
  end
  write_json(File.join(MM_OUT, 'database.json'), mm)
rescue => e
  warn "  MM data failed: #{e.class}: #{e.message}"
  warn e.backtrace.first(5).join("\n")
end

# ------------------------------------------------------------------- 3. maps
puts '== Converting maps'
map_infos = raw['MapInfos'] || []
Dir.glob(File.join(SRC, 'Data', 'Map[0-9]*.rxdata')).sort.each do |file|
  base = File.basename(file, '.rxdata')
  map_id = base[/\d+/].to_i
  map = Marshal.load(File.binread(file))
  width = map.instance_variable_get(:@width)
  height = map.instance_variable_get(:@height)
  data = map.instance_variable_get(:@data)
  tileset_id = map.instance_variable_get(:@tileset_id)
  layer_size = width * height
  layers = [0, 1, 2].map { |z| data.data[z * layer_size, layer_size] || [] }
  events = {}
  (map.instance_variable_get(:@events) || {}).each do |id, ev|
    next if ev.nil?
    pages = (ev.instance_variable_get(:@pages) || []).map do |pg|
      {
        'condition' => plain(pg.instance_variable_get(:@condition)),
        'graphic' => plain(pg.instance_variable_get(:@graphic)),
        'move_type' => pg.instance_variable_get(:@move_type),
        'move_speed' => pg.instance_variable_get(:@move_speed),
        'move_frequency' => pg.instance_variable_get(:@move_frequency),
        'move_route' => plain(pg.instance_variable_get(:@move_route)),
        'walk_anime' => pg.instance_variable_get(:@walk_anime),
        'step_anime' => pg.instance_variable_get(:@step_anime),
        'direction_fix' => pg.instance_variable_get(:@direction_fix),
        'through' => pg.instance_variable_get(:@through),
        'always_on_top' => pg.instance_variable_get(:@always_on_top),
        'trigger' => pg.instance_variable_get(:@trigger),
        'list' => (pg.instance_variable_get(:@list) || []).map do |cmd|
          [cmd.instance_variable_get(:@code),
           cmd.instance_variable_get(:@indent),
           plain(cmd.instance_variable_get(:@parameters))]
        end
      }
    end
    events[id.to_s] = {
      'id' => ev.instance_variable_get(:@id),
      'name' => utf8(ev.instance_variable_get(:@name)),
      'x' => ev.instance_variable_get(:@x),
      'y' => ev.instance_variable_get(:@y),
      'pages' => pages
    }
  end
  payload = {
    'id' => map_id,
    'width' => width,
    'height' => height,
    'tileset_id' => tileset_id,
    'layers' => layers,
    'events' => events,
    'info' => plain(map_infos[map_id])
  }
  write_json(File.join(MAP_OUT, format('map%03d.json', map_id)), payload)
  # native scene wrapper
  scene = <<~TSCN
    [gd_scene load_steps=2 format=3]

    [ext_resource type="Script" path="res://scripts/core/map_scene.gd" id="1_map"]

    [node name="Map#{format('%03d', map_id)}" type="Node2D"]
    script = ExtResource("1_map")
    map_id = #{map_id}
  TSCN
  FileUtils.mkdir_p(File.join(DST, 'scenes', 'maps'))
  File.write(File.join(DST, 'scenes', 'maps', format('map%03d.tscn', map_id)), scene)
end

# -------------------------------------------------------------- 4. asset copy
puts '== Copying assets'
{
  'Graphics' => File.join(ASSET_OUT, 'graphics'),
  'Audio' => File.join(ASSET_OUT, 'audio')
}.each do |src_dir, dst_dir|
  next unless Dir.exist?(File.join(SRC, src_dir))
  FileUtils.mkdir_p(dst_dir)
  Dir.children(File.join(SRC, src_dir)).each do |sub|
    next if sub.start_with?('.')
    FileUtils.cp_r(File.join(SRC, src_dir, sub), dst_dir)
  end
end
puts 'Done.'
