io.stdout:setvbuf("no")

local module = {}

-- INCOMPLETE, I PLAN TO MAKE THE LINES/ARROWS NICE AND MORE CLEAR TO READ,
--             AND I PLAN TO ADD AN AUTO BRUTEFORCE DISPLAY OF SOLVED DFAS
--             WITH ALL THEIR STRINGS/VALUES.

local mouseX, mouseY = 0, 0
local windowX, windowY = 900, 900
local plrZoom = 2
local zoom = 2

local currentDeltaFrame = 1/60
local mapBorder = windowX*2
local canvas = love.graphics.getCanvas( )

local states = { -- positive = 1, negative = 0
  [1] = {4, -2},
  [2] = {3, -1}, 
  [3] = {2, -4}, 
  [4] = {1, -3} 
}

local total = #states 
local halfSize = math.min(windowX/2.0, windowY/2.0) - 100

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

function module.load()
  love.window.setMode(windowX, windowY, {vsync=false})
  screenCanvas = love.graphics.newCanvas(windowX, windowY)
  love.graphics.setBackgroundColor(1,1,1)
  love.window.setTitle("DFA Solver")
  --table.insert(entities, Player)
  print("Started")
end

function getStatePosition(index, radius)
  if radius == nil then radius = halfSize end
  local i = 2.0 * math.pi * (index-1)/total
  return {(radius * math.cos(i) ) + windowX/2.0, (radius * math.sin(i)) + windowY/2.0}
end

function renderStates()
  love.graphics.clear()
  love.graphics.setColor(1, 1, 1)
  love.graphics.circle("line", windowX/2.0, windowY/2.0, halfSize)
  local fontHeight = love.graphics.getFont():getHeight()
  for stateIndex, nextStates in pairs(states) do
    local pos = getStatePosition(stateIndex)
    love.graphics.circle("line", pos[1], pos[2], 50)
    love.graphics.circle("fill", pos[1], pos[2], 45)
    love.graphics.setColor(0, 0, 0)
    love.graphics.print("State "..tostring(stateIndex - 1), pos[1]-25, pos[2]-fontHeight/2)
    love.graphics.setColor(1, 1, 1)
    for index, pointTo in pairs(nextStates) do
      local state = pointTo > 0 and 1 or 0
      local fromPos = getStatePosition(stateIndex, halfSize - 50)
      local pointToPos = getStatePosition(math.abs(pointTo), halfSize - 50)
      
      local offset = {fromPos[2] - windowX/2, -(fromPos[1] - windowY/2)}
      local size = math.sqrt(offset[1]*offset[1] + offset[2]*offset[2])
      offset = {offset[1]/size, offset[2]/size}
      
      local offsetDistance = 65 * (state*2-1)
      local isLeftSide = fromPos[1] > halfSize and 1 or 0
      
      local middleOffset = 0.75
      local middle = {pointToPos[1]*middleOffset+fromPos[1]*(1-middleOffset), pointToPos[2]*middleOffset+fromPos[2]*(1-middleOffset)}
      middle = {middle[1] + offset[1]*offsetDistance, middle[2] + offset[2]*offsetDistance}
      love.graphics.line(fromPos[1], fromPos[2], middle[1], middle[2], pointToPos[1], pointToPos[2])
      love.graphics.setColor(0, 1, 0)
      love.graphics.print(tostring(state)..": ".. tostring(stateIndex-1).." -> "..tostring(math.abs(pointTo) - 1), middle[1] - isLeftSide*25, middle[2])
      love.graphics.setColor(1, 1, 1)
      
      --TODO: ARROWS and smoothing out the middle stuff
    end
  end
end

function module.update(delta)
  currentDeltaFrame = delta
  mouseX, mouseY = love.mouse.getPosition() 
end

function module.draw()
  love.graphics.clear()
  screenCanvas:renderTo(renderStates)
  love.graphics.draw(screenCanvas)
  love.graphics.setCanvas(canvas)
  love.graphics.setColor(0, 1, 0)
  love.graphics.print("FPS: "..love.timer.getFPS().." ("..string.len(tostring(currentDeltaFrame))..", "..currentDeltaFrame..")")
end

return module