-- Copyright (c) 2008--2011 Andres Loeh, 2010--2014 Mikolaj Konarski
-- This file is a part of the computer game Allure of the Stars
-- and is released under the terms of the GNU Affero General Public License.
-- For license and copyright information, see the file LICENSE.
--
-- | Item and treasure definitions.
module Content.ItemKind ( cdefs ) where

import Data.List

import Content.ItemKindActor
import Content.ItemKindOrgan
import Content.ItemKindShrapnel
import Content.ItemKindTempAspect
import Game.LambdaHack.Common.Color
import Game.LambdaHack.Common.ContentDef
import Game.LambdaHack.Common.Dice
import Game.LambdaHack.Common.Effect
import Game.LambdaHack.Common.Flavour
import Game.LambdaHack.Common.Misc
import Game.LambdaHack.Content.ItemKind

cdefs :: ContentDef ItemKind
cdefs = ContentDef
  { getSymbol = isymbol
  , getName = iname
  , getFreq = ifreq
  , validateSingle = validateSingleItemKind
  , validateAll = validateAllItemKind
  , content = items ++ organs ++ shrapnels ++ actors ++ tempAspects
  }

items :: [ItemKind]
items =
  [canOfGlue, crankSpotlight, buckler, dart, dart200, gem1, gem2, gem3, gloveFencing, gloveGauntlet, gloveJousting, currency, gorget, harpoon, jumpingPole, contactLens, necklace1, necklace2, necklace3, necklace4, necklace5, necklace6, necklace7, net, needle, oilLamp, potion1, potion2, potion3, potion4, potion5, potion6, potion7, potion8, potion9, potion10, potion11, potion12, ring1, ring2, ring3, ring4, ring5, scroll1, scroll2, scroll3, scroll4, scroll5, scroll6, scroll7, scroll8, scroll9, shield, dagger, daggerDropBestWeapon, hammer, hammerParalyze, hammerSpark, sword, swordImpress, halberd, halberdPushActor, wand1, wand2, candle, armorLeather, armorMail, honingSteel, constructionHooter]

canOfGlue,    crankSpotlight, buckler, dart, dart200, gem1, gem2, gem3, gloveFencing, gloveGauntlet, gloveJousting, currency, gorget, harpoon, jumpingPole, contactLens, necklace1, necklace2, necklace3, necklace4, necklace5, necklace6, necklace7, net, needle, oilLamp, potion1, potion2, potion3, potion4, potion5, potion6, potion7, potion8, potion9, potion10, potion11, potion12, ring1, ring2, ring3, ring4, ring5, scroll1, scroll2, scroll3, scroll4, scroll5, scroll6, scroll7, scroll8, scroll9, shield, dagger, daggerDropBestWeapon, hammer, hammerParalyze, hammerSpark, sword, swordImpress, halberd, halberdPushActor, wand1, wand2, candle, armorLeather, armorMail, honingSteel, constructionHooter :: ItemKind

gem, necklace, potion, ring, scroll, wand :: ItemKind  -- generic templates

{- Item group symbols (from Angband, only as an informal convention for now):

! potion, flask, concoction, bottle, jar, vial, canister
? scroll, book, note, tablet, remote
, food
- magical wand, magical rod, transmitter, pistol, rifle
_ magical staff, scanner
= ring
" necklace
$ currency, gem
~ light, tool
/ polearm
| edged weapon
\ hafted weapon
} launcher
{ projectile
( clothes
[ torso armour
] misc. armour
) shield

-}

-- * Thrown weapons

dart = ItemKind
  { isymbol  = '{'
  , iname    = "steak knife"
  , ifreq    = [("useful", 100), ("any arrow", 100)]
  , iflavour = zipPlain [BrCyan]
  , icount   = 3 * d 3
  , irarity  = [(1, 20), (10, 10)]
  , iverbHit = "prick"
  , iweight  = 100
  , iaspects = [AddHurtRanged ((d 6 + dl 6) |*| 10)]
  , ieffects = [Hurt (3 * d 1)]
  , ifeature = [toVelocity 75]  -- no fins no special balance
  , idesc    = "Not particularly well balanced, but with a laser-sharpened titanium tip and blade."
  , ikit     = []
  }
dart200 = ItemKind
  { isymbol  = '{'
  , iname    = "billiard ball"
  , ifreq    = [("useful", 100), ("any arrow", 50)]  -- TODO: until arrows added
  , iflavour = zipPlain [BrWhite]
  , icount   = 3 * d 3
  , irarity  = [(4, 20), (10, 10)]
  , iverbHit = "strike"
  , iweight  = 300
  , iaspects = [AddHurtRanged ((d 6 + dl 6) |*| 10)]
  , ieffects = [Hurt (2 * d 1)]
  , ifeature = [toVelocity 150]
  , idesc    = "Ideal shape, size and weight for throwing."
  , ikit     = []
  }

