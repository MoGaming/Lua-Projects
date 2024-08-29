io.stdout:setvbuf("no")
local module = {}
-- this program takes time to load, edit the settings to make it faster, e.g. lower maxiterations = faster loading
local windowX, windowY = 1000, 1000
local size = 1000
local offsetx, offsety = 0, 0
local zoom = 1
local tabl = {}

local c = 0
local maxiterations = 1000

local colors = {}

local smallconst = 0.000000001
local isMandelbrot = false

local templist = {{0,0,1}, {1,0,0}, {0,1,0}, {1, 1, 0}, {1, 0, 1}, {0, 1, 1}, {1, 1, 1}}
for i=1, 15 do
  for _, v in pairs(templist) do
    table.insert(colors, {v[1]*i/15, v[2]*i/15, v[3]*i/15})
  end
end

function getString()
 local length = math.random(2, 10) 
 local str = ""
 for i=1, length do
   if i%2 == 0 then
     str = str.."A"
   else
     str = str.."B"
    end
  end
  print(str)
  return str
end

function getNChar(str, n)
  return string.sub(str, n, n)
end

function update()
  --tabl = {}
  local str = "AB" -- getString()
  for x=0, size*1.25, 1/zoom do
    if x > offsetx and x < offsetx + windowX/zoom then
      for y=0, size, 1/zoom do
        if y > offsety and y < offsety + windowY/zoom then
          if tabl[x] == nil then
            tabl[x] = {}
          end
          
          if not isMandelbrot then
            local sx, sy = 4.0*(x)/size, 4.0*(size - y)/size
            
            local x0, xn = 0.5, 0.5
            local exponent = 0
            
            for iteration=1, maxiterations do
              local rn = getNChar(str, ((iteration - 1) % string.len(str)) + 1 )
              if rn == "A" then rn = sx else rn = sy end
              xn = rn * xn * (1 - xn)
              exponent = exponent + math.log(smallconst + math.abs(rn * (1 - 2 * xn)))/maxiterations
            end
            
            tabl[x][y] = {(exponent + smallconst) % 1, 1/exponent, exponent/maxiterations}
          else
            local r, g, b = 0, 0, 0
            local iterations = 0
            local ix, iy = 0, 0
            
            local sx, sy = 2.47*(x)/size - 2.00, 2.24*(y)/size - 1.12
            
            while ix*ix + iy*iy <= 4 and iterations < maxiterations do
              local xtemp = ix*ix - iy*iy + sx
              iy = 2*ix*iy + sy
              ix = xtemp
              iterations = iterations + 1
            end
            
            if iterations >= 1 then
              tabl[x][y] = colors[iterations] or {r/iterations, math.ceil(10/iterations)/10, (iterations/255) % 1}
            end
          end
        end 
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
end

function module.keypressed( key )
  if key == "e" then
    zoom = zoom + 1
  elseif key == "q" then
    zoom = zoom - 1
  end
  if key == "x" then
    maxiterations = maxiterations + 1
    update()
  elseif key == "v" then
    maxiterations = maxiterations + 100
    update()
  elseif key == "c" then
    maxiterations = maxiterations - 1
    update()
  end
  print(maxiterations)
end

function module.draw()
  local height, width = windowX/size*zoom, windowY/size*zoom
  
  for x, info in pairs(tabl) do
    for y, col in pairs(info) do
      local xmap = (x-offsetx) * height
      local ymap = (y-offsety) * width
      
      love.graphics.setColor(col[1], col[2], col[3])
      love.graphics.rectangle("fill", xmap, ymap, 1, 1)
    end
  end
end

return module