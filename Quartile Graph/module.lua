local module = {}

-- currently only allows for the usecase of line graphs that display the difference of a number compared to others, e.g. X appears below Y in height if X < Y

local pow = math.pow
local sqrt = math.sqrt

local mouseX, mouseY = 0, 0
local currentDeltaFrame = 1/60
local totalDeltaFrame = 0

local width, height 
local average, mode, max, min, total, q1, median, q3
local iqr, lowerwhisker, upperwhisker
local dataSet

local Tmidpoint = 0-- top midpoint
local Bmidpoint = 0-- bottom midpoint
local Mwidth = 0-- marigin width

local path = (...):match('(.+)%.[^.]+$') 

local function magnitude(X, Y, Z)
  return sqrt(pow(X, 2) + pow(Y, 2) + pow(Z, 2))
end

local function cloneTable(tabl)
  local clone = {}
  for i, v in pairs(tabl) do
    clone[i] = v
  end
  return clone
end

local function splitString(text, identifier)
  if identifier == nil then identifier = " " end
  local tabl = {}
  while string.len(text) > 0 do
    local found = string.find(text, identifier)
    if found ~= nil then
      table.insert(tabl, string.sub(text, 1, found - 1))
      text = string.sub(text, found + 1)
    else
      table.insert(tabl, text)
      text = ""
    end
  end
  return tabl
end

local function processDataFile(fileName)
  print("Started Processing", fileName)
  local dataSet = {}
  
  local str, size = love.filesystem.read(path.."/"..fileName) -- read file 
  local lines = splitString(str, "\n") -- split file by lines
  
  for index, line in pairs(lines) do
    local data = splitString(line, ",")
    for i=1, #data do
      if tonumber(data[i]) then
        table.insert(dataSet, tonumber(data[i]))
      end
    end
  end
  
  print("Finished Processing", fileName)
  return dataSet
end

local function getMedian(dataSet)
  table.sort(dataSet)
  if #dataSet % 2 == 1 then -- odd
    return dataSet[math.ceil(#dataSet/2)]
  else -- even
    return dataSet[#dataSet/2]/2 + dataSet[#dataSet/2 + 1]/2
  end
end

local function getStatisticsOnTable(_dataSet)
  local dataSet = cloneTable(_dataSet)
  local average, median, mode = 0, 0, 0
  local total, min, max = 0, 0, 0
  local quartiles = {{}, {}} -- q1 and q3
  local frequencyTable = {}
  median = getMedian(dataSet)
  min = dataSet[1]
  max = dataSet[#dataSet]
  if #dataSet % 2 == 1 then -- Uses "John Tukey's hinges" method
    table.insert(quartiles[1], median)
    table.insert(quartiles[2], median)
  end
  for i=1, #dataSet do
    total = total + dataSet[i]
    if dataSet[i] < median then
      table.insert(quartiles[1], dataSet[i])
    elseif dataSet[i] > median then
      table.insert(quartiles[2], dataSet[i])
    end
    frequencyTable[dataSet[i]] = (frequencyTable[dataSet[i]] or 0) + 1
  end
  quartiles[1] = getMedian(quartiles[1])
  quartiles[2] = getMedian(quartiles[2])
  average = total/#dataSet
  mode = min
  for value, frequency in pairs(frequencyTable) do
    if frequencyTable[value] > frequencyTable[mode] then
      mode = value
    end
  end
  return average, mode, max, min, total, quartiles[1], median, quartiles[2]
end

function module.load()
  width, height = love.graphics.getDimensions( )
  dataSet = processDataFile("data.txt")
  average, mode, max, min, total, q1, median, q3 = getStatisticsOnTable(dataSet)
  iqr = q3 - q1
  lowerwhisker, upperwhisker = q1 - 1.5*iqr, q3 + 1.5*iqr
  print(average, mode, max, min, total, q1, median, q3)
  print(iqr, lowerwhisker, upperwhisker)
  print("Finish Proccessing Data")
  Tmidpoint = height/2 - 150 -- top midpoint
  Bmidpoint = height/2 + 150 -- bottom midpoint
  Mwidth = width - 150 -- marigin width
end

function module.keypressed( key )
  
end

function module.update(delta)
  currentDeltaFrame = delta
  totalDeltaFrame = totalDeltaFrame + delta
  mouseX, mouseY = love.mouse.getPosition() 
end

function renderGraph()
  love.graphics.clear()
  local lines = {}
  for index, point in pairs(dataSet) do
    if point == mode then
      love.graphics.setColor(0, 0, 1)
    else
      love.graphics.setColor(1, 1, 1)
    end
    local x, y = 30 + Mwidth*index/#dataSet, height - (30 + (height - 60)*point/max)
    table.insert(lines, x)
    table.insert(lines, y)
    love.graphics.circle("fill", x, y, 5)
  end
  love.graphics.line( unpack(lines) )
  love.graphics.setColor(0, 1, 0)  
  love.graphics.line(30 + Mwidth*median/max, Tmidpoint, 30 + Mwidth*median/max, Bmidpoint)
  love.graphics.setColor(1, 0, 0)  
  love.graphics.line(30 + Mwidth*upperwhisker/max, Tmidpoint, 30 + Mwidth*upperwhisker/max, Bmidpoint)
  love.graphics.line(30 + Mwidth*lowerwhisker/max, Tmidpoint, 30 + Mwidth*lowerwhisker/max, Bmidpoint)
  love.graphics.line(30 + Mwidth*upperwhisker/max, height/2, 30 + Mwidth*lowerwhisker/max, height/2)
  love.graphics.rectangle("line", 30 + Mwidth*q1/max, height/2 - 150, (30 + Mwidth*q3/max) - (30 + Mwidth*q1/max), 300)
  love.graphics.setColor(0, 0, 0)
end

function module.draw()
  love.graphics.setBackgroundColor(1,1,1)
  renderGraph()
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
