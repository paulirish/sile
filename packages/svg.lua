local svg = require("svg")
local pdf = require("justenoughlibtexpdf")
local parser = require("core/opentype-parser")

local pushSVG = function(string, desiredHeight)
  local figure, width, height = svg.svg_to_ps(string)
  local scalefactor = 1
  if desiredHeight then
    scalefactor = desiredHeight / height
    height = desiredHeight
    width = width * scalefactor
  end
  SILE.typesetter:pushHbox({
    value = nil,
    height = height,
    width = width,
    depth = 0,
    outputYourself= function (self, typesetter)
      pdf.add_content("q")
      SILE.outputter.moveTo(typesetter.frame.state.cursorX, typesetter.frame.state.cursorY)
      local x,y = SILE.outputter.cursor()
      y = y - SILE.documentState.paperSize[2] + height
      pdf.add_content(scalefactor.." 0 0 "..-(scalefactor).." "..x.." "..y.." cm")
      pdf.add_content(figure)
      pdf.add_content("Q")
      typesetter.frame:advanceWritingDirection(self.width)
    end
  })
end

SILE.registerCommand("include-svg-file", function (options,content)
  local fn = SU.required(options, "src", "filename")
  local fh = io.open(fn)
  local inp = fh:read("*all")
  pushSVG(inp)
end)

SILE.registerCommand("svg-glyph", function(options,content)
  local fontoptions = SILE.font.loadDefaults({})
  local items = SILE.shaper:shapeToken(content[1],fontoptions)
  local face = SILE.shaper.getFace(fontoptions)
  parser.parseFont(face)
  if not face.font.svg then return SILE.process(content) end
  for i =1,#items do
    local svg = parser.getSVG(face, items[i].gid)
    if svg then pushSVG(svg,fontoptions.size)
    else
      -- XXX
    end
  end
end)