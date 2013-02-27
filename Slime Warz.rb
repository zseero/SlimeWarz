#!/usr/bin/env ruby
#run the following to package this application:
#ocra --window --icon "SlimeWarzIcon.ico" "Slime Warz.rb" ./**/* ./*
#ocra --console --chdir-first --icon "SlimeWarzIcon.ico" "Slime Warz.rb" ./**/* ./*
#downlaod here:
#https://www.dropbox.com/s/zr5f8k4qnowi9xt/Slime%20Warz.exe

puts "Loading Slime Warz..."
require 'rubygems'
require 'gosu'

module ZOrder
  Background, Bar, Text, Player = *0..3
end

module Color
  Red = 0xf0f04040
  Blue = 0xf04040f0
  Black = 0xffffffff
end

module Mode
  Menu, Play = *0..1
end

class Window < Gosu::Window
  attr_accessor :song, :song2
  def initialize
    super(Gosu::screen_width, Gosu::screen_height, true)    
    self.caption = "Slime Warz"

    @menuModeImage = Gosu::Image.new(self, "start screen.png", true)
    @playModeImage = Gosu::Image.new(self, "start screen.png", true)
    @redBar = Gosu::Image.new(self, "red.png", true)
    @blueBar = Gosu::Image.new(self, "blue.png", true)

    @widthMult = Gosu::screen_width.to_f / @menuModeImage.width.to_f
    @heightMult =  Gosu::screen_height.to_f / @menuModeImage.height.to_f

    @players = [Player.new(self, :red), Player.new(self, :blue)]
    @players.each {|player| player.hide}

    @song = Gosu::Song.new("14_The_City.wav")
    @song2 = Gosu::Song.new("Cold_Kill.wav")

    goToMenu
  end

  def menuSetup
    @background_image = @menuModeImage
    @playgame = Gosu::Font.new(self, Gosu::default_font_name, 75)
    @passKey.reverse!
    @passKey2.reverse!
    @passIndex = 0
  end

  def playSetup
    @background_image = @playModeImage
    @whosit = 0
    @blueTime = 0
    @redTime = 0
    @newGameCounter = 0
    @newGame = true
    @prevEscapeState = false

    @blueFont = Gosu::Font.new(self, Gosu::default_font_name, 30)
    @redFont = Gosu::Font.new(self, Gosu::default_font_name, 30)
    @announcementBox = Gosu::Font.new(self, Gosu::default_font_name, 50)

  end

  def goToMenu
    @mode = Mode::Menu
    @passKey = '\'/'
    @passKey2 = 'qe'
    menuSetup
  end

  def goToPlay
    @mode = Mode::Play
    playSetup
  end

  def menu?
    @mode == Mode::Menu
  end

  def play?
    @mode == Mode::Play
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
        halfX = (Gosu::screen_width / 2).round
        halfY = (Gosu::screen_height / 2).round
        @players[defender].hide
        #@whosit = defender
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
      halfX = (Gosu::screen_width / 2).round
      halfY = (Gosu::screen_height / 2).round
      @players[0].warp(halfX + 300, Gosu::screen_height - 100)
      @players[1].warp(halfX - 300 - @players[1].size, Gosu::screen_height - 100)
      @newGameCounter = -60
      @newGame = false
    end
  end

  def playTextBoxDraw
    blueText = "Blue\'s score: " + time_to_s(@blueTime)
    redText = "Red\'s score: " + time_to_s(@redTime)
    halfX = (Gosu::screen_width / 2).round
    halfY = (Gosu::screen_height / 2).round
    quarterX = (halfX * 0.68).round
    blueWidth = @blueFont.text_width(blueText)
    redWidth = @redFont.text_width(redText)
    halfBlue = (blueWidth / 2).round
    halfRed = (redWidth / 2).round
    @blueFont.draw(blueText, halfX - quarterX - halfBlue, 8, ZOrder::Text, 1, 1, Color::Black)
    @redFont.draw(redText, halfX + quarterX - halfRed, 8, ZOrder::Text, 1, 1, Color::Black)
    newit = "Red" if @whosit == 0
    newit = "Blue" if @whosit == 1
    text = newit + "\'s it!"
    textX = halfX - (@announcementBox.text_width(text) / 2).round
    @announcementBox.draw(text, textX, 10, ZOrder::Text, 1, 1, Color::Black)
    img = @redBar if newit == "Red"
    img = @blueBar if newit == "Blue"
    img.draw(0, 0, ZOrder::Bar, @widthMult, 1)
    #@blueFont.draw(blueText, halfX - 200, halfY, ZOrder::Text, 1, 1, Color::Blue)
    #redWidth = @redFont.text_width(redText)
    #@redFont.draw(redText, halfX + 200 - redWidth, halfY, ZOrder::Text, 1, 1, Color::Red)
    #newit = "Red" if @whosit == 0
    #newit = "Blue" if @whosit == 1
    #text = newit + ", you\'re it!"
    #textX = halfX - (@announcementBox.text_width(text) / 2).round
    #color = Color::Red if newit == "Red"
    #color = Color::Blue if newit == "Blue"
    #@announcementBox.draw(text, textX, halfY - 200, ZOrder::Text, 1, 1, color)
  end

  def menuTextBoxDraw
    word = "Play Game"
    halfX = (Gosu::screen_width / 2).round
    halfY = (Gosu::screen_height / 2).round

    textWidth = @playgame.text_width(word)
    textHeight = @playgame.height
    topLeftX = halfX - (textWidth / 2).round
    topLeftY = halfY

    color = Color::Blue
    @playgame.draw(word, topLeftX, topLeftY, ZOrder::Text, 1, 1, color)
  end

  def time_to_s(time)
    mins = ((time / 60) / 60).round.to_s
    seconds = ((time / 60) % 60).round.to_s
    seconds.insert(0, "0") if seconds.length == 1
    mins + ':' + seconds
  end

  def escape?
    if @prevEscapeState && !button_down?(Gosu::KbEscape)
      true
    else
      false
    end
  end
  
  def update
    if menu?
      if escape?
        puts "See you next time"
        close
      end
      goToPlay if button_down? Gosu::KbSpace
    end
    if play?
      goToMenu if escape?
      #p1
      @players[0].jump if button_down? Gosu::KbUp
      @players[0].vel_left if button_down? Gosu::KbLeft
      @players[0].vel_right if button_down? Gosu::KbRight
      @players[0].vel_down if button_down? Gosu::KbDown
      #p2
      @players[1].jump if button_down? Gosu::KbW
      @players[1].vel_left if button_down? Gosu::KbA
      @players[1].vel_right if button_down? Gosu::KbD
      @players[1].vel_down if button_down? Gosu::KbS

      p0 = false
      p1 = false
      p0 = true if @whosit == 0
      p1 = true if @whosit == 1
      @players[0].move(@players[1], p0)
      @players[1].move(@players[0], p1)

      timeIncrease
      touchingCalc
      respawnSenario
    end
    @prevEscapeState = button_down?(Gosu::KbEscape)
  end
  
  def draw
    #draw the background
    @background_image.draw(0, 0, ZOrder::Background, @widthMult, @heightMult)

    if menu?
      menuTextBoxDraw
    end

    if play?
      playTextBoxDraw
      @players.each {|player| player.draw}
    end
  end

  def button_down(id)
    c = self.button_id_to_char(id)
    if c == @passKey[@passIndex] || c == @passKey2[@passIndex]
      @passIndex += 1
    elsif (c==']' || c=='[' || c=='2' || c=='1') && @passIndex == @passKey.length
      @players[0].cheat = !@players[0].cheat if c == ']' || c == '2'
      @players[1].cheat = !@players[1].cheat if c == '[' || c == '1'
      @passIndex = 0
    elsif (c!='' && c!='w' && c!='a' && c!='s' && c!='d')
      @passIndex = 0
    end
  end