-- * Exotic thrown weapons

canOfGlue = ItemKind
  { isymbol  = '{'
  , iname    = "can of glue"
  , ifreq    = [("useful", 100)]
  , iflavour = zipPlain [Magenta]
  , icount   = dl 4
  , irarity  = [(5, 5), (10, 20)]
  , iverbHit = "glue"
  , iweight  = 1500
  , iaspects = []
  , ieffects = [Paralyze (5 + d 10)]
  , ifeature = [toVelocity 50]  -- unwieldy
  , idesc    = "A can of liquid, fast-setting, construction glue."
  , ikit     = []
  }
harpoon = ItemKind
  { isymbol  = '{'
  , iname    = "harpoon"
  , ifreq    = [("useful", 100)]
  , iflavour = zipPlain [Brown]
  , icount   = dl 5
  , irarity  = [(5, 5), (10, 5)]
  , iverbHit = "hook"
  , iweight  = 4000
  , iaspects = [AddHurtRanged ((d 2 + 2 * dl 5) |*| 10)]
  , ieffects = [Hurt (4 * d 1), PullActor (ThrowMod 200 50)]
  , ifeature = []
  , idesc    = "A display piece harking back to the Earth's oceanic tourism hayday. The cruel, barbed head lodges in its victim so painfully that the weakest tug of the thin line sends the victim flying."
  , ikit     = []
  }
net = ItemKind
  { isymbol  = '{'
  , iname    = "net"
  , ifreq    = [("useful", 100)]
  , iflavour = zipPlain [White]
  , icount   = dl 3
  , irarity  = [(3, 5), (10, 4)]
  , iverbHit = "entangle"
  , iweight  = 1000
  , iaspects = []
  , ieffects = [ Paralyze (5 + d 5)
               , DropBestWeapon, DropEqp ')' False ]
  , ifeature = []
  , idesc    = "A large synthetic fibre net with weights affixed along the edges. Entangles weapon and appendages alike."
  , ikit     = []
  }
needle = ItemKind
  { isymbol  = '{'
  , iname    = "needle"
  , ifreq    = []
  , iflavour = zipPlain [BrBlue]
  , icount   = 9 * d 3
  , irarity  = []
  , iverbHit = "prick"
  , iweight  = 1
  , iaspects = [AddHurtRanged ((d 3 + dl 3) |*| 10)]
  , ieffects = [Hurt (1 * d 1)]
  , ifeature = [toVelocity 200, Fragile]
  , idesc    = "The hypodermic needle part of a micro-syringe. Without the payload, it flies far and penetrates deeply, causing intense pain on movement."
  , ikit     = []
  }

-- * Lights

candle = ItemKind
  { isymbol  = '~'
  , iname    = "candle"
  , ifreq    = [("useful", 100), ("light source", 100)]
  , iflavour = zipPlain [Brown]
  , icount   = 1
  , irarity  = [(1, 8), (3, 6)]
  , iverbHit = "scorch"
  , iweight  = 500
  , iaspects = [ AddLight 3
               , AddSight (-2) ]
  , ieffects = [Burn 3]
  , ifeature = [ toVelocity 50  -- easy to break when throwing
               , Fragile, EqpSlot EqpSlotAddLight "", Identified ]
  , idesc    = "A smoking, thick candle with an unsteady fire."
  , ikit     = []
  }
oilLamp = ItemKind
  { isymbol  = '~'
  , iname    = "oil lamp"
  , ifreq    = [("useful", 100), ("light source", 100)]
  , iflavour = zipPlain [BrYellow]
  , icount   = 1
  , irarity  = [(5, 5), (10, 5)]
  , iverbHit = "burn"
  , iweight  = 1000
  , iaspects = [AddLight 3, AddSight (-1)]
  , ieffects = [Burn 3, Paralyze 3, OnSmash (Explode "burning oil 3")]
  , ifeature = [ toVelocity 70  -- hard not to spill the oil while throwing
               , Fragile, EqpSlot EqpSlotAddLight "", Identified ]
  , idesc    = "A sizable glass lamp filled with plant oil feeding a wick."
  , ikit     = []
  }
crankSpotlight = ItemKind
  { isymbol  = '~'
  , iname    = "crank spotlight"
  , ifreq    = [("useful", 100), ("light source", 100)]
  , iflavour = zipPlain [BrWhite]
  , icount   = 1
  , irarity  = [(10, 3)]
  , iverbHit = "snag"
  , iweight  = 2400
  , iaspects = [AddLight 4, AddArmorRanged $ - d 3]  -- noise and busy hands
  , ieffects = []
  , ifeature = [ EqpSlot EqpSlotAddLight "", Identified ]
  , idesc    = "Powerful, wide-beam spotlight, powered by a hand-crank. Requires noisy two-handed recharging every few minutes."
  , ikit     = []
  }

