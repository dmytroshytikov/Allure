module Actions where

import Control.Monad
import Control.Monad.State hiding (State)
import Data.Function
import Data.List as L
import Data.Map as M
import qualified Data.IntMap as IM
import Data.Maybe
import Data.Set as S
import System.Time

import Action
import Actor hiding (updateActor)
import Display2 hiding (display)
import Dungeon
import Geometry
import Grammar
import qualified HighScores as H
import Item
import qualified Keys as K
import Level
import LevelState
import Message
import Monster
import Perception
import Random
import qualified Save as S
import State
import qualified Config

displayHistory :: Action ()
displayHistory =
  do
    hst <- gets shistory
    messageOverlayConfirm "" (unlines hst)
    abort

dumpConfig :: Action ()
dumpConfig =
  do
    config <- gets sconfig
    let fn = "LambdaHack.config.dump"
    liftIO $ Config.dump fn config
    abortWith $ "Current configuration dumped to file " ++ fn ++ "."

saveGame :: Action ()
saveGame =
  do
    b <- messageYesNo "Really save?"
    if b
      then do
        -- Save the game state
        st <- get
        liftIO $ S.saveGame st
        ln <- gets (lname . slevel)
        let total = calculateTotal st
            status = H.Camping ln
        go <- handleScores False status total
        when go $ messageMore "See you soon, stronger and braver!"
        end
      else abortWith "Game resumed."

quitGame :: Action ()
quitGame =
  do
    b <- messageYesNo "Really quit?"
    if b
      then end -- TODO: why no highscore? no display, because the user may be in a hurry, since he quits the game instead of getting himself killed properly? no score recording, not to polute the scores list with games that the player didn't even want to end honourably?
      else abortWith "Game resumed."

cancelCurrent :: Action ()
cancelCurrent =
  do
    state <- get
    case slook state of
      Just lk -> cancelLook lk
      Nothing -> abortWith "Press Q to quit."

moveCursor :: Look -> Dir -> Int -> Action ()  -- TODO: do not take time!!!
moveCursor lk@(Look { cursorLoc = loc }) dir n =
  do
    (sy, sx) <- gets (lsize . slevel)
    let iter :: Int -> (a -> a) -> a -> a  -- not in base libs???
        iter 0 _ x = x
        iter k f x = f (iter (k-1) f x)
        (ny, nx) = iter n (`shift` dir) loc
        nloc = (max 1 $ min ny (sy-1), max 1 $ min nx (sx-1))
        nlk  = lk { cursorLoc = nloc }
    modify (updateLook (const $ Just nlk))
    doLook nlk

move :: Dir -> Action ()
move dir =
  do
    state <- get
    case slook state of
      Just lk -> moveCursor lk dir 1
      Nothing -> moveOrAttack True True APlayer dir

run :: Dir -> Action ()
run dir =
  do
    state <- get
    case slook state of
      Just lk -> moveCursor lk dir 10
      Nothing -> do
        modify (updatePlayer (\ p -> p { mdir = Just dir }))
        -- attacks and opening doors disallowed while running
        moveOrAttack False False APlayer dir

