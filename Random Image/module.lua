io.stdout:setvbuf("no")

local module = {}

local windowX, windowY = 1000, 1000
local size = 100
local precision = 5
local offset = 1

local isGreyScale = true

local tabl = {}
local num = math.random(1,10)

function update()
  for x=offset, size + offset do
    tabl[x] = {}
      for y=offset, size + offset do
        math.randomseed(num*(x*(x + y)))
        if isGreyScale then
          local value = math.random(0, precision)/precision
          tabl[x][y] = {value, value, value}
        else
          tabl[x][y] = {math.random(0,precision)/precision, math.random(0,precision)/precision, math.random(0,precision)/precision}
        end
      end
  end
end

function module.load()
  love.window.setMode(windowX, windowY, {vsync=false})
  screenCanvas = love.graphics.newCanvas(windowX, windowY)
  update()
  print(love.getVersion( ))
end

function module.update(delta)
  
  if love.keyboard.isDown('escape') then
      love.event.quit()
  end
  if love.keyboard.isDown('space') then
      num = num + math.random(1,10)
  end
  update()
end

function module.draw()
  for x, info in pairs(tabl) do
    for y, col in pairs(info) do
      love.graphics.setColor(col[1], col[2], col[3])
      love.graphics.rectangle("fill", (x-offset) * windowX/size, (y-offset) * windowX/size, windowX/size, windowX/size)
    end
  end
  love.graphics.setColor(255, 255, 255) 
end

return module