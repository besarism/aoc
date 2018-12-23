#!/usr/bin/env ruby

require 'pp'

class Time
  def to_ms
    (self.to_f * 1000.0).to_i
  end
end

class NanoBot
  attr_accessor :x, :y, :z, :r
  def initialize(x, y, z, r)
    @x, @y, @z, @r = x, y, z, r
  end

  def dist(bot2)
    (@x - bot2.x).abs + (@y - bot2.y).abs + (@z - bot2.z).abs
  end

  def has_target_in_range(bot2)
    self.dist(bot2) <= @r
  end

  def has_xyz_in_range(xt, yt, zt)
    ((@x - xt).abs + (@y - yt).abs + (@z - zt).abs) <= @r
  end
end

class Region
  attr_reader :x0, :x1, :y0, :y1, :z0, :z1, :size
  attr_accessor :bots_min_bound, :bots_max_bound
  def initialize(x0, y0, z0, x1, y1, z1)
    @x0, @y0, @z0 = x0, y0, z0
    @x1, @y1, @z1 = x1, y1, z1
    @size = (x1-x0) * (y1-y0) * (z1-z0)
    @bots_min_bound = nil
    @bots_max_bound = nil
    raise 'invalid region' if y0 > y1 || x0 > x1 || z0 > z1
  end

  def all_points
    [@x0, @y0, @z0, @x1, @y1, @z1]
  end

  def get_estimates!(bots)
    @bots_max_bound, @bots_min_bound = estimate_region(bots, self)
  end
end

def parse_file(filename)
  bots = []
  File.readlines(filename).each do |line|
    x, y, z, r = line.strip.match(/pos=<(-?\d+),(-?\d+),(-?\d+)>, r=(\d+)/).captures.map(&:to_i)
    bots.push(NanoBot.new(x, y, z, r))
  end
  bots
end

def tests
  a = NanoBot.new(1, 2, 3, 10)
  b = NanoBot.new(2, 3, 5, 10)
  raise 'x' unless a.x == 1
  raise 'y' unless a.y == 2
  raise 'z' unless a.z == 3
  raise 'r' unless a.r == 10
  raise 'dist1' unless a.dist(b) == 4
  raise 'dist2' unless b.dist(a) == 4

  bot1 = NanoBot.new(0, 0, 0, 4)
  bot2 = NanoBot.new(1, 0, 0, 1)
  bot3 = NanoBot.new(4, 0, 0, 3)
  bot4 = NanoBot.new(0, 2, 0, 1)
  bot5 = NanoBot.new(0, 5, 0, 3)
  raise 'in_range 2' unless bot1.has_target_in_range(bot2)
  raise 'in_range 3' unless bot1.has_target_in_range(bot3)
  raise 'in_range 4' unless bot1.has_target_in_range(bot4)
  raise 'in_range 5' unless !bot1.has_target_in_range(bot5)

  raise 'in range' unless part1('input_small.txt') == 7
end

def part1(filename)
  bots = parse_file(filename)
  strongest = bots.max_by(&:r)
  bots.select { |bot| strongest.has_target_in_range(bot) }.count
end

def points_in_range(bots, x, y, z)
  target_bot = NanoBot.new(x, y, z, 0)
  bots.select { |bot| bot.has_target_in_range(target_bot) }.count
end

# x0 = min_x, x1 = max_x, etc
def estimate_region(bots, r2)
  x0, y0, z0, x1, y1, z1 = r2.all_points
  corners = [
    NanoBot.new(x0, y0, z0, 0),
    NanoBot.new(x0, y0, z1, 0),
    NanoBot.new(x0, y1, z0, 0),
    NanoBot.new(x0, y1, z1, 0),
    NanoBot.new(x1, y0, z0, 0),
    NanoBot.new(x1, y0, z1, 0),
    NanoBot.new(x1, y1, z0, 0),
    NanoBot.new(x1, y1, z1, 0)
  ]
  upper_bound = 0
  lower_bound = 0

  bots.each do |bot|
    # Is the bot actually sitting inside the box?

    corners_in_range = corners.select { |corner| bot.has_target_in_range(corner) }.count
    if corners_in_range == 8
      upper_bound += 1
      lower_bound += 1
    elsif corners_in_range > 0
      upper_bound += 1
    elsif bot.x >= x0 && bot.x <= x1 && bot.y >= y0 && bot.y <= y1 && bot.z >= z0 && bot.z <= z1
      # ^ Checks to see if bot is sitting inside the range
      upper_bound += 1
    elsif is_on_face(bot, Region.new(x0, y0, z0, x1, y1, z1))
      #puts 'END SUCCESS scanning faces'
      # Check along all 6 faces to see if points are in range..(slow?)
      upper_bound += 1
    end
  end
  [upper_bound, lower_bound]
end

