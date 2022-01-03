--[[
    GD50
    Match-3 Remake

    -- Board Class --

    Author: Colton Ogden
    cogden@cs50.harvard.edu

    The Board is our arrangement of Tiles with which we must try to find matching
    sets of three horizontally or vertically.
]]

Board = Class{}

function Board:init(x, y, level)
    self.x = x
    self.y = y
    self.matches = {}
    self.level = level

    self:initializeTiles()
end

function Board:initializeTiles()
    self.tiles = {}

    for tileY = 1, 8 do

        -- empty table that will serve as a new row
        table.insert(self.tiles, {})

        for tileX = 1, 8 do
            if self.level < 6 then
                -- create a new tile at X,Y with a random color and variety 1
                table.insert(self.tiles[tileY], Tile(tileX, tileY, math.random(18), math.random(self.level)))
            else
                -- create a new tile at X,Y with a random color and variety
                table.insert(self.tiles[tileY], Tile(tileX, tileY, math.random(18), math.random(6)))
            end
        end
    end

    while self:checkPotential() < 3 do
        print("Board lacks potential. Reinitializing.")
        self:initializeTiles()
    end

    while self:calculateMatches()  do
        print("Board has matches. Reinitializing.")
        self:initializeTiles()
    end
end

--[[
    Goes left to right, top to bottom in the board, calculating matches by counting consecutive
    tiles of the same color. Doesn't need to check the last tile in every row or column if the
    last two haven't been a match.
]]
function Board:calculateMatches()
    local matches = {}

    -- how many of the same color blocks in a row we've found
    local matchNum = 1

    -- horizontal matches first
    for y = 1, 8 do
        local colorToMatch = self.tiles[y][1].color

        matchNum = 1

        local hasShiny = false

        -- every horizontal tile
        for x = 2, 8 do

            -- if this is the same color as the one we're trying to match...
            if self.tiles[y][x].color == colorToMatch then
                matchNum = matchNum + 1
            else

                -- set this as the new color we want to watch for
                colorToMatch = self.tiles[y][x].color

                -- if we have a match of 3 or more up to now, add it to our matches table
                if matchNum >= 3 then
                    local match = {}

                    -- go backwards from here by matchNum to find shinies
                    for x2 = x - 1, x - matchNum, -1 do
                        if self.tiles[y][x2].isShiny then
                            hasShiny = true
                            break
                        end
                    end

                    if hasShiny then
                        -- if theres a shiny add whole row to matches
                        for i = 1, 8 do
                            table.insert(match, self.tiles[y][i])
                        end
                    else
                        -- go backwards from here by matchNum
                        for x2 = x - 1, x - matchNum, -1 do

                            -- add each tile to the match that's in that match
                            table.insert(match, self.tiles[y][x2])
                        end
                    end
                    hasShiny = false
                    -- add this match to our total matches table
                    table.insert(matches, match)
                end

                matchNum = 1

                -- don't need to check last two if they won't be in a match
                if x >= 7 then
                    break
                end
            end
        end

        -- account for the last row ending with a match
        if matchNum >= 3 then
            local match = {}

            -- find shinies
            for x = 8, 8 - matchNum + 1, -1 do
                if self.tiles[y][x].isShiny then
                    hasShiny = true
                    break
                end
            end

            if hasShiny then
                for i = 1, 8 do
                    table.insert(match, self.tiles[y][i])
                end
            else
                -- go backwards from end of last row by matchNum
                for x = 8, 8 - matchNum + 1, -1 do
                    table.insert(match, self.tiles[y][x])
                end
            end
            hasShiny = false
            table.insert(matches, match)
        end
    end

    -- vertical matches
    for x = 1, 8 do
        local colorToMatch = self.tiles[1][x].color

        matchNum = 1

        -- every vertical tile
        for y = 2, 8 do
            if self.tiles[y][x].color == colorToMatch then
                matchNum = matchNum + 1
            else
                colorToMatch = self.tiles[y][x].color

                if matchNum >= 3 then
                    local match = {}

                    for y2 = y - 1, y - matchNum, -1 do
                        if self.tiles[y2][x].isShiny then
                            hasShiny = true
                            break
                        end
                    end

                    if hasShiny then
                        for i = 1, 8 do
                            table.insert(match, self.tiles[i][x])
                        end
                    else
                        for y2 = y - 1, y - matchNum, -1 do
                            table.insert(match, self.tiles[y2][x])
                        end
                    end
                    hasShiny = false
                    table.insert(matches, match)
                end

                matchNum = 1

                -- don't need to check last two if they won't be in a match
                if y >= 7 then
                    break
                end
            end
        end

        -- account for the last column ending with a match
        if matchNum >= 3 then
            local match = {}

            for y = 8, 8 - matchNum + 1, -1 do
                if self.tiles[y][x].isShiny then
                    hasShiny = true
                    break
                end
            end
            if hasShiny then
                for i = 1, 8 do
                    table.insert(match, self.tiles[i][x])
                end
            else
                -- go backwards from end of last row by matchNum
                for y = 8, 8 - matchNum + 1, -1 do
                    table.insert(match, self.tiles[y][x])
                end
            end
            hasShiny = false
            table.insert(matches, match)

        end
    end

    -- store matches for later reference
    self.matches = matches


    -- return matches table if > 0, else just return false
    return #self.matches > 0 and self.matches or false
