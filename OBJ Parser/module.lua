local module = {}

local mouseX, mouseY = 0, 0
local currentDeltaFrame = 1/60
local totalDeltaFrame = 0

local path = (...):match('(.+)%.[^.]+$') 

local scale = 1

local function xAxisMatrix(deg)
  local theta = math.rad(deg)
  return { 
    {1, 0, 0},
    {0, math.cos(theta), -math.sin(theta)},
    {0, math.sin(theta), math.cos(theta)}}
end
local function yAxisMatrix(deg)
  local theta = math.rad(deg)
  return { 
    {math.cos(theta), 0, math.sin(theta)},
    {0, 1, 0},
    {-math.sin(theta), 0, math.cos(theta)}}
end
local function zAxisMatrix(deg)
  local theta = math.rad(deg)
  return { 
    {math.cos(theta), -math.sin(theta), 0},
    {math.sin(theta), math.cos(theta), 0},
    {0, 0, 1}}
end

local function multiplyMatrix(m1, m2) -- from: davidm/lua-matrix/lua/matrix.lua
	local mtx = {}
	for i = 1,#m1 do
    mtx[i] = {}
		for j = 1,#m2[1] do
      local num = m1[i][1] * m2[1][j]
			for n = 2,#m1[1] do
				num = num + m1[i][n] * m2[n][j]
			end
			mtx[i][j] = num
		end
	end
  return mtx
end

local function splitString(text, identifier)
  if identifier == nil then identifier = " " end
  local tabl = {}
  while string.len(text)>0 do
		local found=string.find(text, identifier)
		if found~=nil then
			table.insert(tabl, string.sub(text, 1, found-1))
			text=string.sub(text, found+1)
		else
			table.insert(tabl, text)
			text=""
		end
	end
  return tabl
end

local function processMesh(fileName)
  print("Started Processing", fileName)
  local newMesh = nil
  local vertices = {}
  local vertexMap = {}
  local vertexFormat = {
    {"VertexPosition", "float", 3},
    {"VertexColor", "byte", 4},
}
  
  local str, size = love.filesystem.read(path.."/"..fileName)
  local lines = splitString(str, "\n")
  
  for i=#lines, 1, -1 do
    local line = lines[i]
    if not (string.find(line, "v ") or --[[string.find(line, "vn ") or string.find(line, "vt ") or]] string.find(line, "f ")) then
      table.remove(lines, i)
    end
  end
  
  for i, line in pairs(lines) do 
    local split = splitString(line)
    if split[1] == "v" then -- Y-Axis is reversed since in 3D engines (Godot, Blender, Roblox Studio) y+ goes up and y- goes down, in here it is the opposite
      table.insert(vertices, {split[2], -split[3], split[4], math.random(255)/255, math.random(255)/255, math.random(255)/255})
    elseif split[1] == "f" then
      for i=2, #split do
        table.insert(vertexMap, splitString(split[i], "/")[1])
      end
    end
  end
  
  newMesh = love.graphics.newMesh(vertexFormat, vertices, "triangles")
  newMesh:setVertexMap(vertexMap)
  
  print("Finished Processing", fileName)
  return newMesh
end

local mesh = nil

function module.load()
  mesh = processMesh("full slug smaller.obj") -- full slug.obj takes too long to debug quickly
  love.graphics.setMeshCullMode("back")
  love.graphics.setDepthMode("less", true)
end

function module.keypressed( key )
  if key == "e" then
    scale = scale / 1.1
    print(scale)
  elseif key == "q" then
    scale = scale * 1.1
    print(scale)
  end
end

function module.update(delta)
  currentDeltaFrame = delta
  totalDeltaFrame = totalDeltaFrame + delta
  mouseX, mouseY = love.mouse.getPosition() 
  
  local anchorX, anchorY, anchorZ = 0, 0, 0
  
  for index=1, mesh:getVertexCount() do
    local x, y, z, r, g, b, a = mesh:getVertex(index)
    x = x - anchorX
    y = y - anchorY
    z = z - anchorZ
    local rotated = multiplyMatrix(xAxisMatrix(90*delta), multiplyMatrix(yAxisMatrix(5*delta), {{x}, {y}, {z}}))
    mesh:setVertex(index, rotated[1][1] + anchorX, rotated[2][1] + anchorY, rotated[3][1] + anchorZ, r, g, b, a)
  end
end

function module.draw()
  love.graphics.setBackgroundColor(0.3,0.3,1)
  love.graphics.draw(mesh, mouseX, mouseY, 0, scale*100, scale*100)
  love.graphics.print("FPS: "..love.timer.getFPS().." ("..string.len(tostring(currentDeltaFrame))..", "..currentDeltaFrame..")")
end

return module