import vec
import color
import gl

let screen = xy{600,700}
var fieldSize = xy{11,11}
let minScreenSize = min(screen)
var maxFieldSize = max(fieldSize)
var cellSize = minScreenSize / maxFieldSize
var fieldFilled = fieldSize * cellSize
var screenLeft = screen - fieldFilled
var offset = float(screenLeft) / 2.0

var fcs = float(cellSize)
var cellSizeVec = xy{fcs,fcs}
var halfCell = cellSizeVec / 2.0
var quarterCell = halfCell / 2.0

let unopenedColor = xyzw{0.5,0.5,0.5,1.0}
let openedColor = xyzw{0.7,0.7,0.7,1.0}
let gridLineColor = xyzw{0.0,0.0,0.0,1.0}
let colorsForNumber = [xyzw{0.0,0.0,1.0,1.0},xyzw{0.0,0.8,0.0,1.0},xyzw{1.0,0.0,0.0,1.0},xyzw{0.0,0.0,0.7,1.0},
                       xyzw{0.7,0.0,0.0,1.0},xyzw{0.0,1.0,1.0,1.0},xyzw{0.0,0.0,0.0,1.0},xyzw{0.5,0.5,0.5,1.0}]
let minePrimaryColor = xyzw{0.0,0.0,0.0,1.0}
let mineSecondaryColor = xyzw{1.0,1.0,1.0,1.0}
let backgroundColor = xyzw{1.0,1.0,1.0,1.0}
let flagColor = xyzw{0.9,0.8,0.0,1.0}
let gameEndTextColor = xyzw{0.0,0.0,0.0,1.0}

let circleAmountOfSides = 6
let lineThickness = 2

var amountOfMines = 5

var needToIncrease = 1
var currentAmount = 0

fatal(gl_window("minesweeper", screen.x, screen.y))
let flagPoly = gl_new_poly([quarterCell, quarterCell + xy{halfCell.x,0.0}, halfCell+xy{0.0,quarterCell.y}])
check(gl_set_font_name("data/fonts/Square/square.ttf") , "Font couldn\'t be loaded")

class cell:
    number = 0
    hasMine = false
    opened = false
    flagged = false
    def draw(pos:xy_f):
        gl_translate(pos+offset):
            if not opened:
                gl_color(unopenedColor)
                gl_rect(cellSizeVec)
                if flagged:
                    gl_color(flagColor)
                    gl_render_mesh(flagPoly)
            else:
                gl_color(openedColor)
                gl_rect(cellSizeVec)
                if hasMine:
                    gl_color(minePrimaryColor)
                    gl_translate(halfCell):
                        gl_circle(halfCell.x,circleAmountOfSides)
                    gl_color(mineSecondaryColor)
                    gl_translate(quarterCell):
                        gl_circle(quarterCell.x, circleAmountOfSides)
                elif number > 0:
                    gl_color(colorsForNumber[number-1])
                    gl_set_font_size(cellSize)
                    let toPrint = string(number)
                    gl_translate((cellSizeVec - float(gl_text_size(toPrint))) / 2.0):
                        gl_text(toPrint)

var cells = []
for(fieldSize.x):
    let line = []
    for(fieldSize.y):
        line.push(cell{})
    cells.push(line)


def openEmptyCell(pos) -> int:
    var returnValue = 0
    cells[pos.x][pos.y].opened = true
    if cells[pos.x][pos.y].hasMine: return 1
    if cells[pos.x][pos.y].number != 0: return 0
    let adjacent = createDirections(pos)
    let alsoOpen = []
    for(adjacent) i:
        if not cells[i.x][i.y].opened:
            if cells[i.x][i.y].number == 0: alsoOpen.push(i)
            cells[i.x][i.y].opened = true 
    for(alsoOpen) i: 
        if openEmptyCell(i) == 1: returnValue = 1
    return returnValue

def drawFieldLines():
    gl_color(gridLineColor)
    gl_translate(offset)
    for(fieldSize.x+1) i:
        gl_translate(xy{float(i)*cellSize, 0.0}):
            gl_line(xy_0, xy{0.0, fieldFilled.y}, lineThickness)
    for(fieldSize.y+1) i:
        gl_translate(xy{0.0,float(i)*cellSize}):
            gl_line(xy_0,xy{float(fieldFilled.x),0.0}, lineThickness)
            
def placeMines(firstPress:xy_i):
    let field = []
    for(fieldSize.x) i:
        for(fieldSize.y) j:
            let point = xy{i,j}
            if point != firstPress: field.push(point)
    let haveMines = []
    for(amountOfMines) i:
        let fieldLength = length(field)
        if fieldLength == 0 : break
        let index = rnd(fieldLength)
        let point = field.remove(index)
        haveMines.push(point)
        cells[point.x][point.y].hasMine = true
    for(haveMines) i:
        addForMine(i)

