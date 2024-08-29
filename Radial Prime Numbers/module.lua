io.stdout:setvbuf("no")
local module = {}
-- this program displays polar coordinates (p,p) where p are the same prime number then coverts it into cartisan plane and displays it
local windowX, windowY = 1000, 1000
local size = 1000
local offsetx, offsety = 0, 0
local zoom = 1
local tabl = {}
local tooltip

local showLines = false
local lines = {}

function update()
  lines = {}
  for i=1, size*2 do
    local x,y = polarToCartesian(i,i)
    x, y = x, -y -- increases precision, negative y because Love2D goes positive x and positive y going down and to the right
    x, y = math.floor(x + 0.5 + size/2), math.floor(y + 0.5 + size/2)
    if tabl[x] == nil then
      tabl[x] = {}
    end
    if prime(i) then
      tabl[x][y] = {1,0.6,0.3}
      table.insert(lines, (x-offsetx) * windowX/size*zoom)
      table.insert(lines, (y-offsety) * windowX/size*zoom)
    else
      tabl[x][y] = {0.3,0.3,0.3}
    end
  end 
  tabl[math.floor(size/2 + 0.5)][math.floor(size/2 + 0.5)] = {1, 0, 0}
end

function prime(n)
    for i = 2, n^(1/2) do
        if (n % i) == 0 then
            return false
        end
    end
    return true
end

function polarToCartesian(r, theta)
  return r*math.cos(theta), r*math.sin(theta)
end

function cartesianToPolar(x, y)
  local r = math.sqrt( math.pow(x, 2) + math.pow(y, 2) )
  local theta = math.atan2(y, x)
  return r, theta
end

function module.load()
  love.window.setMode(windowX, windowY, {vsync=false})
  screenCanvas = love.graphics.newCanvas(windowX, windowY)
  
  local font = love.graphics.getFont()
  love.graphics.setLineStyle("smooth")
  tooltip = love.graphics.newText(font, {{1,1,1}, "0, 0"})
  
  update()
  print(love.getVersion( ))
end

function module.update(delta)
  if love.keyboard.isDown('escape') then
      love.event.quit()
  end
  
  local speed = 15 * delta * math.max((6 - zoom), 1)
  if love.keyboard.isDown('a') then
    offsetx = offsetx - speed
  elseif love.keyboard.isDown('d') then
    offsetx = offsetx + speed
  end
  if love.keyboard.isDown('w') then
    offsety = offsety - speed
  elseif love.keyboard.isDown('s') then
    offsety = offsety + speed
  end
  zoom = math.min(math.max(zoom, 1), 10)
end

function module.keypressed( key )
  if key == "e" then
    zoom = zoom + 1
  end
  if key == "q" then
    zoom = zoom - 1
  end
  if key == "l" then
    showLines = not showLines
    update()
  end
end

function module.draw()
  local height, width = windowX/size*zoom, windowY/size*zoom
  if showLines then
    love.graphics.setColor(1,0.6,0.3)
    love.graphics.line(lines)
  end
  
  for x, info in pairs(tabl) do
    for y, col in pairs(info) do
      local xmap = (x-offsetx) * windowX/size*zoom
      local ymap = (y-offsety) * windowX/size*zoom
      
      love.graphics.setColor(col[1], col[2], col[3])
      love.graphics.rectangle("fill", xmap, ymap, height, width)
    end
  end
    
  love.graphics.setColor(255, 255, 255) 
  local x, y = love.mouse.getPosition()
  local textX = math.floor(10*((x/zoom + offsetx) - size/2 ))/10
  local textY = math.floor(10*((y/zoom + offsety) - size/2 ))/10
  local r, theta = cartesianToPolar(textX, textY)
  r = math.ceil(r)
  theta = math.ceil(theta*100)/100
  tooltip:set({{1,1,1}, textX ..", ".. textY..(prime(math.floor(r/math.sqrt(2) + 0.5)) and ("\n "..r..", ".. theta) or "").. "\n "..zoom.."x Zoom" })
  love.graphics.draw (tooltip, x+10, y-2)
end

return module