end

function Board:checkPotential()
--[[ 5/13/2021:
    having indexing issues. being a border piece isnt the only consideration. if tile.gridX == 2 that means that you cant look to tile.gridX - 3 for a helper tile.
    -check for 'near edge' cases
        - x == 2 or 7, y == 2 or 7
    - consider using tile2 as a location reference for helper blocks on the right to simplify indexes
    - perhaps create variables to store information about where the 6 potential helper tiles are.

    5/14/2021:
    I tried to solve the "near edge" problem, but some tiles are slipping through causing an index nil error in the final else
--]]

    local potentialScore = 0

    -- looking for horizontal pairs with match potential
	for y = 1, 8 do
        --since we're peeking to the right of tiles no need to check last column
        for x = 1, 7 do
            local hasPotential = false
            tile = self.tiles[y][x]
            tile2 = self.tiles[y][x + 1]

            print("X: " .. tile.gridX)
            print("Y: " .. tile.gridY)

		    if tile.color == self.tiles[tile.gridY][tile.gridX + 1].color then
			    -- Found a horizontal pair
				if tile:topEdge() then
					if tile:leftEdge() then
                    --top left corner
						if self.tiles[tile.gridY][tile.gridX + 3].color == tile.color or self.tiles[tile.gridY + 1][tile.gridX + 2] == tile.color then
							hasPotential = true
						end
                    elseif tile:nearLeftEdge() then
                        if self.tiles[tile.gridY + 1][tile.gridX - 1].color == tile.color then
                            hasPotential = true
                        end
					elseif tile2:rightEdge() then
                    -- top right corner
						if self.tiles[tile.gridY][tile.gridX - 2].color == tile.color or self.tiles[tile.gridY + 1][tile.gridX - 1] == tile.color then
							hasPotential = true
						end
                    elseif tile2:nearRightEdge() then
                        if self.tiles[tile.gridY + 1][tile.gridX + 2].color == tile.color then
                            hasPotential = true
                        end
					else
                    --plain top edge
						if self.tiles[tile.gridY][tile.gridX + 3].color == tile.color or self.tiles[tile.gridY + 1][tile.gridX + 2] == tile.color or self.tiles[tile.gridY][tile.gridX - 2].color == tile.color or self.tiles[tile.gridY + 1][tile.gridX - 1] == tile.color then
						hasPotential = true
                        end
					end
				elseif tile:botEdge() then
					if tile:leftEdge() then
                    --bottom left corner
						if self.tiles[tile.gridY - 1][tile.gridX + 2].color == tile.color or self.tiles[tile.gridY][tile.gridX + 3] == tile.color then
							hasPotential = true
						end
                    elseif tile:nearLeftEdge() then
                        if self.tiles[tile.gridY - 1][tile.gridX - 1].color == tile.color then
                            hasPotential = true
                        end
					elseif tile2:rightEdge() then
                    -- bottom right corner
						if self.tiles[tile.gridY - 1][tile.gridX - 1].color == tile.color or self.tiles[tile.gridY][tile.gridX - 2] == tile.color then
							hasPotential = true
						end
                    elseif tile2:nearRightEdge() then
                        if self.tiles[tile.gridY - 1][tile.gridX + 2].color == tile.color then
                            hasPotential = true
                        end
					else
                    --plain bottom edge
						if self.tiles[tile.gridY - 1][tile.gridX + 2].color == tile.color or self.tiles[tile.gridY][tile.gridX + 3] == tile.color or self.tiles[tile.gridY - 1][tile.gridX - 1].color == tile.color or self.tiles[tile.gridY][tile.gridX - 2] == tile.color then
							hasPotential = true
						end
					end
				elseif tile:leftEdge() then
                --plain left edge
					if self.tiles[tile.gridY][tile.gridX + 3].color == tile.color or self.tiles[tile.gridY + 1][tile.gridX + 2] == tile.color or self.tiles[tile.gridY - 1][tile.gridX + 2].color == tile.color then
						hasPotential = true
					end
                elseif tile:nearLeftEdge() then
                    if self.tiles[tile.gridY - 1][tile.gridX - 1].color == tile.color or self.tiles[tile.gridY + 1][tile.gridX - 1].color == tile.color or self.tiles[tile.gridY][tile.gridX + 3].color == tile.color or self.tiles[tile.gridY + 1][tile.gridX + 2] == tile.color or self.tiles[tile.gridY - 1][tile.gridX + 2].color == tile.color then
                        hasPotential = true
                    end
				elseif tile2:rightEdge() then
                --plain right edge
					if self.tiles[tile.gridY - 1][tile.gridX - 1].color == tile.color or self.tiles[tile.gridY][tile.gridX - 2] == tile.color or self.tiles[tile.gridY + 1][tile.gridX - 1] == tile.color then
						hasPotential = true
					end
                elseif tile2:nearRightEdge() then
                    if self.tiles[tile.gridY - 1][tile.gridX + 2].color == tile.color or self.tiles[tile.gridY + 1][tile.gridX + 2].color == tile.color or self.tiles[tile.gridY - 1][tile.gridX - 1].color == tile.color or self.tiles[tile.gridY][tile.gridX - 2] == tile.color or self.tiles[tile.gridY + 1][tile.gridX - 1] == tile.color then
                        hasPotential = true
                    end
				else
				    if self.tiles[tile.gridY][tile.gridX - 2].color == tile.color or self.tiles[tile.gridY - 1][tile.gridX - 1].color == tile.color or
							self.tiles[tile.gridY + 1][tile.gridX - 1].color == tile.color or self.tiles[tile.gridY][tile.gridX + 3].color == tile.color or
									self.tiles[tile.gridY - 1][tile.gridX + 2].color == tile.color or self.tiles[tile.gridY + 1][tile.gridX + 2].color == tile.color then
					    hasPotential = true
				    end
			    end
                if hasPotential then
				    potentialScore = potentialScore + 1
                    hasPotential = false
                end

		    end
        end
	end

	return potentialScore
