#!/usr/bin/env ruby
#run the following to package this application:
#ocra --console --chdir-first --icon "SlimeWarzIcon.ico" "Client Slime Warz.rb" ./**/* ./*
#downlaod here:
#https://www.dropbox.com/s/flbi9iw3aes7sd2/Client%20Slime%20Warz.exe

puts "Loading Slime Warz..."
require 'rubygems'
require 'gosu'
require 'socket'

module ZOrder
  Background, Bar, Text, Player = *0..3
end

module Color
  Red = 0xf0f04040
  Blue = 0xf04040f0
  Black = 0xffffffff
end

class Array
  def parse
    map! do |a|
      if a == "true"
        a = true 
      elsif a == "false"
        a = false
      else
        a = a.to_i
      end
      a
    end
    self
  end
end

class Window < Gosu::Window
  attr_accessor :song, :song2
  def initialize(server, whoAmI)
    @screenHeight = 800
    @screenWidth = 1290
    super(@screenWidth, @screenHeight, false)    
    self.caption = "Slime Warz"
    @server = server
    @whoAmI = whoAmI
    @background_image = Gosu::Image.new(self, "start screen.png", true)
    @redBar = Gosu::Image.new(self, "red.png", true)
    @blueBar = Gosu::Image.new(self, "blue.png", true)

    @widthMult = @screenWidth / @background_image.width.to_f
    @heightMult =  @screenHeight / @background_image.height.to_f

    @players = [Player.new(self, :red), Player.new(self, :blue)]

    @song = Gosu::Song.new("14_The_City.wav")
    @song2 = Gosu::Song.new("Cold_Kill.wav")

    @blueFont = Gosu::Font.new(self, Gosu::default_font_name, 30)
    @redFont = Gosu::Font.new(self, Gosu::default_font_name, 30)
    @announcementBox = Gosu::Font.new(self, Gosu::default_font_name, 50)

    @passKey = '\';'.reverse
    @passKey2 = 'qr'.reverse
    @passIndex = 0
    update
  end

  def playTextBoxDraw
    blueText = "Blue\'s score: " + time_to_s(@blueTime)
    redText = "Red\'s score: " + time_to_s(@redTime)
    halfX = (@screenWidth / 2).round
    halfY = (@screenHeight / 2).round
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
  end

  def time_to_s(time)
    mins = ((time / 60) / 60).round.to_s
    seconds = ((time / 60) % 60).round.to_s
    seconds.insert(0, "0") if seconds.length == 1
    mins + ':' + seconds
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

  def outGoingUpdate
    data = []
    if @players[@whoAmI].cheat
      data << :true
    else
      data << :false
    end
    up = (button_down? Gosu::KbW) || (button_down? Gosu::KbUp)
    left = (button_down? Gosu::KbA) || (button_down? Gosu::KbLeft)
    right = (button_down? Gosu::KbD) || (button_down? Gosu::KbRight)
    down = (button_down? Gosu::KbS) || (button_down? Gosu::KbDown)
    data << :jump if up
    data << :left if left
    data << :right if right
    data << :down if down
    @server.syswrite data.join(':') + "\n"
  end

  def incomingUpdate
    data = gets(@server)
    data = data.chomp.split(':').parse
    @players[0].x = data[0]
    @players[0].y = data[1]
    @players[0].showing = data[2]
    @players[1].x = data[3]
    @players[1].y = data[4]
    @players[1].showing = data[5]
    @whosit = data[6]
    @blueTime = data[7]
    @redTime = data[8]
  end
  
  def update
    outGoingUpdate
    incomingUpdate
  end
  
  def draw
    @background_image.draw(0, 0, ZOrder::Background, @widthMult, @heightMult)

    playTextBoxDraw
    @players.each {|player| player.draw}
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
  attr_accessor :x, :y, :cheat, :showing
  def initialize(window, type)
    @window = window
    filePre = "Blue pathogen " if type == :blue
    filePre = "Red pathogen " if type == :red
    @imageRight = Gosu::Image.new(window, "Pathogen pics/" + filePre + "e.PNG", false)
    @imageLeft = Gosu::Image.new(window, "Pathogen pics/" + filePre + "w.PNG", false)
    @image = @imageRight
    @sizeMult = 0.75 #CHANGE THIS
    @size = 100 * @sizeMult #DO NOT CHANGE THIS
    @x = @y = 0.0
    @showing = true
    @cheat = false
  end

  def draw
    @image.draw(@x, @y, ZOrder::Player, @sizeMult, @sizeMult) if @showing
  end
end

printf 'Ip: '
hostname = gets.chomp
server = TCPSocket.open(hostname, 2001)
puts 'Connected'
playerNumber = server.gets.chomp.to_i
puts "You are player #{playerNumber}"

window = Window.new(server, playerNumber)
window.song.play(true)
window.show