end

class Player
  attr_reader :x, :y, :vel_x, :vel_y, :size, :touchingGround
  attr_accessor :cheat
  def initialize(window, type)
    @window = window
    filePre = "Blue pathogen " if type == :blue
    filePre = "Red pathogen " if type == :red
    @imageRight = Gosu::Image.new(window, "Pathogen pics/" + filePre + "e.PNG", false)
    @imageLeft = Gosu::Image.new(window, "Pathogen pics/" + filePre + "w.PNG", false)
    @image = @imageRight
    @sizeMult = 0.75 #CHANGE THIS
    @size = 100 * @sizeMult #DO NOT CHANGE THIS
    @gravCounter = 0
    @x = @y = @vel_x = @vel_y = @angle = 0.0
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
    @image = @imageLeft
    @vel_x -= 1
  end

  def vel_right
    @image = @imageRight
    @vel_x += 1
  end

  def hide
    @showing = false
  end

  def show
    @showing = true
  end

  def shoot(vel)
    Bullet b = Bullet.new(@x, vel)
  end

  def jetpack
    @jetpack = true
  end

  def unequipJetpack
    @jetpack = false
  end

  def touching?(two)
    half = (@size / 2).round
    myMidx = half + @x
    myMidy = half + @y
    twoMidX = half + two.x
    twoMidY = half + two.y
    dist = Gosu::distance(myMidx, myMidy, twoMidX, twoMidY)
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
    ground = @window.height - @size
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
    if (@x < 0 || @x > @window.width - @size)
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

  def draw
    @image.draw(@x, @y, ZOrder::Player, @sizeMult, @sizeMult) if @showing
  end
end

window = Window.new
window.song2.play(true)
window.show