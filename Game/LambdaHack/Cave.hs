-- | Generation of caves (not yet inhabited dungeon levels) from cave kinds.
module Game.LambdaHack.Cave
  ( Cave(..), SecretMapXY, ItemMapXY, TileMapXY, buildCave
  ) where

import Control.Monad
import qualified Data.Map as M
import qualified Data.List as L

import Game.LambdaHack.Geometry
import Game.LambdaHack.Area
import Game.LambdaHack.AreaRnd
import Game.LambdaHack.Item
import Game.LambdaHack.Random
import qualified Game.LambdaHack.Tile as Tile
import qualified Game.LambdaHack.Kind as Kind
import Game.LambdaHack.Content.CaveKind
import Game.LambdaHack.Content.TileKind
import Game.LambdaHack.Content.RoomKind
import Game.LambdaHack.Room
import qualified Game.LambdaHack.Feature as F

-- All maps used here are sparse. In case of the tile map, the default tile
-- is specified in the cave kind specification.

type SecretMapXY = M.Map (X, Y) SecretStrength

type ItemMapXY = M.Map (X, Y) Item

-- TODO: dmonsters :: [(X, Y), actorKind]  -- ^ fixed monsters on the level
data Cave = Cave
  { dkind     :: !(Kind.Id CaveKind)  -- ^ the kind of the cave
  , dsecret   :: SecretMapXY
  , ditem     :: ItemMapXY
  , dmap      :: TileMapXY
  , dmeta     :: String
  }
  deriving Show

