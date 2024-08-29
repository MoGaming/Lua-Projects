io.stdout:setvbuf("no")

local module = {}
-- very much so WIP but I will probably never finish it, main character is supposed to have a swinging grapple and the jump animation doesn't seem to play

local path = (...):match('(.+)%.[^.]+$') -- get current path of file, thanks to "Elias Josué" for providing this code and steveRoll for explaining the alternative use of "..." in modules.
                            -- explanation: require's only parameter refers to the path of the module we want to require, only way to access this is with "..." which I use to get relative path of files.

local mouseX, mouseY = 0, 0
local windowX, windowY = 900, 700
local plrZoom = 2
local zoom = 2

mapBorder = windowX*2
screenCanvas = nil
Classic = nil
Creator = nil
Player = nil
currentDeltaFrame = 0

local PlayerSize = {16, 16}
local PlayerState = "Idle"
local PlayerStates = {
  ["Idle"] = {1, 2, 2}, -- frame row, frame start, frame count
  ["Jump"] = {2, 2, 2},
}
local PlayerFrames = {}
local PlayerFrame = 1

local entities = {}

local globalTime = 0
local timeSpeed = 1
local timers = {}

local tilemap = {}

local function clamp(val, lower, upper)
  local _val = val
  if val < lower then
    _val = lower
  end
  if val > upper then
    _val = upper
  end
  return _val
end

local function getTimer(num)
  if timers[num] == nil then
    for i=#timers+1, (num - #timers)+1 do
       timers[i] = globalTime + (num/10)
    end
    
    return false
  else 
    local returnValue = (timers[num] <= globalTime)
    
    if returnValue then
      timers[num] = globalTime + (num/10)
    end
    
    return returnValue
  end
end

local function updateEntities(dt)
  for _, entity in pairs(entities) do
    entity.update(entity, dt)
  end
end

local function drawEntities()
  for _, entity in pairs(entities) do
    entity.draw(entity)
  end
end

local function updateAllTimers()
  for i=1, #timers do
    getTimer(i)
  end
end

function module.load()
  Classic = require (path..".classic")
  require (path..".creator")
  love.window.setMode(windowX, windowY, {vsync=false})
  screenCanvas = love.graphics.newCanvas(windowX*10, windowY*10)
  love.window.setTitle("The Platformers")
  Player = Creator({0, 0}, {14, 14}, 0, path.."/grappler character.png", {1, 1}, {0, 0}, "rect")
  Player.Velocity = {0,0}
  Player.Weight = 1
  --table.insert(entities, Player)
  print("Started")
  
  for x=1, Player.image:getWidth()/PlayerSize[1] do
    for y=1, Player.image:getHeight()/PlayerSize[2] do
      PlayerFrames[y] = PlayerFrames[y] or {}
      PlayerFrames[y][x] = love.graphics.newQuad(1 + x * (PlayerSize[1]), 1 + y * PlayerSize[2] - PlayerSize[2], PlayerSize[1] - 2, PlayerSize[2] - 2, Player.image:getWidth(), Player.image:getHeight())
    end  end
  
  Player.pos[2] = windowY/2
  
  for y=1, math.ceil((windowY*1.96666667)/14) + 1 do
    tilemap[y] = {}
    for x=1, math.ceil((windowX*2.97500)/14) + 1 do
      tilemap[y][x] = 0
    end
  end
  
  -- these 2 lines are from a tutorial I had followed when I first started learning LOVE2D
  background = love.graphics.newImage(path.."/yourbackgroundfile.png")
  frontground = love.graphics.newImage(path.."/Frontground.png")
end