-- | This function implements the actual "logic" of running. It checks if we
-- have to stop running because something interested happened, and it checks
-- if we have to adjust the direction because we're in the corner of a corridor.
continueRun :: Dir -> Action ()
continueRun dir =
  do
    state <- get
    let lvl@(Level { lmonsters = ms, lmap = lmap, lheroes = hs }) = slevel state
    let player@(Monster { mloc = loc }) = splayer state
    let mslocs = S.fromList (L.map mloc ms)
    let t      = lmap `at` loc  -- tile at current location
    per <- currentPerception
    msg <- currentMessage
    let monstersVisible = not (S.null (mslocs `S.intersection` pvisible per))
    let newsReported    = not (L.null msg)
    let itemsHere       = not (L.null (titems t))
    let heroThere       = L.elem (loc `shift` dir) (L.map mloc (IM.elems hs))
    let dirOK           = accessible lmap loc (loc `shift` dir)
    -- What happens next is mostly depending on the terrain we're currently on.
    let exit (Stairs  {}) = True
        exit (Opening {}) = True
        exit (Door    {}) = True
        exit _            = False
    let hop t
          | monstersVisible || heroThere
            || newsReported || itemsHere || exit t = abort
        hop Corridor =
          -- in corridors, explore all corners and stop at all crossings
          let ns = L.filter (\ x -> distance (neg dir, x) > 1
                                    && accessible lmap loc (loc `shift` x))
                            moves
              allCloseTo main = L.all (\ d -> distance (main, d) <= 1) ns
          in  case ns of
                [onlyDir] -> run onlyDir  -- can be diagonal
                _         ->
                  -- prefer orthogonal to diagonal dirs, for hero's safety
                  case L.filter (\ x -> not $ diagonal x) ns of
                    [ortoDir]
                      | allCloseTo ortoDir -> run ortoDir
                    _ -> abort
        hop _  -- outside corridors, never change direction
          | not dirOK = abort
        hop _         =
          let ns = L.filter (\ x -> x /= dir && distance (neg dir, x) > 1) moves
              ls = L.map (loc `shift`) ns
              as = L.filter (\ x -> accessible lmap loc x
                                    || openable 0 lmap x) ls
              ts = L.map (tterrain . (lmap `at`)) as
          in  if L.any exit ts then abort else run dir
    hop (tterrain t)

stopRunning :: Action ()
stopRunning = modify (updatePlayer (\ p -> p { mdir = Nothing }))

ifRunning :: (Dir -> Action a) -> Action a -> Action a
ifRunning t e =
  do
    mdir <- gets (mdir . splayer)
    maybe e t mdir

-- | Store current message in the history and reset current message.
history :: Action ()
history =
  do
    msg <- resetMessage
    config <- gets sconfig
    let historyMax = Config.get config "ui" "historyMax"
    unless (L.null msg) $
      modify (updateHistory (take historyMax . ((msg ++ " "):)))

-- | Update player memory.
remember :: Action ()
remember =
  do
    per <- currentPerception
    let vis         = S.toList (pvisible per)
    let rememberLoc = M.update (\ (t,_) -> Just (t,t))
    modify (updateLevel (updateLMap (\ lmap -> foldr rememberLoc lmap vis)))

-- | Remove dead heroes, check if game over.
-- For now we only check the selected hero, but if poison, etc.
-- is implemented, we'd need to check all heroes on the level.
checkPartyDeath :: Action ()
checkPartyDeath =
  do
    state  <- get
    player <- gets splayer
    config <- gets sconfig
    let firstDeathEnds = Config.get config "heroes" "firstDeathEnds"
    when (mhp player <= 0) $ do
      messageAddMore
      go <- messageMoreConfirm "You die."
      if firstDeathEnds
        then gameOver go
        else case allLevelHeroes state of
               [] -> gameOver go
               (ni, nln, np) : _ -> do
                 promotePlayer ni (nln, np)
                 message "The survivors carry on."

-- | End game, showing the ending screens, if requsted.
gameOver :: Bool -> Action ()
gameOver showEndingScreens =
  do
    when showEndingScreens $ do
      state <- get
      ln <- gets (lname . slevel)
      let total = calculateTotal state
          status = H.Killed ln
      handleScores True status total
      messageMore "Let's hope another party can save the day!"
    end

neverMind :: Bool -> Action a
neverMind b = abortIfWith b "never mind"

-- | Open and close doors
openclose :: Bool -> Action ()
openclose o =
  do
    message "direction?"
    display
    e <- session nextCommand
    handleDirection e (actorOpenClose APlayer True o) (neverMind True)

actorOpenClose :: Actor ->
                  Bool ->    -- ^ verbose?
                  Bool ->    -- ^ open?
                  Dir -> Action ()
