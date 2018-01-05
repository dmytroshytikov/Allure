-- Copyright (c) 2008--2011 Andres Loeh
-- Copyright (c) 2010--2018 Mikolaj Konarski and others (see git history)
-- This file is a part of the computer game Allure of the Stars
-- and is released under the terms of the GNU Affero General Public License.
-- For license and copyright information, see the file LICENSE.
--
-- | Definitions of items embedded in map tiles.
module Content.ItemKindEmbed
  ( embeds
  ) where

import Prelude ()

import Game.LambdaHack.Common.Prelude

import Game.LambdaHack.Common.Color
import Game.LambdaHack.Common.Dice
import Game.LambdaHack.Common.Flavour
import Game.LambdaHack.Common.Misc
import Game.LambdaHack.Content.ItemKind

embeds :: [ItemKind]
embeds =
  [stairsUp, stairsDown, escape, terrainCache, terrainCacheTrap, signboardExit, signboardMap, fireSmall, fireBig, frost, rubble, staircaseTrapUp, staircaseTrapDown, doorwayTrap, obscenePictograms, subtleFresco, scratchOnWall, pulpit]
      -- Allure-specific
      ++ [liftUp, liftDown, jewelryDisplay, liftTrap, liftTrap2, ruinedFirstAidKit, wall3dBillboard]
stairsUp,    stairsDown, escape, terrainCache, terrainCacheTrap, signboardExit, signboardMap, fireSmall, fireBig, frost, rubble, staircaseTrapUp, staircaseTrapDown, doorwayTrap, obscenePictograms, subtleFresco, scratchOnWall, pulpit :: ItemKind
-- Allure-specific
liftUp,           liftDown, jewelryDisplay, liftTrap, liftTrap2, ruinedFirstAidKit, wall3dBillboard :: ItemKind

stairsUp = ItemKind
  { isymbol  = '<'
  , iname    = "staircase up"
  , ifreq    = [("staircase up", 1)]
  , iflavour = zipPlain [BrWhite]
  , icount   = 1
  , irarity  = [(1, 1)]
  , iverbHit = "crash"  -- the verb is only used when the item hits,
                        -- not when it's applied otherwise, e.g., from tile
  , iweight  = 100000
  , idamage  = toDmg 0
  , iaspects = []
  , ieffects = [Ascend True]
  , ifeature = [Identified, Durable]
  , idesc    = "Stairs that rise towards the spaceship core."
  , ikit     = []
  }
stairsDown = stairsUp
  { isymbol  = '>'
  , iname    = "staircase down"
  , ifreq    = [("staircase down", 1)]
  , ieffects = [Ascend False]
  , idesc    = "Stairs that decend towards the outer ring."
  }
escape = stairsUp
  { isymbol  = 'E'
  , iname    = "escape"
  , ifreq    = [("escape", 1)]
  , iflavour = zipPlain [BrYellow]
  , ieffects = [Escape]
  , idesc    = ""  -- generic: moon outdoors, in spaceship, everywhere
  }
terrainCache = stairsUp
  { isymbol  = 'O'
  , iname    = "intact deposit box"
  , ifreq    = [("treasure cache", 1)]
  , iflavour = zipPlain [BrBlue]
  , ieffects = [CreateItem CGround "useful" TimerNone]
  , idesc    = ""
  }
terrainCacheTrap = ItemKind
  { isymbol  = '^'
  , iname    = "anti-burglary protection"
  , ifreq    = [("treasure cache trap", 1)]
  , iflavour = zipPlain [Red]
  , icount   = 1
  , irarity  = [(1, 1)]
  , iverbHit = "taint"
  , iweight  = 1000
  , idamage  = toDmg 0
  , iaspects = []
  , ieffects = [OneOf [ toOrganNone "poisoned", Explode "glue"
                      , ELabel "", ELabel "", ELabel ""
                      , ELabel "", ELabel "", ELabel ""
                      , ELabel "", ELabel "" ]]
  , ifeature = [Identified]  -- not Durable, springs at most once
  , idesc    = ""
  , ikit     = []
  }
signboardExit = ItemKind
  { isymbol  = 'O'
  , iname    = "signboard with exits"
  , ifreq    = [("signboard", 80)]
  , iflavour = zipPlain [BrMagenta]
  , icount   = 1
  , irarity  = [(1, 1)]
  , iverbHit = "whack"
  , iweight  = 10000
  , idamage  = toDmg 0
  , iaspects = []
  , ieffects = [DetectExit 100]  -- low tech, hence fully operational
  , ifeature = [Identified, Durable]
  , idesc    = "Mandatory emergency exit information in low-tech form."
  , ikit     = []
  }
signboardMap = signboardExit
  { iname    = "signboard with a map"
  , ifreq    = [("signboard", 20)]
  , ieffects = [Detect 10]  -- low tech, hence fully operational
  , idesc    = "Detailed schematics for the maintenance crew."
  }
