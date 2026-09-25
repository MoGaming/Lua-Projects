io.stdout:setvbuf("no")

local module = {}

-- DFA visualizer + simulator
-- Transition encoding (unchanged from original): states[i] = {t1, t2}
--   sign(t)  -> input symbol (positive = 1, negative = 0)
--   abs(t)   -> destination state's internal (1-based) index
-- Display uses 0-based state numbers ("State 0" == internal index 1)

local mouseX, mouseY = 0, 0
local windowX, windowY = 900, 900

local currentDeltaFrame = 1/60
local screenCanvas

local states = { -- positive = 1, negative = 0
  [1] = {4, -2},
  [2] = {3, -1},
  [3] = {2, -4},
  [4] = {1, -3}
}

local total = #states
local minStates, maxStates = 2, 24
local halfSize = math.min(windowX/2.0, windowY/2.0) - 100

local startState = 1 -- internal index of the start state (assumption: State 0)

-- Default accept states (assumption: State 3 is accepting)
local finalStates = { [4] = true }

-- Simulator state
local inputText = ""
local simMode = nil     -- nil | "instant" | "step"
local simState = nil    -- current internal state index while simulating
local simIndex = 0      -- how many input symbols have been consumed
local simResult = nil   -- nil (pending) | true (accept) | false (reject)
local simStuck = false  -- true if simulation halted early (no transition)

-- Bruteforce
local bruteforceLen = 4
local bruteforceAccepted = {}
local bruteforceTotal = 0
local bruteforceRan = false

local function clamp(val, lower, upper)
  if val < lower then return lower end
  if val > upper then return upper end
  return val
end

-- Follows one transition
local function stepDFA(stateIndex, symbol)
  for _, transition in ipairs(states[stateIndex]) do
    local bit = transition > 0 and 1 or 0
    if bit == symbol then
      return math.abs(transition)
    end
  end
  return nil
end

-- Runs a full string through the DFA from the start state
-- Returns accepted (bool), finalOrStuckState (index), stuckAtChar (index or nil)
local function runFullSimulation(str)
  local state = startState
  for i = 1, #str do
    local symbol = tonumber(str:sub(i, i))
    local nextState = stepDFA(state, symbol)
    if nextState == nil then
      return false, state, i
    end
    state = nextState
  end
  return finalStates[state] == true, state, nil
end

local function resetSimulation()
  simMode = nil
  simState = nil
  simIndex = 0
  simResult = nil
  simStuck = false
end

local function runInstantSimulation()
  local accepted, state, stuckAt = runFullSimulation(inputText)
  simMode = "instant"
  simState = state
  simIndex = stuckAt and (stuckAt - 1) or #inputText
  simResult = accepted
  simStuck = stuckAt ~= nil
end

local function beginStepSimulation()
  simMode = "step"
  simState = startState
  simIndex = 0
  simResult = nil
  simStuck = false
end

local function advanceStep()
  if simIndex >= #inputText then return end
  local symbol = tonumber(inputText:sub(simIndex + 1, simIndex + 1))
  local nextState = stepDFA(simState, symbol)
  simIndex = simIndex + 1
  if nextState == nil then
    simStuck = true
    simResult = false
    return
  end
  simState = nextState
  if simIndex == #inputText then
    simResult = finalStates[simState] == true
  end
end

