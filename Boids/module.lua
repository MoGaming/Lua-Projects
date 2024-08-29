io.stdout:setvbuf("no")

local module = {}

local ceil = math.ceil
local sqrt = math.sqrt
local pow = math.pow
local abs = math.abs

local mouseX, mouseY = 0, 0
local windowX, windowY = 800, 800

local currentDeltaFrame = 1/60
local canvas = love.graphics.getCanvas( )

local boidsCount = 500
local boidsSpinSpeed = 3
local boidsMoveSpeed = 40
local boids = {}

local halfSize = math.min(windowX/2.0, windowY/2.0)
local borderSize = 300 -- halfSize/2
local offset = halfSize

local boidsLocalMaxRange = 50
local boidsLocalMinRange  = boidsLocalMaxRange/3

local seperationRate = 1.5
local alignmentRate = 1
local cohesionRate = 1

local gridPixelSize = 60
local gridCheckRange = ceil(boidsLocalMaxRange/gridPixelSize)
local boidsGrid = {}

local renderRange = false
local renderGrid = false
local colors = {{1,0,0}, {0,1,0}, {0,0,1}, {1,1,0}, {1,0,1}, {0,1,1}, {0.5,0.5,0.5}, {0,1,1}, {1,1,1}, {0.25,0.5,0.5}, {1,0.25,0.25}}

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

local function magnitude(X, Y)
  return sqrt(pow(X, 2) + pow(Y, 2))
end

local function unitVector(X, Y)
  local sum = magnitude(X, Y)
  return X/abs(sum), Y/abs(sum)
end

local function pixelToGrid(X, Y)
  return ceil(X/gridPixelSize), ceil(Y/gridPixelSize)
end

local function getBoidsData(boidIndex)
  local avgNearbyX, avgNearbyY = 0, 0
  local avgGroupPosX, avgGroupPosY = 0, 0
  local avgGroupDirX, avgGroupDirY = 0, 0
  local nearbyBoids, groupBoids = 0, 0
  
  local info = boids[boidIndex]
  local gridX, gridY = pixelToGrid(info[1], info[2])
  
  for gridIndexX=gridX - gridCheckRange, gridX + gridCheckRange do
    for gridIndexY=gridY - gridCheckRange, gridY + gridCheckRange do
      if boidsGrid[gridIndexX] == nil then
        boidsGrid[gridIndexX] = {}
      end
      if boidsGrid[gridIndexX][gridIndexY] == nil then
        boidsGrid[gridIndexX][gridIndexY] = {}
      end
      for index, otherIndex in pairs(boidsGrid[gridIndexX][gridIndexY]) do
        if otherIndex ~= boidIndex then
          local otherInfo = boids[otherIndex]
          local x, y = otherInfo[1], otherInfo[2]
          local dist = magnitude(x - info[1], y - info[2])
          if dist < boidsLocalMinRange then
            nearbyBoids = nearbyBoids + 1
            avgNearbyX = avgNearbyX + x
            avgNearbyY = avgNearbyY + y
          elseif dist > boidsLocalMinRange and dist < boidsLocalMaxRange then
            groupBoids = groupBoids + 1
            avgGroupPosX = avgGroupPosX + x
            avgGroupPosY = avgGroupPosY + y
            avgGroupDirX = avgGroupDirX + otherInfo[3]
            avgGroupDirY = avgGroupDirY + otherInfo[4]
          end
        end
      end
    end
  end
    
  return avgNearbyX, avgNearbyY, avgGroupPosX, avgGroupPosY, avgGroupDirX, avgGroupDirY, nearbyBoids, groupBoids
end

local function updateGridPosition(index)
  local posX, posY = boids[index][1], boids[index][2]
  local prevGridX, prevGridY = boids[index][6], boids[index][7] 
  local gridX, gridY = pixelToGrid(posX, posY)
  boids[index][6], boids[index][7]  = gridX, gridY
  if boidsGrid[gridX] == nil then
    boidsGrid[gridX] = {}
  end
  if boidsGrid[gridX][gridY] == nil then
    boidsGrid[gridX][gridY] = {}
  end
  if boidsGrid[prevGridX] and boidsGrid[prevGridX][prevGridY] then
    boidsGrid[prevGridX][prevGridY][index] = nil
  end
  boidsGrid[gridX][gridY][index] = index
end

function module.load()
  love.window.setMode(windowX, windowY)
  screenCanvas = love.graphics.newCanvas(windowX, windowY)
  love.window.setTitle("Boids Simulation")
  print("Attempt Load")
  for index = 1, boidsCount do
    local randX, randY, randDirX, randDirY = 2*math.random(-halfSize/4, halfSize/4), 2*math.random(-halfSize/4, halfSize/4), math.random(-30,30)/30, math.random(-30,30)/30
    if randDirX + randDirY == 0 then
      randDirY = 1
    end
    table.insert(boids, {halfSize + randX, halfSize + randY, randDirX, randDirY, math.random(2, 3), -1, -1}) 
      -- X, Y, dirX, dirY, radius, currGridX, currGridY
    updateGridPosition(index)
  end 
  print("Loading Finished") 
  print(love.filesystem.getWorkingDirectory( ))
end