end

--[[
    Remove the matches from the Board by just setting the Tile slots within
    them to nil, then setting self.matches to nil.
]]
function Board:removeMatches()
    for k, match in pairs(self.matches) do
        for k, tile in pairs(match) do
            self.tiles[tile.gridY][tile.gridX] = nil
        end
    end

    self.matches = nil
end

--[[
    Shifts down all of the tiles that now have spaces below them, then returns a table that
    contains tweening information for these new tiles.
]]
function Board:getFallingTiles()
    -- tween table, with tiles as keys and their x and y as the to values
    local tweens = {}

    -- for each column, go up tile by tile till we hit a space
    for x = 1, 8 do
        local space = false
        local spaceY = 0

        local y = 8
        while y >= 1 do

            -- if our last tile was a space...
            local tile = self.tiles[y][x]

            if space then

                -- if the current tile is *not* a space, bring this down to the lowest space
                if tile then

                    -- put the tile in the correct spot in the board and fix its grid positions
                    self.tiles[spaceY][x] = tile
                    tile.gridY = spaceY

                    -- set its prior position to nil
                    self.tiles[y][x] = nil

                    -- tween the Y position to 32 x its grid position
                    tweens[tile] = {
                        y = (tile.gridY - 1) * 32
                    }

                    -- set Y to spaceY so we start back from here again
                    space = false
                    y = spaceY

                    -- set this back to 0 so we know we don't have an active space
                    spaceY = 0
                end
            elseif tile == nil then
                space = true

                -- if we haven't assigned a space yet, set this to it
                if spaceY == 0 then
                    spaceY = y
                end
            end

            y = y - 1
        end
    end

    -- create replacement tiles at the top of the screen
    for x = 1, 8 do
        for y = 8, 1, -1 do
            local tile = self.tiles[y][x]

            -- if the tile is nil, we need to add a new one
            if not tile then

                -- new tile with random color and variety
                if self.level < 6 then
                    tile = Tile(x, y, math.random(18), math.random(self.level))
                else
                    tile = Tile(x, y, math.random(18), math.random(6))
                end
                tile.y = -32
                self.tiles[y][x] = tile

                -- create a new tween to return for this tile to fall down
                tweens[tile] = {
                    y = (tile.gridY - 1) * 32
                }
            end
        end
    end

    return tweens
end

function Board:render()
    for y = 1, #self.tiles do
        for x = 1, #self.tiles[1] do
            self.tiles[y][x]:render(self.x, self.y)
        end
    end
end
