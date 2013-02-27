#!/usr/bin/env ruby
#run the following to package this application:
#ocra --window --icon "SlimeWarzIcon.ico" "Slime Warz.rb" ./**/* ./*
#ocra --console --chdir-first --icon "SlimeWarzIcon.ico" "Server Slime Warz.rb" ./**/* ./*
#downlaod here:
#https://www.dropbox.com/s/zr5f8k4qnowi9xt/Slime%20Warz.exe

require 'socket'

module Color
  Red = 0xf0f04040
  Blue = 0xf04040f0
  Black = 0xffffffff
end

class Server
  def initialize(clients)
    @clients = clients
    @players = [Player.new(), Player.new()]
    @players.each {|player| player.hide}
    @whosit = 0
    @blueTime = 0
    @redTime = 0
    @newGame = true
    @newGameCounter = 0
  end

  def timeIncrease
    if !@newGame
      @blueTime += 1 if @whosit == 0
      @redTime += 1 if @whosit == 1
    end
  end

  def touchingCalc
    if !@newGame
      defender = 1 if @whosit == 0
      defender = 0 if @whosit == 1
      if @players[defender].touching?(@players[@whosit])
        @players[defender].hide
        @newGame = true
      end
    end
  end

  def respawnSenario
    @newGameCounter += 1 if @newGame
    if @newGame && @newGameCounter >= 0
      defender = 1 if @whosit == 0
      defender = 0 if @whosit == 1
      @whosit = defender
      @players.each {|player| player.show}
      halfX = (1280 / 2).round
      @players[0].warp(halfX + 300, 800 - 100)
      @players[1].warp(halfX - 300 - @players[1].size, 800 - 100)
      @newGameCounter = -60
      @newGame = false
    end
  end

  def gets(io)
    begin
      s = ""
      while true
        c = ''
        io.sysread(1, c)
        if (c != "\n")
          s += c
        else
          break
        end
      end
      s
    rescue
      puts "Connection Lost"
      exit
    end
  end

  def outGoingUpdate()
    data = []
    data << @players[0].x
    data << @players[0].y
    data << @players[0].showing
    data << @players[1].x
    data << @players[1].y
    data << @players[1].showing
    data << @whosit
    data << @blueTime
    data << @redTime
    data.join(':')
  end

  def incomingUpdate(i)
    data = gets(@clients[i])
    data = data.chomp.split(':')
    data.map! do |a|
      a = a.to_sym
      a
    end
    @players[i].jump if data.include?(:jump)
    @players[i].vel_left if data.include?(:left)
    @players[i].vel_right if data.include?(:right)
    @players[i].vel_down if data.include?(:down)
    @players[i].cheat = true if data.include?(:true)
    @players[i].cheat = false if data.include?(:false)
  end

  def update
    incomingUpdate(0)
    incomingUpdate(1)
    p0 = p1 = false
    p0 = true if @whosit == 0
    p1 = true if @whosit == 1
    @players[0].move(@players[1], p0)
    @players[1].move(@players[0], p1)
    timeIncrease
    touchingCalc
    respawnSenario
    data = outGoingUpdate()
    @clients[0].syswrite(data + "\n")
    @clients[1].syswrite(data + "\n")
  end

  def start
    while true
      update
    end
  end
end

class Player
  attr_reader :x, :y, :vel_x, :vel_y, :size, :touchingGround, :showing
  attr_accessor :cheat
  def initialize
    @sizeMult = 0.75 #CHANGE THIS
    @size = 100 * @sizeMult #DO NOT CHANGE THIS
    @gravCounter = 0
    @x = @y = @vel_x = @vel_y = 0.0
    @showing = true
    @jetpack = false
    @cheat = false
  end

  def warp(x, y)
    @x, @y = x, y
    @vel_x = 0
    @vel_y = 0
  end

  def jump
    if @touchingGround
      @vel_y = -15
    elsif (@jetpack || @cheat) && @vel_y > -10
      vel_up
    end
  end
  
  def vel_up
    @vel_y -= 1
  end
  
  def vel_down
    @vel_y += 1
  end

  def vel_left
    @direction = :left
    @vel_x -= 1
  end

  def vel_right
    @direction = :right
    @vel_x += 1
  end

  def hide
    @showing = false
  end

  def show
    @showing = true
  end

  def jetpack
    @jetpack = true
  end

  def unequipJetpack
    @jetpack = false
  end

  def distance(x1, y1, x2, y2)
    Math.sqrt((x2 - x1).abs ** 2 + (y2 - y1).abs ** 2)
  end

  def touching?(two)
    half = (@size / 2).round
    myMidx = half + @x
    myMidy = half + @y
    twoMidX = half + two.x
    twoMidY = half + two.y
    dist = distance(myMidx, myMidy, twoMidX, twoMidY)
    if dist <= @size && !@cheat
      true
    else
      false
    end
  end

  def fCheat(other, it)
    if (!other.nil?)
      difX = @x - other.x
      difY = @y - other.y
      if it
        radius = 75
        amt = other.vel_y.abs
        if !other.touchingGround# && difY.abs > (@size + radius)
          if difY <= 0
            @vel_y = amt
          elsif difY > 0
            @vel_y = amt * -1
          end
        end
        #@y = other.y
      else
        radius = 100
        if difX.abs < (@size + radius) && difY.abs < (@size + radius)
          if difY <= 0
            @vel_y = -15
          elsif difY > 0
            @vel_y = 15
          end
          factor = 1
          factor = -1 if difY > 0
          if other.vel_x.abs > 5
            @vel_x = other.vel_x * factor
          elsif @vel_x.abs > 10
            @vel_x = 10 * (@vel_x.abs / @vel_x) * factor
          end
        end
        lastResortRadius = 15
        if difX.abs <= (@size + lastResortRadius) && difY.abs <= (@size + lastResortRadius)
          if difX <= 0
            @vel_x = -20#(@size / 4).round * -1
          elsif difX > 0
            @vel_x = 20#(@size / 4).round
          end
        end
      end
    end
  end

  def groundCalc
    ground = 800 - @size
    if @y >= ground
      @vel_y = 0
      @touchingGround = true
      @y = ground
    end
    if @y < ground
      @touchingGround = false
    end
  end

  def wallCalc(origX, origY)
    if (@x < 0 || @x > 1280 - @size)
      amt = 10
      if @vel_x.abs < amt && !@touchingGround
        @vel_x = amt * -1 * (@vel_x.abs / @vel_x)
      end
      @vel_x = (@vel_x *= -1.2).round
      @vel_y = ((1 / @vel_y) * 12).round if @vel_y < 0
      @x = origX
    end
  end

  def ceilingCalc
    if @y < 0
      @y = 0
      @vel_y = (@vel_y * -0.5).round
    end
  end

  def gravity
    if @vel_y < 30 && @gravCounter > 1
      @gravCounter = 0
      @vel_y += 1
    end
    @gravCounter += 1
  end
  
  def move(other = nil, it = false)
    fCheat(other, it) if @cheat
    origX = @x
    origY = @y
    @x += @vel_x
    @y += @vel_y
    @vel_x *= 0.95
    gravity
    groundCalc
    wallCalc(origX, origY)
    ceilingCalc
  end
end

printf 'Ip: '
hostname = gets.chomp
server = TCPServer.open(hostname, 2001)
puts 'Waiting for users...'
clients = []
2.times do |i|
  client = server.accept
  clients << client
  puts "User #{i} connected"
end

2.times do |i|
  clients[i].puts "#{i}"
end

server = Server.new(clients)
server.start