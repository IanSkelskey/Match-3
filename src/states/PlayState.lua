--[[
  GD50
  Match-3 Remake

  -- PlayState Class --

  Author: Colton Ogden
  cogden@cs50.harvard.edu

  State in which we can actually play, moving around a grid cursor that
  can swap two tiles; when two tiles make a legal swap (a swap that results
  in a valid match), perform the swap and destroy all matched tiles, adding
  their values to the player's point score. The player can continue playing
  until they exceed the number of points needed to get to the next level
  or until the time runs out, at which point they are brought back to the
  main menu or the score entry menu if they made the top 10.
]]

PlayState = Class{__includes = BaseState}

function PlayState:init()

  -- start our transition alpha at full, so we fade in
  self.transitionAlpha = 1

  -- position in the grid which we're highlighting
  self.boardHighlightX = 0
  self.boardHighlightY = 0

  -- timer used to switch the highlight rect's color
  self.rectHighlighted = false

  -- flag to show whether we're able to process input (not swapping or clearing)
  self.canInput = true

  -- tile we're currently highlighting (preparing to swap)
  self.selected_tile = nil

  self.score = 0
  self.timer = 60

  -- set our Timer class to turn cursor highlight on and off
  Timer.every(0.5, function()
      self.rectHighlighted = not self.rectHighlighted
  end)

  -- subtract 1 from timer every second
  Timer.every(1, function()
      self.timer = self.timer - 1

      -- play warning sound on timer if we get low
      if self.timer <= 5 then
          gSounds['clock']:play()
      end
  end)
end

function PlayState:enter(params)

  -- grab level # from the params we're passed
  self.level = params.level

  -- spawn a board and place it toward the right
  self.board = params.board or Board(VIRTUAL_WIDTH - 272, 16)

  -- track # of matches
  self.matches = self.board:calculateMatches()

  -- grab score from params if it was passed
  self.score = params.score or 0

  -- score we have to reach to get to the next level
  self.scoreGoal = self.level * 1.25 * 1000
end

function PlayState:update(dt)
  if love.keyboard.wasPressed('escape') then
      love.event.quit()
  end

  -- go back to start if time runs out
  if self.timer <= 0 then

      -- clear timers from prior PlayStates
      Timer.clear()

      gSounds['game-over']:play()

      gStateMachine:change('game-over', {
          score = self.score
      })
  end

  -- go to next level if we surpass score goal
  if self.score >= self.scoreGoal then

      -- clear timers from prior PlayStates
      -- always clear before you change state, else next state's timers
      -- will also clear!
      Timer.clear()

      gSounds['next-level']:play()

      -- change to begin game state with new level (incremented)
      gStateMachine:change('begin-game', {
          level = self.level + 1,
          score = self.score
      })
  end

  if self.canInput then
      -- move cursor around based on bounds of grid, playing sounds
      if love.keyboard.wasPressed('up') then
          self.boardHighlightY = math.max(0, self.boardHighlightY - 1)
          gSounds['select']:play()
      elseif love.keyboard.wasPressed('down') then
          self.boardHighlightY = math.min(7, self.boardHighlightY + 1)
          gSounds['select']:play()
      elseif love.keyboard.wasPressed('left') then
          self.boardHighlightX = math.max(0, self.boardHighlightX - 1)
          gSounds['select']:play()
      elseif love.keyboard.wasPressed('right') then
          self.boardHighlightX = math.min(7, self.boardHighlightX + 1)
          gSounds['select']:play()
      end

      -- if we've pressed enter, to select or deselect a tile...
      if love.keyboard.wasPressed('enter') or love.keyboard.wasPressed('return') then

          -- if same tile as currently highlighted, deselect
          local x = self.boardHighlightX + 1
          local y = self.boardHighlightY + 1

          -- if nothing is highlighted, highlight current tile
          if not self.selected_tile then
              self.selected_tile = self.board.tiles[y][x]

          -- if we select the position already highlighted, remove highlight
          elseif self.selected_tile == self.board.tiles[y][x] then
              self.selected_tile = nil

          -- if the difference between X and Y combined of this highlighted tile
          -- vs the previous is not equal to 1, also remove highlight
          elseif math.abs(self.selected_tile.gridX - x) + math.abs(self.selected_tile.gridY - y) > 1 then
              gSounds['error']:play()
              self.selected_tile = nil
          else

              --SWAP BEGIN

              -- swap grid positions of tiles
              local tempX = self.selected_tile.gridX
              local tempY = self.selected_tile.gridY

              local newTile = self.board.tiles[y][x]

              self.selected_tile.gridX = newTile.gridX
              self.selected_tile.gridY = newTile.gridY
              newTile.gridX = tempX
              newTile.gridY = tempY

              -- swap tiles in the tiles table
              self.board.tiles[self.selected_tile.gridY][self.selected_tile.gridX] =
                  self.selected_tile

              self.board.tiles[newTile.gridY][newTile.gridX] = newTile

              self.matches = self.board:calculateMatches()

              -- finish tween in matches
              if self.matches then

                  -- tween coordinates between the two so they swap
                  Timer.tween(0.1, {
                      [self.selected_tile] = {x = newTile.x, y = newTile.y},
                      [newTile] = {x = self.selected_tile.x, y = self.selected_tile.y}
                  })

                  -- once the swap is finished, we can tween falling blocks as needed
                  :finish(function()
                      self:calculateMatches()
                  end)

                  --SWAP END
              else
                  -- swap back if no matches
                  tempX = self.selected_tile.gridX
                  tempY = self.selected_tile.gridY

                  self.selected_tile.gridX = newTile.gridX
                  self.selected_tile.gridY = newTile.gridY

                  newTile.gridX = tempX
                  newTile.gridY = tempY

                  -- swap tiles in the tiles table
                  self.board.tiles[self.selected_tile.gridY][self.selected_tile.gridX] = self.selected_tile
                  self.board.tiles[newTile.gridY][newTile.gridX] = newTile

                  -- play error sound
                  gSounds["error"]:play()
                  self.selected_tile = nil
              end



          end

      end

      -- fill matches table
      self.matches = self.board:calculateMatches()

  end

  Timer.update(dt)
