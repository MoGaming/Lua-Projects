local module = {}

local pow = math.pow
local sqrt = math.sqrt

local mouseX, mouseY = 0, 0
local currentDeltaFrame = 1/60
local totalDeltaFrame = 0

local width, height
local average, mode, max, min, total, q1, median, q3
local iqr, lowerwhisker, upperwhisker
local dataSet

local Mwidth = 0 -- margin width (usable horizontal space)
local Mheight = 0 -- margin height (usable vertical space)
local margin = 30

local boxColumnWidth = 100 -- width reserved for the vertical box plot
local boxColumnGap = 40    -- gap between the line graph and the box plot
local boxWidth = 60        -- width of the box itself within its column
local graphWidth = 0       -- width available to the line graph (Mwidth minus the box column)
local boxCenterX = 0       -- x position of the box plot's centre line

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
  median = getMedian(dataSet) -- sorts dataSet as a side effect
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

local function valueToY(point)
  return height - (margin + Mheight * (point - min) / (max - min))
end

local function indexToX(index)
  if #dataSet <= 1 then return margin end
  return margin + graphWidth * (index - 1) / (#dataSet - 1)
end

function module.load()
  width, height = love.graphics.getDimensions()
  dataSet = processDataFile("data.txt")
  average, mode, max, min, total, q1, median, q3 = getStatisticsOnTable(dataSet)
  iqr = q3 - q1
  lowerwhisker, upperwhisker = q1 - 1.5*iqr, q3 + 1.5*iqr
  -- clamp whiskers to the actual data range so they don't get drawn off-chart
  lowerwhisker = math.max(lowerwhisker, min)
  upperwhisker = math.min(upperwhisker, max)
  print(average, mode, max, min, total, q1, median, q3)
  print(iqr, lowerwhisker, upperwhisker)
  print("Finish Processing Data")
  Mwidth = width - margin*2   -- usable horizontal space
  Mheight = height - margin*2 -- usable vertical space
  graphWidth = Mwidth - boxColumnGap - boxColumnWidth
  boxCenterX = margin + graphWidth + boxColumnGap + boxColumnWidth/2
end

function module.keypressed( key )

end

function module.update(delta)
  currentDeltaFrame = delta
  totalDeltaFrame = totalDeltaFrame + delta
  mouseX, mouseY = love.mouse.getPosition()
end

local function renderLineGraph()
  love.graphics.setColor(1, 1, 1)
  local lines = {}
  for index, point in ipairs(dataSet) do
    table.insert(lines, indexToX(index))
    table.insert(lines, valueToY(point))
  end
  if #lines >= 4 then
    love.graphics.line(unpack(lines))
  end
  for index, point in ipairs(dataSet) do
    if point == mode then
      love.graphics.setColor(0, 0, 1)
    else
      love.graphics.setColor(1, 1, 1)
    end
    love.graphics.circle("fill", indexToX(index), valueToY(point), 5)
  end
end

local function renderBoxPlot()
  local left = boxCenterX - boxWidth/2
  local boxTop = valueToY(q3)
  local boxBottom = valueToY(q1)
  local medianY = valueToY(median)
  local upperY = valueToY(upperwhisker)
  local lowerY = valueToY(lowerwhisker)
  local capHalf = boxWidth/2 * 0.5

  -- Whisker stems (box edge to whisker cap)
  love.graphics.setColor(0, 0, 0)
  love.graphics.line(boxCenterX, boxTop, boxCenterX, upperY)
  love.graphics.line(boxCenterX, boxBottom, boxCenterX, lowerY)

  -- Whisker caps
  love.graphics.line(boxCenterX - capHalf, upperY, boxCenterX + capHalf, upperY)
  love.graphics.line(boxCenterX - capHalf, lowerY, boxCenterX + capHalf, lowerY)

  -- Box (Q1 to Q3)
  love.graphics.setColor(0, 1, 0, 0.25)
  love.graphics.rectangle("fill", left, boxTop, boxWidth, boxBottom - boxTop)
  love.graphics.setColor(0, 0, 0)
  love.graphics.rectangle("line", left, boxTop, boxWidth, boxBottom - boxTop)

  -- Median line
  love.graphics.setColor(1, 0, 0)
  love.graphics.line(left, medianY, left + boxWidth, medianY)
end

local function renderGraph()
  love.graphics.setBackgroundColor(0.5,0.5,1)
  renderLineGraph()
  renderBoxPlot()
  love.graphics.setColor(0, 0, 0)
end

function module.draw()
  renderGraph()
  love.graphics.setColor(0, 1, 0)
  love.graphics.print(string.format("FPS: %d (%.5f)", love.timer.getFPS(), currentDeltaFrame))
end

return module
