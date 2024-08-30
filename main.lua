io.stdout:setvbuf("no") -- shoves print towards console instead of waiting and displaying later
-- after talking to others who I presume are more experienced in github, I could've just uploaded all the folders as their own projects with their own main.lua .
-- this would've saved me a lot of time and removed the weird coding structure, other could've just compiled/ran the correct folder instead of this method.

local currentProject = "Boids" -- "hot" swappable project directory, easier to share multiplie projects this way
local currentData = {}

function love.conf(t)
	t.screen.vsync = false
end

function love.load()
  files = love.filesystem.getDirectoryItems( currentProject )
  for i, file in ipairs(files) do
    if file == "module.lua" then 
        currentData = require(currentProject..".module")
    end
  end
  if currentData.load then
    currentData.load()
  end 
end

function love.update(delta)
  if currentData.update then
    currentData.update(delta)
  end
end

function love.draw()
  if currentData.draw then
    currentData.draw()
  end
end

function love.keypressed(key)
  if currentData.keypressed then
    currentData.keypressed( key )
  end
end
