io.stdout:setvbuf("no")
local module = {}

local windowX, windowY = 1000, 1000
local size = 1000
local offsetx, offsety = 0, 0
local zoom = 1
local tabl = {}

local sideLength = 400
local shape = "Square"

local half = math.ceil(sideLength/2)
local middle = {math.ceil(windowX/2), math.ceil(windowY/2)}

local directionVector = {1/math.sqrt(2), 1/math.sqrt(2)}
local projpos = {middle[1] + 3*math.random(-10,10), middle[2] + 3*math.random(-10,10)}
local projspeed = 120

function update()
  for i=-half, half do
    tabl[i + middle[1]] = {}
    tabl[i + middle[1]][middle[1] - half] = {1,1,1}
    tabl[i + middle[1]][middle[1] + half] = {1,1,1}
    if math.abs(i) == half then
      for j=-half, half do
        tabl[i + middle[1]][j + middle[2]] = {1,1,1}
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
  
  local dist = math.sqrt(math.pow(directionVector[1], 2) + math.pow(directionVector[2], 2))
  directionVector = {directionVector[1]/dist, directionVector[2]/dist}
  
  projpos = {projpos[1]+directionVector[1]*delta*projspeed, projpos[2]+directionVector[2]*delta*projspeed}
  print(projpos[1], projpos[2])
end

function module.keypressed( key )
  if key == "e" then
    zoom = zoom + 1
  end
  if key == "q" then
    zoom = zoom - 1
  end
  
  if key == "l" then
    directionVector[1] = directionVector[1] + 2 * math.random(-2, 2)
    directionVector[2] = directionVector[2] - 2 * math.random(-1, 1)
  end
end

function module.draw()
  local height, width = windowX/size*zoom, windowY/size*zoom
  
  for x, info in pairs(tabl) do
    for y, col in pairs(info) do
      local xmap = (x-offsetx) * windowX/size*zoom
      local ymap = (y-offsety) * windowY/size*zoom
      
      love.graphics.setColor(col[1], col[2], col[3])
      love.graphics.rectangle("fill", xmap, ymap, height, width)
    end
  end
  
  local currx = projpos[1]
  local curry = projpos[2]
  
  local absposx=math.abs(currx)
  local distoffx=((absposx-half)%sideLength) * (math.floor((absposx+half)/sideLength)%2 * -2 + 1)
  currx = (((currx/absposx)*(distoffx-half) + half) % sideLength) - half + middle[1]
  
  local absposy=math.abs(curry)
  local distoffy=((absposy-half)%sideLength) * (math.floor((absposy+half)/sideLength)%2 * -2 + 1)
  curry = (((curry/absposy)*(distoffy-half) + half) % sideLength) - half + middle[2]
  
  love.graphics.setColor(1, 0, 0)
  love.graphics.rectangle("fill", math.ceil(currx-offsetx) * windowX/size*zoom, math.ceil(curry-offsety) * windowY/size*zoom, 2*height, 2*width)
end

return module