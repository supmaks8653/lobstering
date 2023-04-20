import vec
import color
import gl

var maxScore = 0
let highScoreFile = "highscore.bin"
let file = read_file(highScoreFile)
if(file != nil): maxScore = string_to_int(file)
let cellSize = 10
let fieldSize = 10
let entireFieldSize = float(cellSize * fieldSize)
let maxIndex = fieldSize - 2
let halfMaxIndex = maxIndex / 2
let fcs = float(cellSize)
let squareSize = xy{fcs,fcs}
let halfCellSize = cellSize / 2
let halfCellOffset = xy{halfCellSize,halfCellSize}
var pos = xy{halfMaxIndex-1, halfMaxIndex}
var dir = xy{1,0}
var score = 0
let startMessage = "press space to start"
var gameStarted = false
let endMessageStart = "your score is "
let endMessageEnd = ", press space to start again"
var gameEnd = false
fatal(gl_window("lines", 500, 600))
check(gl_set_font_name("data/fonts/Square/square.ttf"), "can\'t load font!")
//z/girgayev/fgiyak/plan-konspekt/sluck
let max = 17
var current = max
var nextDir = xy_0i
var removeEnd = true
var snake = [pos]
var food = xy_0i
def placeFood():
    var point = xy{rnd(maxIndex+1),rnd(maxIndex+1)}
    while(true):
        var sc = false
        for(snake) i:
            if(point == i):
                sc = true
                point = movePoint(point)
                break
        if(not sc): break
    food = point
    
def movePoint(point):
    var rx = point.x+1
    var ry = point.y
    if(point.x == maxIndex):
        rx = 0
        if(point.y == maxIndex):
            ry = 0
        ry++
    return xy{rx,ry}
    
def shift():
    insert(snake, 0, pos)
    if(removeEnd):
        remove(snake, length(snake)-1)
    else: removeEnd = true
def restart():
    score = 0
    pos = xy{halfMaxIndex-1,halfMaxIndex}
    dir = xy{1,0}
    nextDir = xy_0i
    gameEnd = false
    current = max
    snake = [pos]
def checkSelfCollision():
    if(length(snake) == 1): return false
    var first = true
    for(snake) i:
        if(first):
            first = false
        elif(i == snake[0]): return true
    return false
def save():
    write_file(highScoreFile, string(maxScore))
placeFood()
while gl_frame():
    if gl_button("escape") == 1:
        save()
        return
    if(gl_button("up")>=1): nextDir = xy{0,-1}
    elif(gl_button("down")>=1): nextDir = xy{0,1}
    elif(gl_button("right")>=1): nextDir = xy{1,0}
    elif(gl_button("left")>=1): nextDir = xy{-1,0} 
    let windowSize = float(gl_window_size())
    if(gameEnd):
        if(maxScore < score): maxScore = score
        save()
        let endMessage = endMessageStart + score + endMessageEnd
        gl_clear(color_black)
        gl_set_font_size(10)
        gl_translate((windowSize - float(gl_text_size(endMessage))) / 2.0):
            gl_text(endMessage)
        if gl_button("space") == 1 : restart()
    else:
        if(gameStarted):
            if(current == max):
                gl_scale(windowSize.x / (fieldSize*cellSize))
                gl_clear(color_black)
                gl_color(color_white)
                var a = 0
                while a < fieldSize:
                    let value = float(a*cellSize)+halfCellSize
                    gl_translate(xy{value,0.0}):
                        gl_line(xy_0, xy{0.0,windowSize.y},0.1)
                    gl_translate(xy{0.0,value}):
                        gl_line(xy_0,xy{windowSize.x,0.0},0.1)
                    a++
                if(nextDir != xy_0i):
                    let dirSum = dir+nextDir
                    if(dirSum != xy_0i):
                        dir = nextDir
                        nextDir = xy_0i
                pos += dir
                shift()
                if(pos == food):
                    removeEnd = false
                    placeFood()
                gl_color(color_red)
                for(snake) i:
                    gl_translate(float(i*cellSize+halfCellOffset)):
                        gl_rect(squareSize)
                gl_color(color_green)
                gl_translate(float(food*cellSize+halfCellOffset)):
                    gl_rect(squareSize)
                current = 0   
                gl_color(color_black)
                gl_translate(xy{0.0,entireFieldSize}):
                    gl_rect(xy{entireFieldSize,2*cellSize})
                    gl_color(color_white)
                    gl_translate(xy{0.0,float(halfCellSize)}):
                        gl_scale((fieldSize*cellSize)/ windowSize.x):
                            gl_set_font_size(10)
                            gl_text("Current score: {score}")
                        gl_translate(xy{0.0,float(cellSize)}):
                            gl_scale((fieldSize*cellSize)/ windowSize.x):
                                gl_set_font_size(10)
                                gl_text("Max score: {maxScore}")
                if (pos.x < 0 or pos.x > maxIndex) or (pos.y < 0 or pos.y > maxIndex) or checkSelfCollision(): gameEnd = true
                else:
                    let length = length(snake)
                    score+=length
                    score+=length/4
            else: current++
        else:
            gl_set_font_size(10)
            gl_translate((windowSize - float(gl_text_size(startMessage))) / 2.0):
                gl_text(startMessage)
            if gl_button("space") >= 1 :
                gameStarted = true