end

--[[
  Calculates whether any matches were found on the board and tweens the needed
  tiles to their new destinations if so. Also removes tiles from the board that
  have matched and replaces them with new randomized tiles, deferring most of this
  to the Board class.
]]
function PlayState:calculateMatches()
  self.selected_tile = nil

  -- if we have any matches, remove them and tween the falling blocks that result
  local matches = self.board:calculateMatches()

  if matches then
      gSounds['match']:stop()
      gSounds['match']:play()

      -- add score for each match
      for k, match in pairs(matches) do
          self.score = self.score + #match * 50
          self.timer = self.timer + #match
      end


      -- remove any tiles that matched from the board, making empty spaces
      self.board:removeMatches()

      -- gets a table with tween values for tiles that should now fall
      local tilesToFall = self.board:getFallingTiles()

      -- tween new tiles that spawn from the ceiling over 0.25s to fill in
      -- the new upper gaps that exist
      Timer.tween(0.25, tilesToFall):finish(function()

          -- recursively call function in case new matches have been created
          -- as a result of falling blocks once new blocks have finished falling
          self:calculateMatches()
      end)

  -- if no matches, we can continue playing
  else
      self.canInput = true


  end
end

function PlayState:swapTiles(tile_1, tile_2)



end

function PlayState:render()
  -- render board of tiles
  self.board:render()

  -- render highlighted tile if it exists
  if self.selected_tile then

      -- multiply so drawing white rect makes it brighter
      love.graphics.setBlendMode('add')

      love.graphics.setColor(1, 1, 1, 96/255)
      love.graphics.rectangle('fill', (self.selected_tile.gridX - 1) * 32 + (VIRTUAL_WIDTH - 272),
          (self.selected_tile.gridY - 1) * 32 + 16, 32, 32, 4)

      -- back to alpha
      love.graphics.setBlendMode('alpha')
  end

  -- render highlight rect color based on timer
  if self.rectHighlighted then
      love.graphics.setColor(217/255, 87/255, 99/255, 1)
  else
      love.graphics.setColor(172/255, 50/255, 50/255, 1)
  end

  -- draw actual cursor rect
  love.graphics.setLineWidth(4)
  love.graphics.rectangle('line', self.boardHighlightX * 32 + (VIRTUAL_WIDTH - 272),
      self.boardHighlightY * 32 + 16, 32, 32, 4)

  -- GUI text
  love.graphics.setColor(56/255, 56/255, 56/255, 234/255)
  love.graphics.rectangle('fill', 16, 16, 186, 116, 4)

  love.graphics.setColor(99/255, 155/255, 1, 1)
  love.graphics.setFont(gFonts['medium'])
  love.graphics.printf('Level: ' .. tostring(self.level), 20, 24, 182, 'center')
  love.graphics.printf('Score: ' .. tostring(self.score), 20, 52, 182, 'center')
  love.graphics.printf('Goal : ' .. tostring(self.scoreGoal), 20, 80, 182, 'center')
  love.graphics.printf('Timer: ' .. tostring(self.timer), 20, 108, 182, 'center')

  -- print matches for debug
  if self.matches then
      love.graphics.printf('Match?: ' .. tostring(true), 20, 216, 182, 'center')
  else
      love.graphics.printf('Match?: ' .. tostring(false), 20, 216, 182, 'center')
  end
end
