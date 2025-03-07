 color.loadpalette() -- much more easier to work with rather than hex values
-- script.lua Written by theHeroGAC and Harommel OddSock
-- Carica la palette di colori
color.loadpalette()

-- Funzione per creare la cartella se non esiste
function createDirectoryIfNotExists(path)
    if not files.exists(path) then
        files.mkdir(path)
    end
end

-- Creazione della cartella all'avvio
createDirectoryIfNotExists("ux0:/data/dino_game")

-- Traduzioni multilingue
local translations = {
    it = {
        play = "Gioca",
        instructions = "Istruzioni",
        settings = "Impostazioni",
        exit = "Esci",
        score = "Punteggio",
        highScore = "High Score",
        time = "Tempo",
        gameOver = "Game Over",
        restart = "Premi X per Ricominciare",
        pause = "Pausa",
        resume = "Riprendi",
        backToMenu = "Torna al Menu",
        music = "Musica",
        sounds = "Suoni",
        language = "Lingua",
        infinite = "Infinito",
        timed = "A Tempo",
    },
    en = {
        play = "Play",
        instructions = "Instructions",
        settings = "Settings",
        exit = "Exit",
        score = "Score",
        highScore = "High Score",
        time = "Remaining Time", 
        gameOver = "Game Over!",
        restart = "Press X to Restart",
        pause = "Pause",
        resume = "Resume",
        backToMenu = "Circle to return to the menu", 
        music = "Music",
        sounds = "Sounds",
        language = "Language",
        infinite = "Infinite",
        timed = "Timed",
    },
    fr = {
        play = "Jouer",
        pause = "Pause",
        exit = "Quitter",
        instructions = "Instructions",
        settings = "Réglage", 
        score = "Score",
        highScore = "Score Élevé", 
        time = "Temps Restant", 
        gameOver = "Jeu Terminé!", 
        restart = "X pour redémarrer", 
        resume = "Rependre", 
        backToMenu = "Cercle pour revenir au menu", 
        music = "Musique", 
        sounds = "Sons", 
        language = "Langue", 
        infinite = "Infini", 
        timed = "Chronométré", 
    },
    es = {
        play = "Jugar",
        instructions = "Instrucciones",
        settings = "Configuración",
        exit = "Salir",
        score = "Puntuación",
        highScore = "Máxima Puntuación",
        time = "Tiempo",
        gameOver = "Fin del Juego",
        restart = "Presiona X para Reiniciar",
        pause = "Pausa",
        resume = "Reanudar",
        backToMenu = "Volver al Menú",
        music = "Música",
        sounds = "Sonidos",
        language = "Idioma",
        infinite = "Infinito",
        timed = "A Tiempo",
    }
}

-- Lingua corrente (predefinita: english)
local currentLanguage = "en"
local currentLanguageStr = {["en"]="English", ["it"]="Italiano", ["es"]="Espagnol", ["fr"]="Fran  ais"}
-- Funzione di traduzione
function translate(key)
    return translations[currentLanguage][key] or "[" .. key .. "]"
end

-- Carica la configurazione della lingua
local configFile = "ux0:/data/dino_game/config.txt"

local function loadConfig()
    local file = io.open(configFile, "r")
    if file then
        currentLanguage = file:read("*a") or "it"
        file:close()
    end
end

-- Salva la configurazione della lingua
local function saveConfig()
    local file = io.open(configFile, "w")
    if file then
        file:write(currentLanguage)
        file:close()
    end
end

-- Carica la configurazione all'avvio
loadConfig()

-- Variabili del gioco
local dino = {
    x = 50,                  -- Posizione X del dinosauro
    y = 200,                 -- Posizione Y del dinosauro
    speed = 0,               -- Velocità verticale del dinosauro
    width = 30,              -- Larghezza del dinosauro 
    height = 30,             -- Altezza del dinosauro 
    image = nil,             -- Immagine corrente (verrà impostata dall'animazione)
    isDucking = false        -- Indica se il dinosauro è abbassato
}

-- Carica i frame dell'animazione del dinosauro
local dinoFrames = {
    image.load("assets/images/DinoRun1.png"), -- Frame 1 della corsa
    image.load("assets/images/DinoRun2.png")  -- Frame 2 della corsa
}
local dinoJumpFrame = image.load("assets/images/DinoJump.png") -- Frame del salto
local dinoGameOverFrame = image.load("assets/images/DinoDead.png") -- Frame di "game over"
local dinoDuckFrames = {
    image.load("assets/images/DinoDuck1.png"), -- Frame 1 dell'abbassamento
    image.load("assets/images/DinoDuck2.png")  -- Frame 2 dell'abbassamento
}
local dinoStartFrame = image.load("assets/images/DinoStart.png") -- Frame di inizio

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

-- Impostazioni
local settings = {
    musicEnabled = true,     -- Abilita/disabilita la musica
    soundEnabled = true      -- Abilita/disabilita i suoni
}

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
    speed = -5,              -- Velocità di scorrimento dello sfondo 
    image = image.load("assets/images/background.png")
}

