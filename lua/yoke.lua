-- main module file
-- local module = require("flesh-and-blood.module")

---@class Config
---@field opt string Your config option
local config = {
  -- opt = "Hello!",
}

local M = {}

---@type Config
M.config = config

---@param args Config?
-- you can define your setup function here. Usually configurations can be merged, accepting outside params and
-- you can also put some validation here for those.
M.setup = function(args)
  M.config = vim.tbl_deep_extend("force", M.config, args or {})
end

-- function dump(o)
--    if type(o) == 'table' then
--       local s = '{ '
--       for k,v in pairs(o) do
--          if type(k) ~= 'number' then k = '"'..k..'"' end
--          s = s .. '['..k..'] = ' .. dump(v) .. ','
--       end
--       return s .. '} '
--    else
--       return tostring(o)
--    end
-- end

local function GetPrevNextLine(forward, curPos)
  local startLimit = 1
  local endLimit = vim.fn.line('$')
  local increment = 1

  if forward == 'b' then
    startLimit = vim.fn.line('$')
    endLimit = 1
    increment = -1
  end

  local prevLineInfo = {"", -1}
  local nextLineInfo = {"", -1}

  if curPos == 0 or curPos == endLimit then
    local prevLine = curPos - increment
    prevLineInfo = {vim.fn.getline(prevLine), prevLine}
    nextLineInfo = {"", endLimit}
  else
    prevLine = curPos - increment
    nextLine = curPos + increment
    prevLineInfo = {vim.fn.getline(prevLine), prevLine}
    nextLineInfo = {vim.fn.getline(nextLine), nextLine}
  end

  return {prevLineInfo, nextLineInfo}
end


local function IsLineEmpty(lineNum)
  local lineText = vim.fn.getline(lineNum)
  return vim.regex('^\\s\\+$'):match_str(lineText) or lineText == ""
end


local function IsLineSyntaxKeyword(lineNum)
  if lineNum < 0 then
    return false
  end
  local savePos=vim.fn.getcurpos()
  local retVal = false

  vim.fn.cursor(lineNum, 1)
  -- local stop_re = '\\c.*\\%(Keyword\\|Function\\|Conditional\\|Repeat\\|Exception\\|Operator\\)'
  local stop_re = '\\c.*\\%(Function\\|Conditional\\|Repeat\\|Exception\\|Operator\\)'

  while vim.fn.search('\\<', 'W') > 0 do
    -- print('xxdfdfdfxx')

    local curpos=vim.fn.getcurpos()
    if curpos[2] ~= lineNum then
      break
    end

    local synToken = vim.treesitter.get_captures_at_cursor(0)
    if #synToken > 0 then
      synToken = synToken[1]
    else
      synToken = ""
    end

    if vim.regex(stop_re):match_str(synToken) then
      retVal = true
      break
    else
      print("")
    end
  end

  vim.fn.setpos('.', savePos)
  return retVal
end


local function SearchBlankLines(forward)

  -- print('search blank lines')
  local res =  vim.fn.search('\\v^\\s*$', 'W' .. forward)
  -- print('num blank lines: ' .. res)
  return res
end

local function SearchSyntaxTokenLine(forward)
  while vim.fn.search('\\v^', 'W' .. forward) > 0 do
    -- print('foox1')
    local curpos=vim.fn.getcurpos()
    if IsLineSyntaxKeyword(curpos[2]) then
      return curpos[2]
    end
  end
  -- print("end token lines")
  return 0
end