def is_on_face(bot, r)
  #puts 'BEGIN scanning faces'
  #pp bot
  #pp r
  x0, y0, z0, x1, y1, z1 = r.all_points
  x0.upto(x1) do |x|
    # All Xs and Ys with Z at min
    # All Xs and Ys with Z at max
    y0.upto(y1) do |y|
      return true if bot.has_xyz_in_range(x, y, z0) || bot.has_xyz_in_range(x, y, z1)
    end

    # All Zs and Xs with Y at min
    # All Zs and Xs with Y at max
    z0.upto(z1) do |z|
      return true if bot.has_xyz_in_range(x, y0, z) || bot.has_xyz_in_range(x, y1, z)
    end
  end

  # All Zs and Ys with X at min
  # All Zs and Ys with X at max
  z0.upto(z1) do |z|
    y0.upto(y1) do |y|
      return true if bot.has_xyz_in_range(x0, y, z) || bot.has_xyz_in_range(x1, y, z)
    end
  end

  #puts 'END FAIL scanning faces'
  false
end

def part2(filename)
  bots = parse_file(filename)
  r = get_max_region(bots)
  #r.get_estimates!(bots)

  regions = [r]
  final_candidates = []
  tell_regions_to_calculate_estimates(regions, bots)

  loop do
    candidate = regions.max_by { |this_r| this_r.bots_max_bound }
    if candidate.size < 50
      final_candidates.push candidate
      break
    end
    regions.reject! { |y| y == candidate }
    new_regions = split(candidate)
    tell_regions_to_calculate_estimates(new_regions, bots)
    regions += new_regions
  end

  pp final_candidates

  raise 'hi'
end

def tell_regions_to_calculate_estimates(regions, bots)
  regions.select { |this_r| this_r.bots_max_bound.nil? }.each { |this_r| this_r.get_estimates!(bots) }
end

def split(r)
  rs = []
  x0, y0, z0, x1, y1, z1 = r.all_points
  x_mid = (x0 + x1) / 2
  y_mid = (y0 + y1) / 2
  z_mid = (z0 + z1) / 2
  #pp "-----"
  #pp r
  ##puts "xmid #{x_mid} ymid #{y_mid} zmid #{z_mid} "

  rs.push(Region.new(x0, y0, z0, x_mid, y_mid, z_mid)) # Original cut down
  rs.push(Region.new(x_mid, y0, z0, x1, y_mid, z_mid)) # Only X moved
  rs.push(Region.new(x0, y_mid, z0, x_mid, y1, z_mid)) # Only Y moved
  rs.push(Region.new(x_mid, y_mid, z0, x1, y1, z_mid)) # X+Y moved
  rs.push(Region.new(x0, y0, z_mid, x_mid, y_mid, z1)) # Only Z moved
  rs.push(Region.new(x_mid, y0, z_mid, x1, y_mid, z1)) # Z+X moved
  rs.push(Region.new(x0, y_mid, z_mid, x_mid, y1, z1)) # Z+Y moved
  rs.push(Region.new(x_mid, y_mid, z_mid, x1, y1, z1)) # Everything moved
  rs
end

def get_max_region(bots)
  x0, y0, z0, x1, y1, z1 = [nil, nil, nil, nil, nil, nil]
  bots.each do |bot|
    x0 = bot.x if x0.nil? || bot.x < x0
    x1 = bot.x if x1.nil? || bot.x > x1
    y0 = bot.y if y0.nil? || bot.y < y0
    y1 = bot.y if y1.nil? || bot.y > y1
    z0 = bot.z if z0.nil? || bot.z < z0
    z1 = bot.z if z1.nil? || bot.z > z1
  end
  Region.new(x0, y0, z0, x1, y1, z1)
end

begin_tests = Time.now
tests
end_tests = Time.now
puts "All tests passed - #{end_tests.to_ms - begin_tests.to_ms}ms"

puts 'Part1: '
pp part1('input.txt')

puts 'Part2 playground: '
pp part2('input_small2.txt')
#pp part2('input.txt')

=begin

bots = parse_file('input_small2.txt')
num = points_in_range(bots, 12, 12, 12)
pp num
pp '---'
upper_bound, lower_bound = estimate_region(bots, Region.new(10, 10, 10, 13, 13, 13))
pp upper_bound, lower_bound
upper_bound, lower_bound = estimate_region(bots, Region.new(11, 11, 11, 13, 13, 13))
pp upper_bound, lower_bound

upper_bound, lower_bound = estimate_region(bots, Region.new(12, 12, 12, 12, 12, 12))
pp '?'
pp upper_bound, lower_bound

#def estimate_region(bots, x0, x1, y0, y1, z0, z1)
upper_bound, lower_bound = estimate_region(bots, Region.new(-500, -500, -500, 500, 500, 500))
pp upper_bound, lower_bound

=end
