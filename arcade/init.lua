registerForEvent("onInit", function()
  -- Key Settings (lower case)
    LeftKey = "4"
    RightKey = "6"
    DownKey = "2"
    RotateKey = "8"
    InteractKey = "f"

 	  CPS = require ("CPStyling")
    print("CPStyling.lua loaded")
 	  theme = CPS.theme
    color = CPS.color
	  print("Theme Loaded")
    wWidth, wHeight = GetDisplayResolution()

    looksAtArcade = false
    currentMachine = nil
    minDistance = 1.5
    gameRunning = false
    timer = 0
    timer2 = 0
    brokenLines = 0
    highscore = 0

    modOn = false

    tetrisField = {}
    activeFigure = {}
    activeFigureIndex = {}
    fLength = {1, 3, 3, 3, 0, 3, 3}
    figures = { [0] = {[0] = {1, 11, 21, 31, color.cyan, {x1_border = 0, x2_border = 9}}, [1] = {1, 2, 3, 4, color.cyan, {x1_border = 0, x2_border = 6}}},
                [1] = {[0] = {1, 2, 11, 21, color.blue, {x1_border = 0, x2_border = 8}}, [1] = {10, 11, 12, 22, color.blue, {x1_border = 1, x2_border = 8}}, [2] = {1, 11, 21, 20, color.blue, {x1_border = 1, x2_border = 9}}, [3] = {0, 10, 11, 12, color.blue, {x1_border = 1, x2_border = 8}}},
                [2] = {[0] = {1, 2, 12, 22, color.orange, {x1_border = 0, x2_border = 8}}, [1] = {11, 12, 13, 3, color.orange, {x1_border = 0, x2_border = 7}}, [2] = {2, 12, 22, 23, color.orange, {x1_border = -1, x2_border = 7}}, [3] = {11, 12, 13, 21, color.orange, {x1_border = 0, x2_border = 7}}},
                [3] = {[0] = {1, 10, 11, 12, color.magenta, {x1_border = 1, x2_border = 8}}, [1] = {1, 11, 12, 21, color.magenta, {x1_border = 0, x2_border = 8}}, [2] = {10, 11, 12, 21, color.magenta, {x1_border = 1, x2_border = 8}}, [3] = {1, 10, 11, 21, color.magenta, {x1_border = 1, x2_border = 9}}},
                [4] = {[0] = {1, 2, 11, 12, color.yellow, {x1_border = 0, x2_border = 8}}},
                [5] = {[0] = {1, 2, 10, 11, color.lime, {x1_border = 1, x2_border = 8}}, [1] = {1, 11, 12, 22, color.lime, {x1_border = 0, x2_border = 8}}, [2] = {11, 12, 20, 21, color.lime, {x1_border = 1, x2_border = 8}}, [3] = {0, 10, 11, 21, color.lime, {x1_border = 1, x2_border = 9}}},
                [6] = {[0] = {0, 1, 11, 12, color.red, {x1_border = 1, x2_border = 8}}, [1] = {2, 11, 12, 21, color.red, {x1_border = 0, x2_border = 8}}, [2] = {10, 11, 21, 22, color.red, {x1_border = 1, x2_border = 8}}, [3] = {1, 10, 11, 20, color.red, {x1_border = 1, x2_border = 9}}}
            }

    print("[ArcadeTetris WIP] Mod is now loaded, sorry for the incoming error spam")

    function distanceVectors(v1, v2)
        dV = (v1.x - v2.x)^2 + (v1.y - v2.y)^2 + (v1.z - v2.z)^2
        return math.sqrt(dV)
    end

    function isLookingAtArcade(range)
        currentObj = Game.GetTargetingSystem():GetLookAtObject(player, false, false)
        if currentObj ~= nil then
          if (currentObj:IsExactlyA("ArcadeMachine") and distanceVectors(player:GetWorldPosition(), currentObj:GetWorldPosition()) < range) then
              return true
          else
              return false
          end
        end
    end

    function spendMoney(amount)
        tdbid = TweakDBID.new("Items.money")
        moneyId = GetSingleton('gameItemID'):FromTDBID(tdbid)
        Game.GetTransactionSystem():RemoveItem(player, moneyId, amount)
    end

    function tpToMachine()
        obj = Game.GetTargetingSystem():GetLookAtObject(player, false, false)

        dir = obj:GetWorldForward()
        pos = obj:GetWorldPosition()

        local xNew = pos.x + dir.x
        local yNew = pos.y + dir.y
        local zNew = pos.z + dir.z
        tpTo = Vector4.new(xNew,yNew,zNew,pos.w)
        Game.GetTeleportationFacility():Teleport(player, tpTo , EulerAngles.new(0,0,obj:GetWorldYaw() - 180))
    end

-- All Tetris functions, might break up into modules later, when require is fixed

    function createField()
        for i = 1, 200 do
            tetrisField[i] = color.grey
        end
    end

    function drawField(size)
        local wposX, wposY = ImGui.GetWindowPos()
        local cursorX, cursorY = ImGui.GetCursorPos()
        CPS.colorBegin("ChildBg", color.black)
        ImGui.BeginChild("##background", (size+1)*10, (size+1)*20)
        local drawlist = ImGui.GetWindowDrawList()
        local originX = wposX + cursorX
        local originY = wposY + cursorY
        local y = originY
        local x = originX
        for i = 0, 19 do
            y = originY + i * size + i
            for j = 1, 10 do
                x = originX + (j-1) * size + j
                if has_value(activeFigure, i * 10 + j) then
                    ImGui.ImDrawListAddRectFilled(drawlist, x, y, x+size, y+size, ImGui.GetColorU32(table.unpack(activeFigure[5])))
                elseif tetrisField[i * 10 + j] ~= color.grey then
                    ImGui.ImDrawListAddRectFilled(drawlist, x, y, x+size, y+size, ImGui.GetColorU32(table.unpack(tetrisField[i * 10 + j])))
                end
            end
        end
        ImGui.EndChild()
        CPS.colorEnd(1)
    end

    function has_value (tab, val)
        for index, value in ipairs(tab) do
            if value == val then
                return true
            end
        end

        return false
    end

    function spawnFigure(x, y, checkInter, index1, index2)
        rN = index1 or math.random(0, 6)
        rR = index2 or math.random(0, fLength[rN + 1])
        activeFigure = {}
        activeFigure = deepcopy(figures[rN][rR])
        moveActiveFigureBy(x + 10 *y)
        activeFigure[7] = {x_pos = x, y_pos = y}                      -- needs to be done this way so that it doesnt get drawn
        activeFigureIndex = {p1 = rN, p2 = rR}
        if intersects() and checkInter then
            stopGame()
        end
    end

    function deepcopy(origin) -- wtf is wrong with lua tables
        local orig_type = type(origin)
        local copy
        if orig_type == 'table' then
            copy = {}
            for origin_key, origin_value in next, origin, nil do
                copy[deepcopy(origin_key)] = deepcopy(origin_value)
            end
            setmetatable(copy, deepcopy(getmetatable(origin)))
        else
            copy = origin
        end
        return copy
    end

    function intersects()
        intersection = false
        for i = 1, 4 do
            if (tetrisField[activeFigure[i]] ~= color.grey) or ((activeFigure[i] / 10) > 20) then
                intersection = true
            end
        end
        return intersection
    end

    function breakLines()
        for y = 0, 19 do
            line = 0
            for x = 1, 10 do

                if tetrisField[x + y * 10] ~= color.grey then
                    line = line + 1
                end

            end

            if line == 10 then
                moveDownAbove(y)
                brokenLines = brokenLines + 1
                if brokenLines * 10 > highscore then
                    highscore = brokenLines * 10
                end
            end
        end
    end

    function moveDownAbove(line)
        for y = (line * 10)  + 10, 11, -1 do
            tetrisField[y] = tetrisField[y - 10]
        end
    end

    function moveActiveFigureBy(x)
        activeFigure[1] = activeFigure[1] + x
        activeFigure[2] = activeFigure[2] + x
        activeFigure[3] = activeFigure[3] + x
        activeFigure[4] = activeFigure[4] + x
    end

    function rotate()
        i1, i2 = activeFigureIndex.p1, activeFigureIndex.p2
        newFigIndex2 = (activeFigureIndex.p2 + 1) % (fLength[activeFigureIndex.p1 + 1] + 1)
        spawnFigure(activeFigure[7].x_pos, activeFigure[7].y_pos, false, activeFigureIndex.p1, newFigIndex2)
        if (intersects()) or (activeFigure[7].x_pos < activeFigure[6].x1_border) or (activeFigure[7].x_pos > activeFigure[6].x2_border)then
            spawnFigure(activeFigure[7].x_pos, activeFigure[7].y_pos, false, i1, i2)
        end
    end

    function goDown()
        moveActiveFigureBy(10)
        activeFigure[7].y_pos = activeFigure[7].y_pos + 1
        if (intersects()) then
            moveActiveFigureBy(-10)
            activeFigure[7].y_pos = activeFigure[7].y_pos - 1
            freeze()
        end
    end

    function freeze()
        for i = 1, 4 do
            tetrisField[activeFigure[i]] = activeFigure[5]
        end
        breakLines()
        spawnFigure(4,0, true)
    end

    function goSide(direction)
        dir = 1
        if (direction == "left") then
            dir = -1
        end
        moveActiveFigureBy(dir)
        activeFigure[7].x_pos = activeFigure[7].x_pos + dir
        if intersects() or (activeFigure[7].x_pos < activeFigure[6].x1_border) or (activeFigure[7].x_pos > activeFigure[6].x2_border) then
             moveActiveFigureBy(-dir)
             activeFigure[7].x_pos = activeFigure[7].x_pos - dir
        end
    end

    function reset()
        activeFigure = {}
        createField()
        brokenLines = 0
    end

    function startGame()
        currentMachine = Game.GetTargetingSystem():GetLookAtObject(player, false, false)
        currentMachine:TurnOffDevice()
        createField()
        spawnFigure(4, 0, true)
    end

    function stopGame()
        reset()
        gameRunning = false
        Game.AddToInventory("Items.money",brokenLines)
        currentMachine:TurnOnDevice()
    end

-- End Tetris functions
end)

