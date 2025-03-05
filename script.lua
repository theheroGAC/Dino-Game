-- script.lua
-- Logica principale del gioco.

-- Funzione per creare la cartella se non esiste
function createDirectoryIfNotExists(path)
    if not files.exists(path) then
        files.mkdir(path)
    end
end

-- Creazione della cartella all'avvio
createDirectoryIfNotExists("ux0:/data/dino_game")

-- Variabili del gioco
local dino = {
    x = 50,                  -- Posizione X del dinosauro
    y = 200,                 -- Posizione Y del dinosauro
    speed = 0,               -- Velocità verticale del dinosauro
    width = 50,              -- Larghezza del dinosauro
    height = 50,             -- Altezza del dinosauro
    image = nil              -- Immagine corrente (verrà impostata dall'animazione)
}

-- Carica i frame dell'animazione del dinosauro
local dinoFrames = {
    image.load("assets/images/dino_run1.png"), -- Frame 1 della corsa
    image.load("assets/images/dino_run2.png")  -- Frame 2 della corsa
}
local dinoJumpFrame = image.load("assets/images/dino_jump.png") -- Frame del salto
local dinoGameOverFrame = image.load("assets/images/dino_gameover.png") -- Frame di "game over"

local currentFrame = 1       -- Frame corrente
local frameTimer = 0         -- Timer per l'animazione
local frameInterval = 10     -- Intervallo tra i frame (in frame del gioco)

local cacti = {}             -- Tabella per memorizzare i cactus
local cactusSpeed = -5       -- Velocità base dei cactus
local cactusSpawnTimer = 0   -- Timer per generare nuovi cactus
local cactusSpawnInterval = 100 -- Intervallo di generazione dei cactus (in frame)
local maxCacti = 5           -- Numero massimo di cactus

local gravity = 0.5          -- Gravità applicata al dinosauro
local score = 0              -- Punteggio del gioco
local gameOver = false       -- Stato del gioco (true se il gioco è finito)
local highScore = 0          -- Highscore

-- Modalità di gioco
local gameMode = "infinite"  -- Modalità predefinita: infinita
local timeLeft = 60          -- Tempo rimanente per la modalità a tempo (in secondi)

-- Schermata di pausa
local isPaused = false       -- Indica se il gioco è in pausa

-- Carica l'highscore all'avvio
local saveData = io.open("ux0:/data/dino_game/highscore.txt", "r")
if saveData then
    highScore = tonumber(saveData:read("*a")) or 0
    saveData:close()
end

-- Variabili per lo sfondo scorrevole
local background = {
    x1 = 0,                  -- Posizione X della prima immagine di sfondo
    x2 = 960,                -- Posizione X della seconda immagine di sfondo (larghezza dell'immagine)
    speed = -2,              -- Velocità di scorrimento dello sfondo
    image = image.load("assets/images/background.png")
}

-- Variabili per il menu
local inMenu = true          -- Indica se siamo nel menu
local menuSelection = 1      -- Indica l'opzione selezionata (1 = Gioca, 2 = Istruzioni, 3 = Esci)

-- Carica i suoni
local jumpSound = sound.load("assets/sounds/jump.wav")
local gameOverSound = sound.load("assets/sounds/gameover.wav")

-- Carica le immagini dei cactus
local cactusImages = {
    image.load("assets/images/cactus.png"),
    image.load("assets/images/cactus2.png")
}

local currentCactusImage = 1 -- Immagine corrente del cactus

-- Funzione per generare un nuovo cactus
function spawnCactus()
    local numCacti = math.min(math.floor(score / 20) + 1, maxCacti)
    for i = 1, numCacti do
        local spacing = 100  -- Distanza orizzontale tra i cactus
        table.insert(cacti, {
            x = 800 + (i * spacing),
            y = 200,
            speed = cactusSpeed,
            width = 50,
            height = 50,
            image = cactusImages[currentCactusImage]
        })

        currentCactusImage = currentCactusImage + 1
        if currentCactusImage > #cactusImages then
            currentCactusImage = 1
        end
    end
end

-- Funzione per aggiornare lo sfondo scorrevole
function updateBackground()
    background.x1 = background.x1 + background.speed
    background.x2 = background.x2 + background.speed

    if background.x1 < -960 then
        background.x1 = 960
    end
    if background.x2 < -960 then
        background.x2 = 960
    end
end

-- Funzione per aggiornare l'animazione del dinosauro
function updateDinoAnimation()
    if dino.y == 200 then -- Se il dinosauro è a terra
        frameTimer = frameTimer + 1
        if frameTimer >= frameInterval then
            currentFrame = currentFrame + 1
            if currentFrame > #dinoFrames then
                currentFrame = 1
            end
            frameTimer = 0
        end
        dino.image = dinoFrames[currentFrame] -- Usa il frame corrente
    else
        dino.image = dinoJumpFrame -- Usa il frame del salto
    end
end

-- Funzione di caricamento
function load()
    screen.clear(0xFFFFFFFF)
end

-- Funzione di aggiornamento
function update()
    if not gameOver and not isPaused then
        -- Aggiorna il timer per la modalità a tempo
        if gameMode == "timed" then
            timeLeft = timeLeft - 1 / 60 -- Aggiorna il timer
            if timeLeft <= 0 then
                gameOver = true
            end
        end

        -- Applica la gravità al dinosauro
        dino.speed = dino.speed + gravity
        dino.y = dino.y + dino.speed

        if dino.y > 200 then
            dino.y = 200
            dino.speed = 0
        end

        -- Aggiorna l'animazione del dinosauro
        updateDinoAnimation()

        -- Genera nuovi cactus
        cactusSpawnTimer = cactusSpawnTimer + 1
        if cactusSpawnTimer >= cactusSpawnInterval then
            spawnCactus()
            cactusSpawnTimer = 0
        end

        -- Aggiorna la posizione dei cactus e controlla le collisioni
        for i = #cacti, 1, -1 do
            local cactus = cacti[i]
            cactus.x = cactus.x + cactus.speed

            if cactus.x < -cactus.width then
                table.remove(cacti, i)
                score = score + 1
            end

            if cactus.x < dino.x + dino.width and
               cactus.x + cactus.width > dino.x and
               dino.y + dino.height > cactus.y then
                gameOver = true
                if score > highScore then
                    highScore = score
                    local file = io.open("ux0:/data/dino_game/highscore.txt", "w")
                    if file then
                        file:write(tostring(highScore))
                        file:close()
                    end
                end
                if gameOverSound then
                    sound.play(gameOverSound)
                end
            end
        end

        updateBackground()
    end
end

-- Funzione di disegno
function draw()
    screen.clear(0xFFFFFFFF)
    image.blit(background.image, background.x1, 0)
    image.blit(background.image, background.x2, 0)

    if gameOver then
        -- Mostra il frame di "game over"
        image.blit(dinoGameOverFrame, dino.x, dino.y)
    else
        -- Mostra il frame corrente dell'animazione
        image.blit(dino.image, dino.x, dino.y)
    end

    -- Disegna i cactus
    for _, cactus in ipairs(cacti) do
        image.blit(cactus.image, cactus.x, cactus.y)
    end

    -- Disegna il punteggio e l'highscore
    screen.print(10, 10, "Score: " .. score, 0.7, 0xFF000000)
    screen.print(10, 30, "High Score: " .. highScore, 0.7, 0xFF000000)

    -- Disegna il timer per la modalità a tempo
    if gameMode == "timed" then
        screen.print(10, 50, "Time: " .. math.floor(timeLeft), 0.7, 0xFF000000)
    end

    if gameOver then
        screen.print(300, 200, "Game Over", 0.7, 0xFFFF0000)
        screen.print(280, 250, "Press X to Restart", 0.7, 0xFFFF0000)
    elseif isPaused then
        drawPauseMenu()
    end

    screen.flip()
end

-- Funzione per disegnare il menu di pausa
function drawPauseMenu()
    screen.print(300, 100, "Pausa", 0.7, 0xFFFF0000)
    screen.print(280, 150, "Premi Start per riprendere", 0.7, 0xFFFF0000)
    screen.print(280, 200, "Premi X per riavviare", 0.7, 0xFFFF0000)
    screen.print(280, 250, "Premi O per tornare al menu", 0.7, 0xFFFF0000)
end

-- Funzione per gestire il touch
function handleTouchInput()
    touch.read()

    if touch.front.count > 0 and dino.y == 200 then
        dino.speed = -10
        if jumpSound then
            sound.play(jumpSound)
        end
    end
end

-- Gestione degli input
function handleInput()
    buttons.read()

    if buttons.cross and dino.y == 200 then
        dino.speed = -10
        if jumpSound then
            sound.play(jumpSound)
        end
    end

    handleTouchInput()

    if gameOver and buttons.cross then
        gameOver = false
        dino.y = 200
        dino.speed = 0
        cacti = {}
        score = 0
        if gameMode == "timed" then
            timeLeft = 60 -- Resetta il timer
        end
    end

    -- Gestione della pausa
    if buttons.start then
        isPaused = not isPaused
    end

    -- Gestione del menu di pausa
    if isPaused then
        if buttons.cross then
            -- Riavvia il gioco
            gameOver = false
            dino.y = 200
            dino.speed = 0
            cacti = {}
            score = 0
            if gameMode == "timed" then
                timeLeft = 60 -- Resetta il timer
            end
            isPaused = false
        elseif buttons.circle then
            -- Torna al menu principale
            inMenu = true
            isPaused = false
        end
    end
end

-- Funzione per disegnare il menu principale
function drawMenu()
    screen.clear(0xFFFFFFFF)
    screen.print(200, 50, "Dino Game", 1.0, 0xFF000000)

    if menuSelection == 1 then
        screen.print(200, 150, "> Gioca (Modalità Infinita)", 0.7, 0xFFFF0000)
    else
        screen.print(200, 150, "Gioca (Modalità Infinita)", 0.7, 0xFF000000)
    end

    if menuSelection == 2 then
        screen.print(200, 200, "> Gioca (Modalità a Tempo)", 0.7, 0xFFFF0000)
    else
        screen.print(200, 200, "Gioca (Modalità a Tempo)", 0.7, 0xFF000000)
    end

    if menuSelection == 3 then
        screen.print(200, 250, "> Istruzioni", 0.7, 0xFFFF0000)
    else
        screen.print(200, 250, "Istruzioni", 0.7, 0xFF000000)
    end

    if menuSelection == 4 then
        screen.print(200, 300, "> Esci", 0.7, 0xFFFF0000)
    else
        screen.print(200, 300, "Esci", 0.7, 0xFF000000)
    end

    screen.flip()
end

-- Funzione per gestire l'input nel menu
function handleMenuInput()
    buttons.read()

    if buttons.down then
        menuSelection = menuSelection + 1
        if menuSelection > 4 then
            menuSelection = 1
        end
    elseif buttons.up then
        menuSelection = menuSelection - 1
        if menuSelection < 1 then
            menuSelection = 4
        end
    end

    if buttons.cross then
        if menuSelection == 1 then
            inMenu = false
            gameMode = "infinite"
        elseif menuSelection == 2 then
            inMenu = false
            gameMode = "timed"
            timeLeft = 60 -- Resetta il timer
        elseif menuSelection == 3 then
            showInstructions()
        elseif menuSelection == 4 then
            os.exit()
        end
    end
end

-- Funzione per mostrare le istruzioni
function showInstructions()
    while true do
        screen.clear(0xFFFFFFFF)
        screen.print(100, 50, "Istruzioni:", 0.7, 0xFF000000)
        screen.print(100, 100, "Premi X per saltare", 0.7, 0xFF000000)
        screen.print(100, 150, "Evita i cactus!", 0.7, 0xFF000000)
        screen.print(100, 200, "Premi O per tornare al menu", 0.7, 0xFF000000)
        screen.flip()

        buttons.read()
        if buttons.circle then
            break
        end

        os.delay(16)
    end
end

-- Loop principale del gioco
function main()
    load()
    while true do
        if inMenu then
            drawMenu()
            handleMenuInput()
        else
            handleInput()
            update()
            draw()
        end

        os.delay(16)
    end
end

-- Avvia il gioco
main()