function module.update(delta) 
  currentDeltaFrame = delta
  mouseX, mouseY = love.mouse.getPosition() 
  if delta == 0 then
    delta = 1/60
  end
  local baseSpin = boidsSpinSpeed * delta
  for index, info in pairs(boids) do
    local spin = baseSpin * math.random(9,11)/10
    local avgNearbyX, avgNearbyY, avgGroupPosX, avgGroupPosY, avgGroupDirX, avgGroupDirY, nearbyBoids, groupBoids = getBoidsData(index)
    
    if groupBoids > 0 then
      avgGroupPosX = avgGroupPosX/groupBoids
      avgGroupPosY = avgGroupPosY/groupBoids
      avgGroupDirX = avgGroupDirX/groupBoids
      avgGroupDirY = avgGroupDirY/groupBoids
    
      if avgGroupDirX ~= 0 and avgGroupDirY ~= 0 and info[3] ~= 0 and info[4] ~= 0 then -- double check
        avgGroupDirX, avgGroupDirY = unitVector(avgGroupDirX, avgGroupDirY)
        local ratio = delta * alignmentRate
        info[3] = ratio*avgGroupDirX + (1 - ratio)*info[3]
        info[4] = ratio*avgGroupDirY + (1 - ratio)*info[4]
      end
      if avgGroupPosX ~= 0 and avgGroupPosY ~= 0 then
        local diffX = info[1] - avgGroupPosX
        local diffY = info[2] - avgGroupPosY
        
        if diffX == 0 then
          diffX = 0.05
        end if diffY == 0 then
          diffY = 0.05
        end
        
        local rangeDiff = boidsLocalMaxRange - boidsLocalMinRange
        info[3] = info[3] - spin * diffX/abs(diffX) * clamp(1 - (abs(diffX) - boidsLocalMinRange)/rangeDiff, 0.3, 1)/2 * cohesionRate
        info[4] = info[4] - spin * diffY/abs(diffY) * clamp(1 - (abs(diffY) - boidsLocalMinRange)/rangeDiff, 0.3, 1)/2 * cohesionRate
      end
    end
    if nearbyBoids > 0 then
      avgNearbyX = avgNearbyX/nearbyBoids
      avgNearbyY = avgNearbyY/nearbyBoids
      
      if avgNearbyX ~= 0 and avgNearbyY ~= 0 then -- double check
        local diffX = info[1] - avgNearbyX
        local diffY = info[2] - avgNearbyY
        
        if diffX == 0 then
          diffX = 0.05
        end if diffY == 0 then
          diffY = 0.05
        end
        
        info[3] = info[3] + spin * diffX/abs(diffX) * clamp(1 - abs(diffX)/boidsLocalMinRange, 0.1, 1) * seperationRate
        info[4] = info[4] + spin * diffY/abs(diffY) * clamp(1 - abs(diffY)/boidsLocalMinRange, 0.1, 1) * seperationRate
      end
    end
    
    local boidDistanceX = info[1]-offset 
    local boidDistanceY = info[2]-offset
    
    if boidDistanceY > borderSize then -- print("bottom")
      info[4] = info[4] - baseSpin
      info[3] = info[3] - spin
    elseif boidDistanceX > borderSize then -- print("right")
      info[3] = info[3] - baseSpin
      info[4] = info[4] + spin
    elseif boidDistanceX < -borderSize then -- print("left")
      info[3] = info[3] + baseSpin
      info[4] = info[4] - spin
    elseif boidDistanceY < -borderSize then -- print("top")
      info[4] = info[4] + baseSpin
    end 
    
    local dirX, dirY = unitVector(info[3], info[4])
    info[3], info[4] = dirX, dirY
    
    info[1] = info[1] + dirX*boidsMoveSpeed*delta
    info[2] = info[2] + dirY*boidsMoveSpeed*delta
    
    updateGridPosition(index)
  end
end

function renderBoids()
  love.graphics.clear()
  love.graphics.setColor(0, 0, 0)
  love.graphics.rectangle("line", offset - borderSize, offset - borderSize, 2*borderSize, 2*borderSize)
  love.graphics.setColor(1, 1, 1) -- so first boid isn't black and when renderRange is false, all will be white
  for index, info in pairs(boids) do
    local x,y = info[1], info[2]
    if renderRange then
      love.graphics.setColor(1, 0.3, 0.3)
      love.graphics.circle("line", x, y, boidsLocalMinRange)
      love.graphics.setColor(0.3, 1, 0.3)
      love.graphics.circle("line", x, y, boidsLocalMaxRange)
      love.graphics.setColor(1, 1, 1)
    end
    if renderGrid then
      local currGrid = ceil(info[6] + (info[7] - 1)*(windowX/gridPixelSize)) % #colors + 1
      love.graphics.setColor(colors[currGrid][1], colors[currGrid][2], colors[currGrid][3])
    end
    love.graphics.circle("fill", x, y, info[5])
  end
end

function module.draw() 
  love.graphics.setBackgroundColor(0.3,0.3,1)
  screenCanvas:renderTo(renderBoids)
  love.graphics.draw(screenCanvas)
  love.graphics.setCanvas(canvas)
  love.graphics.setColor(0, 1, 0)
  local deltaRate = tostring(currentDeltaFrame)
  if string.len(deltaRate) < 20 then
    for i=string.len(deltaRate), 20 do
      deltaRate = deltaRate.."0"
    end
  end
  love.graphics.print("FPS: "..love.timer.getFPS().." ("..currentDeltaFrame..")")
end

return module