-- * Treasure

gem = ItemKind
  { isymbol  = '*'
  , iname    = "gem"
  , ifreq    = [("treasure", 100)]  -- x3, but rare on shallow levels
  , iflavour = zipPlain $ delete BrYellow brightCol  -- natural, so not fancy
  , icount   = 1
  , irarity  = []
  , iverbHit = "tap"
  , iweight  = 50
  , iaspects = [AddLight 1, AddSpeed (-1)]  -- reflects strongly, distracts
  , ieffects = []
  , ifeature = [ Durable  -- prevent destruction by evil monsters
               , Precious ]
  , idesc    = "Precious, though useless. Worth around 100 gold grains."
  , ikit     = []
  }
gem1 = gem
  { irarity  = [(2, 0), (10, 10)]
  }
gem2 = gem
  { irarity  = [(5, 0), (10, 10)]
  }
gem3 = gem
  { irarity  = [(8, 0), (10, 10)]
  }
currency = ItemKind
  { isymbol  = '$'
  , iname    = "gold grain"
  , ifreq    = [("treasure", 100), ("currency", 1)]
  , iflavour = zipPlain [BrYellow]
  , icount   = 10 + d 20 + dl 20
  , irarity  = [(1, 10), (6, 25), (10, 10)]
  , iverbHit = "tap"
  , iweight  = 1
  , iaspects = []
  , ieffects = []
  , ifeature = [Durable, Identified, Precious]
  , idesc    = "Reliably valuable in every civilized place."
  , ikit     = []
  }

-- * Periodic jewelry

gorget = ItemKind
  { isymbol  = '"'
  , iname    = "gorget"
  , ifreq    = [("useful", 100)]
  , iflavour = zipFancy [BrCyan]
  , irarity  = [(4, 1), (10, 2)]
  , icount   = 1
  , iverbHit = "whip"
  , iweight  = 30
  , iaspects = [ Periodic
               , Timeout $ (d 3 + 3 - dl 3) |*| 10
               , AddArmorMelee 1
               , AddArmorRanged 1 ]
  , ieffects = [Recharging (RefillCalm 1)]
  , ifeature = [ Durable, Precious, EqpSlot EqpSlotPeriodic "", Identified
               , toVelocity 50 ]  -- not dense enough
  , idesc    = "Highly ornamental, cold, large, steel medallion on a chain. Unlikely to offer much protection as an armor piece, but the old, worn engraving reassures you."
  , ikit     = []
  }
necklace = ItemKind
  { isymbol  = '"'
  , iname    = "necklace"
  , ifreq    = [("useful", 100)]
  , iflavour = zipFancy stdCol ++ zipPlain brightCol
  , irarity  = [(10, 3)]
  , icount   = 1
  , iverbHit = "whip"
  , iweight  = 30
  , iaspects = [Periodic]
  , ieffects = []
  , ifeature = [ Durable, Precious, EqpSlot EqpSlotPeriodic ""
               , toVelocity 50 ]  -- not dense enough
  , idesc    = "Tingling, rattling chain of flat encrusted links. Eccentric millionaires are known to hide their highly personalized body augmentation packs in such large jewelry pieces."
  , ikit     = []
  }
necklace1 = necklace
  { iaspects = (Timeout $ (d 3 + 4 - dl 3) |*| 10) : iaspects necklace
  , ieffects = [ Recharging (RefillHP 1)
               , Burn 1 ]  -- only beneficial if activation is periodic
  }
necklace2 = necklace
  { irarity  = [(2, 0), (10, 1)]
  , iaspects = (Timeout $ (d 3 + 3 - dl 3) |*| 10) : iaspects necklace
  , ieffects = [ Recharging (Impress)
               , Recharging (Summon [("mobile animal", 1)] $ 1 + dl 2)
               , Recharging (Explode "waste") ]
  }
necklace3 = necklace
  { iaspects = (Timeout $ (d 3 + 3 - dl 3) |*| 10) : iaspects necklace
  , ieffects = [ Recharging (Paralyze $ 5 + d 5 + dl 5)
               , Recharging (RefillCalm 999)
               , Paralyze $ 15 + d 15  -- extra pain without periodic
               , OnSmash (Explode "explosion blast 2") ]
  , ifeature = Fragile : ifeature necklace  -- too powerful projection
  }
necklace4 = necklace
  { iaspects = (Timeout $ (d 4 + 4 - dl 4) |*| 2) : iaspects necklace
  , ieffects = [ Recharging (Teleport $ d 3 |*| 3)
               , RefillHP (-2)  -- price to pay if activation not periodic
               , OnSmash (Explode "explosion blast 2") ]
  , ifeature = Fragile : ifeature necklace  -- too powerful projection
  }