let right = xy{1,0}
let left = -right
let down = xy{0,1}
let up = -down

def createDirections(pos):
    let result = []
    let xDirs = []
    let yDirs = []
    if pos.x > 0: xDirs.push(left)
    if pos.x < fieldSize.x-1: xDirs.push(right)
    if pos.y > 0: yDirs.push(up)
    if pos.y < fieldSize.y-1: yDirs.push(down)
    for(xDirs) i:
        let np = pos + i
        result.push(np)
    for(yDirs) i:
        let np = pos + i
        result.push(np)
    for(xDirs) i:
        for(yDirs) j:
            let np = pos + i + j
            result.push(np)
    return result

def addForMine(pos):
    let directions = createDirections(pos)
    for(directions) i:
        cells[i.x][i.y].number++

def drawCells():
    for(cells) a,i:
        for(a) b,j:
            b.draw(float(xy{i,j})*cellSize)

var firstPress = true

def openFast(pos):
    var returnValue = 0
    let adjacent = createDirections(pos)
    var amount = 0
    for(adjacent) i:
        if cells[i.x][i.y].flagged: amount++
    if amount != cells[pos.x][pos.y].number: return 0
    for(adjacent) i:
        if not cells[i.x][i.y].flagged:
            if openEmptyCell(i) == 1: returnValue = 1
    return returnValue


def mousePressed(pos:xy_f, leftMouse:bool):
    var result = 0
    let diff = pos - offset
    if diff.x < 0 or diff.y < 0: return 0
    let gridPos = int(diff) / cellSize
    if(gridPos.x >= fieldSize.x or gridPos.x < 0) or (gridPos.y >= fieldSize.y or gridPos.y < 0): return 0
    if leftMouse:
        if firstPress:
            firstPress = false
            placeMines(gridPos)
        if not cells[gridPos.x][gridPos.y].opened:
            result = openEmptyCell(gridPos)
        else: result = openFast(gridPos)
    else:
        cells[gridPos.x][gridPos.y].flagged = not cells[gridPos.x][gridPos.y].flagged
    return result
    //print(gridPos)

let maxCooldown = 20
var currentCooldown = maxCooldown

var gameEnded = false
var gameWon = false

let gameWonText = "You have won! Press space to start again"
let gameLostText = "Unlucky!!! Press space to start again"

def restart():
    currentCooldown = maxCooldown
    firstPress = true
    gameEnded = false
    if gameWon:
        amountOfMines++
        if currentAmount == needToIncrease:
            currentAmount = 0
            needToIncrease++
            fieldSize = fieldSize + xy{1,1}
            maxFieldSize = max(fieldSize)
            cellSize = minScreenSize / maxFieldSize
            fieldFilled = fieldSize * cellSize
            screenLeft = screen - fieldFilled
            offset = float(screenLeft) / 2.0
            fcs = float(cellSize)
            cellSizeVec = xy{fcs,fcs}
            halfCell = cellSizeVec / 2.0
            quarterCell = halfCell / 2.0
        else: currentAmount++
        
    cells = []
    for(fieldSize.x):
        let line = []
        for(fieldSize.y):
            line.push(cell{})
        cells.push(line)
    

def checkWinCondition():
    var amountOfUnopened = 0
    for(cells) i:
        for(i) j:
            if not j.hasMine and not j.opened: return false
    return true


while gl_frame():
    if gl_button("escape") == 1: return
    if gameEnded:
        gl_clear(backgroundColor)
        let text = if gameWon: gameWonText else: gameLostText
        gl_color(gameEndTextColor)
        gl_set_font_size(cellSize/5)
        gl_translate(float(screen-gl_text_size(text))/2.0):
            gl_text(text)
        if gl_button("space") >=1:
            restart()
    else:
        if(currentCooldown == maxCooldown):
            let mouseLeft = gl_button("mouse1") >= 1
            let mouseRight = gl_button("mouse3") >= 1
            if mouseLeft or mouseRight:
                currentCooldown = 0
                let mouseValue = if not mouseRight: mouseLeft else: mouseRight
                let shouldEnd = mousePressed(float(gl_mouse_pos(0)), mouseLeft)
                if checkWinCondition():
                    gameEnded = true
                    gameWon = true
                if shouldEnd == 1:
                    gameEnded = true
                    gameWon = false
        else: currentCooldown++ 
        gl_clear(backgroundColor)
        drawCells()
        drawFieldLines()