local function runBruteforce(maxLen)
  local accepted = {}
  local totalTested = 0

  local function generate(prefix, remaining)
    if remaining == 0 then
      totalTested = totalTested + 1
      local ok = runFullSimulation(prefix)
      if ok then table.insert(accepted, prefix == "" and "(empty string)" or prefix) end
      return
    end
    generate(prefix .. "0", remaining - 1)
    generate(prefix .. "1", remaining - 1)
  end

  for len = 0, maxLen do
    generate("", len)
  end

  print(("Bruteforce: %d/%d strings (length 0-%d) accepted:"):format(#accepted, totalTested, maxLen))
  for _, s in ipairs(accepted) do
    print("  " .. s)
  end

  bruteforceAccepted = accepted
  bruteforceTotal = totalTested
  bruteforceRan = true
end

local function countAcceptedFrom(maxLen, startS, finalSet)
  local count = 0
  local function rec(state, remaining)
    if remaining == 0 then
      if finalSet[state] then count = count + 1 end
      return
    end
    local n0 = stepDFA(state, 0)
    if n0 then rec(n0, remaining - 1) end
    local n1 = stepDFA(state, 1)
    if n1 then rec(n1, remaining - 1) end
  end
  for len = 0, maxLen do
    rec(startS, len)
  end
  return count
end

-- Gives every state a fresh pair of random transitions (one per input symbol)
local function randomizeTransitions()
  for i = 1, total do
    local target0 = math.random(1, total)
    local target1 = math.random(1, total)
    states[i] = { target1, -target0 } -- {positive = symbol 1, negative = symbol 0}
  end
end

local function randomizeDFA()
  local maxAttempts = 500
  for attempt = 1, maxAttempts do
    randomizeTransitions()
    local candidateStart = math.random(1, total)

    -- Preferred: an accepting state different from the entrance state
    for c = 1, total do
      if c ~= candidateStart then
        local finalSet = { [c] = true }
        local count = countAcceptedFrom(bruteforceLen, candidateStart, finalSet)
        if count > 1 then
          startState = candidateStart
          finalStates = finalSet
          resetSimulation()
          inputText = ""
          print(("Randomized DFA: entrance = State %d, accept = State %d (attempt %d)"):format(candidateStart - 1, c - 1, attempt))
          runBruteforce(bruteforceLen)
          return
        end
      end
    end

    -- Fallback: only let entrance and accept overlap if nothing else qualified for this random transition table
    local finalSet = { [candidateStart] = true }
    local count = countAcceptedFrom(bruteforceLen, candidateStart, finalSet)
    if count > 1 then
      startState = candidateStart
      finalStates = finalSet
      resetSimulation()
      inputText = ""
      print(("Randomized DFA: entrance/accept overlap at State %d (fallback, attempt %d)"):format(candidateStart - 1, attempt))
      runBruteforce(bruteforceLen)
      return
    end
  end
  print("Randomize DFA: no qualifying configuration found after " .. maxAttempts .. " attempts; defaulting to State 0.")
  startState = 1
  finalStates = { [1] = true }
  resetSimulation()
  runBruteforce(bruteforceLen)
end

local function setTotalStates(newTotal)
  newTotal = clamp(newTotal, minStates, maxStates)
  if newTotal == total then return end
  for i = newTotal + 1, maxStates do
    states[i] = nil
  end
  total = newTotal
  randomizeDFA()
end

local function getStateRadius()
  if total <= 1 then return 50 end
  local spacing = 2 * halfSize * math.sin(math.pi / total)
  return clamp(spacing * 0.4, 12, 50)
end

function module.load()
  math.randomseed(os.time())
  love.window.setMode(windowX, windowY, {vsync = false})
  screenCanvas = love.graphics.newCanvas(windowX, windowY)
  love.graphics.setBackgroundColor(1, 1, 1)
  love.window.setTitle("DFA Solver")
  print("Started")
end

local function getStatePosition(index, radius)
  if radius == nil then radius = halfSize end
  local i = 2.0 * math.pi * (index - 1) / total
  return {(radius * math.cos(i)) + windowX / 2.0, (radius * math.sin(i)) + windowY / 2.0}
end

local function drawArrowhead(from, tip)
  local dx, dy = tip[1] - from[1], tip[2] - from[2]
  local len = math.sqrt(dx*dx + dy*dy)
  if len == 0 then return end
  dx, dy = dx / len, dy / len
  local perpX, perpY = -dy, dx
  local size = 12
  local backX, backY = tip[1] - dx * size, tip[2] - dy * size
  love.graphics.polygon("fill",
    tip[1], tip[2],
    backX + perpX * size * 0.5, backY + perpY * size * 0.5,
    backX - perpX * size * 0.5, backY - perpY * size * 0.5
  )
end

local function stateColor(stateIndex)
  -- Simulation highlight takes priority over the plain accept/reject fill
  if simMode and simState == stateIndex then
    if simResult == nil then
      return 1, 0.6, 0 -- orange: mid-simulation, no verdict yet
    elseif simResult then
      return 0, 1, 0 -- green: accepted here
    else
      return 1, 0, 0 -- red: rejected / stuck here
    end
  end
  return 1, 1, 1
end

local function renderStates()
  love.graphics.clear()
  love.graphics.setColor(0, 0, 0)
  love.graphics.circle("line", windowX/2.0, windowY/2.0, halfSize)
  local fontHeight = love.graphics.getFont():getHeight()
  local stateRadius = getStateRadius()

  for stateIndex, nextStates in pairs(states) do
    local pos = getStatePosition(stateIndex)

    -- Start state marker: short arrow pointing in from outside the circle
    if stateIndex == startState then
      local dir = {pos[1] - windowX/2.0, pos[2] - windowY/2.0}
      local dlen = math.sqrt(dir[1]*dir[1] + dir[2]*dir[2])
      dir = {dir[1]/dlen, dir[2]/dlen}
      local outer = {pos[1] + dir[1]*(stateRadius+40), pos[2] + dir[2]*(stateRadius+40)}
      local edge = {pos[1] + dir[1]*stateRadius, pos[2] + dir[2]*stateRadius}
      love.graphics.setColor(0, 0, 0)
      love.graphics.line(outer[1], outer[2], edge[1], edge[2])
      drawArrowhead(outer, edge)
    end

    local r, g, b = stateColor(stateIndex)
    love.graphics.setColor(0, 0, 0)
    love.graphics.circle("line", pos[1], pos[2], stateRadius)
    love.graphics.setColor(r, g, b)
    love.graphics.circle("fill", pos[1], pos[2], stateRadius*0.9)
    if finalStates[stateIndex] then -- double ring = accepting state
      love.graphics.setColor(0, 0, 0)
      love.graphics.circle("line", pos[1], pos[2], stateRadius*0.76)
    end
    love.graphics.setColor(0, 0, 0)
    love.graphics.print("State " .. tostring(stateIndex - 1), pos[1] - 25, pos[2] - fontHeight/2)

    for _, pointTo in ipairs(nextStates) do
      local symbol = pointTo > 0 and 1 or 0
      local fromPos = getStatePosition(stateIndex, halfSize - stateRadius)
      local pointToPos = getStatePosition(math.abs(pointTo), halfSize - stateRadius)

      local offset = {fromPos[2] - windowX/2, -(fromPos[1] - windowY/2)}
      local size = math.sqrt(offset[1]*offset[1] + offset[2]*offset[2])
      offset = {offset[1]/size, offset[2]/size}

      local offsetDistance = 65 * (symbol*2 - 1)
      local isLeftSide = fromPos[1] > halfSize and 1 or 0

      local middleOffset = 0.75
      local middle = {pointToPos[1]*middleOffset + fromPos[1]*(1-middleOffset), pointToPos[2]*middleOffset + fromPos[2]*(1-middleOffset)}
      middle = {middle[1] + offset[1]*offsetDistance, middle[2] + offset[2]*offsetDistance}

      love.graphics.setColor(0.3, 0.3, 0.3)
      love.graphics.line(fromPos[1], fromPos[2], middle[1], middle[2], pointToPos[1], pointToPos[2])
      drawArrowhead(middle, pointToPos)

      love.graphics.setColor(0, 0.5, 0)
      love.graphics.print(tostring(symbol)..": "..tostring(stateIndex-1).." -> "..tostring(math.abs(pointTo) - 1), middle[1] - isLeftSide*25, middle[2])
    end
  end
end

local function renderUI()
  love.graphics.setColor(0, 0, 0)
  local y = 10
  local function line(text)
    love.graphics.print(text, 10, y)
    y = y + 18
  end

  line("Input: " .. inputText .. (simMode == "step" and (" (step " .. simIndex .. "/" .. #inputText .. ")") or ""))

  if simMode == "instant" then
    if simStuck then
      line("Result: REJECT (no transition partway through)")
    else
      line("Result: " .. (simResult and "ACCEPT" or "REJECT"))
    end
  elseif simMode == "step" then
    if simResult == nil then
      line("Stepping... press SPACE to advance")
    elseif simStuck then
      line("Result: REJECT (no transition partway through)")
    else
      line("Result: " .. (simResult and "ACCEPT" or "REJECT"))
    end
  else
    line("Result: (type 0/1, ENTER = run instantly, SPACE = step through)")
  end

  line("Bruteforce length: " .. bruteforceLen .. "  (+/- to change, B to run)")
  if bruteforceRan then
    line("Bruteforce: " .. #bruteforceAccepted .. "/" .. bruteforceTotal .. " accepted (full list printed to console)")
  end

  line("States: " .. total .. "  (]/[ to change, re-randomizes on change)")
  line("R = reset input | N = randomize DFA | click a state = toggle accept/reject")
end

function module.update(delta)
  currentDeltaFrame = delta
  mouseX, mouseY = love.mouse.getPosition()
end

function module.keypressed(key) print(key)
	key = tostring(key)
  if key == "0" or key == "1" then
    inputText = inputText .. key
    resetSimulation()
  elseif key == "backspace" then
    inputText = inputText:sub(1, -2)
    resetSimulation()
  elseif key == "return" or key == "kpenter" then
    runInstantSimulation()
  elseif key == "space" then
    if simMode ~= "step" or simResult ~= nil then
      beginStepSimulation()
    else
      advanceStep()
    end
  elseif key == "r" then
    inputText = ""
    resetSimulation()
  elseif key == "n" then
    randomizeDFA()
  elseif key == "]" then
    setTotalStates(total + 1)
  elseif key == "[" then
    setTotalStates(total - 1)
  elseif key == "+" or key == "=" or key == "kp+" then
    bruteforceLen = clamp(bruteforceLen + 1, 0, 12)
  elseif key == "-" or key == "kp-" then
    bruteforceLen = clamp(bruteforceLen - 1, 0, 12)
  elseif key == "b" then
    runBruteforce(bruteforceLen)
  end
end

function module.mousepressed(x, y, button)
	print(x,y,button)
  if button ~= 1 then return end
  local stateRadius = getStateRadius()
  for stateIndex = 1, total do
    local pos = getStatePosition(stateIndex)
    local dx, dy = x - pos[1], y - pos[2]
    if math.sqrt(dx*dx + dy*dy) <= stateRadius then
      finalStates[stateIndex] = not finalStates[stateIndex] or nil
      break
    end
  end
end

function module.draw()
  love.graphics.setBackgroundColor(0.5,0.5,1)
  screenCanvas:renderTo(renderStates)
  love.graphics.draw(screenCanvas)
  love.graphics.setColor(0, 1, 0)
  love.graphics.print("FPS: " .. love.timer.getFPS() .. " (" .. currentDeltaFrame .. ")")
  renderUI()
end

return module