actorOpenClose actor v o dir =
  do
    let txt = if o then "open" else "closed"
    state <- get
    let lvl@Level { lmonsters = ms, lmap = lmap } = slevel state
    let loc                                       = mloc (getActor state actor)
    let isPlayer  = actor == APlayer
    let isVerbose = v && isPlayer
    let dloc = shift loc dir  -- location we act upon
      in case lmap `at` dloc of
           Tile d@(Door hv o') []
             | secret o' && isPlayer-> -- door is secret, cannot be opened or closed by hero
                                       neverMind isVerbose
             | maybe o ((|| not o) . (> 10)) o' ->
                                       -- door is in unsuitable state
                                       abortIfWith isVerbose ("already " ++ txt)
             | not (unoccupied ms lmap dloc) ->
                                       -- door is blocked by a monster
                                       abortIfWith isVerbose "blocked"
             | otherwise            -> -- door can be opened / closed
                                       -- TODO: print message if action performed by monster and perceived
                                       let nt    = Tile (Door hv (toOpen o)) []
                                           clmap = M.adjust (\ (_, mt) -> (nt, mt)) dloc lmap
                                       in  modify (updateLevel (const (updateLMap (const clmap) lvl)))
           Tile d@(Door hv o') _    -> -- door is jammed by items
                                       abortIfWith isVerbose "jammed"
           _                        -> -- there is no door here
                                       neverMind isVerbose

-- | Perform a level switch to a given level. False, if nothing to do.
-- TODO: in look mode do not take time, otherwise take as much as 1 step.
lvlswitch :: LevelName -> Action Bool
lvlswitch nln =
  do
    ln <- gets (lname . slevel)
    if (nln == ln)
      then return False
      else do
        level <- gets slevel
        dungeon <- gets sdungeon
        -- put back current level
        -- (first put back, then get, in case we change to the same level!)
        let full = putDungeonLevel level dungeon
        -- get new level
        let (new, ndng) = getDungeonLevel nln full
        modify (\ s -> s { sdungeon = ndng, slevel = new })
        return True

 -- | Attempt a level switch to k levels deeper.
lvldescend :: Int -> Action ()
lvldescend k =
  do
    state <- get
    let n = levelNumber (lname (slevel state))
        nln = n + k
    when (nln < 1 || nln > sizeDungeon (sdungeon state) + 1) $
      abortWith "no more levels in this direction"
    assertTrue $ lvlswitch (LambdaCave nln)

-- | Attempt a level change via up level and down level keys.
-- Will quit the game if the player leaves the dungeon.
lvlchange :: VDir -> Action ()
lvlchange vdir =
  do
    state <- get
    look  <- gets slook
    let map = lmap (slevel state)
        loc = case look of
                Nothing -> mloc (splayer state)
                Just (Look { cursorLoc = loc }) -> loc
    case map `at` loc of
      Tile (Stairs _ vdir' next) is
        | vdir == vdir' -> -- stairs are in the right direction
          case next of
            Nothing ->
              -- we are at the "end" of the dungeon
              case look of  -- lvlswitch does not modify look
                Nothing -> do
                  b <- messageYesNo "Really escape the dungeon?"
                  if b
                    then fleeDungeon
                    else abortWith "Game resumed."
                Just _ ->
                  abortWith "cannot escape dungeon in look mode"
            Just (nln, nloc) -> do
              assertTrue $ lvlswitch nln  -- no stairs go back to the same level
              case look of
                Nothing ->
                  -- land the player at the other end of the stairs
                  modify (updatePlayer (\ p -> p { mloc = nloc }))
                Just lk -> do
                  -- do not freely reveal the other end of the stairs
                  map <- gets (lmap . slevel)  -- lvlswitch modifies map
                  let destinationLoc = if isUnknown (rememberAt map nloc)
                                       then loc
                                       else nloc
                      nlk = lk { cursorLoc = destinationLoc }
                  modify (updateLook (const $ Just nlk))
                  doLook nlk
      _ -> -- no stairs
        case look of
          Just lk -> do
            lvldescend (if vdir == Up then -1 else 1)
            doLook lk  -- lvldescend does not change lk
          Nothing -> do
            let txt = if vdir == Up then "up" else "down"
            abortWith ("no stairs " ++ txt)

-- | Hero has left the dungeon.
fleeDungeon :: Action ()
fleeDungeon =
  do
    state <- get
    let total = calculateTotal state
        hs    = levelHeroList state
        items = L.concatMap mitems hs
    if total == 0
      then do
             go <- messageMoreConfirm "Coward!"
             when go $
               messageMore "Next time try to grab some loot before escape!"
             end
      else do
             let winMsg = "Congratulations, you won! Your loot, worth " ++
                          show total ++ " gold, is:"
             displayItems winMsg True items
             go <- session getConfirm
             when go $ do
               go <- handleScores True H.Victor total
               when go $ messageMore "Can it be done better, though?"
             end

-- | Switches current hero to the next hero on the level, if any, wrapping.
cycleHero :: Action ()
cycleHero =
  do
    hs <- gets (lheroes . slevel)
    player <- gets splayer
    let i = heroNumber player
        (lt, gt) = IM.split i hs
    case IM.keys gt ++ IM.keys lt of
      [] -> abortWith "Cannot select another hero on this level."
      ni : _ -> assertTrue $ selectHero ni

-- | Selects a hero based on the number. Focuses on the hero if level changed.
-- False, if nothing to do.
selectHero :: Int -> Action Bool
selectHero ni =
  do
    player <- gets splayer
    let i = heroNumber player
    if (ni == i)
      then return False -- already selected
      else do
        state <- get
        case findHeroLevel ni state of
          Nothing ->
            abortWith $ "No hero number " ++ show ni ++ " in the party."
          Just (nln, np) -> do
            -- put the old player back into his original level
            stashPlayer
            -- move over the new hero
            promotePlayer ni (nln, np)
            -- announce
            messageAdd $ "Hero number " ++ show ni ++ " selected."
            return True

-- | Copies player to an ordinary hero slot on his level.
stashPlayer :: Action ()
stashPlayer =
  do
    state  <- get
    player <- gets splayer
    let i = heroNumber player
        ins = updateHeroes $ IM.insert i player
        ln = playerLevel state
    modify (updateAnyLevel ins ln)

-- | Moves a hero to the player-controlled position.
promotePlayer :: Int -> (LevelName, Hero) -> Action ()
promotePlayer ni (nln, np) =
  do
    -- switch to the level with the new hero
    lvlChanged <- lvlswitch nln
    -- make the new hero the player controlled hero
    modify (updateLevel (updateHeroes $ IM.delete ni))
    modify (updatePlayer (const np))
    -- if in look mode, record the original level of the new hero
    -- and focus on him, if level changed
    let upd lk = let loc = if lvlChanged then mloc np else cursorLoc lk
                 in  lk { returnLn = nln, cursorLoc = loc }
    modify (updateLook (fmap upd))

-- | Calculate loot's worth. TODO: move to another module, and refine significantly.
calculateTotal :: State -> Int
calculateTotal s =
  L.sum $ L.map price $ L.concatMap mitems hs
    where
      hs = levelHeroList s
      price i = if iletter i == Just '$' then icount i else 10 * icount i

-- | Handle current score and display it with the high scores. Scores
-- should not be shown during the game, because ultimately the worth of items might give
-- information about the nature of the items.
-- False if display of the scores was void or interrupted by the user
handleScores :: Bool -> H.Status -> Int -> Action Bool
handleScores write status total =
  if (total == 0)
  then return False
  else do
    config  <- gets sconfig
    time    <- gets stime
    curDate <- liftIO getClockTime
    let points = case status of
                   H.Killed _ -> (total + 1) `div` 2
                   _ -> total
    let score = H.ScoreRecord points (-time) curDate status
    (placeMsg, slideshow) <- liftIO $ H.register config write score
    messageOverlaysConfirm placeMsg slideshow

-- | Search for secret doors
search :: Action ()
search =
  do
    Level   { lmap = lmap } <- gets slevel
    Monster { mloc = ploc } <- gets splayer
    let searchTile (Tile (Door hv (Just n)) x,t') = Just (Tile (Door hv (Just (max (n - 1) 0))) x, t')
        searchTile t                              = Just t
        slmap = foldl (\ l m -> update searchTile (shift ploc m) l) lmap moves
    modify (updateLevel (updateLMap (const slmap)))

-- | Toggle look mode.
lookAround :: Action ()
lookAround =
  do
    state <- get
    case slook state of
      Just lk -> cancelLook lk
      Nothing -> do
                   lk <- setLook
                   doLook lk

-- | Set look mode.
setLook :: Action Look
setLook =
  do
    state <- get
    let loc = mloc (splayer state)
        tgt = TNone
        ln  = lname (slevel state)
        lk  = Look loc tgt ln
    modify (updateLook (const $ Just lk))
    return lk

-- | Cancel look mode.
cancelLook :: Look -> Action ()
cancelLook (Look _ tgt ln) =
  do
    lvlswitch ln
    modify (updatePlayer (\ p -> p { mtarget = tgt }))
    modify (updateLook (const Nothing))
    messageAdd "Look mode canceled."

-- | Perform look around in the current location of the cursor.
-- TODO: depending on tgt or an extra flag, show tile, monster or both
-- TODO: do not take time
doLook :: Look -> Action ()
doLook (Look { cursorLoc = loc }) =
  do
    state <- get
    lmap  <- gets (lmap . slevel)
    ms    <- gets (lmonsters . slevel)
    per   <- currentPerception
    let monsterMsg =
          if S.member loc (pvisible per)
          then case L.find (\ m -> mloc m == loc) ms of
                 Just m  -> subjectMonster (mtype m) ++ " is there. "
                 Nothing -> ""
          else ""
        -- general info about current loc
        lookMsg = lookAt True state lmap loc monsterMsg
        -- check if there's something lying around at current loc
        t = lmap `at` loc
    if length (titems t) <= 2
      then do
             messageAdd lookMsg
      else do
             displayItems lookMsg False (titems t)
             session getConfirm
             messageAdd ""

-- | Display inventory
inventory :: Action a
inventory =
  do
    player <- gets splayer
    if L.null (mitems player)
      then abortWith "You are not carrying anything"
      else do
             displayItems "This is what you are carrying:" True (mitems player)
             session getConfirm
             abortWith ""

-- | Given item is now known to the player.
discover :: Item -> Action ()
discover i = modify (updateDiscoveries (S.insert (itype i)))

drinkPotion :: Action ()
drinkPotion =
  do
    state <- get
    let lvl   @(Level   { lmap = lmap }) = slevel  state
    let player@(Monster { mloc = ploc }) = splayer state
    if L.null (mitems player)
      then abortWith "You are not carrying anything."
      else do
             i <- getPotion "What to drink?" (mitems player) "inventory"
             case i of
               Just i'@(Item { itype = Potion ptype }) ->
                 do
                   -- only one potion is consumed even if several are joined in the inventory
                   let consumed = i' { icount = 1 }
                       baseHp = Config.get (sconfig state) "heroes" "baseHp"
                   removeFromInventory consumed
                   message (subjectVerbIObject state player "drink" consumed "")
                   -- the potion is identified after drinking
                   discover i'
                   case ptype of
                     PotionWater   -> messageAdd "Tastes like water."
                     PotionHealing -> do
                                        messageAdd "You feel better."
                                        modify (updatePlayer (\ p -> p { mhp = min (mhpmax p) (mhp p + baseHp `div` 4) }))
               Just _  -> abortWith "you cannot drink that"
               Nothing -> neverMind True

dropItem :: Action ()
dropItem =
  do
    state <- get
    let player@(Monster { mloc = ploc }) = splayer state
    if L.null (mitems player)
      then abortWith "You are not carrying anything."
      else do
             i <- getAnyItem "What to drop?" (mitems player) "inventory"
             case i of
               Just i' ->
                 do
                   removeFromInventory i'
                   message (subjectVerbIObject state player "drop" i' "")
                   dropItemsAt [i'] ploc
               Nothing -> neverMind True

dropItemsAt :: [Item] -> Loc -> Action ()
dropItemsAt is loc = modify (updateLevel (scatterItems is loc))

-- | Remove given item from the hero's inventory.
removeFromInventory :: Item -> Action ()
removeFromInventory i =
  modify (updatePlayer (\ p -> p { mitems = removeItemByLetter i (mitems p) }))

-- | Remove given item from the given location.
removeFromLoc :: Item -> Loc -> Action ()
removeFromLoc i loc =
  modify (updateLevel (\ l -> l { lmap = M.adjust (\ (t, rt) -> (update t, rt)) loc (lmap l) }))
  where
    update t = t { titems = removeItemByType i (titems t) }

-- | Let the player choose any potion. Note that this does not guarantee a potion to be chosen,
-- as the player can override the choice.
getPotion :: String ->  -- prompt
             [Item] ->  -- all objects in question
             String ->  -- how to refer to the collection of objects, e.g. "in your inventory"
             Action (Maybe Item)
getPotion prompt is isn = getItem prompt (\ i -> case itype i of Potion {} -> True; _ -> False)
                                  "Potions" is isn

actorPickupItem :: Actor -> Action ()
actorPickupItem actor =
  do
    state <- get
    per   <- currentPerception
    let lvl@(Level { lmap = lmap }) = slevel state
    let monster   = getActor state actor
    let loc       = mloc monster
    let t         = lmap `at` loc -- the map tile in question
    let perceived = loc `S.member` pvisible per
    let isPlayer  = actor == APlayer
    -- check if something is here to pick up
    case titems t of
      []     -> abortIfWith isPlayer "nothing here"
      (i:rs) -> -- pick up first item; TODO: let player select item; not for monsters
        case assignLetter (iletter i) (mletter monster) (mitems monster) of
          Just l ->
            do
              let (ni, nitems) = joinItem (i { iletter = Just l }) (mitems monster)
              -- message is dependent on who picks up and if the hero can perceive it
              if isPlayer
                then message (letterLabel (iletter ni) ++ objectItem state (icount ni) (itype ni))
                else when perceived $
                       message $ subjectCompoundVerbIObject state monster "pick" "up" i ""
              removeFromLoc i loc
              -- add item to actor's inventory:
              updateActor actor $ \ m ->
                m { mitems = nitems, mletter = maxLetter l (mletter monster) }
          Nothing -> abortIfWith isPlayer "you cannot carry any more"

-- | Replaces the version in Actor module
updateActor :: Actor ->                 -- ^ who to update
               (Monster -> Monster) ->  -- ^ the update
               Action ()
updateActor (AMonster n) f =
  do
    monsters <- gets (lmonsters . slevel)
    let (m, ms) = updateMonster f n monsters
    modify (updateLevel (updateMonsters (const ms)))
updateActor APlayer f =
  modify (updatePlayer f)

pickupItem :: Action ()
pickupItem = actorPickupItem APlayer

-- TODO: I think that player handlers should be wrappers around more general actor handlers, but
-- the actor handlers should be performing specific actions, i.e., already specify the item to be
-- picked up. It doesn't make sense to invoke dialogues for arbitrary actors, and most likely the
-- decision for a monster is based on perceiving a particular item to be present, so it's already
-- known. In actor handlers we should make sure that messages are printed to the player only if the
-- hero can perceive the action.

-- | Let the player choose any item from a list of items.
getAnyItem :: String ->  -- prompt
              [Item] ->  -- all objects in question
              String ->  -- how to refer to the collection of objects, e.g. "in your inventory"
              Action (Maybe Item)
getAnyItem prompt is isn = getItem prompt (const True) "Objects" is isn

-- | Let the player choose a single item from a list of items.
getItem :: String ->              -- prompt message
           (Item -> Bool) ->      -- which items to consider suitable
           String ->              -- how to describe suitable objects
           [Item] ->              -- all objects in question
           String ->              -- how to refer to the collection of objects, e.g. "in your inventory"
           Action (Maybe Item)
getItem prompt p ptext is0 isn =
  let is = L.filter p is0
      choice | L.null is = "[*]"
             | otherwise = "[" ++ letterRange (concatMap (maybeToList . iletter) is) ++ " or ?*]"
      r = do
            message (prompt ++ " " ++ choice)
            display
            let h = session nextCommand >>= h'
                h' e = case e of
                         K.Char '?' -> do
                                         -- filter for supposedly suitable objects
                                         b <- displayItems (ptext ++ " " ++ isn) True is
                                         if b then session (getOptionalConfirm (const r) h')
                                              else r
                         K.Char '*' -> do
                                         -- show all objects
                                         b <- displayItems ("Objects " ++ isn) True is0
                                         if b then session (getOptionalConfirm (const r) h')
                                              else r
                         K.Char l   -> return (find (\ i -> maybe False (== l) (iletter i)) is0)
                         _          -> return Nothing
            h
  in r

displayItems :: Message -> Bool -> [Item] -> Action Bool
displayItems msg sorted is =
    do
      state <- get
      let inv = unlines $
                L.map (\ (Item { icount = c, iletter = l, itype = t }) ->
                         letterLabel l ++ objectItem state c t ++ " ")
                      ((if sorted then sortBy (cmpLetter' `on` iletter) else id) is)
      let ovl = inv ++ more
      message msg
      overlay ovl

-- | This function performs a move (or attack) by any actor,
-- i.e., it can handle monsters, heroes and both.
moveOrAttack :: Bool ->        -- allow attacks?
                Bool ->        -- auto-open doors on move
                Actor ->       -- who's moving?
                Dir ->
                Action ()
moveOrAttack allowAttacks autoOpen source dir
  | dir == (0,0) =
      -- Moving with no direction is a noop.
      -- We include it currently to prevent that
      -- monsters attack themselves by accident.
      return ()
  | otherwise = do
      -- We start by looking at the target position.
      state <- get
      ms    <- gets (lmonsters . slevel)
      lmap  <- gets (lmap . slevel)
      let sm   = getActor state source
          sloc = mloc sm           -- source location
          tloc = sloc `shift` dir  -- target location
          hs   = levelHeroList state
          tgt  = case L.find (\ m -> mloc m == tloc) hs of
                   Just m -> Just (APlayer, m)
                   Nothing ->
                     case L.findIndex (\ m -> mloc m == tloc) ms of
                       Just i -> Just (AMonster i, ms !! i)
                       Nothing -> Nothing
      case tgt of
        Just (target, tm) ->
          if allowAttacks then
            -- Attacking does not require full access, adjacency is enough.
            actorAttackActor source sm target tm
          else if accessible lmap sloc tloc then do
            -- Switching positions requires full access.
            actorRunActor source sm target tm
            when (source == APlayer) $ message $ lookAt False state lmap tloc ""
          else abort
        Nothing ->
          if accessible lmap sloc tloc then do
            -- perform the move
            updateActor source (\ m -> m { mloc = tloc })
            when (source == APlayer) $ message $ lookAt False state lmap tloc ""
          else if autoOpen then
            -- try to open a door
            actorOpenClose source False True dir
          else abort

-- | Resolves the result of an actor moving into another. Usually this
-- involves melee attack, but with two heroes it just changes focus.
-- Monsters on blocked locations can be attacked without any restrictions.
-- For instance, a monster on an open door can be attacked diagonally,
-- and a monster capable of moving through walls can be attacked from an
-- adjacent position.
-- TODO: perhaps do not use actors, but the mtype field of monsters instead?
-- I use actors here via a hack, anyway, because if the target actor is
-- APlayer, then his monster body may be not equal to (getActor state target),
-- until the hero is selected (and in actorRunActor the target may be not
-- selected at all, whenever source is a hero). If monsters are kept in a map,
-- not on a list, they will have permanent numbers, so mtype will be usable.
actorAttackActor :: Actor -> Monster -> Actor -> Monster -> Action ()
actorAttackActor APlayer _ APlayer tm = do -- TODO: do not take a turn!!!
  -- Select adjacent hero by bumping into him.
  let i = heroNumber tm
  assertTrue $ selectHero i
actorAttackActor source sm target tm =
  do
    debug "actorAttackActor"
    when (target == APlayer) $ do
      -- Focus on the attacked hero.
      let i = heroNumber tm
      b <- selectHero i
      -- Extra prompt, in case many heroes attacked in one turn.
      when b $ messageAddMore >> return ()
    state <- get
    let -- determine the weapon used for the attack
        sword = strongestSword (mitems sm)
        -- damage the target
        newHp  = mhp tm - 3 - sword
        killed = newHp <= 0
        -- determine how the hero perceives the event; TODO: we have to be more
        -- precise and treat cases where two monsters fight,
        -- but only one is visible; TODO: if 2 heroes hit a monster,
        -- still only one of them should kill it
        combatVerb = if killed && target /= APlayer then "kill" else "hit"
        swordMsg   = if sword == 0 then "" else
                       " with a (+" ++ show sword ++ ") sword" -- TODO: generate proper message
        combatMsg  = subjectVerbMObject state sm combatVerb tm swordMsg
    updateActor target $ \ m -> m { mhp = newHp }
    per <- currentPerception
    let perceived  = mloc sm `S.member` pvisible per
    messageAdd $
      if perceived
        then combatMsg
        else "You hear some noises."
    when killed $ do
      -- place the actor's possessions on the map
      dropItemsAt (mitems tm) (mloc tm)
      -- clean bodies up
      case target of
        APlayer    ->
          checkPartyDeath  -- kills heroes and checks game over
        AMonster n ->
          let upd l = L.take n l ++ L.drop (n + 1) l
          in  modify (updateLevel (updateMonsters upd))

-- | Resolves the result of an actor running into another.
-- This involves switching positions of the two actors. Always takes time.
actorRunActor :: Actor -> Monster -> Actor -> Monster -> Action ()
actorRunActor source sm target tm = do
  let sloc = mloc sm  -- source location
      tloc = mloc tm  -- target location
  updateActor source (\ m -> m { mloc = tloc })
  case target of
    APlayer -> do
      let i = heroNumber tm
      modify (updateAnyHero (\ m -> m { mloc = sloc }) i)
      case source of
        APlayer ->
          stopRunning
        AMonster _ -> do
          b <- selectHero i
          -- Extra prompt, in case many heroes disturbed in one turn.
          when b $ messageAddMore >> return ()
    AMonster _ ->
      updateActor target (\ m -> m { mloc = sloc })

-- | Generate a monster, possibly.
generateMonster :: Action ()
generateMonster =
  do
    state <- get
    nlvl  <- liftIO $ rndToIO $ addMonster state
    modify (updateLevel (const nlvl))

-- | Advance the move time for the given actor.
advanceTime :: Actor -> Action ()
advanceTime actor =
  do
    time <- gets stime
    updateActor actor (\ m -> m { mtime = time + mspeed m })

-- | Possibly regenerate HP for the given actor.
regenerate :: Actor -> Action ()
regenerate actor =
  do
    time <- gets stime
    -- TODO: remove hardcoded time interval, regeneration should be an attribute of the monster
    let upd m = m { mhp = min (mhpmax m) (mhp m + 1) }
    when (time `mod` 1500 == 0) $ do
      updateActor actor upd
    -- ugly, but we really want hero selection to be a purely UI distinction
      when (actor == APlayer) $
        modify (updateLevel (updateHeroes (IM.map upd)))