necklace5 = necklace
  { iaspects = (Timeout $ (d 3 + 4 - dl 3) |*| 10) : iaspects necklace
  , ieffects = [ Recharging (Teleport $ 12 + d 3 |*| 3)
               , RefillHP (-3)  -- price to pay if activation not periodic
               , OnSmash (Explode "explosion blast 2") ]
  , ifeature = Fragile : ifeature necklace  -- too powerful projection
  }
necklace6 = necklace
  { iaspects = (Timeout $ d 4 |*| 10) : iaspects necklace
  , ieffects = [ Recharging (PushActor (ThrowMod 100 50))
               , RefillHP (-1)  -- price to pay if activation not periodic
               , OnSmash (Explode "explosion blast 2") ]
  , ifeature = Fragile : ifeature necklace  -- quite powerful projection
  }
necklace7 = necklace  -- TODO: teach AI to wear only for fight
  { irarity  = [(4, 0), (10, 2)]
  , iaspects = (Timeout $ (d 3 + 3 - dl 3) |*| 2) : iaspects necklace
  , ieffects = [ Recharging (InsertMove 1)
               , Recharging (RefillHP (-1)) ]
  }

-- * Non-periodic jewelry

contactLens = ItemKind
  { isymbol  = '='
  , iname    = "contact lens"
  , ifreq    = [("useful", 100)]
  , iflavour = zipPlain [White]
  , icount   = 1
  , irarity  = [(5, 0), (10, 1)]
  , iverbHit = "rap"
  , iweight  = 50
  , iaspects = [AddSight $ d 2, AddHurtMelee $ d 2 |*| 3]
  , ieffects = []
  , ifeature = [Precious, Identified, Durable, EqpSlot EqpSlotAddSight ""]
  , idesc    = "Advanced design. Never needs to be taken off."
  , ikit     = []
  }
ring = ItemKind
  { isymbol  = '='
  , iname    = "ring"
  , ifreq    = [("useful", 100)]
  , iflavour = zipPlain stdCol ++ zipFancy darkCol
  , icount   = 1
  , irarity  = [(10, 3)]
  , iverbHit = "knock"
  , iweight  = 15
  , iaspects = []
  , ieffects = []
  , ifeature = [Precious, Identified]
  , idesc    = "A sturdy ring with a softly shining eye. If it contains a body booster unit, beware of the side-effects."
  , ikit     = []
  }
ring1 = ring
  { irarity  = [(2, 0), (10, 2)]
  , iaspects = [AddSpeed $ d 2, AddMaxHP $ dl 3 - 5 - d 3]
  , ifeature = ifeature ring ++ [Durable, EqpSlot EqpSlotAddSpeed ""]
  }
ring2 = ring
  { iaspects = [AddMaxHP $ 3 + dl 5, AddMaxCalm $ dl 6 - 15 - d 6]
  , ifeature = ifeature ring ++ [EqpSlot EqpSlotAddMaxHP ""]
  }
ring3 = ring
  { iaspects = [AddMaxCalm $ 10 + dl 10]
  , ifeature = ifeature ring ++ [EqpSlot EqpSlotAddMaxCalm ""]
  , idesc    = "Cold, solid to the touch, perfectly round, engraved with solemn, strangely comforting, worn out words."
  }
ring4 = ring  -- TODO: move to level-ups and to timed effects
  { irarity  = [(3, 12), (10, 12)]
  , iaspects = [AddHurtMelee $ (d 5 + dl 5) |*| 3, AddMaxHP $ dl 3 - 4 - d 2]
  , ifeature = ifeature ring ++ [Durable, EqpSlot EqpSlotAddHurtMelee ""]
  }
ring5 = ring  -- by the time it's found, probably no space in eqp
  { irarity  = [(5, 0)]
  , iaspects = [AddLight $ d 2]
  , ifeature = ifeature ring ++ [EqpSlot EqpSlotAddLight ""]
  , idesc    = "A sturdy ring with a large, shining stone."
  }

-- * Exploding consumables, often intended to be thrown

potion = ItemKind
  { isymbol  = '!'
  , iname    = "vial"
  , ifreq    = [("useful", 100)]
  , iflavour = zipPlain stdCol ++ zipFancy brightCol
  , icount   = 1
  , irarity  = [(1, 15), (10, 12)]
  , iverbHit = "splash"
  , iweight  = 200
  , iaspects = []
  , ieffects = []
  , ifeature = [ toVelocity 50  -- oily, bad grip
               , Applicable, Fragile ]
  , idesc    = "A flask of bubbly, slightly oily liquid of a suspect color."  -- purely natural; no nano, no alien tech  -- TODO: move distortion to a special flask item or trigger when some precious high tech item is destroyed (jewelry?)?
  , ikit     = []
  }
potion1 = potion
  { ieffects = [ NoEffect "of rose water", Impress
               , OnSmash (ApplyPerfume), OnSmash (Explode "fragrance") ]
  }