-- Variabili per il menu
local inMenu = true          -- Indica se siamo nel menu
local menuSelection = 1      -- Indica l'opzione selezionata (1 = Gioca Infinito, 2 = Gioca a Tempo, 3 = Istruzioni, 4 = Impostazioni, 5 = Esci)
local menuBackground = image.load("assets/images/menu_background.png") -- Sfondo del menu
local titleY = 50            -- Posizione Y del titolo (per l'animazione)
local titleDirection = 1     -- Direzione dell'animazione del titolo

-- Carica i suoni
local jumpSound = sound.load("assets/sounds/jump.wav")
local gameOverSound = sound.load("assets/sounds/gameover.wav")
local backgroundMusic = sound.load("assets/sounds/background_music.mp3")

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
            width = 30, 
            height = 30, 
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
        if dino.isDucking then
            frameTimer = frameTimer + 1
            if frameTimer >= frameInterval then
                currentFrame = currentFrame + 1
                if currentFrame > #dinoDuckFrames then
                    currentFrame = 1
                end
                frameTimer = 0
            end
            dino.image = dinoDuckFrames[currentFrame] -- Usa il frame corrente dell'abbassamento
        else
            frameTimer = frameTimer + 1
            if frameTimer >= frameInterval then
                currentFrame = currentFrame + 1
                if currentFrame > #dinoFrames then
                    currentFrame = 1
                end
                frameTimer = 0
            end
            dino.image = dinoFrames[currentFrame] -- Usa il frame corrente della corsa
        end
    else
        dino.image = dinoJumpFrame -- Usa il frame del salto
    end
end

-- Funzione per resettare il gioco
function resetGame()
    dino.y = 200
    dino.speed = 0
    dino.isDucking = false
    cacti = {}
    score = 0
    gameOver = false
    if gameMode == "timed" then
        timeLeft = 60 -- Resetta il timer per la modalità a tempo
    end
end

-- Funzione di caricamento
function load()
    screen.clear(color.white)
    if settings.musicEnabled then
        sound.play(backgroundMusic, true) -- Riproduci la musica in loop
    end
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
                if gameOverSound and settings.soundEnabled then
                    sound.play(gameOverSound, false, 1) -- Priorità bassa
                end
            end
        end

        updateBackground()
    end
end

-- Funzione di disegno
function draw()
    screen.clear(color.white)
    image.blit(background.image, background.x1, 262) 
    image.blit(background.image, background.x2, 262) 

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
    screen.print(10, 10, translate("score") .. ": " .. score, 0.7, color.gray) 
    screen.print(10, 30, translate("highScore") .. ": " .. highScore, 0.7, color.gray) 

    -- Disegna il timer per la modalità a tempo
    if gameMode == "timed" then
        screen.print(10, 50, translate("time")..": " ..math.floor(timeLeft).." seconds", 0.7, color.gray) 
    end

    if gameOver then
        screen.print(300, 200, translate("gameOver"), 0.7, color.gray) 
        screen.print(280, 250, translate("restart"), 0.7, color.gray) 
    elseif isPaused then
        drawPauseMenu()
    end

    screen.flip()
end

-- Funzione per disegnare il menu di pausa
function drawPauseMenu()
    screen.print(300, 100, translate("pause"), 0.7, color.gray) 
    screen.print(280, 150, translate("resume"), 0.7, color.gray) 
    screen.print(280, 200, translate("restart"), 0.7, color.gray) 
    screen.print(280, 250, translate("backToMenu"), 0.7, color.gray) 
end

-- Gestione degli input
function handleInput()
    buttons.read()
    touch.read()

    -- Controllo touch per il salto
    if touch.front.count > 0 then
        for i = 1, touch.front.count do
            if touch.front[i].pressed and touch.front[i].y > 200 and dino.y == 200 then
                dino.speed = -15
                if jumpSound and settings.soundEnabled then
                    sound.play(jumpSound, false, 1) -- Priorità bassa
                end
            end
        end
    end

    -- Controllo touch per l'abbassamento
    if touch.front.count > 0 then
        for i = 1, touch.front.count do
            if touch.front[i].held and touch.front[i].y > 200 and dino.y == 200 then
                dino.isDucking = true
            else
                dino.isDucking = false
            end
        end
    end

    if gameOver and buttons.cross then
        gameOver = false
        resetGame() -- Resetta il gioco
    end

    -- Gestione della pausa
    if buttons.start then
        isPaused = not isPaused
        if isPaused then
            sound.pause(backgroundMusic) -- Ferma la musica in pausa 
        else
            if settings.musicEnabled then
                sound.play(backgroundMusic, true) -- Riprendi la musica
            end
        end
    end

    -- Gestione del menu di pausa
    if isPaused then
        if buttons.cross then
            -- Riavvia il gioco
            resetGame()
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
    screen.clear(color.white)
    image.blit(menuBackground, 0, 0) -- Disegna lo sfondo del menu

    -- Animazione del titolo
    titleY = titleY + titleDirection
    if titleY > 70 or titleY < 50 then
        titleDirection = -titleDirection
    end
    screen.print(200, titleY, "Dino Game", 1.0, color.gray) 

    -- Opzioni del menu
    if menuSelection == 1 then
        screen.print(200, 150, "> " .. translate("play") .. " (" .. translate("infinite") .. ")", 0.7, color.red)
    else
        screen.print(200, 150, translate("play") .. " (" .. translate("infinite") .. ")", 0.7, color.black)
    end

    if menuSelection == 2 then
        screen.print(200, 200, "> " .. translate("play") .. " (" .. translate("timed") .. ")", 0.7, color.red)
    else
        screen.print(200, 200, translate("play") .. " (" .. translate("timed") .. ")", 0.7, color.black)
    end

    if menuSelection == 3 then
        screen.print(200, 250, "> " .. translate("instructions"), 0.7, color.red)
    else
        screen.print(200, 250, translate("instructions"), 0.7, color.black)
    end

    if menuSelection == 4 then
        screen.print(200, 300, "> " .. translate("settings"), 0.7, color.red)
    else
        screen.print(200, 300, translate("settings"), 0.7, color.black)
    end

    if menuSelection == 5 then
        screen.print(200, 350, "> " .. translate("exit"), 0.7, color.red)
    else
        screen.print(200, 350, translate("exit"), 0.7, color.black)
    end

    screen.flip()
end

-- Funzione per gestire l'input nel menu
function handleMenuInput()
    buttons.read()
    touch.read()

    -- Selezione con l'analogico sinistro (asse Y)
    local analogY = buttons.analogly
    if analogY > 60 then -- Analogico verso il basso
        menuSelection = menuSelection + 1
        if menuSelection > 5 then
            menuSelection = 1
        end
    elseif analogY < -60 then -- Analogico verso l'alto
        menuSelection = menuSelection - 1
        if menuSelection < 1 then
            menuSelection = 5
        end
    end

    -- Selezione con i tasti direzionali (d-pad)
    if buttons.up then
        menuSelection = menuSelection - 1
        if menuSelection < 1 then
            menuSelection = 5
        end
    elseif buttons.down then
        menuSelection = menuSelection + 1
        if menuSelection > 5 then
            menuSelection = 1
        end
    end

    -- Selezione con il touch
    if touch.front.count > 0 then
        for i = 1, touch.front.count do
            local touchX, touchY = touch.front[i].x, touch.front[i].y

            -- Selezione del menu tramite touch
            if touchY > 150 and touchY < 200 then
                menuSelection = 1
            elseif touchY > 200 and touchY < 250 then
                menuSelection = 2
            elseif touchY > 250 and touchY < 300 then
                menuSelection = 3
            elseif touchY > 300 and touchY < 350 then
                menuSelection = 4
            elseif touchY > 350 and touchY < 400 then
                menuSelection = 5
            end

            -- Conferma selezione con touch
            if touch.front[i].pressed then
                if menuSelection == 1 then
                    inMenu = false
                    gameMode = "infinite"
                    resetGame() -- Resetta il gioco per la modalità infinita
                elseif menuSelection == 2 then
                    inMenu = false
                    gameMode = "timed"
                    resetGame() -- Resetta il gioco per la modalità a tempo
                    timeLeft = 60 -- Imposta il timer a 60 secondi
                elseif menuSelection == 3 then
                    showInstructions()
                elseif menuSelection == 4 then
                    showSettings()
                elseif menuSelection == 5 then
                    os.exit()
                end
            end
        end
    end

    -- Conferma selezione con il tasto Cross (X)
    if buttons.cross then
        if menuSelection == 1 then
            inMenu = false
            gameMode = "infinite"
            resetGame() -- Resetta il gioco per la modalità infinita
        elseif menuSelection == 2 then
            inMenu = false
            gameMode = "timed"
            resetGame() -- Resetta il gioco per la modalità a tempo
            timeLeft = 60 -- Imposta il timer a 60 secondi
        elseif menuSelection == 3 then
            showInstructions()
        elseif menuSelection == 4 then
            showSettings()
        elseif menuSelection == 5 then
            os.exit()
        end
    end
end

-- Funzione per mostrare le istruzioni
function showInstructions()
    while true do
        screen.clear(color.white)
        screen.print(100, 50, translate("instructions") .. ":", 0.7, color.gray) 
        screen.print(100, 100, translate("jumpHint"), 0.7, color.gray) 
        screen.print(100, 150, translate("avoidCacti"), 0.7, color.gray) 
        screen.print(100, 200, translate("backToMenu"), 0.7, color.gray) 
        screen.flip()

        buttons.read()
        if buttons.circle then
            break
        end

        os.delay(16)
    end
end

-- Funzione per mostrare le impostazioni
function showSettings()
    local settingsSelection = 1
    while true do
        screen.clear(color.white)
        screen.print(100, 50, translate("settings") .. ":", 0.7, color.black)

        if settingsSelection == 1 then
            screen.print(100, 100, "> " .. translate("music") .. ": " .. (settings.musicEnabled and "ON" or "OFF"), 0.7, color.red)
        else
            screen.print(100, 100, translate("music") .. ": " .. (settings.musicEnabled and "ON" or "OFF"), 0.7, color.black)
        end

        if settingsSelection == 2 then
            screen.print(100, 150, "> " .. translate("sounds") .. ": " .. (settings.soundEnabled and "ON" or "OFF"), 0.7, color.red)
        else
            screen.print(100, 150, translate("sounds") .. ": " .. (settings.soundEnabled and "ON" or "OFF"), 0.7, color.black)
        end

        if settingsSelection == 3 then
            screen.print(100, 200, "> " .. translate("language") .. ": " .. currentLanguageStr[currentLanguage], 0.7, color.red)
        else
            screen.print(100, 200, translate("language") .. ": " .. currentLanguageStr[currentLanguage], 0.7, color.black)
        end

        screen.print(100, 250, translate("backToMenu"), 0.7, color.black) 
        screen.flip()

        buttons.read()
        if buttons.down then
            settingsSelection = settingsSelection + 1
            if settingsSelection > 3 then
                settingsSelection = 1
            end
        elseif buttons.up then
            settingsSelection = settingsSelection - 1
            if settingsSelection < 1 then
                settingsSelection = 3
            end
        elseif buttons.cross then
            if settingsSelection == 1 then
                settings.musicEnabled = not settings.musicEnabled
                if settings.musicEnabled then
                    sound.play(backgroundMusic, true)
                else
                    sound.stop(backgroundMusic)
                end
            elseif settingsSelection == 2 then
                settings.soundEnabled = not settings.soundEnabled
            elseif settingsSelection == 3 then
                -- Cambia lingua
                if currentLanguage == "it" then
                    currentLanguage = "en"
                elseif currentLanguage == "en" then
                    currentLanguage = "fr" 
                elseif currentLanguage == "fr" then 
                    currentLanguage = "es" 
                else
                    currentLanguage = "it" 
                end
                saveConfig() -- Salva la nuova lingua
            end
        elseif buttons.circle then
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