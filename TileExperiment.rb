puts "Loading Game..."
require 'gosu'

class Window < Gosu::Window
  def initialize
    super(Gosu::screen_width, Gosu::screen_height, true)    
    self.caption = "Tiles"

    @background_image = Gosu::Image.new(self, "start screen.png", true)

    @widthMult = Gosu::screen_width.to_f / @menuModeImage.width.to_f
    @heightMult =  Gosu::screen_height.to_f / @menuModeImage.height.to_f
  end

  def update
  end

  def draw
    #draw the background
    @background_image.draw(0, 0, ZOrder::Background, @widthMult, @heightMult)
  end
end

class Tiles
  attr_accessor tiles:
  def initialize(size)
    @tiles = []
    for x in 0...size
      column = []
      for y in 0...size
        column << Tile.new()
      end
      @tiles << column
    end
  end
end

def Random
Random.rand(0..10)
end

class Tile
end