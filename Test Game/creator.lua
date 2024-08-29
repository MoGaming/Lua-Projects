Creator = Classic:extend() -- global variables so this file returns no table like a local module would

function Creator:new(pos, size, rotate, image, scale, origin, collisionType)
  self.pos = pos
  self.size = size
  self.rotate = rotate
  self.scale = scale
  self.origin = origin
  self.image = image and love.graphics.newImage(image)
  self.type = collisionType -- rect, circle, none
  self.Gravity = 4
  
  print(self.super)
  
  if image and self.size[1] == 0 and self.size[2] == 0 then
    self.size = {
      self.image:getWidth(), 
      self.image:getHeight()
    }
  end
  
  if self.origin[1] == -0.1337 and self.origin[2] == -0.1337 then
    self.origin = {
      self.image:getWidth()/2, 
      self.image:getHeight()/2
    }
  end
end

function Creator:update(dt)
  
end

function Creator:draw()
  if self.image then
      love.graphics.draw(self.image, self.pos[1], self.pos[2], math.rad(self.rotate), self.scale[1], self.scale[2], self.origin[1], self.origin[2])
  else
      --love.graphics.draw(self.image, self.pos[1], self.pos[2], math.rad(self.rotate), self.scale[1], self.scale[2], self.origin[1], self.origin[2])
  end
end

function Creator:collidesWith(obj2)
    local a_left = self.pos[1]
    local a_right = self.pos[1] + self.size[1]
    local a_top = self.pos[2]
    local a_bottom = self.pos[2] + self.size[2]

    local b_left = obj2.pos[1]
    local b_right = obj2.pos[1] + obj2.size[1]
    local b_top = obj2.pos[2]
    local b_bottom = obj2.pos[2] + obj2.size[2]

    return  a_right > b_left
        and a_left < b_right
        and a_bottom > b_top
        and a_top < b_bottom
end