function module.update(delta)
  delta = math.min(delta, 1/15)
  currentDeltaFrame = delta
  if PlayerFrame > PlayerStates[PlayerState][3] + PlayerStates[PlayerState][2] - 1 then
    PlayerFrame = PlayerStates[PlayerState][2] - 1
  end
  PlayerFrame = PlayerFrame + (PlayerStates[PlayerState][3] * delta * (timeSpeed/3))
  globalTime = globalTime + (1 * delta * timeSpeed)
  mouseX, mouseY = love.mouse.getPosition() 
  
  updateEntities(delta)
  
  local speed = 25 * delta
  
  if love.keyboard.isDown('escape') then
      love.event.quit()
  end
  if love.keyboard.isDown('d') then
      Player.Velocity[1] = Player.Velocity[1] + speed
  end
  if love.keyboard.isDown('a') then
      Player.Velocity[1] = Player.Velocity[1] - speed
  end
  if love.keyboard.isDown('s') then
      Player.Velocity[2] = Player.Velocity[2] + speed
  end
  if love.keyboard.isDown('w') and getTimer(10) and Player.pos[2] >= (windowY*2 - (PlayerSize[1]*plrZoom)) - 1 then
      print("jumped", Player.Velocity[2])
      Player.Velocity[2] = Player.Velocity[2] - (1.5)
  end
  
  Player.pos = {Player.pos[1] + Player.Velocity[1], Player.pos[2] + Player.Velocity[2]}
  
  local grounded = Player.pos[2] >= (windowY*2 - (PlayerSize[1]*plrZoom)) - 1
  Player.Velocity = {Player.Velocity[1] * 0.95, (not grounded and Player.Velocity[2] + (Player.Weight * Player.Gravity * delta) or 0)}
  
  Player.pos = {clamp(Player.pos[1], 0, windowX*3 - (PlayerSize[1]*plrZoom)), clamp(Player.pos[2], 0, windowY*2 - (PlayerSize[1]*plrZoom))}
   --print(Player.pos[1], Player.pos[2])
   --print(Player.Velocity[1], Player.Velocity[2])
end

local function drawGame()
    love.graphics.push() 
      --love.graphics.translate(-Player.pos[1] + windowX/2 - Player.size[1]/2, -Player.pos[2] + windowY/2 - Player.size[2]/2)
      Player.image:setFilter('nearest', 'nearest')
      love.graphics.draw(Player.image, PlayerFrames[PlayerStates[PlayerState][1]][math.floor(PlayerFrame)], math.ceil(Player.pos[1]), math.ceil(Player.pos[2]), 0, plrZoom, plrZoom)
      love.graphics.setBackgroundColor(0.65, 1, 1)
      drawEntities()
    love.graphics.pop() 
end

function module.draw()
    for i = 0, (mapBorder / background:getWidth()) * 2 do
        for j = 0, (windowY / background:getHeight()) * 3 do
            local r,g,b = 1 - math.sin(globalTime*j)/10,1 - j/((windowY / background:getHeight()) * 3),1 - j/((windowY / background:getHeight()) * 3)
            love.graphics.setColor(r,g,b)
            love.graphics.draw(background, i * background:getWidth() - Player.pos[1], j * background:getHeight() - Player.pos[2])
        end
    end

	love.graphics.setColor(1, 1, 1)
  screenCanvas:setFilter('nearest', 'nearest')
  
  local _windowX, _windowY = -Player.pos[1] + windowX/2 - Player.size[1]/2, -Player.pos[2] + windowY/2 - Player.size[2]/2
  if zoom == 2 then
    _windowX, _windowY = clamp(-_windowX + windowX/4, -15, mapBorder + windowX/2 + 15), clamp(-_windowY + windowY/4, 0, windowY + windowY/2 + 10)
  else
    _windowX, _windowY = clamp(-_windowX, -15, mapBorder + 15), clamp(-_windowY, 0, windowY + 10)
  end
  
  love.graphics.setCanvas(screenCanvas)
      love.graphics.clear()
      drawGame()
  love.graphics.setCanvas()
  love.graphics.draw(screenCanvas, 0,0,0,zoom,zoom,_windowX,_windowY)
  
	love.graphics.setColor(1, 1, 1, 0.6)
	love.graphics.rectangle('fill', 0, (globalTime * 350) % windowY, windowX, 5)
	love.graphics.rectangle('fill', 0, (globalTime * 350) % windowY - (9 + (math.sin(globalTime) * 3)), windowX, 3)
	love.graphics.setColor(1, 1, 1, 0.9)
  love.graphics.draw(frontground, 0,0)
  
  love.graphics.print("FPS: "..love.timer.getFPS().." ("..string.len(tostring(currentDeltaFrame))..", "..currentDeltaFrame..")")
end

return module