local module = {}

-- fumo.obj found online from sketchfab by Renafox, but modified to use less vertices, triangulate faces and fix small holes

local pow = math.pow
local sqrt = math.sqrt

local mouseX, mouseY = 0, 0
local currentDeltaFrame = 1/60
local totalDeltaFrame = 0

local path = (...):match('(.+)%.[^.]+$') 

local scale = 1
local xMove, yMove, zMove = 0, 0, 0

local function xAxisMatrix(deg)
  local theta = math.rad(deg)
  return { 
      {1, 0, 0},
      {0, math.cos(theta), -math.sin(theta)},
      {0, math.sin(theta), math.cos(theta)}
    }
end
local function yAxisMatrix(deg)
  local theta = math.rad(deg)
  return { 
      {math.cos(theta), 0, math.sin(theta)},
      {0, 1, 0},
      {-math.sin(theta), 0, math.cos(theta)}
    }
end
local function zAxisMatrix(deg)
  local theta = math.rad(deg)
  return { 
      {math.cos(theta), -math.sin(theta), 0},
      {math.sin(theta), math.cos(theta), 0},
      {0, 0, 1}
    }
end

local function magnitude(X, Y, Z)
  return sqrt(pow(X, 2) + pow(Y, 2) + pow(Z, 2))
end

local function multiplyMatrix(matrix1, matrix2) -- from: davidm/lua-matrix/lua/matrix.lua
  local result = {}
  for row=1, #matrix1 do
    result[row] = {}
    for col=1, #matrix2[1] do
      local num = 0
      for index=1, #matrix1[1] do
        num = num + matrix1[row][index] * matrix2[index][col]
      end
      result[row][col] = num
    end
  end
  return result
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

local function processMesh(fileName)
  print("Started Processing", fileName)
  local newMesh = nil
  local vertices, vertexMap = {}, {}
  local vertexFormat = {
    {"VertexPosition", "float", 3}, -- 3 32bit numbers from 0-1 for each vertex's position
    {"VertexColor", "byte", 4}, -- 4 16bit numbers from 0-1 for each color; r,g,b (alpha defaults to 1.0)
  }
  
  local str, size = love.filesystem.read(path.."/"..fileName) -- read file 
  local lines = splitString(str, "\n") -- split file by lines
  
  local maxVertexMagnitude = 0 -- resize to be normalized so it can fit the frustum 
  
  print("Cleaning unused data", fileName)
  
  for i=#lines, 1, -1 do
    local line = lines[i]
    if not (string.find(line, "v ") or --[[string.find(line, "vn ") or string.find(line, "vt ") or]] string.find(line, "f ")) then -- remove unnessary information to simplify
      table.remove(lines, i)
    end
  end
  
  print("Adding Vertices and Faces", fileName)
  
  for i, line in pairs(lines) do 
    local split = splitString(line)
    if split[1] == "v" then -- Y-Axis is reversed since in 3D engines (Godot, Blender, Roblox Studio) y+ goes up and y- goes down, in here it is the opposite
      table.insert(vertices, {split[2], -split[3], split[4], math.random(255)/255, math.random(255)/255, math.random(255)/255})
      maxVertexMagnitude = math.max(magnitude(split[2], -split[3], split[4]), maxVertexMagnitude)
    elseif split[1] == "f" then
      for i=2, #split do
        table.insert(vertexMap, splitString(split[i], "/")[1]) -- remove other info like vertex normals and texture
      end
    end
  end
  
  print("Normalizing Vertices", fileName)
  
  for i, v in pairs(vertices) do
    local x,y,z, r,g,b = unpack(vertices[i])
    local ratio = 1/maxVertexMagnitude
    vertices[i] = {x*ratio,y*ratio,z*ratio, r,g,b}
  end
  
  newMesh = love.graphics.newMesh(vertexFormat, vertices, "triangles")
  newMesh:setVertexMap(vertexMap)
  
  print("Finished Processing", fileName)
  return newMesh
end

local mesh = nil

function module.load()
  mesh = processMesh("fumo.obj") -- high vertex and triangle counts result in a longer time to debug
  love.graphics.setDepthMode("less", true) -- remove vertices off depth
  love.graphics.setMeshCullMode("back") -- remove back facing faces
end

function module.keypressed( key )
  if key == "z" then
    scale = scale / 1.1 -- zoom out
  elseif key == "x" then
    scale = scale * 1.1 -- zoom in
    
  elseif key == "q" then
    xMove = xMove + 1
  elseif key == "a" then
    xMove = xMove - 1
    
  elseif key == "w" then
    yMove = yMove + 1
  elseif key == "s" then
    yMove = yMove - 1
    
  elseif key == "e" then
    zMove = zMove + 1
  elseif key == "d" then
    zMove = zMove - 1
  end
end

function module.update(delta)
  currentDeltaFrame = delta
  totalDeltaFrame = totalDeltaFrame + delta
  mouseX, mouseY = love.mouse.getPosition() 
  
  local anchorX, anchorY, anchorZ = 0, -0.5, 0 -- rotates around this point
  
  for index=1, mesh:getVertexCount() do
    local x, y, z, r, g, b, a = mesh:getVertex(index)
    x = x - anchorX
    y = y - anchorY
    z = z - anchorZ
    local rotated = multiplyMatrix(xAxisMatrix(xMove*delta), multiplyMatrix(yAxisMatrix(yMove*delta), multiplyMatrix(zAxisMatrix(zMove*delta), {{x}, {y}, {z}})))
    mesh:setVertex(index, rotated[1][1] + anchorX, rotated[2][1] + anchorY, rotated[3][1] + anchorZ, r, g, b, a)
  end
end

function module.draw()
  love.graphics.setBackgroundColor(0.5,0.5,1)
  love.graphics.draw(mesh, mouseX, mouseY, 0, scale*200, scale*200)
  local str = "FPS: "..love.timer.getFPS().." ("..string.len(tostring(currentDeltaFrame))..", "..currentDeltaFrame..")"
  for i, v in pairs({"X Axis Q / A: "..xMove, "Y Axis W / S: "..yMove, "Z Axis E / D: "..zMove, "Zoom: ".. math.ceil(scale*100).. "% (".. math.ceil(scale*200*100)/100 .. "px)"}) do
    str = str.."\n"..v
  end
  love.graphics.print(str)
end

return module