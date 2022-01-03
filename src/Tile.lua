--[[
    GD50
    Match-3 Remake

    -- Tile Class --

    Author: Colton Ogden
    cogden@cs50.harvard.edu

    The individual tiles that make up our game board. Each Tile can have a
    color and a variety, with the varietes adding extra points to the matches.
]]

Tile = Class{}

function Tile:init(x, y, color, variety)

    -- board positions
    self.gridX = x
    self.gridY = y

    -- coordinate positions
    self.x = (self.gridX - 1) * 32
    self.y = (self.gridY - 1) * 32

    -- tile appearance/points
    self.color = color
    self.variety = variety

    -- Random # and a boolean to determine if a tile is shiny
    local rand = math.random(16)
    if rand == 16 then
        self.isShiny = true
    else
        self.isShiny = false
    end
    -- alpha to make shine animate
    self.shineAlpha = 0

    -- Animate shiny tiles
    Timer.every(3, function()
        Timer.tween(1.5,{
            [self] = {shineAlpha = .3}
        }):finish(function()
            Timer.tween(1.5,{
                [self] = {shineAlpha = 0}
            })
        end)

    end)
end

function Tile:render(x, y)

    -- draw shadow
    love.graphics.setColor(34/255, 32/255, 52/255, 255/255)
    love.graphics.draw(gTextures['main'], gFrames['tiles'][self.color][self.variety],
        self.x + x + 2, self.y + y + 2)

    -- draw tile itself
    love.graphics.setColor(255/255, 255/255, 255/255, 255/255)
    love.graphics.draw(gTextures['main'], gFrames['tiles'][self.color][self.variety],
        self.x + x, self.y + y)

    -- Render a way to identify shiny tiles
    if self.isShiny then
        -- translucent overlay
        love.graphics.setColor(1, 1, 1, self.shineAlpha)
        love.graphics.rectangle('fill', self.x + x, self.y + y, 32, 32, 8, 8, 4)

        -- gold border
        love.graphics.setColor(1, 0.8, 0.05, 1)
        love.graphics.setLineWidth(2)
        love.graphics.rectangle('line', self.x + x, self.y + y, 32, 32, 6, 6, 4)
    end
end

function Tile:update(dt)



    Timer.update(dt)
end



function Tile:leftEdge()
    if self.gridX == 1 then
        print("Found left edge.")
        return true
    end
    return false
end

function Tile:nearLeftEdge()
    if self.gridX == 2 then
        print("Found near left edge.")
        return true
    end
    return false
end

function Tile:rightEdge()
    if self.gridX == 8 then
        print("Found right edge.")
        return true
    end
    return false
end

function Tile:nearRightEdge()
    if self.gridX == 7 then
        print("Found near right edge.")
        return true
    end
    return false
end

function Tile:topEdge()
    if self.gridY == 1 then
        print("Found top edge.")
        return true
    end
    return false
end

function Tile:nearTopEdge()
    if self.gridY == 2 then
        print("Found near top edge.")
        return true
    end
    return false
end

function Tile:botEdge()
    if self.gridY == 8 then
        print("Found bot edge.")
        return true
    end
    return false
end

function Tile:nearBotEdge()
    if self.gridY == 7 then
        print("Found near bot edge.")
        return true
    end
    return false
end