fireSmall = ItemKind
  { isymbol  = '%'
  , iname    = "small fire"
  , ifreq    = [("small fire", 1)]
  , iflavour = zipPlain [BrRed]
  , icount   = 1
  , irarity  = [(1, 1)]
  , iverbHit = "burn"
  , iweight  = 10000
  , idamage  = toDmg 0
  , iaspects = []
  , ieffects = [Burn 1, Explode "single spark"]
  , ifeature = [Identified, Durable]
  , idesc    = "A few small logs, burning brightly."
  , ikit     = []
  }
fireBig = fireSmall
  { isymbol  = 'O'
  , iname    = "big fire"
  , ifreq    = [("big fire", 1)]
  , ieffects = [ Burn 2, Explode "spark"
               , CreateItem CInv "wooden torch" TimerNone ]
  , ifeature = [Identified, Durable]
  , idesc    = "Glowing with light and warmth."
  , ikit     = []
  }
frost = ItemKind
  { isymbol  = '^'
  , iname    = "frost"
  , ifreq    = [("frost", 1)]
  , iflavour = zipPlain [BrBlue]
  , icount   = 1
  , irarity  = [(1, 1)]
  , iverbHit = "burn"
  , iweight  = 10000
  , idamage  = toDmg 0
  , iaspects = []
  , ieffects = [ Burn 1  -- sensory ambiguity between hot and cold
               , RefillCalm 20  -- cold reason
               , PushActor (ThrowMod 200 50) ]  -- slippery ice
  , ifeature = [Identified, Durable]
  , idesc    = "Intricate patterns of shining ice."
  , ikit     = []
  }
rubble = ItemKind
  { isymbol  = '&'
  , iname    = "rubble"
  , ifreq    = [("rubble", 1)]
  , iflavour = zipPlain [BrYellow]
  , icount   = 1
  , irarity  = [(1, 1)]
  , iverbHit = "bury"
  , iweight  = 100000
  , idamage  = toDmg 0
  , iaspects = []
  , ieffects = [OneOf [ Explode "glass piece", Explode "waste"
                      , Summon "animal" 1, toOrganNone "poisoned"
                      , CreateItem CGround "useful" TimerNone
                      , ELabel "", ELabel "", ELabel ""
                      , ELabel "", ELabel "", ELabel "" ]]
  , ifeature = [Identified, Durable]
  , idesc    = "Broken chunks of foam concrete and glass."
  , ikit     = []
  }
staircaseTrapUp = ItemKind
  { isymbol  = '^'
  , iname    = "staircase trap"
  , ifreq    = [("staircase trap up", 1)]
  , iflavour = zipPlain [Red]
  , icount   = 1
  , irarity  = [(1, 1)]
  , iverbHit = "buffet"
  , iweight  = 10000
  , idamage  = toDmg 0
  , iaspects = []
  , ieffects = [ Temporary "be caught in an updraft"
               , Teleport $ 3 + 1 `dL` 10 ]
  , ifeature = [Identified]  -- not Durable, springs at most once
  , idesc    = "A hidden spring, to help the unwary soar."
  , ikit     = []
  }
-- Needs to be separate from staircaseTrapUp, to make sure the item is
-- registered after up staircase (not only after down staircase)
-- so that effects are invoked in the proper order and, e.g., teleport works.
staircaseTrapDown = staircaseTrapUp
  { ifreq    = [("staircase trap down", 1)]
  , iverbHit = "open up under"
  , ieffects = [ Temporary "tumble down the stairwell"
               , toOrganActorTurn "drunk" (20 + 1 `d` 5) ]
  , idesc    = "A treacherous slab, to teach those who are too proud."
  }
doorwayTrap = ItemKind
  { isymbol  = '^'
  , iname    = "doorway trap"
  , ifreq    = [("doorway trap", 1)]
  , iflavour = zipPlain [Red]
  , icount   = 1
  , irarity  = [(1, 1)]
  , iverbHit = "cripple"
  , iweight  = 10000
  , idamage  = toDmg 0
  , iaspects = []
  , ieffects = [OneOf [ toOrganActorTurn "blind" $ (2 + 1 `dL` 3) * 10
                      , toOrganActorTurn "slowed" $ (2 + 1 `dL` 3) * 10
                      , toOrganActorTurn "weakened" $ (2 + 1 `dL` 3) * 10 ]]
  , ifeature = [Identified]  -- not Durable, springs at most once
  , idesc    = "Just turn the handle..."
  , ikit     = []
  }
obscenePictograms = ItemKind
  { isymbol  = '*'
  , iname    = "repulsing graffiti"
  , ifreq    = [("obscene pictograms", 1)]
  , iflavour = zipPlain [BrMagenta]
  , icount   = 1
  , irarity  = [(1, 1)]
  , iverbHit = "infuriate"
  , iweight  = 1000
  , idamage  = toDmg 0
  , iaspects = [Timeout 7]
  , ieffects = [ Temporary "enter unexplainable rage at a glimpse of the inscrutable graffiti"
               , RefillCalm (-20)
               , Recharging $ OneOf
                   [ toOrganActorTurn "strengthened" (3 + 1 `d` 3)
                   , CreateItem CInv "sandstone rock" TimerNone ] ]
  , ifeature = [Identified, Durable]
  , idesc    = ""
  , ikit     = []
  }