potion2 = potion
  { ifreq    = [("useful", 1)]  -- extremely rare
  , irarity  = [(1, 1)]
  , ieffects = [ NoEffect "of musky concoction", Impress, DropBestWeapon
               , OnSmash (Explode "pheromone")]
  }
potion3 = potion
  { ieffects = [RefillHP 5, OnSmash (Explode "healing mist")]
  }
potion4 = potion  -- TODO: a bit boring
  { irarity  = [(1, 7)]
  , ieffects = [RefillHP (-5), OnSmash (Explode "wounding mist")]
  }
potion5 = potion
  { ieffects = [ Explode "explosion blast 10", Impress
               , PushActor (ThrowMod 200 75)
               , OnSmash (Explode "explosion blast 10") ]
  }
potion6 = potion
  { irarity  = [(10, 2)]
  , ieffects = [ NoEffect "of distortion", Impress
               , OnSmash (Explode "distortion")]
  }
potion7 = potion
  { ieffects = [ NoEffect "of bait cocktail", CreateOrgan (5 + d 5) "drunk"
               , OnSmash (Summon [("mobile animal", 1)] $ 1 + dl 2)
               , OnSmash (Explode "waste") ]
  }
potion8 = potion
  { ieffects = [ OneOf [ Impress, DropBestWeapon, RefillHP 5, Burn 3
                       , CreateOrgan (7 + d 3) "drunk" ]
               , OnSmash (OneOf [ Explode "healing mist"
                                , Explode "wounding mist"
                                , Explode "fragrance"
                                , Explode "explosion blast 10"
                                , Explode "whiskey spray" ]) ]
  }
potion9 = potion
  { irarity  = [(3, 3), (10, 6)]
  , ieffects = [ OneOf [ Dominate, DropBestWeapon, RefillHP 20, Burn 9
                       , InsertMove 2, CreateOrgan (4 + d 3) "fast 20" ]
               , OnSmash (OneOf [ Explode "healing mist 2"
                                , Explode "healing mist 2"
                                , Explode "pheromone"
                                , Explode "distortion"
                                , Explode "explosion blast 20" ]) ]
  }
potion10 = potion  -- used only as initial equipmnt; count betray identity
  { ifreq    = [("useful", 100), ("potion of glue", 1)]
  , irarity  = [(1, 1)]
  , icount   = 1 + d 2
  , ieffects = [ NoEffect "of sticky foam", Paralyze (5 + d 5)
               , OnSmash (Explode "glue")]
  , ifeature = [Identified]
  }
potion11 = potion
  { irarity  = [(10, 5)]
  , ieffects = [RefillHP 10, OnSmash (Explode "healing mist 2")]
  }
potion12 = potion
  { ieffects = [ NoEffect "whiskey", CreateOrgan (20 + d 5) "drunk"
               , Burn 3, RefillHP 4, OnSmash (Explode "whiskey spray") ]
  }

-- * Non-exploding consumables, not specifically designed for throwing

constructionHooter = scroll
  { iname    = "construction hooter"
  , ifreq    = [("useful", 1), ("construction hooter", 1)]  -- extremely rare
  , iflavour = zipPlain [BrRed]
  , irarity  = [(1, 1)]
  , iaspects = []
  , ieffects = [Summon [("construction robot", 1)] $ 1 + dl 2]
  , ifeature = ifeature scroll ++ [Identified]
  , idesc    = "The single-use electronic overdrive hooter that construction robots use to warn about danger and call help in extreme emergency."
  , ikit     = []
  }
scroll = ItemKind
  { isymbol  = '?'
  , iname    = "tablet"
  , ifreq    = [("useful", 100), ("any scroll", 100)]
  , iflavour = zipFancy stdCol ++ zipPlain darkCol  -- arcane and old
  , icount   = 1
  , irarity  = [(1, 15), (10, 12)]
  , iverbHit = "thump"
  , iweight  = 700
  , iaspects = []
  , ieffects = []
  , ifeature = [ toVelocity 25  -- bad grip
               , Applicable ]
  , idesc    = "A standard issue spaceship crew tablet displaying a fixed infographic and a big button. Some of these still contain a one-time password authorizing a particular spaceship's infrastructure transition. It is unknown how the infrastructure might respond after so many years."
  , ikit     = []
  }
scroll1 = scroll
  { irarity  = [(1, 2), (10, 3)]
  , ieffects = [CallFriend 1]
  }
scroll2 = scroll
  { irarity  = [(1, 7), (10, 5)]
  , ieffects = [NoEffect "of fireworks", Explode "firecracker 7"]
  }
scroll3 = scroll
  { irarity  = [(1, 5), (10, 3)]
  , ieffects = [Ascend 1]
  }