registerForEvent("onUpdate", function(deltaTime)

    timer = timer + deltaTime
    if (timer > 0.75) then
        timer = timer - 0.75
        if gameRunning then
            goDown()
        end
    end

    player = Game.GetPlayer()

    if (not looksAtArcade and gameRunning) then
        gameRunning = false
        stopGame()
    end

    looksAtArcade = isLookingAtArcade(minDistance)
    local keypress = CPS.Input:GetKeyPress()
    if gameRunning then
      CPS.Input:Enable(true)
      if keypress == RotateKey then
        rotate()
      elseif keypress == DownKey then
        goDown()
      elseif keypress == LeftKey then
        goSide("left")
      elseif keypress == RightKey then
        goSide("right")
      end
    elseif looksAtArcade and (not gameRunning) then
      CPS.Input:Enable(true)
      if keypress == InteractKey then
        spendMoney(10)
        startGame()
        gameRunning = true
      end
    else
      CPS.Input:Enable(false)
    end
end)

registerForEvent("onDraw", function()
    CPS.Input:Register()

    if (looksAtArcade and not gameRunning) then

        CPS.setThemeBegin()
        CPS.styleBegin("WindowBorderSize", 0)
        CPS.colorBegin("WindowBg", {0,0,0,0.2})
        ImGui.Begin("Arcade Machine", true, ImGuiWindowFlags.NoResize | ImGuiWindowFlags.AlwaysAutoResize | ImGuiWindowFlags.NoTitleBar)
        ImGui.SetWindowFontScale(1.5)
        ImGui.SetWindowPos((wWidth / 2) - 100, wHeight * 0.66)
        ImGui.Text("Arcade Machine")
        CPS.CPRect2("PopupSeparator", 230, 1, theme.Text)
        ImGui.Dummy(0,8)
        CPS.colorBegin("Text", theme.CPButtonText)
        CPS.CPRect(InteractKey:upper(), 28, 28, theme.Hidden, theme.CPButtonText, 1, 3)
        ImGui.SameLine()
        ImGui.Text("Start Game")
        ImGui.SameLine()
        ImGui.TextColored(1, 0.76, 0.23, 1, "[10 E$]")
        CPS.colorEnd()
        ImGui.End()
        CPS.colorEnd(1)
        CPS.styleEnd(1)
        CPS.setThemeEnd()
    end

    if (gameRunning) then
        CPS.setThemeBegin()
        ImGui.Begin("CyberTetris v.01", true, ImGuiWindowFlags.NoResize | ImGuiWindowFlags.AlwaysAutoResize | ImGuiWindowFlags.NoTitleBar)
        local tetrisWindowSize = {}
        local size = 20
        tetrisWindowSize.x, tetrisWindowSize.y = ImGui.GetWindowSize()
        ImGui.SetWindowPos((wWidth / 2) - tetrisWindowSize.x / 2, (wHeight / 2) - tetrisWindowSize.y / 2)
        ImGui.Text("CyberTetris v.01")
        ImGui.Spacing()
        ImGui.BeginChild("Score", size*10, 20)
        ImGui.SetWindowFontScale(1.1)
        s = string.format ("Score: %i", brokenLines * 10)
        ImGui.Text(s)
        ImGui.SameLine(87)
        h = string.format ("Highscore: %i", highscore)
        ImGui.Text(h)
        ImGui.EndChild()

        drawField(size)

        ImGui.End()
        CPS.setThemeEnd()
    end
end)
