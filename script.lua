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
        restart = "Premi X per continuare",
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
local currentLanguageStr = {["en"]="English", ["it"]="Italiano", ["es"]="Español", ["fr"]="Français"}

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

-- Variabili globali per la velocità base
local initialCactusSpeed = -10 -- Velocità base dei cactus
local initialBirdSpeed = -12   -- Velocità base dell'uccello
local initialBackgroundSpeed = -10 -- Velocità base dello sfondo

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
local cactusSpeed = initialCactusSpeed -- Velocità dei cactus (inizializzata con il valore base)
local cactusSpawnTimer = 0   -- Timer per generare nuovi cactus
local cactusSpawnInterval = 80 -- Intervallo di generazione dei cactus (in frame)
local maxCacti = 5           -- Numero massimo di cactus

-- Carica le immagini degli uccelli
local birdImages = {
    image.load("assets/images/bird1.png"),
    image.load("assets/images/bird2.png")
}

-- Variabili per l'uccello
local bird = {
    x = 800,                -- Posizione X iniziale dell'uccello
    y = 250,                -- Posizione Y iniziale dell'uccello
    speed = initialBirdSpeed, -- Velocità base dell'uccello (inizializzata con il valore base)
    width = 30,             -- Larghezza dell'uccello
    height = 30,            -- Altezza dell'uccello
    frame = 1,              -- Frame corrente dell'animazione
    frameTimer = 0,         -- Timer per l'animazione
    frameInterval = 10      -- Intervallo tra i frame (in frame del gioco)
}

-- Altezze per l'uccello
local birdHeights = {150, 140, 180} -- Altezze per l'uccello
local birdHeightIndex = 1           -- Indice per alternare le altezze
local nextBirdSpawnScore = 0        -- Memorizza il prossimo punteggio in cui l'uccello apparirà
local isBirdActive = false          -- Indica se l'uccello è attivo

-- Variabili per il movimento verticale degli uccelli
local birdAmplitude = 20 -- Quanto si sposta su e giù
local birdFrequency = 1 -- Velocità del movimento

-- Variabili per la gravità
local initialGravity = 0.7 -- Gravità ridotta a 0.7
local gravity = initialGravity

-- Carica l'immagine della nuvola
local cloudImage = image.load("assets/images/cloud.png")

-- Variabili per le nuvole
local clouds = {}             -- Tabella per memorizzare le nuvole
local cloudSpeed = initialBackgroundSpeed -- Velocità delle nuvole (inizializzata con il valore base)
local cloudSpawnTimer = 0     -- Timer per generare nuove nuvole
local cloudSpawnInterval = 150 -- Intervallo di generazione delle nuvole (2.5 secondi, 60 FPS * 2.5)

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
    speed = initialBackgroundSpeed, -- Velocità di scorrimento dello sfondo (inizializzata con il valore base)
    image = image.load("assets/images/background.png")
}

-- Variabili per il ciclo giorno/notte
local dayNightCycle = {
    timer = 0,               -- Timer per il ciclo giorno/notte
    phase = "day",           -- Fase corrente (day, sunset, night, sunrise)
    backgroundColors = {
        day = color.new(255, 255, 255),       -- Colore di sfondo di giorno
        sunset = color.new(255, 200, 100),    -- Colore di sfondo al tramonto
        night = color.new(50, 50, 100),       -- Colore di sfondo di notte
        sunrise = color.new(255, 150, 50)     -- Colore di sfondo all'alba
    }
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
    image.load("assets/images/cactus2.png"),
    image.load("assets/images/cactus3.png"),
    image.load("assets/images/cactus4.png"),
    image.load("assets/images/cactus5.png"),
    image.load("assets/images/cactus6.png")
}

local currentCactusImage = 1 -- Immagine corrente del cactus

-- Variabile per memorizzare lo stato precedente del tasto quadrato
local prevSquareState = false

-- Carica l'immagine di game over
local gameOverImage = image.load("assets/images/gameover.png")

-- Dimensioni predefinite dell'immagine gameover.png
local gameOverWidth = 400  -- Larghezza dell'immagine gameover.png
local gameOverHeight = 100 -- Altezza dell'immagine gameover.png