scroll4 = scroll
  { ieffects = [ OneOf [ Teleport $ d 3 |*| 3, RefillCalm 10, RefillCalm (-10)
                       , InsertMove 4, Paralyze 10, Identify CGround ] ]
  }
scroll5 = scroll
  { irarity  = [(3, 3), (10, 6)]
  , ieffects = [ OneOf [ Summon standardSummon $ d 2
                       , CallFriend 1, Ascend (-1), Ascend 1
                       , RefillCalm 30, RefillCalm (-30), CreateItem $ d 2
                       , PolyItem CGround ] ]
               -- TODO: ask player: Escape 1
  }
scroll6 = scroll
  { ieffects = [Teleport $ d 3 |*| 3]
  }
scroll7 = scroll
  { irarity  = [(10, 3)]
  , ieffects = [InsertMove $ d 2 + dl 2]
  }
scroll8 = scroll
  { irarity  = [(3, 8), (10, 4)]
  , ieffects = [Identify CGround]  -- TODO: ask player: AskPlayer cstore eff?
  }
scroll9 = scroll
  { irarity  = [(10, 10)]
  , ieffects = [PolyItem CGround]
  }

standardSummon :: Freqs
standardSummon = [ ("alien", 20)
                 , ("mobile animal", 50)
                 , ("mobile robot", 30) ]

-- * Armor

armorLeather = ItemKind
  { isymbol  = '['
  , iname    = "spacesuit breastplate"
  , ifreq    = [("useful", 100)]
  , iflavour = zipPlain [Brown]
  , icount   = 1
  , irarity  = [(3, 6), (10, 3)]
  , iverbHit = "thud"
  , iweight  = 7000
  , iaspects = [ AddHurtMelee (-3)
               , AddArmorMelee $ (1 + dl 3) |*| 5
               , AddArmorRanged $ (1 + dl 3) |*| 5 ]
  , ieffects = []
  , ifeature = [ toVelocity 30  -- unwieldy to throw and blunt
               , Durable, EqpSlot EqpSlotAddArmorMelee "", Identified ]
  , idesc    = "A hard-shell torso segment cut from a disposed off spacesuit."
  , ikit     = []
  }
armorMail = armorLeather
  { iname    = "bulletproof vest"
  , iflavour = zipPlain [Cyan]
  , irarity  = [(6, 6), (10, 6)]
  , iweight  = 12000
  , iaspects = [ AddHurtMelee (-3)
               , AddArmorMelee $ (2 + dl 4) |*| 5
               , AddArmorRanged $ (2 + dl 4) |*| 5 ]
  , idesc    = "A civilian bulletproof vest. Discourages foes from attacking your torso, making it harder for them to land a blow."
  }
gloveFencing = ItemKind
  { isymbol  = ']'
  , iname    = "construction glove"
  , ifreq    = [("useful", 100)]
  , iflavour = zipPlain [BrYellow]
  , icount   = 1
  , irarity  = [(5, 8), (10, 8)]
  , iverbHit = "flap"
  , iweight  = 100
  , iaspects = [ AddHurtMelee $ (d 2 + dl 10) * 3
               , AddArmorRanged $ d 2 |*| 5 ]
  , ieffects = []
  , ifeature = [ toVelocity 30  -- flaps and flutters
               , Durable, EqpSlot EqpSlotAddArmorRanged "", Identified ]
  , idesc    = "A flexible construction glove from rough leather ensuring a good grip. Also, quite effective in deflecting or even catching slow projectiles."
  , ikit     = []
  }
gloveGauntlet = gloveFencing
  { iname    = "spacesuit glove"
  , irarity  = [(6, 12)]
  , iflavour = zipPlain [BrCyan]
  , iweight  = 300
  , iaspects = [ AddArmorMelee $ (1 + dl 2) |*| 5
               , AddArmorRanged $ (1 + dl 2) |*| 5 ]
  , idesc    = "A piece of a hull maintenance spacesuit, padded and reinforced with carbon fibre."
  }
gloveJousting = gloveFencing
  { iname    = "welding handgear"
  , irarity  = [(6, 6)]
  , iflavour = zipFancy [BrRed]
  , iweight  = 500
  , iaspects = [ AddHurtMelee $ (dl 4 - 6) |*| 3
               , AddArmorMelee $ (2 + dl 2) |*| 5
               , AddArmorRanged $ (2 + dl 2) |*| 5 ]
  , idesc    = "Rigid, bulky handgear embedding a welding equipment, complete with an affixed small shield and a darkened visor. Awe-inspiring."
  }