subtleFresco = ItemKind
  { isymbol  = '*'
  , iname    = "subtle mural"
  , ifreq    = [("subtle fresco", 1)]
  , iflavour = zipPlain [BrGreen]
  , icount   = 1
  , irarity  = [(1, 1)]
  , iverbHit = "sooth"
  , iweight  = 1000
  , idamage  = toDmg 0
  , iaspects = [Timeout 7]
  , ieffects = [ Temporary "be entranced by the subtle mural"
               , RefillCalm 2
               , Recharging $ toOrganActorTurn "far-sighted" (3 + 1 `d` 3)
               , Recharging $ toOrganActorTurn "keen-smelling" (3 + 1 `d` 3) ]
  , ifeature = [Identified, Durable]
  , idesc    = "Expensive yet tasteful."
  , ikit     = []
  }
scratchOnWall = ItemKind
  { isymbol  = '*'
  , iname    = "scratch on wall"
  , ifreq    = [("scratch on wall", 1)]
  , iflavour = zipPlain [BrBlack]
  , icount   = 1
  , irarity  = [(1, 1)]
  , iverbHit = "scratch"
  , iweight  = 1000
  , idamage  = toDmg 0
  , iaspects = []
  , ieffects = [Temporary "start making sense of the scratches", DetectHidden 3]
  , ifeature = [Identified, Durable]
  , idesc    = "A seemingly random series of scratches, carved deep into the wall."
  , ikit     = []
  }
pulpit = ItemKind
  { isymbol  = '%'
  , iname    = "VR harness"
  , ifreq    = [("pulpit", 1)]
  , iflavour = zipFancy [BrYellow]
  , icount   = 1
  , irarity  = [(1, 1)]
  , iverbHit = "immerse"
  , iweight  = 10000
  , idamage  = toDmg 0
  , iaspects = []
  , ieffects = [ CreateItem CGround "any scroll" TimerNone
               , Detect 20
               , Paralyze $ (2 + 1 `dL` 3) * 10
               , toOrganActorTurn "drunk" (20 + 1 `d` 5) ]
  , ifeature = [Identified]  -- not Durable, springs at most once
  , idesc    = ""
  , ikit     = []
  }

-- * Allure-specific

liftUp = stairsUp
  { iname    = "lift up"
  , ifreq    = [("lift up", 1)]
  , idesc    = ""
  }
liftDown = stairsDown
  { iname    = "lift down"
  , ifreq    = [("lift down", 1)]
  , idesc    = ""
  }
jewelryDisplay = terrainCache
  { iname    = "jewelry display"
  , ifreq    = [("jewelry display", 1)]
  , ieffects = [CreateItem CGround "any jewelry" TimerNone]
  , idesc    = ""
  }
liftTrap = staircaseTrapUp
  { iname    = "elevator trap"  -- hat tip to US heroes
  , ifreq    = [("lift trap", 100)]
  , iverbHit = "squeeze"
  , ieffects = [ Temporary "be crushed by the sliding doors"
               , DropBestWeapon, Paralyze 10 ]
  , idesc    = ""
  }
liftTrap2 = liftTrap
  { ifreq    = [("lift trap", 50)]
  , iverbHit = "choke"
  , ieffects = [ Temporary "inhale the gas lingering inside the cab"
               , toOrganActorTurn "slowed" $ (2 + 1 `dL` 3) * 10 ]
  , idesc    = ""
  }
ruinedFirstAidKit = ItemKind
  { isymbol  = '*'
  , iname    = "ruined first aid kit"
  , ifreq    = [("ruined first aid kit", 1)]
  , iflavour = zipPlain [BrGreen]
  , icount   = 1
  , irarity  = [(1, 1)]
  , iverbHit = "prick"
  , iweight  = 1000
  , idamage  = toDmg 0
  , iaspects = []
  , ieffects = [ Temporary "inhale the last whiff of chemicals from ruined first aid kit"
               , OneOf [ toOrganNone "poison resistant"
                       , toOrganNone "slow resistant"
                       , toOrganActorTurn "drunk" (20 + 1 `d` 5) ]
               , CreateItem CInv "needle" TimerNone ]
  , ifeature = [Identified]  -- not Durable, springs at most once
  , idesc    = ""  -- regulations require
  , ikit     = []
  }
wall3dBillboard = ItemKind
  { isymbol  = '*'
  , iname    = "3D billboard"
  , ifreq    = [("3D billboard", 1)]
  , iflavour = zipPlain [BrGreen]
  , icount   = 1
  , irarity  = [(1, 1)]
  , iverbHit = "push"
  , iweight  = 1000
  , idamage  = toDmg 0
  , iaspects = []
  , ieffects = [Temporary "make out excited moves of bleached shapes"]
  , ifeature = [Identified, Durable]
  , idesc    = ""
  , ikit     = []
  }