-- Funzione per generare un nuovo cactus
function spawnCactus()
    local numCacti = 1 -- Genera sempre solo 1 cactus
    for i = 1, numCacti do
        local spacing = 200  -- Aumenta la distanza tra i cactus
        local cactusType = math.random(1, #cactusImages) -- Scegli un tipo di cactus casuale
        table.insert(cacti, {
            x = 800 + (i * spacing),
            y = 200,
            speed = cactusSpeed, -- Usa la velocità aggiornata
            width = 30, 
            height = 30, 
            image = cactusImages[cactusType] -- Usa l'immagine casuale
        })
    end
end

-- Funzione per generare nuove nuvole
function spawnCloud()
    for i = 1, 3 do -- Genera 3 nuvole
        local cloudY = math.random(50, 150) -- Posizione Y casuale per la nuvola
        table.insert(clouds, {
            x = 960 + (i * 200), -- Distanzia le nuvole orizzontalmente
            y = cloudY,                     -- Posizione Y
            speed = cloudSpeed,             -- Velocità della nuvola
            width = 64,                     -- Larghezza della nuvola
            height = 24                     -- Altezza della nuvola
        })
    end
end

-- Funzione per aggiornare l'animazione dell'uccello
function updateBirdAnimation()
    bird.frameTimer = bird.frameTimer + 1
    if bird.frameTimer >= bird.frameInterval then
        bird.frame = bird.frame + 1
        if bird.frame > #birdImages then
            bird.frame = 1
        end
        bird.frameTimer = 0
    end
end

-- Funzione per aggiornare il movimento verticale dell'uccello
function updateBirdMovement()
    if isBirdActive then
        bird.y = birdHeights[birdHeightIndex] + math.sin(os.clock() * birdFrequency) * birdAmplitude
    end
end

-- Funzione per aggiornare la posizione dell'uccello
function updateBird()
    -- Controlla se il punteggio ha raggiunto il prossimo punteggio di spawn
    if score >= nextBirdSpawnScore then
        bird.x = 800 -- Resetta la posizione dell'uccello
        -- Alterna l'altezza dell'uccello
        birdHeightIndex = birdHeightIndex + 1
        if birdHeightIndex > #birdHeights then
            birdHeightIndex = 1
        end
        bird.y = birdHeights[birdHeightIndex]
        nextBirdSpawnScore = score + math.random(400, 1200) -- Imposta il prossimo spawn su un multiplo casuale tra 400 e 1200
        isBirdActive = true -- Attiva l'uccello
    end

    -- Aggiorna la posizione dell'uccello solo se è attivo
    if isBirdActive then
        bird.x = bird.x + bird.speed

        -- Controlla la collisione con il dinosauro
        if bird.x < dino.x + dino.width and
           bird.x + bird.width > dino.x and
           dino.y + dino.height > bird.y then
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

        -- Disattiva l'uccello quando esce dallo schermo
        if bird.x < -bird.width then
            isBirdActive = false
        end
    end
end

-- Funzione per aggiornare le nuvole
function updateClouds()
    cloudSpawnTimer = cloudSpawnTimer + 1
    if cloudSpawnTimer >= cloudSpawnInterval then
        spawnCloud()
        cloudSpawnTimer = 0
    end

    -- Aggiorna la posizione delle nuvole
    for i = #clouds, 1, -1 do
        local cloud = clouds[i]
        cloud.x = cloud.x + cloud.speed

        -- Rimuovi la nuvola se esce dallo schermo
        if cloud.x < -cloud.width then
            table.remove(clouds, i)
        end
    end
end

-- Funzione per disegnare le nuvole
function drawClouds()
    for _, cloud in ipairs(clouds) do
        image.blit(cloudImage, cloud.x, cloud.y)
    end
end

-- Funzione per aggiornare il punteggio continuamente
function updateScoreContinuously()
    score = score + 1 -- Aumenta il punteggio ogni frame (60 punti al secondo)
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
    if dino.y == 200 or dino.y == 230 then -- Se il dinosauro è a terra o abbassato
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
            dino.y = 230 -- Sposta il dinosauro verso il basso di 30 pixel
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
            dino.y = 200 -- Ripristina la posizione Y normale
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
    bird.x = 800 -- Resetta la posizione dell'uccello
    bird.y = birdHeights[birdHeightIndex] -- Imposta l'altezza casuale
    clouds = {}  -- Resetta le nuvole
    score = 0
    gameOver = false
    if gameMode == "timed" then
        timeLeft = 60 -- Resetta il timer per la modalità a tempo
    end
    -- Resetta il ciclo giorno/notte
    dayNightCycle.timer = 0
    dayNightCycle.phase = "day"
    -- Resetta l'uccello
    isBirdActive = false
    nextBirdSpawnScore = 0
    -- Resetta la gravità
    gravity = initialGravity
    -- Resetta le velocità
    cactusSpeed = initialCactusSpeed
    bird.speed = initialBirdSpeed
    background.speed = initialBackgroundSpeed
end

-- Funzione per aggiornare il ciclo giorno/notte
function updateDayNightCycle()
    dayNightCycle.timer = dayNightCycle.timer + 1 / 60 -- Incrementa il timer ogni secondo

    -- Cambia fase ogni 1 minuto (60 secondi)
    if dayNightCycle.timer >= 60 then
        dayNightCycle.timer = 0
        if dayNightCycle.phase == "day" then
            dayNightCycle.phase = "sunset"
        elseif dayNightCycle.phase == "sunset" then
            dayNightCycle.phase = "night"
        elseif dayNightCycle.phase == "night" then
            dayNightCycle.phase = "sunrise"
        elseif dayNightCycle.phase == "sunrise" then
            dayNightCycle.phase = "day"
        end
    end
end

-- Funzione per disegnare lo sfondo con il ciclo giorno/notte
function drawBackgroundWithDayNight()
    local bgColor = dayNightCycle.backgroundColors[dayNightCycle.phase] or color.new(255, 255, 255)
    screen.clear(bgColor)
    image.blit(background.image, background.x1, 262) 
    image.blit(background.image, background.x2, 262) 
end

-- Funzione per aumentare la gravità gradualmente
function increaseGravity()
    if score % 800 == 0 and score > 0 then
        gravity = gravity + 0.05 -- Aumenta la gravità di 0.05 ogni 800 punti
    end
end

-- Funzione per aggiornare la velocità in base al punteggio
function updateSpeedBasedOnScore()
    local speedIncrease = math.floor(score / 100) * 0.5 -- Aumenta la velocità ogni 100 punti
    cactusSpeed = initialCactusSpeed - speedIncrease
    bird.speed = initialBirdSpeed - speedIncrease
    background.speed = initialBackgroundSpeed - speedIncrease
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

        -- Aggiorna la posizione dell'uccello e l'animazione
        updateBird()
        updateBirdAnimation()
        updateBirdMovement() -- Aggiorna il movimento verticale dell'uccello

        -- Aggiorna le nuvole
        updateClouds()

        -- Aggiorna il punteggio continuamente
        updateScoreContinuously()

        -- Aumenta la gravità gradualmente
        increaseGravity()

        -- Aggiorna il ciclo giorno/notte
        updateDayNightCycle()

        -- Aggiorna la velocità in base al punteggio
        updateSpeedBasedOnScore()

        -- Aggiorna la posizione dei cactus e controlla le collisioni
        for i = #cacti, 1, -1 do
            local cactus = cacti[i]
            cactus.x = cactus.x + cactus.speed

            if cactus.x < -cactus.width then
                table.remove(cacti, i)
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
    drawBackgroundWithDayNight()

    -- Disegna le nuvole
    drawClouds()

    if gameOver then
        -- Carica l'immagine di game over
        local gameOverImage = image.load("assets/images/gameover.png")

        -- Calcola le coordinate per centrare l'immagine
        local gameOverX = (960 - gameOverWidth) / 2
        local gameOverY = (544 - gameOverHeight - 40) / 2 -- Lascia spazio per il testo sotto

        -- Disegna l'immagine di game over centrata
        image.blit(gameOverImage, gameOverX, gameOverY)

        -- Testo "Premi X per continuare"
        local restartText = translate("restart") -- "Premi X per continuare" (tradotto)

        -- Dimensioni approssimative del testo
        local restartWidth = 250 -- Larghezza approssimativa di "Premi X per continuare"
        local restartHeight = 20 -- Altezza approssimativa di "Premi X per continuare"

        -- Calcola le coordinate per centrare il testo sotto l'immagine
        local restartX = (960 - restartWidth) / 2
        local restartY = gameOverY + gameOverHeight + 20 -- Posiziona sotto l'immagine

        -- Mostra "Premi X per continuare"
        screen.print(restartX, restartY, restartText, 0.7, color.gray) -- Testo grigio, dimensione 0.7
    else
        -- Mostra il frame corrente dell'animazione
        image.blit(dino.image, dino.x, dino.y)
    end

    -- Disegna i cactus
    for _, cactus in ipairs(cacti) do
        image.blit(cactus.image, cactus.x, cactus.y)
    end

    -- Disegna l'uccello solo se è attivo
    if isBirdActive then
        image.blit(birdImages[bird.frame], bird.x, bird.y)
    end

    -- Disegna il punteggio e l'highscore
    screen.print(10, 10, translate("score") .. ": " .. score, 0.7, color.gray) 
    screen.print(10, 30, translate("highScore") .. ": " .. highScore, 0.7, color.gray) 

    -- Disegna il timer per la modalità a tempo
    if gameMode == "timed" then
        screen.print(10, 50, translate("time")..": " ..math.floor(timeLeft).." seconds", 0.7, color.gray) 
    end

    -- Disegna il menu di pausa se il gioco è in pausa
    if isPaused then
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

    -- Controllo salto con il tasto X
    if buttons.cross and (dino.y == 200 or dino.y == 230) then
        dino.speed = -15
        if jumpSound and settings.soundEnabled then
            sound.play(jumpSound, false, 1) -- Priorità bassa
        end
    end

    -- Controllo abbassamento/rialzamento con il tasto quadrato
    local currentSquareState = buttons.square
    if currentSquareState and not prevSquareState then
        -- Tasto quadrato premuto (non era premuto nel frame precedente)
        dino.isDucking = not dino.isDucking -- Alterna lo stato di abbassamento
    end
    prevSquareState = currentSquareState -- Memorizza lo stato corrente per il prossimo frame

    -- Controllo touch per il salto
    if touch.front.count > 0 then
        for i = 1, touch.front.count do
            if touch.front[i].pressed and touch.front[i].y > 200 and (dino.y == 200 or dino.y == 230) then
                dino.speed = -15
                if jumpSound and settings.soundEnabled then
                    sound.play(jumpSound, false, 1) -- Priorità bassa
                end
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
            isPaused = false
            if settings.musicEnabled then
                sound.play(backgroundMusic, true) -- Riprendi la musica
            end
        elseif buttons.circle then
            -- Torna al menu principale
            inMenu = true
            isPaused = false
            resetGame() -- Resetta il gioco
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