-- Shield doesn't protect against ranged attacks to prevent
-- micromanagement: walking with shield, melee without.
buckler = ItemKind
  { isymbol  = ')'
  , iname    = "buckler"
  , ifreq    = [("useful", 100)]
  , iflavour = zipPlain [Blue]
  , icount   = 1
  , irarity  = [(4, 6)]
  , iverbHit = "bash"
  , iweight  = 2000
  , iaspects = [ AddArmorMelee 40
               , AddHurtMelee (-30)
               , Timeout $ (d 3 + 3 - dl 3) |*| 2 ]
  , ieffects = [Recharging (PushActor (ThrowMod 200 50))]
  , ifeature = [ toVelocity 30  -- unwieldy to throw and blunt
               , Durable, EqpSlot EqpSlotAddArmorMelee "", Identified ]
  , idesc    = "Heavy and unwieldy arm protection made from an outer airlock panel. Absorbs a percentage of melee damage, both dealt and sustained. Too small to intercept projectiles with."
  , ikit     = []
  }
shield = buckler
  { iname    = "shield"
  , irarity  = [(7, 5)]
  , iflavour = zipPlain [Green]
  , iweight  = 3000
  , iaspects = [ AddArmorMelee 80
               , AddHurtMelee (-70)
               , Timeout $ (d 3 + 6 - dl 3) |*| 2 ]
  , ieffects = [Recharging (PushActor (ThrowMod 400 50))]
  , ifeature = [ toVelocity 20  -- unwieldy to throw and blunt
               , Durable, EqpSlot EqpSlotAddArmorMelee "", Identified ]
  , idesc    = "Large and unwieldy rectangle made of anti-meteorite ceramic sheet. Absorbs a percentage of melee damage, both dealt and sustained. Too heavy to intercept projectiles with."
  }

-- * Weapons

dagger = ItemKind
  { isymbol  = '|'
  , iname    = "cleaver"
  , ifreq    = [("useful", 100), ("starting weapon", 100)]
  , iflavour = zipPlain [BrCyan]
  , icount   = 1
  , irarity  = [(1, 12), (10, 4)]
  , iverbHit = "stab"
  , iweight  = 1000
  , iaspects = [AddHurtMelee $ (d 3 + dl 3) |*| 3, AddArmorMelee $ d 2 |*| 5]
  , ieffects = [Hurt (6 * d 1)]
  , ifeature = [ toVelocity 40  -- ensuring it hits with the tip costs speed
               , Durable, EqpSlot EqpSlotWeapon "", Identified ]
  , idesc    = "A heavy professional kitchen blade. Will do fine cutting any kind of meat and bone, as well as parrying blows. Does not penetrate deeply, but is hard to block. Especially useful in conjunction with a larger weapon."
  , ikit     = []
  }
daggerDropBestWeapon = dagger
  { ifreq    = [("useful", 100)]
  , irarity  = [(1, 1), (10, 2)]
  -- The timeout has to be small, so that the player can count on the effect
  -- occuring consistently in any longer fight. Otherwise, the effect will be
  -- absent in some important fights, leading to the feeling of bad luck,
  -- but will manifest sometimes in fights where it doesn't matter,
  -- leading to the feeling of wasted power.
  -- If the effect is very powerful and so the timeout has to be significant,
  -- let's make it really large, for the effect to occur only once in a fight:
  -- as soon as the item is equipped, or just on the first strike.
  , iaspects = iaspects dagger ++ [Timeout $ (d 3 + 4 - dl 3) |*| 2]
  , ieffects = ieffects dagger ++ [Recharging DropBestWeapon]
  , idesc    = "A knife with a forked blade that a focused fencer can use to catch and twist an opponent's weapon occasionally."
  }
hammer = ItemKind
  { isymbol  = '\\'
  , iname    = "demolition hammer"
  , ifreq    = [("useful", 100), ("starting weapon", 100)]
  , iflavour = zipPlain [BrMagenta]
  , icount   = 1
  , irarity  = [(4, 12), (10, 2)]
  , iverbHit = "club"
  , iweight  = 1500
  , iaspects = [AddHurtMelee $ (d 2 + dl 2) |*| 3]
  , ieffects = [Hurt (8 * d 1)]
  , ifeature = [ toVelocity 20  -- ensuring it hits with the sharp tip costs
               , Durable, EqpSlot EqpSlotWeapon "", Identified ]
  , idesc    = "A hammer on a long handle used for construction work. It may not cause grave wounds, but neither does it ricochet or glance off armor. Great sidearm for opportunistic blows against armored foes."
  , ikit     = []
  }
hammerParalyze = hammer
  { ifreq    = [("useful", 100)]
  , irarity  = [(4, 1), (10, 2)]
  , iaspects = iaspects hammer ++ [Timeout $ (d 2 + 3 - dl 2) |*| 2]
  , ieffects = ieffects hammer ++ [Recharging $ Paralyze 5]
  }
hammerSpark = hammer
  { iname    = "smithhammer"
  , ifreq    = [("useful", 100)]
  , irarity  = [(4, 1), (10, 2)]
  , iaspects = iaspects hammer ++ [Timeout $ (d 4 + 4 - dl 4) |*| 2]
  , ieffects = ieffects hammer ++ [Recharging $ Explode "spark"]
  }
