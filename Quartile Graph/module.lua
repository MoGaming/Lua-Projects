local module = {}

-- disable graph
-- display median, mean, mode
-- display the 3 quartile lines
-- display IQR Box (Q3-Q1) 
-- display lower and upper whiskers (inlier range) and outlier red zone (marked by red cross hatching)
-- display min, max, IQRmin, IQRmax
-- display IQR average, mean, mode

local pow = math.pow
local sqrt = math.sqrt

local mouseX, mouseY = 0, 0
local currentDeltaFrame = 1/60
local totalDeltaFrame = 0

local path = (...):match('(.+)%.[^.]+$') 

local function magnitude(X, Y, Z)
  return sqrt(pow(X, 2) + pow(Y, 2) + pow(Z, 2))
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

local function getStatisticsOnTable(dataSet)
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
    if frequencyTable[value] < frequency then
      mode = value
    end
  end
  return average, mode, max, min, total, quartiles[1], median, quartiles[2]
end

function module.load()
  local dataSet = processDataFile("data.txt")
  print(getStatisticsOnTable(dataSet))
end

function module.keypressed( key )
  
end

function module.update(delta)
  currentDeltaFrame = delta
  totalDeltaFrame = totalDeltaFrame + delta
  mouseX, mouseY = love.mouse.getPosition() 
end

function module.draw()
  love.graphics.setBackgroundColor(1,1,1)
  
  local str = "FPS: "..love.timer.getFPS().." ("..string.len(tostring(currentDeltaFrame))..", "..currentDeltaFrame..")"
  love.graphics.print(str)
end

return module