local function ParLine(forward, matchFunc, searchFunc, type)

  -- used to restore cursor position
  local savePos=vim.fn.getcurpos()
  local startLine=vim.fn.getcurpos()[2]

  -- start searching from a line above/below
  -- unless it's the max line

  local maxLine = vim.fn.line('$')
  if forward ~= 'b' then
    local maxLine = vim.fn.line('$')
    if savePos[2] ~= maxLine then
      vim.fn.cursor(savePos[2] - 1, 1)
    end
  else
    maxLine = 1
    if savePos[2] ~= maxLine then
      vim.fn.cursor(savePos[2] + 1, 1)
    end
  end

  while true do
    if vim.fn.getcurpos()[2] == maxLine then
      -- print('max line')
      break
    end


    local curLine  = searchFunc(forward)
    if curLine == 0 then
      -- print('maxed out ' )

      retLine = maxLine
      break
    end

    -- print('curline: ' .. curLine .. "type: " .. type)
    local prevNextLine = GetPrevNextLine(forward, curLine)
    local prevLineNum = prevNextLine[1][2]
    local nextLineNum = prevNextLine[2][2]

    -- print('prevLineNum: ' .. prevLineNum .. "type: " .. type)
    -- print(dump(not (matchFunc(prevLineNum))) .. "type: " .. type)
    -- print(not false)

    local retLine = false

    if (not matchFunc(prevLineNum))
      and prevNextLine[1][2] ~= startLine
      and curLine ~= startLine
      and type ~= "a" then
      retLine =  prevLineNum

    elseif (not matchFunc(prevLineNum)) and type == "a" then
      retLine =  curLine

    elseif (not matchFunc(nextLineNum))
      and prevNextLine[2][2] ~= startLine
      and type ~= "a" then
      retLine =  nextLineNum

    elseif (not matchFunc(nextLineNum)) and prevNextLine[2][2] ~= startLine and type == "a" then
      retLine = curLine
    end

    if retLine and retLine ~= startLine then
      -- print('heree' .. retLine)

      vim.fn.setpos('.', savePos)
      return retLine
    end
  end
  vim.fn.setpos('.', savePos)
  return retLine

end

function Set (list)
  local set = {}
  for _, l in ipairs(list) do set[l] = true end
  return set
end

Filetypes = Set{'nim', 'lua', 'swift', 'c', 'cpp', 'python'}

M.MoveCursor = function(forward, visual)

  local prevPos=vim.fn.getcurpos()
  local nextPar = ParLine(forward, IsLineEmpty, SearchBlankLines, "b")

  -- print('nextpar: ' .. nextPar)

  -- print('syn')
  local nextSyn = nextPar

  if Filetypes[vim.bo.filetype] then
    nextSyn = ParLine(forward,
      IsLineSyntaxKeyword,
      SearchSyntaxTokenLine,
      "a")
  end

  -- print('nextSyn' .. nextSyn)

  if true then end
  -- vim.fn.cursor(nextPar, 1)

  -- echo "nextPar: ". nextPar
  -- echo "nextSyn: ". nextSyn


  local jumpToLine = nextPar
  if forward ~= 'b' then
    -- print('nextPar')
    -- print(nextPar)

    -- print('nextSyn')
    -- print(nextSyn)
    if nextPar and (nextPar < nextSyn) then
      jumpToLine = nextPar
    else
      jumpToLine = nextSyn
    end

    if vim.fn.foldclosed(jumpToLine) ~= -1 then
      jumpToLine = vim.fn.foldclosedend(jumpToLine)
    end
  else
    if nextPar and (nextPar > nextSyn)  then
      jumpToLine = nextPar
    else
      jumpToLine = nextSyn
    end

    if vim.fn.foldclosed(jumpToLine) ~= -1 then
      jumpToLine = vim.fn.foldclosed(jumpToLine)
    end
  end

  -- the mark stuff is there to append to the jump list
  -- so that ctrl+p and ctrl+o get affected by it.
  -- currently removing it because I'm not sure that I
  -- actually want that functionality
  local ok, result = pcall(
    function()
      -- vim.cmd('mark `')
      vim.fn.cursor(jumpToLine, 1)
      -- vim.cmd('mark `')
    end
  )

  if not ok and jumpToLine then
    print("error in jump: " .. jumpToLine)
  end
  -- vim.fn.cursor(jumpToLine, 1)
end

M.VMoveCursor = function(forward)
  vim.cmd('normal! gv')
  M.MoveCursor(forward, 'v')
end

return M