sword = ItemKind
  { isymbol  = '/'
  , iname    = "sharpened pipe"
  , ifreq    = [("useful", 100), ("starting weapon", 100)]
  , iflavour = zipPlain [BrBlue]
  , icount   = 1
  , irarity  = [(3, 1), (6, 16), (10, 8)]
  , iverbHit = "slash"
  , iweight  = 2000
  , iaspects = []
  , ieffects = [Hurt (10 * d 1)]
  , ifeature = [ toVelocity 20  -- ensuring it hits with the tip costs speed
               , Durable, EqpSlot EqpSlotWeapon "", Identified ]
  , idesc    = "A makeshift weapon of simple design, but great potential. Hard to master, though."
  , ikit     = []
  }
swordImpress = sword
  { isymbol  = '|'
  , iname    = "an antique sword"
  , ifreq    = [("useful", 100)]
  , irarity  = [(3, 1), (10, 2)]
  , iaspects = iaspects sword ++ [Timeout $ (d 4 + 5 - dl 4) |*| 2]
  , ieffects = ieffects sword ++ [Recharging Impress]
  , idesc    = "An old, dull, but well-balance blade, lending itself to impressive shows of fencing skill."
  }
halberd = ItemKind
  { isymbol  = '/'
  , iname    = "pole cleaver"
  , ifreq    = [("useful", 100), ("starting weapon", 1)]
  , iflavour = zipPlain [BrYellow]
  , icount   = 1
  , irarity  = [(7, 1), (10, 10)]
  , iverbHit = "impale"
  , iweight  = 3000
  , iaspects = [AddArmorMelee $ (1 + dl 3) |*| 5]
  , ieffects = [Hurt (12 * d 1)]
  , ifeature = [ toVelocity 20  -- not balanced
               , Durable, EqpSlot EqpSlotWeapon "", Identified ]
  , idesc    = "An improvised but deadly weapon made of a long, sharp kitchen knife glued and bound to a long pole."
  , ikit     = []
  }
halberdPushActor = halberd
  { iname    = "halberd"
  , ifreq    = [("useful", 100)]
  , irarity  = [(7, 1), (10, 2)]
  , iaspects = iaspects halberd ++ [Timeout $ (d 5 + 5 - dl 5) |*| 2]
  , ieffects = ieffects halberd ++ [Recharging (PushActor (ThrowMod 400 25))]
  , idesc    = "A perfect replica made for a reenactor troupe, missing only some sharpening. Versatile, with great reach and leverage. Foes are held at a distance."
  }

-- * Wands

wand = ItemKind
  { isymbol  = '-'
  , iname    = "injector"
  , ifreq    = [("useful", 100)]
  , iflavour = zipFancy brightCol
  , icount   = 1
  , irarity  = []  -- TODO: add charges, etc.
  , iverbHit = "club"
  , iweight  = 300
  , iaspects = [AddLight 1, AddSpeed (-1)]  -- pulsing with power, distracts
  , ieffects = []
  , ifeature = [ toVelocity 125  -- sufficiently advanced tech
               , Applicable, Durable ]
  , idesc    = "Buzzing with dazzling light that shines even through appendages that handle it."
  , ikit     = []
  }
wand1 = wand
  { ieffects = []  -- TODO: emit a cone of sound shrapnel that makes enemy cover his ears and so drop '{'
  }
wand2 = wand
  { ieffects = []
  }

-- * Assorted tools

jumpingPole = ItemKind
  { isymbol  = '~'
  , iname    = "jumping pole"
  , ifreq    = [("useful", 100)]
  , iflavour = zipPlain [White]
  , icount   = 1
  , irarity  = [(1, 2), (10, 1)]
  , iverbHit = "prod"
  , iweight  = 10000
  , iaspects = []
  , ieffects = [CreateOrgan 1 "fast 20"]
  , ifeature = [Durable, Applicable, Identified]
  , idesc    = "Makes you vulnerable at take-off, but then you are free like a bird."
  , ikit     = []
  }
honingSteel = ItemKind
  { isymbol  = '~'
  , iname    = "honing steel"
  , ifreq    = [("useful", 100)]
  , iflavour = zipPlain [Blue]
  , icount   = 1
  , irarity  = [(10, 10)]
  , iverbHit = "smack"
  , iweight  = 400
  , iaspects = [AddHurtMelee $ d 10 |*| 3]
  , ieffects = []
  , ifeature = [EqpSlot EqpSlotAddHurtMelee "", Identified]
  , idesc    = "Originally used for realigning the bent or buckled edges of kitchen knives in the local bars. Now it saves lives by letting you fix your weapons between or even during fights, without the need to set up camp, fish out tools and assemble a proper sharpening workshop."
  , ikit     = []
  }