{-
Rogue cave is generated by an algorithm inspired by the original Rogue,
as follows:

  * The available area is divided into a 3 by 3 grid
    where each of the 9 grid cells has approximately the same size.

  * In each of the 9 grid cells one room is placed at a random location.
    The minimum size of a room is 2 by 2 floor tiles. A room is surrounded
    by walls, and the walls still have to fit into the assigned grid cells.

  * Rooms that are on horizontally or vertically adjacent grid cells
    may be connected by a corridor. Corridors consist of 3 segments of straight
    lines (either "horizontal, vertical, horizontal" or "vertical, horizontal,
    vertical"). They end in openings in the walls of the room they connect.
    It is possible that one or two of the 3 segments have length 0, such that
    the resulting corridor is L-shaped or even a single straight line.

  * Corridors are generated randomly in such a way that at least every room
    on the grid is connected, and a few more might be. It is not sufficient
    to always connect all adjacent rooms.
-}
-- | Cave generated by an algorithm inspired by the original Rogue,
buildCave :: Kind.COps -> Int -> Kind.Id CaveKind -> Rnd Cave
buildCave Kind.COps{ cotile=cotile@Kind.Ops{opick}
                   , cocave=Kind.Ops{okind}
                   , coroom=Kind.Ops{okind=rokind, opick=ropick}} n ci = do
  let cfg@CaveKind{cxsize, cysize, corTile} = okind ci
  lgrid@(gx, gy) <- levelGrid cfg
  lminroom <- minRoomSize cfg
  let gs = grid lgrid (0, 0, cxsize - 1, cysize - 1)
  -- grid locations of "no-rooms"
  nrnr <- noRooms cfg lgrid
  nr   <- replicateM nrnr $ xyInArea (0, 0, gx - 1, gy - 1)
  rs0  <- mapM (\ (i, r) -> do
                   r' <- if i `elem` nr
                         then mkNoRoom (border cfg) r
                         else mkRoom (border cfg) lminroom r
                   return (i, r')) gs
  let rooms :: [Area]
      rooms = L.map snd rs0
  dlrooms <- mapM (\ r -> darkRoomChance cfg n
                          >>= \ c -> return (r, not c)) rooms
  let rs = M.fromList rs0
  connects <- connectGrid lgrid
  addedConnects <- replicateM (extraConnects cfg lgrid) (randomConnection lgrid)
  let allConnects = L.nub (addedConnects ++ connects)
  cs <- mapM (\ (p0, p1) -> do
                 let r0 = rs M.! p0
                     r1 = rs M.! p1
                 connectRooms r0 r1) allConnects
  fenceId <- Tile.wallId cotile
  let fenceBounds = (1, 1, cxsize - 2, cysize - 2)
      fence = buildFence fenceId fenceBounds
  doorOpenId   <- Tile.doorOpenId cotile
  doorClosedId <- Tile.doorClosedId cotile
  doorSecretId <- Tile.doorSecretId cotile
  lrooms <- foldM (\ m (r@(x0, _, x1, _), dl) ->
                    if x0 == x1
                    then return m
                    else do
                      roomId <- ropick (roomValid r)
                      let kr = rokind roomId
                      floorId <- (if dl || not (rfence kr)
                                  then Tile.floorRoomLitId
                                  else Tile.floorRoomDarkId) cotile
                      wallId <- Tile.wallId cotile
                      let room = digRoom kr floorId wallId doorOpenId r
                      return $ M.union room m
                  ) fence dlrooms
  pickedCorTile <- opick corTile
  let lcorridors = M.unions (L.map (digCorridors pickedCorTile) cs)
      unknownId = Tile.unknownId cotile
      lm = M.unionWith (mergeCorridor unknownId cotile)
             lcorridors lrooms
  -- Convert openings into doors, possibly.
  (dmap, secretMap) <-
    let f (l, le) ((x, y), t) =
          if t == doorOpenId || t == unknownId
          then do
            -- Openings have a certain chance to be doors;
            -- doors have a certain chance to be open; and
            -- closed doors have a certain chance to be secret
            rb <- doorChance cfg
            ro <- doorOpenChance cfg
            if t /= doorOpenId && not rb
              then return (M.insert (x, y) pickedCorTile l, le)
              else if ro
                   then return (M.insert (x, y) doorOpenId l, le)
                   else do
                     rsc <- doorSecretChance cfg
                     if t == doorOpenId || not rsc
                       then return (M.insert (x, y) doorClosedId l, le)
                       else do
                         rs1 <- rollDice (csecretStrength cfg)
                         return (M.insert (x, y) doorSecretId l,
                                 M.insert (x, y) (SecretStrength rs1) le)
          else return (l, le)
    in foldM f (lm, M.empty) (M.toList lm)
  let cave = Cave
        { dkind = ci
        , dsecret = secretMap
        , ditem = M.empty
        , dmap
        , dmeta = show allConnects
        }
  return cave

type Corridor = [(X, Y)]

-- | Create a random room according to given parameters.
mkRoom :: Int       -- ^ border columns
       -> (X, Y)    -- ^ minimum size
       -> Area      -- ^ this is the area, not the room itself
       -> Rnd Area  -- ^ upper-left and lower-right corner of the room
mkRoom bd (xm, ym) (x0, y0, x1, y1) = do
  (rx0, ry0) <- xyInArea (x0 + bd, y0 + bd, x1 - bd - xm + 1, y1 - bd - ym + 1)
  (rx1, ry1) <- xyInArea (rx0 + xm - 1, ry0 + ym - 1, x1 - bd, y1 - bd)
  return (rx0, ry0, rx1, ry1)

-- | Create a no-room, i.e., a single corridor field.
mkNoRoom :: Int      -- ^ border columns
         -> Area     -- ^ this is the area, not the room itself
         -> Rnd Area -- ^ upper-left and lower-right corner of the room
mkNoRoom bd (y0, x0, y1, x1) = do
  (ry, rx) <- xyInArea (y0 + bd, x0 + bd, y1 - bd, x1 - bd)
  return (ry, rx, ry, rx)

digCorridors :: Kind.Id TileKind -> Corridor -> TileMapXY
digCorridors tile (p1:p2:ps) =
  M.union corPos (digCorridors tile (p2:ps))
 where
  corXY  = fromTo p1 p2
  corPos = M.fromList $ L.zip corXY (repeat tile)
digCorridors _ _ = M.empty

mergeCorridor :: Kind.Id TileKind -> Kind.Ops TileKind -> Kind.Id TileKind
              -> Kind.Id TileKind -> Kind.Id TileKind
mergeCorridor _         cotile _ t | Tile.hasFeature cotile F.Walkable t = t
mergeCorridor unknownId _      _ _ = unknownId
