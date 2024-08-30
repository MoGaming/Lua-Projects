-- default configure file for love2d, it gets replaced by love.window.setMode(..) function

function love.conf(t)
  t.window.vsync = false
  t.window.depth = 24
  t.window.stencil = 8
  t.window.width = 1200
  t.window.height = 800
end
