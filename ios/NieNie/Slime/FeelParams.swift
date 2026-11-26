import UIKit

/// Feel parameters, same names and meanings as the web prototype's `PRESETS`
/// (prototype/web/index.html) and 參數表. Haptic and sound numbers only exist here.
struct FeelParams: Equatable, Codable {
    var alpha: Double      // shape-matching stiffness per substep (0...1)
    var damp: Double       // Verlet velocity damping per substep
    var yield: Double      // deformation (in radii) before the body starts remembering a shape
    var creep: Double      // how fast the remembered shape follows the current one (per second)
    var recover: Double    // how fast the remembered shape relaxes back (per second)
    var grabR: Double      // grab radius, in radii
    var maxPull: Double    // soft stretch limit, in radii
    var lag: Double        // sticky lag behind the finger (s)
    var wGlobal: Double    // weight of the whole-body cluster (bigger = more like one lump)
    var cSpace: Double     // cluster spacing, in radii (smaller = softer)
    var cRad: Double       // cluster radius, in radii
    var upright: Double    // how fast it turns back head-up (per substep)
    var anchor: Double     // how much harder it stays put while grabbed
    var areaGain: Double   // area pressure: how much the sides bulge when squashed
    var gripRot: Double    // extra upright strength while grabbed
    var life: Double       // idle motion amount (0 = still)
    var drift: Double      // tentacle sway amplitude, in radii
    var wriggle: Double    // whole-body travelling-wave amplitude, in radii
    var wander: Double     // idle roaming speed, radii per second
    var floppy: Double     // how much softer tentacle tips are (0...0.9)
    var seed: Double       // shape seed (1...30); changing it rebuilds the body

    // v2.3 press (接觸點先凹): the grabbed patch spreads away from the finger. The side view
    // cannot show depth, so "pressing in" is drawn as squashing flat. Visible spread is about
    // half the number (the finger constraint and shape matching meet in the middle).
    var pressBase: Double = 0.12      // spread on contact, in radii
    var pressHold: Double = 0.18      // extra spread while held still, in radii
    var pressHoldTime: Double = 0.6   // seconds held still to reach the full extra spread
    var pressRise: Double = 0.06      // time constant of the spread (s)
    var pressFirst: Double = 0.5      // fraction of the target applied on the very first frame
    // plasticity only after dwelling (輕按回彈，揉捏即留形)
    var dwellLo: Double = 0.2         // seconds grabbed before the body starts remembering
    var dwellHi: Double = 0.6         // seconds grabbed until it remembers at full speed

    // v2.4 second-batch candidates (手感精修提案). Defaults are the control values (the v2.3 behaviour);
    // the panel's 候選 buttons apply one candidate at a time for blind tests.
    var idleFreeze: Double = 0        // 1: idle motion freezes its clock while touched instead of fading to the rest pose (第 19 條)
    var specialEvery: Double = 0      // every N releases (±2) one comes back extra bouncy; 0 = off (第 2 條)
    var pressRadiusGain: Double = 0   // extra press spread from contact size (UITouch.majorRadius); 0 = off (第 9 條)
    // haptics (第 38 條 on the panel; candidates 12, 13, 14)
    var hapMax: Double = 0.8          // continuous haptic ceiling
    var hapStatic: Double = 0         // continuous haptic: weight of deformation^1.5; 1 before v2.25 (a steady hum, stronger with the hand still)
    var hapRate: Double = 0           // continuous haptic: weight of the rate of change (candidate 0.75 with static 0.25)
    var hapRateNorm: Double = 2.5     // rate of change that counts as full, per second
    var hapSharp: Double = 0.25       // continuous haptic sharpness
    var hapSharpStretch: Double = 0.15   // extra sharpness when stretched, grains too (第三批第 15 條); 0 before v2.25
    var popMin: Double = 0.3          // release pop intensity at zero strength
    var popMax: Double = 0.7          // release pop intensity at full strength
    var popSharp: Double = 0.3        // release pop sharpness (v2.25: clay 0.3, mochi 0.4, jelly 0.5; 0.45 before)
    var popCount: Double = 2          // taps per release at full strength, fewer when let go gently (v2.25: clay 2, mochi 3, jelly 4; 1 before)
    var popGap: Double = 0.09         // seconds between taps (with inertia on they follow its swing instead: half a period)
    var popDecay: Double = 0.35       // each tap is this fraction of the previous (v2.25: clay 0.35, mochi 0.45, jelly 0.55; 0.5 before)
    var tickSpacing: Double = 12      // v2.25 F5: a grain every N points of finger travel; 0 = off (v2.24)
    var tickMin: Double = 0.15        // grain intensity when the finger is slow (0.10 before v2.25)
    var tickMax: Double = 0.35        // grain intensity at 3 radii per second (0.30 before v2.25)
    var tickSharp: Double = 0.25      // grain sharpness (v2.25: clay 0.25, mochi 0.3, jelly 0.45; 0.4 before)
    var tickRate: Double = 20         // v2.25 F5: at most this many grains a second (dozens a second numbs the hand)
    var tickTense: Double = 0.6       // v2.25 F5: how much closer the grains get at full stretch (2R)
    var pressGrain: Double = 1        // v2.25 F5: pressing in: fading grains after the landing tap, one more when the contact patch changes. 0: only the tap (v2.24)
    var grainMin: Double = 0.08       // v2.25 F5: the faintest press grain
    var grainMax: Double = 0.30       // v2.25 F5: the strongest press grain
    var grainSharp: Double = 0.12     // v2.25 F5: press grain sharpness (dull, it should feel like sinking)
    var purrRoll: Double = 1          // v2.25 F5: the purr as a low rolling rumble (continuous, 3 swells a second). 0: two taps every half second (v2.24)
    // 提案第 41 條 (2026-11-01): tentacle rungs. 0 = the v2.4 behaviour, where a tentacle pushed root-to-tip could fold over itself
    var tentRung: Double = 0.5        // the two edges of a tentacle stay on their own sides, at least this fraction of the rest width apart
    var tentAxis: Double = 0.85       // each link of a tentacle's medial axis keeps advancing by at least this fraction of its rest length
    // 提案第 20 條 (2026-11-01): while wandering the tentacles trail the motion
    var tail: Double = 0.12           // tentacle tail while wandering, in radii at the nominal wander speed (tips most); 0 = off
    // 第三批其餘 (2026-11-01): all defaults are the control values
    var homeK: Double = 0.02          // idle home spring per substep (候選 21: 0.003)
    var afterglow: Double = 0         // seconds of extra wobble after a release, damping eases from 0.975 (候選 22: 0.25)
    var breathT: Double = 3.8         // breathing period, seconds (候選 23a: 6)
    var breathShape: Double = 0       // 1: inhale 40%, exhale 55%, pause 5% (候選 23b)
    var breathDeep: Double = 0        // 1: a grab held over 10 s makes the next 20 s breathe deeper and slower (候選 23c)
    var pinchSquish: Double = 1       // 1: squish events when two grabbing fingers close in (提案第 24 條)
    var slip: Double = 0              // 1: pulling past 1.2× maxPull for 120 ms slips out of the fingers (候選 25)
    // v2.38 極限拉扯 (多米 11-09: extreme pulls still break). Web `pairStep`, `dragClamp`, `flipMarks`, the cling `messy` check
    var pairMax: Double = 4.5         // two grabbing fingers at most this many R apart, harder from 60% of it; 0 = v2.37 (no limit between fingers: pulled opposite ways it went 9R and knotted)
    var tear: Double = 1              // 1: the fingers really pulled apart past tearK × pairMax for 0.12 s, the one farther from the body lets go (it tears), loudest pop
    var tearK: Double = 1.3
    var flipMem: Double = 1           // 1: a flipped triangle's corners do not remember that frame; a remembered shape with flips relaxes at 0.3 (like a crossing)
    var homeClamp: Double = 1         // 1: the drag offset may not take home out of the room (v2.37: pulled below the sill it was pressed into a 17 pt line, 9% of its area)
    var clingTidy: Double = 1         // 1: let go sticking out past the window by 0.8R or crossed, it does not stick to the frame
    var stick: Double = 0             // seconds a slow lift keeps holding before the release (候選 26: 0.1)
    var localArea: Double = 1         // area pressure weighted towards the fingers (候選 27, on since v2.26 F7; 0 before)
    var homeFrac: Double = 0.40       // home height as a fraction of the screen (候選 33: 0.46)
    var inkVar: Double = 0            // outline width follows compression, 1.3× squashed, 0.8× stretched (候選 34)
    var pressSharp: Double = 0.2      // sharpness of the press tap (提案第 15 條)
    var hapSharpSquash: Double = 0    // sharpness taken away while squashing (候選 15: 0.05)
    var popViaHaptics: Double = 0     // 1: the release pop plays as a Core Haptics audio event in the taps' pattern (候選 17)
    // 2026-11-01 多米真機回報 (build 46): idle wriggle looked like one shape swaying; clay sprang straight back and kept no mark
    var morph: Double = 1             // 1: idle outline follows smooth noise (modes 2–5 plus two roaming bumps), never repeats; 0 = v2.7 travelling waves
    var tentMem: Double = 0           // tentacles remember like the body and relax at `recover`; 0 = v2.7 (tips barely remember, spring back in ~1 s)
    // v2.9 (多米 second device report, build 48): not a starfish. No fixed tentacles; pseudopods grow, hold and retract anywhere
    // (the top too); a regular jellyfish pulse; free sculpting, pulled long and spread flat like dough
    var limbs: Double = 0             // fixed tentacles (v2.27 8 ringing the body, each grabbable; 0 none; 5 = the old starfish shape; changing it rebuilds the body)
    var tentSlip: Double = 0        // v2.27: pushed toward its own root to this share of its rest length, or round the back of the body, a tentacle slides out of the finger; 0 = off (it tangles and shakes)
    var tentBump: Double = 0        // v2.27: how hard a tentacle knocks another it runs into (多米 11-05); 0 = they pass through
    var moodColor: Double = 0.8       // v2.27: how far a mood tints the body (comfort peach, strained red, scared or wary blue-grey, asleep indigo); 0 = off
    var pods: Double = 2              // pseudopods growing at once while untouched; 0 = off
    var podLen: Double = 0.6          // pseudopod length at full extension, in radii (each one 0.7 to 1.2× of it; 1.1 in v2.10)
    var idlePace: Double = 0.45       // pace of the idle morph and the pseudopods (1 = v2.9 web, which 多米 found too fast)
    var bodySize: Double = 0.30       // body radius as a fraction of the screen width (0.26 before v2.9, 0.22 v2.10 to v2.23; changing it rebuilds the body)
    var jelly: Double = 1             // 1: jellyfish pulse (fast contraction, slow relax, a lift on each contraction); 0: the plain breathing
    var jellyT: Double = 3            // jellyfish pulse period, seconds
    var jellyAmp: Double = 0.06       // how much narrower at full contraction (taller by 0.85 of it; 0.1 in v2.10)
    var jellyLift: Double = 0.08      // lift per contraction, in radii; sinks back with a 1 s time constant (0.12 in v2.10)
    var nearMem: Double = 0           // near the fingers the body remembers in the whole-body frame (clay 1: a pulled-out lump stays)
    var memMax: Double = 1.1          // how far the remembered shape may move from the original, in radii (clay 4)
    var grabHold: Double = 0          // how much less the grabbed patch listens to shape matching (clay 0.85: it follows the finger)
    // v2.11 (多米 build 53): smaller self-driven deformation; grab the middle of a pulled strand and pull again; no crossing;
    // press it flat
    var grabK: Double = 0.55          // how far the grabbed patch moves to the finger per substep (× its weight); clay 1.2
    var nearR: Double = 1.58          // radius of the whole-body-frame memory around the fingers, in radii; clay 3 = the whole lump
    var ringGuard: Double = 1         // 1: a boundary particle may not pass through another boundary segment
    // v2.29 防打結 (多米 11-06: 拉扯時常常打結; measured on the web: rough pulling flipped up to 602 of 960 inner triangles and they stayed flipped 3 s after release).
    // Distance constraints only know near and far, not which side: a whole patch can turn inside out. The rest shape is cut into a triangle
    // mesh and no triangle may shrink below noFlip of its rest area (the remembered shape too), so nothing can fold over and knot.
    var noFlip: Double = 0.15         // 0 = off (v2.28)
    var gripUp: Double = 0.004        // most the body turns back upright per substep while grabbed; larger and it cannot turn, so a pulled strand can only wrap around it (0.2 before)
    var homeCap: Double = 0.5         // most the whole body follows the finger per substep (× particle spacing); faster and the ring beside the finger shears open and flips (0 = no cap, 24 pt a substep measured)
    var softWall: Double = 1          // v2.29: on the sill the left, right and top edges are soft: the body may go a little past them and is eased back (grabbed: slower); 0 = hard walls
    // v2.28 窗台 (多米 11-06): a room with a window, gravity, a sill to stand on and a bowl to sit in; v2.31 the bowl in the middle, the pebble dish
    // and the succulent as pictures on the sill's ends. 0 = the blue floating room (nothing of the old behaviour changes there), 1 day, 2 night
    var scene: Double = 1
    // v2.28 果凍皮 / v2.31 皮 A 清透 (多米 11-07): the body as a lit see-through jelly (Metal), the glitter shows inside; 0 = the flat cartoon fill (and phones without Metal)
    var skin: Double = 1
    var envRoam: Double = 1           // v2.30: how often it leaves the bowl by itself and walks the sill (0 = it stays put)
    // v2.31 搖晃沉澱 (多米 11-07: 互動改成搖手機, like a snow globe: shake it up, then wait for it to settle). One rule for the whole app: moved, it clouds; still, it clears.
    var shake: Double = 0             // 1: a shake bounces it in the bowl and stirs the glitter inside it up into a haze; left alone about settleT s it clears, glows, opens its eyes, dings; a pinch stirs a little too. 0 off
    var shakeN: Double = 3            // this many shakes and all the glitter is up; harder shaking adds nothing
    var settleT: Double = 30          // seconds from fully clouded to fully clear when nothing touches it
    var calmBreathT: Double = 10      // its breath period while the glitter settles (10 s = 6 a minute), taking you down with it
    var stirRate: Double = 0.12       // glitter stirred up per second while held or rubbed (0.12: 5 s of rubbing is about 60% cloudy); 0 = only a shake clouds it
    var shakeKick: Double = 1         // how hard a shake bounces it in the bowl (capped: flung hard lying down it stays in the bowl); 0 = only the glitter moves
    var cling: Double = 1             // v2.36 黏牆 (多米 11-07: like an octopus on the wall, it resists being pulled off): 1 set down slowly by a jamb or the top it sticks, a ring of suckers on the wall, 8-15 s; 0 the v2.30 1.6 s
    var bowl: Double = 0              // v2.35 拿掉碗 (多米 11-08): 0 no bowl, it lives in the middle of the sill; 1 the v2.31 bowl (kept for the code path, not in the panel)
    var props: Double = 0             // v2.35 (多米 11-08: the sill things go): 1 the old pebble dish and succulent
    var deco: Double = 1              // v2.37 擺飾 (多米 11-08, his sticker set): 1 cloth, candle (lit at night), wind bell; 2 + books and a teru teru bozu; 3 the jar instead of the books; 0 none
    var excite: Double = -1           // v2.32 興奮 (多米 11-07: the more you walk, the livelier it is): -1 from what it brought back today (0-1 things 0, 2 half, 3 full); 0 to 3 pretend that many
    var one: Double = 1               // v2.33 一隻為主 (多米 11-07: a companion pet, you keep one, 芋圓): 1 hides the four-slime row and always starts on 芋圓; 0 the four come back
    var trKeep: Double = 1            // v2.34 熟留下來 (多米 11-07: a pet remembers you): 1 trust is saved per slime on this phone, wariness still resets each visit; 0 back to v2.33
    var shakeG: Double = 10           // 11-08: 13 → 10, never shaken on a phone before build 117; a hand shake of ±2 cm at 2.5 Hz is about 5, ±5 cm at 3 Hz about 18. m/s² of phone acceleration that counts as one shake: a gentle shake lying down must count, walking or picking the phone up must not
    var glitN: Double = 150           // bits of glitter inside it
    var fingerSolid: Double = 0.2     // the grabbing finger is solid (× R): dragged across the body it pushes the flesh it did not grab aside instead of passing through; 0 = off
    var pressFlat: Double = 0         // 1: pressing down from the upper half flattens it on an invisible table (clay)
    var flatMin: Double = 0.3         // flattest, as a fraction of the height when the press began
    // v2.12 (多米 build 55: pulled a little bigger and it would not go further; measured: the screen edge, right 1.1R, up 1.8R)
    var zoomMin: Double = 0           // the view zooms out to fit a big shape, down to this; 0 = no limit and no walls (v2.13, 多米), 1 = off, v2.12 was 0.45
    // v2.13 (多米: zoom out without limit, as far as the slime is pulled)
    var camFill: Double = 0.85        // v2.24 (0.7 before: with the bigger body a short pull zoomed the view); while grabbed the shape fills at most this much of the view, leaving room for the finger; 1 = tight (v2.12)
    var camCenter: Double = 1         // 1: once big or pulled the view centres on the shape, so there is room ahead of the finger to pull again
                                      // (v2.15 default; in v2.13 it ran to 15R because the resting finger was dragged out by the view); 0: on home
    // v2.14 (多米 build 59: only the edge could be pulled; nothing happened pulling from the middle)
    var grabReach: Double = 1         // 1: grabbed from inside out of reach of the boundary, a strip to the boundary is added once the finger moves
    // v2.15 (多米 build 61: a tap should leave something, maybe a dent)
    var dent: Double = 1              // 1: a press leaves a dent (a crescent of shade upper-left), fading at the relax rate
    var dentSize: Double = 0.5        // dent radius, in radii (v2.26 F7: 1.5 to 2 times the finger's contact patch, a ring shows outside the finger; 0.3 before)
    // v2.16 (多米: the press looked like a toy). Defaults are clay; jelly and mochi set theirs in `defaults`
    var press2: Double = 1            // 1: the whole body thins and spreads, the dent bends with the body, fast then slow sinking,
                                      // a material rebound on release, the highlight squeezed aside, a deeper shadow; 0: v2.15 crescent
    var pressArea: Double = 0.06      // fully pressed, the body's area grows this much (pressed from the front it gets thinner, so wider)
    var pressSpread: Double = 0.10    // around the finger the body is pushed out this much (in radii, most at 0.3R from the finger)
    var pressSink: Double = 0.8       // 60% in the first 40 ms, the rest takes this long (s)
    var pressBounce: Double = 1       // release damping: 1 no rebound (clay), lower rebounds more (jelly 0.3)
    // v2.17 (多米: when the app opens it comes hopping over from far away; the camera should not pin it to the middle: it moves,
    // sometimes off screen, and the camera follows slowly)
    var intro: Double = 1             // 1: four hops in from far away on a cold start (about 2.8 s), a touch on the way brings it home at once
    var camFollow: Double = 1         // 1: the camera follows once it walks off-centre, it may leave the screen; still while grabbed. 0: v2.16
    var followZone: Double = 0.65     // v2.24 (0.8 before: with the bigger body it was half off screen before the camera moved); how far off its usual spot (1 = half the view) before the camera follows; v2.18 0.8 (near the edge), v2.17 0.5
    var followStop: Double = 0.35     // the chase stops this close, it does not pull the slime back to dead centre (v2.18; v2.17 0.06)
    // v2.18 (多米: it always sits in the middle; pulled it should want to run away, stroked it should purr; no face)
    var emo: Double = 1               // 1: comfort softens it and purrs, happiness wags a pseudopod and hops, a hard pull makes it flee, pokes make it dart
    var flee: Double = 1              // how far it runs after a hard pull (1 = half to 0.8 of a view, longer pulls further)
    var purr: Double = 1              // strength of the purr taps while stroked gently
    var followSpeed: Double = 1.4     // follow spring (rad/s), critically damped; 1.4 catches up in about 2 s
    var dash: Double = 0.25           // chance a wander walks far and fast (2.5× speed); the camera lags and it leaves the screen a bit
    var specks: Double = 1            // 1: faint fixed specks far behind (parallax 0.55) so a moving camera reads as moving
    // v2.19 (多米 build 73: no sense of life, it does not read as a creature; is the shadow needed?) .uiux/04-手感/活物感提案-暫定.md
    var life2: Double = 1             // master: the A1...A8 below; 0 = v2.18 (the switches below only count while this is 1)
    var lifeRest: Double = 1          // A1 A2: mostly resting (breath only, wriggle down), a pseudopod sniffs a direction, 65% then go that way; 0: v2.18 walk-and-pause, random pods, twitches
    var lifeGait: Double = 1          // A3: it moves by contracting (gather, each stroke surges forward then glides, a curved path, a bump on arrival); 0: v2.18 glide
    var lifeHeld: Double = 1          // A4: keeps breathing while held; a finger on empty space does not freeze it
    var lifeFlinch: Double = 1        // A5: flinches 0.1...0.25 s after a touch and gets used to it; shakes off after a hard pull
    var lifeBreath: Double = 1        // A6: each breath a little different, a sigh every 30...90 s, panting after running
    var lifeAttend: Double = 1        // A7: sniffs toward where your finger left, and toward a touch on empty space nearby (does not walk there)
    var shadow: Double = 0            // A8: 1 draws the shadow (v2.18); 0 none (floating and walking every way, a shadow contradicts the space). Always drawn with life2 0
    var heldBreath: Double = 0.75     // breathing while held, share of normal (the pinned middle eats some: 0.75 reads as about 0.6)
    var restWrig: Double = 0.3        // wriggle while resting, share of normal (looking 0.6, walking 0.5)
    var flinchAmp: Double = 0.1       // v2.24 (0.05 before); how much the flinch shrinks it (resting ×1.2, comfortable ×0.5, each flinch ×0.55, back with a 7 s time constant)
    // v2.20 (多米 build 75: dragging only deforms it, nothing moves; a tap's dent takes too long to go; it still does not feel like it
    // reacts to you, wants second-order effects of how you treat it) .uiux/04-手感/互動與拖拉提案-暫定.md
    var slide: Double = 1.5           // v2.21 D1' pull (多米 build 77 video: pulled down-right, it should go down-right too): stretched about this far (×R), pulling further drags the whole body; two fingers apart still stretch long; 0 = v2.20 (jelly 0.6, mochi 0.9, clay 1.5)
    var drag: Double = 0.35           // D1: while held, home follows this share of the finger's travel (0.25 s lag); release keeps it there, a fling glides on; 0 = v2.19
    var dentFade: Double = 0.6        // D2: seconds a tap's dent takes to go (2.5× after a press of 1 s or more); 10 = v2.19 (fades with recover)
    var imp: Double = 1               // master: an impression of you (trust, wariness) for this run of the app, zeroed after 10 min in the background; C1...C5 only count while this and life2 are 1
    var impC1: Double = 1             // C1: a finger resting beside it: trusting, it swims over and touches it (very trusting, nestles and rubs); wary, it backs off and points at you
    var impC2: Double = 1             // C2: a finger moving nearby: a pseudopod follows it; trusting, it chases and pounces when you stop; a fast swipe startles it when not trusting
    var impC3: Double = 1             // C3: drag follow by impression: trusting 0.5, wary 0.15; very wary slips free after a while; less while it strains to flee
    var impC4: Double = 1             // C4: after a purr and release it reaches for where your finger left and edges over; touched within 5 s, the purr comes fast
    var impC5: Double = 1             // C5: wary, it flinches more and sooner and calms after gentle touches; idle, trusting sniffs toward your last touch, wary away
    // v2.22 (多米 build 77: still no feeling it reacts to you; go on with the drops). All five only count while life2 is 1
    var e1: Double = 1                // E1: it makes small sounds: poked, stroked, pulled, happy, begging, tickled, gulping a drop, saying hello; higher when trusting
    var e2: Double = 1                // E2: every action answered: a tap → it leans toward your finger; held still → it pushes once, then nuzzles; tickled → it squirms, too long → slips free; wary and dragged → it claws away
    var e3: Double = 1                // E3: the impression shows: trust 3–4× faster; trusting rounder, taller, warmer, slower breath; wary flatter, paler
    var e4: Double = 1                // E4: trusting and left alone 10–20 s, it swims to the front, waves a pseudopod, hums, goes back (3 times a run at most)
    // v2.23 (多米 build 86: the drops look wrong and come off too easily, too many; still no feeling it reacts to you; try a face, eyes only;
    // sleep, rhythm, swim-in and the collection all at once). All but eyes only count while life2 is 1
    var eyes: Double = 1              // v2.27 off (多米 11-05: remove the eyes). 1: two small eyes: look at your finger, blink; squint held, > < pulled, ∩ purring or happy, ∪ asleep, wide when wary. 0: no face
    var sleep: Double = 1             // B2: untouched 40 s (a tap on the empty screen counts) while resting, it falls asleep; a touch startles it awake, a finger beside it 1.2 s wakes it gently
    var echo: Double = 1              // C6: tap the empty screen 2–8 times in a rhythm (0.12–1.2 s apart); it answers with the same count and rhythm; answer it back the same and it is happy
    // v2.24 (多米 11-04: make the feel the best it can be; .uiux/04-手感/手感診斷-暫定.md): the body was 3 cm wide under a 1.6 to 2 cm finger, reactions under 1 mm, ordinary rubbing got no reaction
    // v2.25 F4: the reference shape with inertia (measured: a release was over in 33 ms and rang 7 times a second, a very small piece of rubber)
    var inertiaHz: Double = 3         // how many swings a second on a release, a fling, a drag that stops; 3 is about 0.17 s for the first (clay 3, mochi 2.6, jelly 3.2); 0: v2.24
    var inertiaZ: Double = 0.3        // its damping ratio, smaller swings longer (clay 0.3, mochi 0.26, jelly 0.16); Reduce Motion at least 0.7
    var inertiaCarry: Double = 0.6    // how much of the body's velocity at the release goes into the swing
    var inertiaDrag: Double = 3       // a drag's acceleration pushing the reference shape the other way, more the farther from the finger; 0 off
    var dragSpring: Double = 0.5      // the whole body follows the finger on a spring with this damping ratio (0.5 runs past by about 16%); 0: v2.24 (0.2 s smoothing, it stops dead)
    var dragHz: Double = 1.4          // that spring's swings a second; 1.4 lags about 0.1 s
    // v2.26 F6: stroke or grab (measured: a finger sliding across dragged the body along 74 to 113 pt)
    var strokeV: Double = 400         // 150 before v2.26.1 (12 pt in 80 ms: a quick drag from the side slid off); moving this fast right after landing, not outward: a stroke (the finger slides over, nothing pinned); 0: v2.25 (a touch is a grab)
    var strokeT: Double = 0.08        // within how long of landing; shorter is harder to count as a stroke
    var strokeStop: Double = 60       // a stroke slower than this for 0.12 s becomes a grab
    var strokeCarry: Double = 0.2     // how far a stroke carries the whole body at most, in radii; it comes back by itself
    var strokePush: Double = 30       // how hard the finger pushes the skin aside
    var strokeFric: Double = 20       // how much the skin is carried along with the finger; 0 slides as on ice
    // v2.26 F7
    var dentTrail: Double = 0.5       // a rub or a stroke leaves a trail fading in this many seconds; 0 none
    var hiStretch: Double = 1         // 1: the highlight bends with the skin around it; 0: it only turns
    var camGrip: Double = 1           // the picture does not slide under the finger: while grabbed the view only zooms out about the finger; moved back in after the release. 0: v2.23 (centred on the shape from 0.5R)
    var camPad: Double = 0.2          // margin around the framed shape (× radius); 0.35 before
    var pressLocal: Double = 1        // until the finger moves off its spot only the part near it remembers (holding still no longer folds the far edge). 0: the whole body (v2.23)
    var leanAmp: Double = 0.28        // the lean's bulge toward the finger (× radius); 0.16 before
    var leanMove: Double = 0.11       // the whole body shifts toward the finger and back during the lean (× radius); 0: v2.23
    var nuzAmp: Double = 0.12         // nuzzling sway (× radius); 0.05 before
    var gazeAmp: Double = 0.18        // how far the whole face slides when it looks at something (× radius); 0.06 before
    var dodge: Double = 0.22          // the face slides out from under a nearby finger (× radius); 0: v2.23
    var rubSpeed: Double = 12         // rubbing up to this many cm a second counts as gentle; 0: v2.23 (2R a second, about 2.9 cm, ordinary rubbing got nothing)
    var tickRev: Double = 6           // turns within a second that make a tickle (3 trips a second); 4 before (rubbing to and fro set it off)
    var tickSeg: Double = 48          // a leg longer than this (points, about 8 mm) is rubbing, not tickling; 0: any length (v2.23)
    var tickFree: Double = 6          // seconds of tickling before it breaks free, protesting the last 2; 3 before
    var reachV: Double = 1            // only a straight pull adds the strip out to the boundary, rubbing does not; 0: at 0.12R (v2.23, the outline folded while rubbing)
    var introSwim: Double = 1         // the cold start (and a slime switch): it swims in from off the right edge, looks at you, waves, says hello. 0: the v2.17 hops
    // v2.23 personality (set by the chosen slime, see SlimeKind): rest length, voice pitch, eye size, how fast trust and wariness grow, how soon it visits
    var restMul: Double = 1, voicePitch: Double = 1, eyeSize: Double = 1, trRate: Double = 1, wRate: Double = 1, e4Mul: Double = 1
    // v2.57 (the six new slimes, web v2.52): seconds alone before it falls asleep (湯圓 25), how fast wariness fades (× 260 s; 布丁 0.12, scared easily but forgets fast)
    var sleepAfter: Double = 40, wFade: Double = 1
    var coreSoft: Double = 0, edgeClean: Double = 0   // v2.61b (多米 11-26), the panel's two chips, every material: 1 = 湯圓's core smaller and lighter; 1 = the opaque body's edge clean (no grey see-through rim, the dark line 70% lighter)
    var clear: Double = 0             // v2.60 (多米 11-24: back to the opaque body; v2.57's switch for the six new ones now covers all ten): 1 = all ten glossy and see-through as in v2.53b to v2.59 (shine 1, opaque 0); 0 = shine and opaque below. Set from the panel's chip, for every material
    // v2.47 (多米 11-16, phone video of build 127: pulled about, some places turn sharp; pulled too long it twitches; take the powder out; it should look full of water)
    var pressPull: Double = 1         // 1: the press spread fades once the finger has pulled away from where it landed (0.15R to 0.6R). Measured: pulled 3R and held still, the patch under the finger was still spread 0.3R (the grab radius), tearing it: 18 flipped triangles, the guard pushing 5 pt back every frame. 0 = v2.46
    var dragCalm: Double = 1          // 1: the spring the whole body follows the finger on is damped more from 1R of travel, no overshoot from 3R (pulled 3.5R it ran 60 pt past and came back, jumping for a second with the hand still). 0 = v2.46
    var memSmooth: Double = 4         // the remembered shape smooths its own spikes (like surface tension): how much of a one-particle detail goes a second; long pulls and flat spreads barely move. 0 = off (v2.46)
    // v2.48 (多米 11-16: pulled about it often "breaks": past some range it twitches, knots, turns into irregular spikes; fix it at the source).
    // Measured with the web's fuzz.js (random pulls, two fingers, scrubs, stirs from fixed seeds), four sources, each fixed where it starts:
    var stretchCap: Double = 3        // every mesh edge of the live body is at most this many times its rest length: once the ones by the finger are full the next ones stretch (they used to reach 12 to 35 times); 0 off (v2.47)
    var memCap: Double = 2.4          // the same limit for the remembered shape (keep it under stretchCap); 0 off
    var capLo: Double = 0.4           // and at least this much of its rest length
    var capIter: Double = 4           // rounds a substep, together with the no-flip guard; stops early when nothing is over
    var capSlip: Double = 4           // 手指讓: the finger's effective position gives way by this many times what the limits, the sill and the walls pushed the held patch back; 0 off
    var capVel: Double = 0            // 0: the corrections move the last position along and leave no velocity; 1: they keep it (and bounce against shape matching)
    var capGrabW: Double = 0.2        // how much a held particle moves when its edge is at the stretch limit (the other end is 1)
    var capPushW: Double = 1          // how much a held particle moves when its edge is squeezed to the limit or its triangle is about to flip
    var tremble: Double = 0           // 0: no shiver when pulled or poked (it read as broken); 1 = v2.47
    var struggle: Double = 0          // 0: no clawing pseudopods while pulled; 1 = v2.47. The squint, the protest sound and the tug back stay
    var round: Double = 1.3           // the jelly skin's outline is cut from the blurred mask: sharp corners become round heads, concave corners join like water; the number scales the corner size (1 is about 0.07R). 0 = the particle outline (v2.46)
    var glit: Double = 0              // 0: no glitter drawn inside it and no haze when handled (多米 11-16: 粉末去掉); a shake still bounces it and slows its breath. 1 = v2.46
    var wet: Double = 1               // 1: the wet skin (clearer, a larger sharper highlight, a second small one, a rim of light). 0 = skin A (v2.46)
    // v2.49 看得出是水 (多米 11-16: it should read as made of water, 95% water). Needs wet 1 and a room behind it.
    var water: Double = 1             // 1: what is behind it shows through its body, bent; thin places almost colourless, the thick part takes its colour. 0 = the v2.48 skin
    var refr: Double = 0.3            // how far the background seen through it shifts (in radii); most at the edge
    var absorb: Double = 0.68         // 0 the whole of it like clear water; 1 a strong colour in the middle
    var caustic: Double = 0           // v2.51: 0 (the ring under it read as a base). sitting, a patch of gathered light under it and a faint ring of shade; 0 off
    // v2.51 (多米 11-22). Web: the same keys in PRESETS
    var shine: Double = 0             // 0 (v2.60, 多米 11-24: back to the look of v2.51 to v2.53): no highlights on the body (main spot, small spot, the arc, the sheen); 1 = v2.50, and v2.53b to v2.59
    var opaque: Double = 0.9          // how much the thick part of the body hides what is behind it. 0.9 (v2.60): only the thin edge lets it through. 0 = v2.50, and v2.53b to v2.59 (all of it clear: the sill edge and the cloth seen through it were the "line" and the "base")
    var lump: Double = 1              // irregular outline (web shape.js): heavy below, a bump leaning to one side on top, a smaller one low on the other side; 0 = the near-round blob of v2.50. Rebuilds the body
    var strand: Double = 0            // the body itself stretches to a stable length (2.4R on the sill); farther than that a tapered strand runs from the held patch to the finger, drawn into the same mask. 0 = v2.50
    var tugEdge: Double = 0        // a grab this close to the outline (×R) pulls a strand out and the body stays; nearer the middle it is carried whole as before. 0 = always carried
    var split: Double = 1             // v2.62 (多米 11-26): held and pulled past splitAt×R from where it took hold, the finger fast (splitV), it tears into two pinchable slimes; touching, they merge back with mergeFx. At most two. With the strand on: v2.51 (the strand pinches and parts). 0 off
    var splitAt: Double = 1.8         // v2.62: how far the finger is pulled from where it took hold (radii; 3.4 before, measured from the centre). The strand's pinch does not read it: a fixed 3.4 from the centre, as v2.51
    var splitV: Double = 10           // v2.62: the finger faster than this on screen (radii a second) counts as a tear (v2.61's yank is 6)
    var splitFrac: Double = 0.45      // v2.62: the share of the area the second one takes; the first shrinks to the rest, merged they add up to the whole again
    var splitAgain: Double = 1        // v2.62: 1 = merged back, it can tear again (多米 11-26 chose this); 0 = once per opening
    var mergeFx: Double = 1           // v2.62: the merge animation: 0 a bridge of goo, 1 squash and pop, 2 a drop and a ripple, 3 swallowed. 1 (多米 11-26 chose squash and pop); the other three stay as controls
    var mergeGap: Double = 0.08       // v2.62: the two outlines this close (radii) count as touching, the merge starts
    var mergeWait: Double = 1.5       // v2.62 (多米 11-26: touching, they merge a little later): touching this long (seconds, unbroken) before the merge starts; parted, it starts again. 0 = at once
    var rejoin: Double = 6            // seconds left alone before the second one crawls back (in pulses); touching, the merge plays
    var endless: Double = 1           // v2.54 無限拉 (多米 11-22: pulled 5 cm it grew 3 cm and stopped; it should stretch without end and stay under the finger): the finger never gives way, the soft limits (maxPull, memMax) are off, and each edge's hard limit widens by `capG` while the held patch cannot keep up; 0 = v2.53
    var growK: Double = 1.5           // how fast the edge limits widen while the held patch lags the finger (e to this power a second)
    var growMax: Double = 12          // the most the edge limits widen
    var pullCreep: Double = 15        // pulled outward (0.6R on, fully at 1.8R) the remembered shape follows this fast instead of creep
    var pullNearR: Double = 10        // and is measured in the whole body's frame this far around the finger (×R) instead of nearR
    var homeFloor: Double = 1         // v2.55 (11-23): held on the sill, the home spring may not pull the body into the floor (home lowest where the bottom just touches the surface). Pulled up 2.5 to 3.5R and held, the remembered shape grew long while home stayed at the short body's centre, so the spring pushed the lower half into the sill: flattened to a line, a hundred flipped triangles. 0 = v2.54b
    var remeshCalm: Double = 0.25     // v2.56 (11-23): for this long after a re-sample, each 1/60 s the body keeps remeshCalmK of its velocity relative to the whole (the new mesh settles instead of bouncing; held at 3R the 12 frames after a re-sample jerked 8 to 10). 0 = v2.55
    var remeshCalmK: Double = 0.2     // how much of that relative velocity is kept per 1/60 s while settling; 1 = no effect
    var remeshHome: Double = 1        // v2.58 (QC-0007 #46): let go, the body goes back to the mesh it was built with (its shape carried over); a re-sample no longer folds the return target. 0 = v2.57
    var pullGive: Double = 0.3        // v2.58 (11-24): pulled outward (0.6R on, fully at 1.8R) the finger gives way at most this many radii instead of 2 (it piled up to 2R and the held patch trailed: a slanted 5.5R pull 1.6R behind, 3.3R at worst); rubbing, pressing and pinching as before. 0 = before
    var memUntie: Double = 0.8        // v2.58 (11-24, QC-0007 #46): let go, the remembered outline crossed longer than this many seconds is undone fast, the memory's own limits left out until then; knotted over 0.6 s on a screen edge, it drops early. 0 = off
    var walkShow: Double = 0          // v2.58 (QC-0007 #47): 0 = it does not go out and brings nothing back, nothing from walks lies on the sill, no gift stone (what is saved stays saved); 1 = v2.57
    var remesh: Double = 1            // v2.54 拉長時自動補點: re-sample the body from the remembered shape when it is pulled long (see SlimeRig.remesh); 0 = only widen the limits
    var remeshHi: Double = 2.6        // an outline edge of the remembered shape longer than this many point spacings
    var remeshStr: Double = 2.8       // or an edge inside past this × its rest length
    var remeshLo: Double = 0.55       // going back: an outline edge shorter than this many spacings (and more points than at build time)
    var remeshMaxN: Double = 3        // at most this × the build-time point count
    var rateK: Double = 0.8           // v2.54 快扯變硬、慢拉變軟: how much the finger's speed changes the stiffness while held (0 = off)
    var rateLo: Double = 4            // radii a second, at or below: softest
    var rateHi: Double = 14            // radii a second, at or above: stiffest
    var hapPull: Double = 0.55        // v2.54 震動跟著拉力走: continuous rumble at full tension (0 = off)
    var frameCling: Double = 0        // v2.54 (多米 11-22: only the phone's four edges, no more window ledge): 1 = v2.53, set down by the window jambs or under the top bar it sticks to the frame
    var edgeCling: Double = 1         // set down slowly by the left, right or top edge of the screen it sticks there, the same suckers as on the window jambs; 0 = jambs only
    var bubbles: Double = 0           // v2.51: 0 (多米: no drops inside). small air bubbles inside it, each riding a particle (squeezed aside with it); 0 none
    // v2.52 (多米 11-22, 《虛擬手感》3-3 到 3-5 的決定；交辦 A、C 組). Web: the same keys in PRESETS
    var flow: Double = 0              // A4 流: left alone on the sill, the remembered shape slumps under gravity and spreads sideways, this share of its height a second (0.05 ≈ half in 14 s); a finger stops it at once. 0 = off (v2.51). Per material once 多米 has filmed his reference
    var strandAt: Double = 2.4        // A1: with the strand on, how far the body itself stretches on the sill (radii); the rest of the way is the strand. No effect with the strand off.
                                      // v2.51 had 2.4 written in. Held by the edge (tugEdge: the body does not come along) the small grabbed patch had to stretch 2.4R by itself:
                                      // the outline folded to 135-178°, dozens of triangles turned over while held and on release, and the fuzz test's jump-while-held went
                                      // from 0.61 pt (v2.48) to 2.45. At 1.6 it is 0.61 again and the strand still reaches the finger (numbers in .vibe/代決清單.md)
    var sillCap: Double = 0           // A1 control: 0 = the sill does not cap the stretch (clay pulls to its own 7 and remembers 5); 3.2 = v2.50 (stretch at most 3.2R, memory 2.6R). Only with the strand off
    var thin: Double = 0              // C1 細絲: 1 = from 60% of the effective stretch limit the outline's rounding shrinks, down to 30% at the limit, so a thinning strand of body shows; 0 = v2.51 (fixed rounding)
    var wbreath: Double = 0           // C2 水的呼吸: 1 = what is seen through the body bends ±12% with its breath (still, the refraction was static: glass, not water); 0 = v2.51
    var decoThru: Double = 1          // C3: 1 = the wind bell, the teru bozu and what it brought back from walks show through the body too (the baked background gets them every frame); 0 = v2.49 (fixed background only), to measure the cost
    // v2.61 第一批 (.vibe/第一批-合約.md, 2026-11-25). Web: the same keys in PRESETS, the same for all three materials. 0 = build 158 for every one of them
    var skinU: Double = 1             // A1 網格聯集的皮: 1 = the mask is the union of the body's triangles with a line of 0.12R where it is thin, so a figure 8 or a thin neck does not part, and what is clipped to the body follows; 0 = the outline path (v2.60)
    var pullHold: Double = 0          // A3 拉長停住就定住: 1 = pulled long and the finger still, the remembered shape all but stops; 0 = it keeps growing slowly by itself
    var pullWhole: Double = 0         // A4 往裡拉先整隻走: 1 = pulled towards the body's middle, the whole body goes along first, then it stretches; 0 = only the held patch goes in
    var pullSoft: Double = 0          // A5 + A2 放手是收回去: 1 = let go long it is drawn back (fl 1.35, up 3, vc 6, bl 1.35, cg 1, gv 1); 0 = it springs, flees and shakes as before
    var rough: Double = 1             // D1 只有快扯算欺負: 1 = only a fast yank counts as rough (it no longer adds trust, and adds no wariness); 0 = pulled out 1.5R for 0.5 s counts
    var tapSoft: Double = 1           // D2 慢點不算攻擊: 1 = slow light taps are no attack; 0 = as before, three pokes in a second are, however light
    var petSlow: Double = 1           // C3 慢摸累積: 1 = slow strokes add up, feeding only the purr and the trust; 0 = as before
    var wakeSoft: Double = 1          // C1 輕碰慢慢醒: 1 = a light touch wakes it slowly, and just opened it stays up 40 s; 0 = as before (startled awake by any touch, asleep at 30 s)
    var nearFast: Double = 1          // C2 聽節奏時照樣靠過來: 1 = it comes to the finger beside it while it listens for a rhythm too; 0 = as before
    var greetLook: Double = 1         // C4 打開先看你: 1 = opened, or back from the background / lock screen, it looks at you first (asleep: wakes slowly, no sound); 0 = as before. Wired in v2.63 (SlimeRig greetArm, greetStep)
    var brJit: Double = 1             // C7 作息亂數: 1 = each waking and each sleep draws its own pace, an opening starts the needs at random; 0 = as before. Read since v2.63 (SlimeBrain)
    var bumpSoft: Double = 1          // C7 自己撞到只晃不倒: 1 = on; 0 = as before. Web only: the phone has no decorations' physics, 不接
    // v2.63 大腦第一片 (web brain v2.41, brPre v2.42, brAwakeT, brSleepT; the same keys and defaults for all three materials). SlimeBrain.swift, SlimeRig MARK v2.63 大腦
    var brain: Double = 1             // 大腦: 1 = five needs rise and fall, it does what the strongest wants; tired after a run, wakes by itself, comes to you when it wants to be stroked; 0 = as before (dice, asleep 40 s untouched, never wakes by itself)
    var brPre: Double = 1             // 換事情前的前兆: 1 = squints and sighs 2 s before sleeping, looks at you before coming; 0 = straight away
    var brAwakeT: Double = 300        // 醒著多久會睏 (s): sleepiness from 0 to full untouched; twice as fast after 20 s untouched, 1.5× at night
    var brSleepT: Double = 90         // 睡多久睡飽 (s): sleepiness from full to 0 asleep; slept off, it wakes by itself
    // v2.63 大腦第二片 (web mood, moodHalf v2.42; the same keys and defaults for all three materials). SlimeBrain.mood, SlimeRig mdOn / brainM / brainMS
    var mood: Double = 1              // 心情: 1 = a mood that changes over minutes (purr, happy, its rhythm answered: better; pulled, scared, woken: worse) and leans the needs, posture, eyes, strides, the flinch, a poke; only this opening. 0 = as before. Needs brain
    var moodHalf: Double = 300        // 心情多久退一半 (s): with nothing happening the mood goes back to 0.1 (a mild liking), half the way in this many seconds
    // v2.63 C9 (web nap, napPurr, napWait; NAP, napStep, napReady; the same keys and defaults for all three materials). SlimeRig MARK v2.63 C9
    var nap: Double = 1               // 揉夠了在你手邊睡著: 1 = purred napPurr s in all this opening, then no finger for napWait s, it falls asleep where you last touched it (not back to the mat, no 前兆, no words); 0 = as before
    var napPurr: Double = 60          // 揉多久會睡在手邊 (s): purr over 0.3 counted this opening (a slime switch, a rebuild, a rotation start it again). The number is mine, to be tried on a phone
    var napWait: Double = 6           // 放手幾秒睡著 (s): once enough, how long after the last finger leaves. The number is mine, to be tried on a phone
    var eyeTrue: Double = 1           // B4 眼睛讀真手指: 1 = the eyes follow the real finger; 0 = as before (the smoothed one, about a quarter of a second late)
    var snd61: Double = 1             // B1 揉的新循環音、抓著時雨 0.6→0.3: 1 = the new rub loop, the rain at 0.3 while held; 0 = the old files and 0.6
    var dens: Double = 12            // particles per radius (v2.12 and before: 9); at 8R the boundary was too sparse and the tail folded
                                      // across (measured: crossings on every hold at 9, 1 frame in 4 holds at 12); about 1.7× the particles
    // sound
    var volMaster: Double = 0.9       // output volume
    var rubMax: Double = 0.7          // loudest the rub loop gets
    var pitchJitter: Double = 0.08    // random pitch ±
    var sndPullMax: Double = 0.6      // loudest the stretching-strand loop gets (v2 layered sound)
    var volMusic: Double = 0.25       // v2.21 background lofi volume (the speaker button's first state); ducks to 0.6 while held
    var sndSettle: Double = 1         // after-release tail: bubbles after a pull, a small hiss after a long press; 0 = off
    var sndPressSize: Double = 0.5    // how much contact size (majorRadius) changes the press sound; 0 = off

    /// v2.60 what the skin really draws with: `clear` makes all ten glossy and see-through, otherwise the two numbers as they are. Web: lookShine, lookOpaque
    var lookShine: Double { clear >= 0.5 ? 1 : shine }
    var lookOpaque: Double { clear >= 0.5 ? 0 : opaque }
    var lookEdgeClean: Double { lookOpaque > 0 && edgeClean >= 0.5 ? 1 : 0 }   // v2.61b: nothing to clean when it is see-through
}

/// v2.57 a new slime's signature (web `fx`): purple where it is rubbed (蝶豆), fog when shaken (汽水), a sesame core (湯圓), a caramel cap (布丁), pearls (珍奶). RGB 0...255.
struct SlimeFx {
    var purple: (Double, Double, Double)? = nil
    var fog: (Double, Double, Double)? = nil
    var core: (Double, Double, Double)? = nil
    var cap: (Double, Double, Double)? = nil
    var pearls = 0
    var isEmpty: Bool { purple == nil && fog == nil && core == nil && cap == nil && pearls == 0 }
}

struct SlimeColors {
    var base: UIColor
    var shade: UIColor
    var line: UIColor
    var light: UIColor
    var eye = UIColor(hex: 0x3A2614)   // v2.23 eyes
}

enum SlimeMaterial: String, CaseIterable, Identifiable {
    case jelly, mochi, clay

    var id: String { rawValue }

    var name: String {
        switch self {
        case .jelly: return "果凍"
        case .mochi: return "麻糬"
        case .clay: return "黏土"
        }
    }

    /// Same numbers as the prototype's PRESETS (2026-10-31, v2.2; press and dwell added 2026-11-01, v2.3;
    /// wriggle, clay memory and tentMem changed after 多米's device report on build 46, the old values are `v27`).
    var defaults: FeelParams {
        var p: FeelParams
        switch self {
        case .jelly:
            p = FeelParams(alpha: 0.34, damp: 0.986, yield: 1.5, creep: 0, recover: 1, grabR: 0.36, maxPull: 1.6,
                           lag: 0.05, wGlobal: 0.12, cSpace: 0.3, cRad: 0.42, upright: 0.004, anchor: 4,
                           areaGain: 0.6, gripRot: 3, life: 1, drift: 0.16, wriggle: 0.05, wander: 0.5,
                           floppy: 0.5, seed: 7)
            p.pressArea = 0.04; p.pressSpread = 0.06; p.pressSink = 0.2; p.pressBounce = 0.3   // v2.16
            p.slide = 0.6   // v2.21
            p.inertiaHz = 3.2; p.inertiaZ = 0.16; p.tickSharp = 0.45; p.popCount = 4; p.popDecay = 0.55; p.popSharp = 0.5   // v2.25
        case .mochi:
            p = FeelParams(alpha: 0.28, damp: 0.966, yield: 0.14, creep: 0.9, recover: 0.18, grabR: 0.32, maxPull: 1.8,
                           lag: 0.08, wGlobal: 0.10, cSpace: 0.3, cRad: 0.45, upright: 0.004, anchor: 4,
                           areaGain: 0.6, gripRot: 3, life: 1, drift: 0.16, wriggle: 0.05, wander: 0.5,
                           floppy: 0.55, seed: 7)
            p.pressArea = 0.05; p.pressSpread = 0.08; p.pressSink = 0.45; p.pressBounce = 0.6   // v2.16
            p.slide = 0.9   // v2.21
            p.inertiaHz = 2.6; p.inertiaZ = 0.26; p.tickSharp = 0.3; p.popCount = 3; p.popDecay = 0.45; p.popSharp = 0.4   // v2.25
        case .clay:
            // clay remembers at once, tentacles too; the mark relaxes slowly: half in about 15 s (v2.14, 多米 build 59: it sprang back
            // too fast; v2.8 to v2.13 recover 0.3, about 10 s)
            // 多米 11-16, tuned on the phone's feel desk (v2.39): alpha 0.40 → 0.18, lag 0.12 → 0.22, pressSink 0.8 → 0.2; the other six knobs he left where they were
            p = FeelParams(alpha: 0.18, damp: 0.940, yield: 0.05, creep: 6, recover: 0.05, grabR: 0.32, maxPull: 7,
                           lag: 0.22, wGlobal: 0.08, cSpace: 0.3, cRad: 0.45, upright: 0.002, anchor: 4,
                           areaGain: 0.5, gripRot: 3, life: 0.8, drift: 0.14, wriggle: 0.05, wander: 0.5,
                           floppy: 0.6, seed: 7)
            // free sculpting (多米 2026-11-01: pull it long, spread it flat like dough)
            p.dwellLo = 0; p.dwellHi = 0.1; p.tentMem = 1; p.nearMem = 1; p.memMax = 5; p.grabHold = 0.85   // v2.15: pull 7R, remember 5R (past about 8.5R long it shook; v2.13 20 and 12, v2.12 8 and 4)
            p.grabK = 1.2; p.nearR = 3   // pressFlat off since v2.12 (多米: take it out)
            p.slide = 4   // v2.54: 1.5 → 4 (stretched 1.5R the whole body was dragged along and it looked like it would not stretch any more)
            p.pressSink = 0.2   // 多米 11-16 (0.8 before)
        }
        return p
    }

    /// v2.7 control (before the build 46 device report): the starfish shape with five tentacles, travelling-wave wriggle,
    /// plain breathing; clay elastic for 0.2 s, tips spring back, 33 s to forget
    func applyV27(_ p: inout FeelParams) {
        p.off24()
        p.morph = 0; p.tentMem = 0
        p.slide = 0; p.drag = 0; p.dentFade = 10; p.imp = 0; p.e1 = 0; p.e2 = 0; p.e3 = 0; p.e4 = 0   // nothing of v2.20 to v2.22
        p.eyes = 0; p.sleep = 0; p.echo = 0; p.introSwim = 0   // nor v2.23
        p.camFollow = 0; p.wander = 0.22; p.emo = 0; p.life2 = 0   // before v2.17 the view stayed at home and the wander kept to the middle; no moods before v2.18, no v2.19 life
        p.noFlip = 0; p.gripUp = 0.2; p.homeCap = 0; p.fingerSolid = 0   // v2.29 guards are not for fixed tentacles
        p.scene = 0; p.skin = 0   // v2.7 floated, flat
        p.limbs = 5; p.pods = 0; p.jelly = 0; p.idlePace = 1; p.bodySize = 0.26; p.zoomMin = 1; p.camFill = 1; p.dens = 9; p.nearMem = 0; p.memMax = 1.1; p.grabHold = 0; p.grabK = 0.55; p.pressFlat = 0
        switch self {
        case .jelly, .mochi: p.wriggle = 0.07
        case .clay: p.wriggle = 0.06; p.dwellLo = 0.2; p.dwellHi = 0.6; p.creep = 3; p.recover = 0.03; p.maxPull = 2.0
        }
    }

    var colors: SlimeColors {
        switch self {
        case .jelly:
            return SlimeColors(base: UIColor(hex: 0x7FE0C2), shade: UIColor(hex: 0x4FB99E),
                               line: UIColor(hex: 0x2B6E61), light: UIColor(hex: 0xE9FFF7))
        case .mochi:
            return SlimeColors(base: UIColor(hex: 0xC9B6FF), shade: UIColor(hex: 0x9E86E6),
                               line: UIColor(hex: 0x4E3C8F), light: UIColor(hex: 0xFAF6FF))
        case .clay:
            return SlimeColors(base: UIColor(hex: 0xFFD96B), shade: UIColor(hex: 0xF0B64A),
                               line: UIColor(hex: 0x8B5A20), light: UIColor(hex: 0xFFF6D6))
        }
    }
}

/// v2.23 收集 (多米 11-02: all of them there from the start): four slimes, each its own material, colours, shape seed and personality
/// (rest length, how far it runs, voice pitch, eye size, how fast it trusts or turns wary, how soon it visits). Same table as the
/// prototype's SLIMES. Each keeps its own impression for this run; the chosen one is remembered across launches.
enum SlimeKind: String, CaseIterable, Identifiable {
    case honey, mint, taro, peach
    // v2.57 the six new ones (多米 11-22, web v2.52 overnight; ids as on the web). Always after the first four, which keep their places
    case xiancao, tangyuan, diedou, qishui, buding, zhennai
    var id: String { rawValue }
    var name: String { ["蜜蜜", "薄荷", "芋圓", "桃桃", "仙草", "湯圓", "蝶豆", "汽水", "布丁", "珍奶"][index] }
    var desc: String { ["黏土，慢吞吞，最愛睡", "果凍，好動，愛到處跑", "黏土，怕生，熟了很黏人", "黏土，愛撒嬌，常來找你",
                        "果凍偏硬，酷，慢熟", "麻糬，愛睡，肚子裡有芝麻餡", "果凍，怕生，揉過的地方會變紫", "最軟，停不下來，搖了會變霧", "最 Q，膽小，頭上有焦糖", "黏土，貪吃，肚子裡有珍珠"][index] }
    var material: SlimeMaterial { [.clay, .jelly, .clay, .clay, .jelly, .mochi, .jelly, .jelly, .jelly, .clay][index] }
    /// v2.57 one of the six new ones (v2.60: the look no longer tells them apart; nothing reads this now, kept as the mark)
    var isNew: Bool { index >= 4 }
    /// v2.57 each new one's signature, drawn on the body (web `fx`, `drawFx`)
    var fx: SlimeFx {
        switch self {
        case .tangyuan: return SlimeFx(core: (58, 52, 54))
        case .diedou: return SlimeFx(purple: (186, 104, 236))
        case .qishui: return SlimeFx(fog: (240, 248, 252))
        case .buding: return SlimeFx(cap: (168, 90, 30))
        case .zhennai: return SlimeFx(pearls: 5)
        default: return SlimeFx()
        }
    }
    /// v2.57 its own jelly skin numbers on top of the default skin (web `sk`): 仙草's edge does not go white
    var skin: (kEdge: Double?, kCore: Double?, glow: Double?)? {
        switch self {
        case .xiancao: return (0.16, 0.5, 0.5)
        case .zhennai: return (0.3, nil, nil)
        default: return nil
        }
    }   // v2.33: 芋圓 mochi → clay (clay is the reference feel; her material is still undecided, 麻糬 stays in the panel)
    private var index: Int { Self.allCases.firstIndex(of: self) ?? 0 }
    var colors: SlimeColors {
        switch self {
        case .honey: return SlimeColors(base: UIColor(hex: 0xFFD96B), shade: UIColor(hex: 0xF0B64A), line: UIColor(hex: 0x8B5A20), light: UIColor(hex: 0xFFF6D6), eye: UIColor(hex: 0x3A2614))
        case .mint: return SlimeColors(base: UIColor(hex: 0x9BEBD0), shade: UIColor(hex: 0x5CCBA8), line: UIColor(hex: 0x1F6B55), light: UIColor(hex: 0xECFFF8), eye: UIColor(hex: 0x173F33))
        case .taro: return SlimeColors(base: UIColor(hex: 0xD2C2FF), shade: UIColor(hex: 0xA691EC), line: UIColor(hex: 0x4F3A8C), light: UIColor(hex: 0xF6F1FF), eye: UIColor(hex: 0x2E2350))
        case .peach: return SlimeColors(base: UIColor(hex: 0xFFC2CF), shade: UIColor(hex: 0xF28FA6), line: UIColor(hex: 0x8C3349), light: UIColor(hex: 0xFFF0F3), eye: UIColor(hex: 0x4A1C28))
        case .xiancao: return SlimeColors(base: UIColor(hex: 0x4A3A32), shade: UIColor(hex: 0x2A201C), line: UIColor(hex: 0x120D0B), light: UIColor(hex: 0xF6EBD8), eye: UIColor(hex: 0xF6EBD8))
        case .tangyuan: return SlimeColors(base: UIColor(hex: 0xFBF8F4), shade: UIColor(hex: 0xDDD4CA), line: UIColor(hex: 0x7A6F68), light: UIColor(hex: 0xFFFFFF), eye: UIColor(hex: 0x2A2422))
        case .diedou: return SlimeColors(base: UIColor(hex: 0xA9BEFA), shade: UIColor(hex: 0x6C8EF0), line: UIColor(hex: 0x2A3C8F), light: UIColor(hex: 0xF2F6FF), eye: UIColor(hex: 0x1A2456))
        case .qishui: return SlimeColors(base: UIColor(hex: 0xBFE9F8), shade: UIColor(hex: 0x7FCDEB), line: UIColor(hex: 0x1F6F99), light: UIColor(hex: 0xFFFFFF), eye: UIColor(hex: 0x123E57))
        case .buding: return SlimeColors(base: UIColor(hex: 0xFFEFB0), shade: UIColor(hex: 0xF2CC5E), line: UIColor(hex: 0x7A4A14), light: UIColor(hex: 0xFFFBE6), eye: UIColor(hex: 0x4A2E12))
        case .zhennai: return SlimeColors(base: UIColor(hex: 0xF3DCC0), shade: UIColor(hex: 0xD9B48A), line: UIColor(hex: 0x7A5230), light: UIColor(hex: 0xFFF6E8), eye: UIColor(hex: 0x3A2412))
        }
    }
    /// Shape seed and personality on top of the material's numbers.
    func apply(_ p: inout FeelParams) {
        switch self {
        case .honey: p.seed = 7; p.restMul = 1.15; p.voicePitch = 1; p.dash = 0.2; p.eyeSize = 1; p.trRate = 1; p.wRate = 1; p.e4Mul = 1
        case .mint: p.seed = 12; p.restMul = 0.6; p.voicePitch = 1.12; p.dash = 0.45; p.eyeSize = 0.95; p.trRate = 1; p.wRate = 0.8; p.e4Mul = 1
        case .taro: p.seed = 4; p.restMul = 1; p.voicePitch = 0.94; p.dash = 0.2; p.eyeSize = 0.88; p.trRate = 0.7; p.wRate = 1.6; p.e4Mul = 0.7
        case .peach: p.seed = 19; p.restMul = 0.9; p.voicePitch = 1.18; p.dash = 0.25; p.eyeSize = 1.1; p.trRate = 1.6; p.wRate = 0.8; p.e4Mul = 0.6
        // v2.57 the six (web SLIMES `p`): the feel numbers are guesses from the design sheets, nobody has squeezed them yet
        case .xiancao: p.seed = 9; p.alpha = 0.42; p.damp = 0.975; p.inertiaZ = 0.24; p.restMul = 1.2; p.voicePitch = 0.86; p.dash = 0.15; p.eyeSize = 0.8; p.trRate = 0.5; p.wRate = 1; p.e4Mul = 1.6
        case .tangyuan: p.seed = 5; p.recover = 0.12; p.restMul = 1.35; p.voicePitch = 0.9; p.dash = 0.12; p.eyeSize = 1.15; p.trRate = 1.3; p.wRate = 0.6; p.e4Mul = 1; p.sleepAfter = 25
        case .diedou: p.seed = 2; p.restMul = 1; p.voicePitch = 1.05; p.dash = 0.25; p.eyeSize = 0.9; p.trRate = 0.5; p.wRate = 1.8; p.e4Mul = 0.5
        case .qishui: p.seed = 11; p.alpha = 0.22; p.damp = 0.988; p.inertiaHz = 2.4; p.inertiaZ = 0.12; p.shake = 1; p.glit = 0; p.settleT = 14; p.restMul = 0.5; p.voicePitch = 1.22; p.dash = 0.55; p.eyeSize = 1; p.trRate = 1.2; p.wRate = 0.8; p.e4Mul = 0.7   // no "water" material: a softened jelly; the shake clouds it but draws no glitter (多米 11-22: no bubbles, only the fog)
        case .buding: p.seed = 8; p.damp = 0.992; p.inertiaHz = 3.6; p.inertiaZ = 0.09; p.restMul = 0.9; p.voicePitch = 1.15; p.dash = 0.2; p.eyeSize = 1.1; p.trRate = 1; p.wRate = 1.4; p.e4Mul = 0.9; p.wFade = 0.12
        case .zhennai: p.seed = 6; p.restMul = 0.85; p.voicePitch = 0.96; p.dash = 0.3; p.eyeSize = 1; p.trRate = 1.1; p.wRate = 0.9; p.e4Mul = 0.8
        }
    }
}

/// One second-batch candidate (手感精修提案): a named change applied on top of the current numbers.
/// Blind test, one at a time: 存 1 (control) → 套候選 → 存 2 → 切 1／切 2.
struct Candidate: Identifiable {
    let id: Int
    let name: String
    let hint: String
    let apply: (inout FeelParams, SlimeMaterial) -> Void

    static let batch2: [Candidate] = [
        Candidate(id: 6, name: "6 黏滯 0.03", hint: "黏放在身體上，手指不延遲") { p, _ in p.lag = 0.03 },
        Candidate(id: 12, name: "12 觸覺跟變化率", hint: "手停就靜，一動就震") { p, _ in p.hapStatic = 0.25; p.hapRate = 0.75 },
        Candidate(id: 13, name: "13 質地微震", hint: "手指每走 8 點一下") { p, _ in p.tickSpacing = 8 },
        Candidate(id: 14, name: "14 啵依材質", hint: "黏土一下、麻糬兩下、果凍三下") { p, m in
            switch m {
            case .clay: p.popCount = 1; p.popSharp = 0.3
            case .mochi: p.popCount = 2; p.popGap = 0.1; p.popDecay = 0.4; p.popSharp = 0.4
            case .jelly: p.popCount = 3; p.popGap = 0.09; p.popDecay = 0.5; p.popSharp = 0.5
            }
        },
        Candidate(id: 18, name: "18 關停留門檻（對照）", hint: "抓住就記形，輕按也留痕") { p, _ in p.dwellLo = 0; p.dwellHi = 0 },
        Candidate(id: 19, name: "19 碰到時凍住", hint: "活物感停住，不縮回標準姿勢") { p, _ in p.idleFreeze = 1 },
        Candidate(id: 2, name: "2 偶發特別回彈", hint: "每 8 次放手多晃一下") { p, _ in p.specialEvery = 8 },
        Candidate(id: 9, name: "9 接觸面積壓力", hint: "指腹壓得越扁攤得越開") { p, _ in p.pressRadiusGain = 1 },
        Candidate(id: 41, name: "41 對照：關橫檔", hint: "v2.4 以前：觸手被壓縮會對折") { p, _ in p.tentRung = 0; p.tentAxis = 0 },
        Candidate(id: 21, name: "21 回家慢", hint: "放手後半秒飄回去，不過衝") { p, _ in p.homeK = 0.003 },
        Candidate(id: 22, name: "22 放手餘韻", hint: "放手後 0.25 秒多晃一下") { p, _ in p.afterglow = 0.25 },
        Candidate(id: 23, name: "23 呼吸", hint: "6 秒一次、吸短吐長、被摸久變深") { p, _ in p.breathT = 6; p.breathShape = 1; p.breathDeep = 1 },
        Candidate(id: 15, name: "15 銳利度跟材質", hint: "黏土 0.2、麻糬 0.3、果凍 0.45；拉 +0.15、壓 −0.05") { p, m in
            switch m {
            case .clay: p.hapSharp = 0.2
            case .mochi: p.hapSharp = 0.3
            case .jelly: p.hapSharp = 0.45
            }
            p.hapSharpStretch = 0.15; p.hapSharpSquash = 0.05
        },
        Candidate(id: 17, name: "17 啵走觸覺管線", hint: "放手音由 Core Haptics 播，跟震動同一個 pattern；要有錄音檔，第一次套了要重開 app") { p, _ in p.popViaHaptics = 1 },
        Candidate(id: 25, name: "25 拉太遠滑脫", hint: "拉過上限 1.2 倍 0.12 秒就脫手") { p, _ in p.slip = 1 },
        Candidate(id: 26, name: "26 放手黏連", hint: "慢抬手多黏 0.1 秒") { p, _ in p.stick = 0.1 },
        Candidate(id: 27, name: "27 局部鼓", hint: "面積壓力集中在手指附近") { p, _ in p.localArea = 1 },
        Candidate(id: 33, name: "33 家 0.46H", hint: "身體的家往下 6%") { p, _ in p.homeFrac = 0.46 },
        Candidate(id: 34, name: "34 描邊粗細", hint: "被壓的邊變粗、被拉的變細") { p, _ in p.inkVar = 1 },
        Candidate(id: 212, name: "v2.12 對照（鏡頭最遠 0.45）", hint: "鏡頭最遠 0.45、牆在最遠鏡頭的邊、鏡頭貼邊、每個半徑 9 個點、從中間抓拉不動；黏土拉伸 8R、記形 4R、回原形 0.3") { p, m in
            p.off24(); p.zoomMin = 0.45; p.camFill = 1; p.camCenter = 0; p.dens = 9; p.grabReach = 0; p.dent = 0; p.camFollow = 0; p.life2 = 0; p.slide = 0; if m == .clay { p.maxPull = 8; p.memMax = 4; p.recover = 0.3 } },
        Candidate(id: 219, name: "v2.19 對照（不跟手、凹痕慢、沒有印象）", hint: "拖的時候只變形不位移、點一下的凹痕跟回原形一起退（黏土 15 秒退一半）、不記得你怎麼對它") { p, _ in p.slide = 0; p.drag = 0; p.dentFade = 10; p.imp = 0; p.e1 = 0; p.e2 = 0; p.e3 = 0; p.e4 = 0 },
        Candidate(id: 226, name: "v2.26 對照（有眼睛、沒觸手、不變色）", hint: "回到 build 99 的外形：沒有固定觸手、有眼睛、不會變色") { p, _ in p.off27() },
        Candidate(id: 225, name: "v2.25 對照（一碰就抓、凹痕小）", hint: "手指一碰就抓，劃過身體會整團被帶走；凹痕整個在手指底下，揉和摸沒有痕跡，亮光只會轉") { p, _ in p.off26() },
        Candidate(id: 224, name: "v2.24 對照（放手一閃就回去、舊觸覺）", hint: "沒有參考形狀的慣性、拖到停不會衝過頭；連續觸覺跟變形量、沒有顆粒、按下去只有一下、呼嚕是兩下輕敲") { p, _ in p.off25() },
        Candidate(id: 223, name: "v2.23 對照（身體小、反應小、揉沒反應）", hint: "身體 0.22、抓著時畫面會滑、縮傾蹭看都小、揉要很慢才有反應、來回揉會逃") { p, _ in p.off24() },
        Candidate(id: 222, name: "v2.22 對照（沒眼睛、不睡、不回節奏、跳過來）", hint: "v2.23 的五樣一起關") { p, _ in p.eyes = 0; p.sleep = 0; p.echo = 0; p.introSwim = 0 },
        Candidate(id: 221, name: "v2.21 對照（不出聲）", hint: "沒有 E1 到 E4") { p, _ in p.e1 = 0; p.e2 = 0; p.e3 = 0; p.e4 = 0 },
        Candidate(id: 220, name: "v2.20 對照（整團只跟三成五）", hint: "單指拉只有三成五跟過去，果凍拉 1.6R 就頂住") { p, _ in p.slide = 0 },
        Candidate(id: 218, name: "v2.18 對照（沒有 v2.19 活物感）", hint: "一直在動、被拖著滑過去、一碰全停、固定節拍呼吸、隨機偽足、有影子") { p, _ in p.life2 = 0 },
        Candidate(id: 216, name: "v2.16 對照（鏡頭釘在中間）", hint: "鏡頭不跟、整隻一定在畫面裡、遊走只在中間一小塊") { p, _ in p.camFollow = 0 },
        Candidate(id: 215, name: "v2.15 對照（月牙凹痕）", hint: "按壓只有那一小塊攤開、凹痕是左上一彎硬邊月牙、0.08 秒到底，放手不分材質一樣淡") { p, _ in p.press2 = 0 },
        Candidate(id: 270, name: "v2.7 對照（舊外形）", hint: "海星外形五條觸手、固定行進波蠕動、正弦呼吸、黏土輕捏回彈") { p, m in m.applyV27(&p) },
    ]
}

/// One tunable slider in the hidden panel (prototype's `F`).
extension FeelParams {
    /// v2.24 off: the body, the camera, the reactions to the finger and the rub thresholds back to v2.23 (the older controls stack on this)
    /// v2.26 off: a touch is a grab, the small dent. v2.25 off: no inertia, the old haptics
    mutating func off27() {   // v2.27 off: no fixed tentacles, eyes back, no mood colour
        limbs = 0; tentSlip = 0; tentBump = 0; eyes = 1; moodColor = 0; tentAxis = 0.85   // ringed tentacles turn the axis off: it fights the finger (33 pt a frame in rough play); the slip and the length-only memory stop the folding
    }
    mutating func off26() {
        off27()
        strokeV = 0; dentTrail = 0; hiStretch = 0; localArea = 0; dentSize = 0.3
    }
    mutating func off25() {
        off26()
        inertiaHz = 0; dragSpring = 0; hapStatic = 1; hapSharpStretch = 0; popCount = 1; popDecay = 0.5; popSharp = 0.45
        tickSpacing = 0; tickMin = 0.1; tickMax = 0.3; tickSharp = 0.4; pressGrain = 0; purrRoll = 0
    }
    /// v2.52 灰盒 (《虛擬手感》3-2): the physics alone. Nothing it does by itself (breath, pods, walking, reactions, the impression, sleep),
    /// no dents, no decoration, the camera fixed, the sill's props put away; the sill and the walls stay (context is part of the feel).
    /// Laid over the numbers the physics uses while the measuring switch is on, and gone again when it is off. None of the material
    /// knobs (軟、黏滯、留形、彈、韌…) is in this set, so what is tuned in the grey box is the real material. Web: LAB.GREY.
    mutating func greyBox() {
        life = 0; life2 = 0; emo = 0; flee = 0; purr = 0; imp = 0; e1 = 0; e2 = 0; e3 = 0; e4 = 0; eyes = 0; sleep = 0; echo = 0
        pods = 0; jelly = 0; wriggle = 0; drift = 0; wander = 0; excite = 0; envRoam = 0
        dent = 0; dentTrail = 0; moodColor = 0; specks = 0; caustic = 0; bubbles = 0; shine = 0; glit = 0; shake = 0
        camFollow = 0; deco = 0; props = 0; intro = 0; introSwim = 0
        skin = 0   // the flat skin, which the view paints one grey
    }
    mutating func off24() {
        off25()
        bodySize = 0.22; followZone = 0.8; flinchAmp = 0.05; camFill = 0.7; camPad = 0.35; camGrip = 0; pressLocal = 0; leanMove = 0; leanAmp = 0.16; nuzAmp = 0.05
        gazeAmp = 0.06; dodge = 0; rubSpeed = 0; tickRev = 4; tickSeg = 0; tickFree = 3; reachV = 0
    }
}

struct TuneField: Identifiable {
    let key: WritableKeyPath<FeelParams, Double>
    let name: String
    let hint: String
    let range: ClosedRange<Double>
    let step: Double
    var section = "手感"
    var id: String { name }

    static let sections = ["手感", "按壓與記形", "活物感", "觸覺", "聲音", "外形", "這一批 v2.61", "這一批 v2.63"]

    static let all: [TuneField] = [
        TuneField(key: \.alpha, name: "回彈硬度", hint: "越大越快回去、越硬", range: 0.05...0.8, step: 0.01),
        TuneField(key: \.damp, name: "晃動阻尼", hint: "越小放手晃越久", range: 0.85...0.999, step: 0.001),
        TuneField(key: \.grabR, name: "抓取範圍（×半徑）", hint: "一指抓到多大一塊", range: 0.2...0.8, step: 0.01),
        TuneField(key: \.dent, name: "點一下留凹痕", hint: "1：按到身體就出現凹痕（左上一彎陰影），放手跟回原形同速淡掉；拉開 0.4R 以上算拉，凹痕收掉；0 關（v2.14）", range: 0...1, step: 1),
        TuneField(key: \.dentSize, name: "凹痕大小（×半徑）", hint: "凹痕最大半徑；v2.26 0.5，手指接觸面的 1.5 到 2 倍，手指外面看得到一圈（v2.25 0.3，整個在手指底下）", range: 0.1...0.9, step: 0.01),
        TuneField(key: \.intro, name: "開場跑過來", hint: "1：冷啟動時從遠處一跳一跳跑過來（約 2.8 秒），途中碰一下就直接到家；0 關（v2.17）", range: 0...1, step: 1),
        TuneField(key: \.camFollow, name: "鏡頭跟著走", hint: "1：史萊姆走離中心就慢慢跟過去，它可以跑出畫面；抓著時鏡頭不動。0 是 v2.16（鏡頭釘在家）", range: 0...1, step: 1),
        TuneField(key: \.followZone, name: "鏡頭開始追（×半個畫面）", hint: "史萊姆中心離平常位置多遠鏡頭才開始追；0.65 是 v2.24（身體變大），0.8 是 v2.18，v2.17 是 0.5", range: 0.1...1, step: 0.05),
        TuneField(key: \.followStop, name: "鏡頭追到哪停（×半個畫面）", hint: "追到史萊姆離平常位置這麼近就停，不再拉回正中間（v2.18 0.35；v2.17 是 0.06）", range: 0.02...0.8, step: 0.01),
        TuneField(key: \.emo, name: "情緒", hint: "1：舒服會攤軟呼嚕、開心會搖偽足小跳、被拉扯想逃、連戳會閃開；0 關（v2.18）", range: 0...1, step: 1),
        TuneField(key: \.flee, name: "逃多遠", hint: "被拉扯放手後衝出去的距離倍數（1＝半個到 0.8 個畫面寬，拉越久越遠）", range: 0...2, step: 0.1),
        TuneField(key: \.purr, name: "呼嚕", hint: "輕揉時規律輕震的強度倍數；0 關", range: 0...2, step: 0.1),
        TuneField(key: \.followSpeed, name: "鏡頭追的快慢", hint: "彈簧頻率（每秒弧度）；1.4 約 2 秒追上，越大越緊", range: 0.4...5, step: 0.1),
        TuneField(key: \.dash, name: "走遠的機率", hint: "每次遊走有多少機率走遠、走快（2.5 倍速），鏡頭跟不上就會跑出畫面一點", range: 0...1, step: 0.05),
        TuneField(key: \.specks, name: "背景光點", hint: "1：遠處固定的淡光點，鏡頭動的時候看得出來", range: 0...1, step: 1),
        TuneField(key: \.life2, name: "活物 v2.19", hint: "1：動靜分明、一縮一衝地走、碰著也在呼吸、晚一拍才縮、會喘、會探你碰的地方、沒有影子；0 回 v2.18（底下 A1 到 A8 只在這裡是 1 時有用）", range: 0...1, step: 1, section: "活物感"),
        TuneField(key: \.lifeRest, name: "A1 A2 休息與張望", hint: "1：大半時間休息（只呼吸、蠕動變小）；伸一條偽足探一個方向，七成往那邊走；0：v2.18 的走走停停、隨機偽足、偶爾抖", range: 0...1, step: 1, section: "活物感"),
        TuneField(key: \.lifeGait, name: "A3 一縮一衝", hint: "1：走路靠收縮出力（先蓄力、每一下收縮往前衝再滑停、路線彎、到了往前晃一下）；0：v2.18 平滑滑過去", range: 0...1, step: 1, section: "活物感"),
        TuneField(key: \.lifeHeld, name: "A4 碰著也在呼吸", hint: "1：抓著按著時呼吸照跑，按住不動時每次吸氣輕輕震一下；按在空白處不會整隻凍住；0：v2.18 一碰全停", range: 0...1, step: 1, section: "活物感"),
        TuneField(key: \.lifeFlinch, name: "A5 晚一拍才縮", hint: "1：碰到 0.1 到 0.25 秒後自己縮一下，連續碰會習慣、越縮越小；大力拉完放手甩一甩；0 關", range: 0...1, step: 1, section: "活物感"),
        TuneField(key: \.lifeBreath, name: "A6 呼吸像生理", hint: "1：每一下快慢不同、30 到 90 秒一次大口呼吸、跑完會喘；0：v2.18 固定節拍", range: 0...1, step: 1, section: "活物感"),
        TuneField(key: \.lifeAttend, name: "A7 探你碰的地方", hint: "1：放手後往你手指離開的地方探一下；碰它旁邊的空白處，它轉過去探（不走過去）；0 關", range: 0...1, step: 1, section: "活物感"),
        TuneField(key: \.shadow, name: "A8 影子", hint: "1：畫影子（v2.18）；0：不畫（v2.19）。活物總開關 0 時一律畫", range: 0...1, step: 1, section: "活物感"),
        TuneField(key: \.e1, name: "E1 它會出聲", hint: "v2.22：被戳「噗」、被揉「嗯～」、被扯「嗯嗯」、開心「噗咿」、討摸「嗯？」、搔癢咯咯笑、吞黏液「咕嚕」、打招呼；熟的高一點、戒的低一點；0 關", range: 0...1, step: 1, section: "活物感"),
        TuneField(key: \.e2, name: "E2 動作都有它的回應", hint: "1：點它，它朝你的手指傾一下；按著不動 0.35 秒，它往你的手指推一下（輕頂）；手指放著不動它慢慢蹭你；搔癢它扭來扭去，撥太久會掙脫；戒的時候被拖會扒著反方向；0 關", range: 0...1, step: 1, section: "活物感"),
        TuneField(key: \.e3, name: "E3 看得出印象", hint: "1：熟得快三到四倍；熟的圓一點、挺一點、顏色偏暖、呼吸慢；戒的扁一點、顏色淡一點；0 關", range: 0...1, step: 1, section: "活物感"),
        TuneField(key: \.e4, name: "E4 來找你", hint: "1：熟的時候你 10 到 20 秒沒碰它，它游到畫面前面揮一下偽足、哼一聲，再回去休息；一次打開最多 3 次；0 關（碰到不做清單的「主動找你」，多米 11-02 決定留著）", range: 0...1, step: 1, section: "活物感"),
        TuneField(key: \.eyes, name: "眼睛 v2.23", hint: "1：兩顆小眼睛（多米 11-02：加表情看看，只要眼睛）。看你的手指、會眨眼；被捏瞇起來、猛扯擠成 > <、呼嚕和開心彎成 ∩、睡著閉成 ∪、戒的時候睜大；0 回沒有臉", range: 0...1, step: 1, section: "活物感"),
        TuneField(key: \.sleep, name: "B2 睡著", hint: "1：40 秒沒人碰（含點空白處），休息時慢慢閉眼睡著：呼吸慢、深一點、攤軟、不走；碰它嚇醒（縮大一點、「嗯？」），手指放旁邊 1.2 秒慢慢醒；0 關", range: 0...1, step: 1, section: "活物感"),
        TuneField(key: \.echo, name: "C6 照你的節奏回你", hint: "1：在空白處用固定節奏點 2 到 8 下（間隔 0.12 到 1.2 秒），停下來後它照同樣的次數和節奏一縮一縮回你（每下「噗」、輕震）；你再點一樣的節奏，它開心；0 關", range: 0...1, step: 1, section: "活物感"),
        TuneField(key: \.leanAmp, name: "傾一下的幅度（×半徑）", hint: "點它、按著時朝手指傾的鼓包有多大；v2.24 0.28，v2.23 0.16", range: 0...0.5, step: 0.01, section: "活物感"),
        TuneField(key: \.leanMove, name: "傾的時候整團靠過去（×半徑）", hint: "傾一下時整團往手指挪多少再回來；v2.24 0.11，0 回 v2.23", range: 0...0.3, step: 0.01, section: "活物感"),
        TuneField(key: \.nuzAmp, name: "蹭的幅度（×半徑）", hint: "手指放著不動時它左右蹭多少；v2.24 0.12，v2.23 0.05", range: 0...0.25, step: 0.01, section: "活物感"),
        TuneField(key: \.gazeAmp, name: "看的幅度（×半徑）", hint: "看東西時整張臉在身上滑多少；v2.24 0.18，v2.23 0.06", range: 0...0.3, step: 0.01, section: "活物感"),
        TuneField(key: \.dodge, name: "臉躲手指（×半徑）", hint: "手指靠近臉時整張臉滑開多少，不被手指蓋住；0 關（v2.23）", range: 0...0.4, step: 0.01, section: "活物感"),
        TuneField(key: \.rubSpeed, name: "揉的速度上限（公分／秒）", hint: "手指每秒幾公分以內都算舒服的揉（v2.24 12）；0 回 v2.23（約 2.9 公分，一般手速的揉沒反應）", range: 0...30, step: 1, section: "活物感"),
        TuneField(key: \.tickRev, name: "搔癢要幾次折返", hint: "1 秒內手指折返幾次算搔癢；v2.24 6（一秒 3 趟），v2.23 4", range: 2...12, step: 1, section: "活物感"),
        TuneField(key: \.tickSeg, name: "搔癢的幅度上限（點）", hint: "手指每一段超過這麼長就算揉、不算搔癢；v2.24 48（約 8 毫米）；0 不看幅度（v2.23）", range: 0...120, step: 1, section: "活物感"),
        TuneField(key: \.tickFree, name: "撥多久掙脫（秒）", hint: "搔癢撥多久它掙脫，最後 2 秒先抗議；v2.24 6，v2.23 3", range: 1...15, step: 0.5, section: "活物感"),
        TuneField(key: \.introSwim, name: "開場游過來", hint: "1：開場從畫面右邊外面一縮一衝游進來，到家看著你、揮一下偽足、打招呼（換史萊姆時也是）；0：v2.17 從遠處跳過來", range: 0...1, step: 1, section: "活物感"),
        TuneField(key: \.heldBreath, name: "碰著時的呼吸幅度", hint: "抓著、按著時呼吸是平常的幾成（手指壓住的中間會吃掉一點，0.75 看起來約六成）", range: 0...1, step: 0.05, section: "活物感"),
        TuneField(key: \.restWrig, name: "休息時的蠕動", hint: "休息時蠕動是原本的幾成（v2.19 三成；張望六成、走路五成）", range: 0...1, step: 0.05, section: "活物感"),
        TuneField(key: \.flinchAmp, name: "縮一下的幅度", hint: "被碰時自己縮多少（休息時再乘 1.2、舒服時減半，連續碰每次乘 0.55，放著 7 秒恢復）；v2.24 0.1，v2.23 0.05", range: 0...0.25, step: 0.01, section: "活物感"),
        TuneField(key: \.slide, name: "D1' 拉到多長開始整團走（×半徑）", hint: "v2.21 拉力：先被拉長，拉長到這附近再拉就整團被拖著走（果凍 0.6、麻糬 0.9、黏土 1.5，v2.54 起 4）；兩指往兩邊拉不會被拖走、照樣拉很長；0 回 v2.20（整團只跟三成五）", range: 0...8, step: 0.1),
        TuneField(key: \.drag, name: "D1 拖著走", hint: "抓著時身體的原位跟著手指移幾成（v2.20 0.35，約 0.25 秒跟上；放手停在被拖到的地方，甩著放手再滑一小段）；0 是 v2.19（只變形不位移）", range: 0...1, step: 0.05),
        TuneField(key: \.dentFade, name: "D2 凹痕退的時間（秒）", hint: "點一下放手後凹痕多久退完（按越久越慢，按 1 秒以上 2.5 倍）；10 是 v2.19（跟回原形一起退，黏土 15 秒退一半）", range: 0.2...10, step: 0.1, section: "按壓與記形"),
        TuneField(key: \.imp, name: "印象 v2.20", hint: "1：它記得你這一次怎麼對它（熟、戒），關掉 app 或背景 10 分鐘歸零；底下 C1 到 C5 只在這裡是 1、活物 v2.19 也是 1 時有用；0 回 v2.19", range: 0...1, step: 1, section: "活物感"),
        TuneField(key: \.impC1, name: "C1 手指放旁邊", hint: "1：手指按在它旁邊不動，熟的時候游過來用偽足碰你的手指（很熟時整團貼過來蹭），碰到時輕震一下；戒的時候退開、偽足指著你；0：v2.19 只探", range: 0...1, step: 1, section: "活物感"),
        TuneField(key: \.impC2, name: "C2 逗它", hint: "1：手指在旁邊慢慢移，偽足跟著轉；熟的時候追，你停下來它撲過去；不熟時手指動太快它嚇一下；0 關", range: 0...1, step: 1, section: "活物感"),
        TuneField(key: \.impC3, name: "C3 跟手看印象", hint: "1：拖它時熟的跟得多（五成）、戒的跟得少（一成五），戒很高時拖久了會掙脫；用力扯想逃時跟得少；0：一律照 D1", range: 0...1, step: 1, section: "活物感"),
        TuneField(key: \.impC4, name: "C4 討摸", hint: "1：揉到呼嚕放手後，它往你手指離開的地方伸偽足、挪過去；5 秒內再碰，呼嚕來得快；0 關", range: 0...1, step: 1, section: "活物感"),
        TuneField(key: \.impC5, name: "C5 被粗暴之後", hint: "1：戒高時被碰縮得大、縮得早，溫柔碰幾次慢慢放心；沒碰時熟的往你最後摸的地方探、戒的往反方向；0 關", range: 0...1, step: 1, section: "活物感"),
        TuneField(key: \.press2, name: "按壓真實版", hint: "1：v2.16 按壓（整團壓薄攤開、凹痕跟著身體變形、先快後慢地沉、放手依材質回彈、亮光被擠開、影子變深）；0 是 v2.15 的月牙凹痕", range: 0...1, step: 1),
        TuneField(key: \.pressArea, name: "壓薄攤開：面積", hint: "按到底時整團面積多幾成（從正面按下去前後變薄，看起來變大一圈）", range: 0...0.15, step: 0.01),
        TuneField(key: \.pressSpread, name: "壓薄攤開：手指附近（×半徑）", hint: "手指周圍那圈往外推多少（離手指約 0.3R 推最多）", range: 0...0.3, step: 0.01),
        TuneField(key: \.pressSink, name: "下沉時間（秒）", hint: "40 毫秒先到六成，剩下的多久沉到底；黏土 0.8、果凍 0.2", range: 0.05...2, step: 0.05),
        TuneField(key: \.pressBounce, name: "放手回彈阻尼", hint: "1 不彈（黏土）；越小放手彈越多下（果凍 0.3）", range: 0.1...1, step: 0.05),
        TuneField(key: \.grabReach, name: "從中間抓也拉得動", hint: "1：從身體裡面抓、範圍碰不到外圈時，手指一動往拉的方向補抓一條到外圈；0 是 v2.13（從中間拉沒反應）", range: 0...1, step: 1),
        TuneField(key: \.maxPull, name: "拉伸上限（×半徑）", hint: "最多拉多遠（軟上限）；黏土 7（v2.15，超過約 8.5R 會抖），v2.13 是 20，v2.12 是 8", range: 0.6...30, step: 0.1),
        TuneField(key: \.lag, name: "黏滯", hint: "跟手的延遲感（秒）；候選 6 是 0.03", range: 0...0.3, step: 0.01),
        TuneField(key: \.wGlobal, name: "整體性", hint: "越大整團越像一塊", range: 0...1, step: 0.01),
        TuneField(key: \.cSpace, name: "區塊間距（×半徑）", hint: "越小區塊越多越軟", range: 0.15...0.7, step: 0.05),
        TuneField(key: \.cRad, name: "區塊半徑（×半徑）", hint: "越小越軟、越容易拉出一塊", range: 0.25...1, step: 0.01),
        TuneField(key: \.upright, name: "回正", hint: "放手後轉回頭朝上的速度", range: 0...0.02, step: 0.001),
        TuneField(key: \.anchor, name: "抓著時的定身", hint: "越大身體越不會整團跟著手走、轉掉", range: 1...8, step: 0.5),
        TuneField(key: \.areaGain, name: "面積壓力", hint: "壓扁時旁邊鼓出來的程度", range: 0...1.5, step: 0.05),
        TuneField(key: \.gripRot, name: "抓著時不轉", hint: "越大拉它時身體越不會歪掉", range: 1...8, step: 0.5),
        TuneField(key: \.tentRung, name: "觸手橫檔", hint: "兩邊成對的粒子不能翻到對面、寬度不低於靜止的幾成；0 關＝v2.4 以前（第 41 條）", range: 0...0.9, step: 0.05),
        TuneField(key: \.tentAxis, name: "觸手中軸不折返", hint: "中軸每一節在上一節方向上至少前進靜止節距的幾成；0 關（第 41 條）", range: 0...1, step: 0.05),
        TuneField(key: \.homeK, name: "回家彈簧", hint: "放手後身體飄回家的彈簧（每小步）；0.02 原本，候選 21 是 0.003", range: 0.002...0.04, step: 0.001),
        TuneField(key: \.afterglow, name: "放手餘韻（秒）", hint: "放手後幾秒內阻尼從 0.975 回到設定值，多晃一下；0 關，候選 22 是 0.25", range: 0...0.6, step: 0.05),
        TuneField(key: \.pinchSquish, name: "兩指捏 squish", hint: "1：兩指靠近到起始距離 60% 發一次，之後每再縮 15% 一次（第 24 條）", range: 0...1, step: 1),
        TuneField(key: \.slip, name: "拉太遠滑脫", hint: "1：拉超過上限 1.2 倍持續 0.12 秒就脫手（候選 25）", range: 0...1, step: 1),
        TuneField(key: \.pairMax, name: "兩指拉開上限（v2.38）", hint: "兩根抓著的手指之間最多拉開幾個半徑，到六成開始越來越拉不動；0 回 v2.37（兩指沒有上限，往反方向拉會拉到 9 個半徑打結）", range: 0...12, step: 0.1),
        TuneField(key: \.tear, name: "拉太開撕開（v2.38）", hint: "1：兩指實際拉開超過上限的撕開門檻倍、持續 0.12 秒，離身體遠的那根脫手，最重的放手音；0 只有軟上限", range: 0...1, step: 1),
        TuneField(key: \.tearK, name: "撕開門檻（v2.38）", hint: "手指實際拉開到兩指上限的幾倍才撕開", range: 1...2.5, step: 0.05),
        TuneField(key: \.flipMem, name: "翻面不記形（v2.38）", hint: "1：身體裡翻面的地方不記形，記住的形狀有翻面時照 0.3 退；0 回 v2.37", range: 0...1, step: 1),
        TuneField(key: \.homeClamp, name: "家不准拖出房間（v2.38）", hint: "1：整隻被拖著走時，家夾在房間裡；0 回 v2.37（往窗台下面拉，整隻被壓成一條線）", range: 0...1, step: 1),
        TuneField(key: \.clingTidy, name: "扭著不黏牆（v2.38）", hint: "1：放手時身體超出窗框 0.8 個半徑、或外框交叉，就不黏窗框；0 回 v2.37", range: 0...1, step: 1),
        TuneField(key: \.stick, name: "放手黏連（秒）", hint: "慢抬手時抓取多保持幾秒；0 關，候選 26 是 0.1", range: 0...0.2, step: 0.02),
        TuneField(key: \.localArea, name: "局部面積壓力", hint: "面積壓力往手指附近集中的程度；0 全身平均，候選 27 是 1", range: 0...2, step: 0.1),

        TuneField(key: \.pressBase, name: "按壓攤開（×半徑）", hint: "按下去那塊往四周攤多少（看得到的約一半）", range: 0...0.3, step: 0.01, section: "按壓與記形"),
        TuneField(key: \.pressHold, name: "按住再攤（×半徑）", hint: "按住不動時再多攤多少", range: 0...0.3, step: 0.01, section: "按壓與記形"),
        TuneField(key: \.pressHoldTime, name: "按壓下沉時間", hint: "按住多久攤到最深（秒）", range: 0.1...2, step: 0.05, section: "按壓與記形"),
        TuneField(key: \.pressRise, name: "按壓時間常數", hint: "攤開多快到位（秒）", range: 0.01...0.3, step: 0.01, section: "按壓與記形"),
        TuneField(key: \.pressFirst, name: "按壓第一幀比例", hint: "按下那一幀先到目標的幾成", range: 0...1, step: 0.05, section: "按壓與記形"),
        TuneField(key: \.pressRadiusGain, name: "接觸面積壓力", hint: "指腹壓扁（majorRadius 變大）再多攤多少；0 關，候選 9 是 1", range: 0...3, step: 0.1, section: "按壓與記形"),
        TuneField(key: \.yield, name: "定型門檻（×半徑）", hint: "變形超過這個才開始留形", range: 0.02...1.5, step: 0.01, section: "按壓與記形"),
        TuneField(key: \.creep, name: "定型速度", hint: "揉多快記住新形狀（往外拉長時改用「拉長時定型速度」）", range: 0...40, step: 0.5, section: "按壓與記形"),
        TuneField(key: \.dwellLo, name: "定型停留起點", hint: "抓住幾秒後開始記形（秒）", range: 0...1, step: 0.05, section: "按壓與記形"),
        TuneField(key: \.dwellHi, name: "定型停留終點", hint: "抓住幾秒後全速記形（秒）", range: 0...2, step: 0.05, section: "按壓與記形"),
        TuneField(key: \.recover, name: "回原形速度", hint: "放著多快變回原樣；黏土 0.05（v2.14，放手 2 秒退一成、15 秒退一半），v2.8 到 v2.13 是 0.3，v2.7 是 0.03", range: 0...1.5, step: 0.01, section: "按壓與記形"),
        TuneField(key: \.grabK, name: "抓住的力道", hint: "被抓那塊每小步往手指靠幾成（再乘距離權重）；以前 0.55，黏土 1.2 整塊跟手", range: 0.2...2, step: 0.05, section: "按壓與記形"),
        TuneField(key: \.nearR, name: "記形範圍（×半徑）", hint: "手指附近多大範圍用整身座標記形；黏土 3＝整團，拉出來的整條都記住（v2.54 往外拉長時改用「拉長時記形範圍」）", range: 0.5...12, step: 0.1, section: "按壓與記形"),
        TuneField(key: \.pressFlat, name: "一壓就攤平", hint: "1：從上半部往下壓時下面有看不見的桌面，壓多少扁多少；v2.12 起預設關", range: 0...1, step: 1, section: "按壓與記形"),
        TuneField(key: \.zoomMin, name: "鏡頭最遠", hint: "形狀變大時畫面自動縮小，最小縮到幾倍；0 不限制、也沒有牆（多米：鏡頭無限拉遠），1 關，v2.12 是 0.45", range: 0...1, step: 0.05, section: "按壓與記形"),
        TuneField(key: \.inertiaHz, name: "回彈每秒幾下", hint: "放手、甩、拖到一半停時整團晃的快慢；3 約 0.17 秒彈完第一下；0 回 v2.24（33 毫秒彈完）", range: 0...6, step: 0.1),
        TuneField(key: \.inertiaZ, name: "回彈阻尼比", hint: "越小晃越多下（果凍 0.16、麻糬 0.26、黏土 0.3）", range: 0.05...1, step: 0.01),
        TuneField(key: \.inertiaCarry, name: "放手帶多少速度", hint: "放手那一刻身體相對重心的速度帶進回彈的比例", range: 0...1, step: 0.05),
        TuneField(key: \.pressPull, name: "拉開了就不攤 v2.47", hint: "1（多米 11-16：拉一拉變尖、拉太長會抽動）：手指離開落點 0.15R 起，按壓的「往外攤開」淡掉，0.6R 淡完；0 回 v2.46（拉長按著不動，手指底下那塊被撕開、一直跳）", range: 0...1, step: 1),
        TuneField(key: \.dragCalm, name: "拉得遠就不衝過頭 v2.47", hint: "1：整隻跟著手指走的那條彈簧，要跟的距離 1R 起阻尼加大、3R 以上不過衝（原本拉 3.5R 整隻衝過去 60 點再退回來，手沒動牠自己跳一秒）；0 回 v2.46", range: 0...1, step: 1),
        TuneField(key: \.memSmooth, name: "留下的形狀抹圓 v2.47", hint: "記住的形狀裡，刺和細鬚每秒消掉多少（4：一根刺約 0.3 秒變圓頭；整條拉長、整片壓扁這種大形狀幾乎不動）；0 關（v2.46）", range: 0...12, step: 0.5),
        TuneField(key: \.stretchCap, name: "每一小塊最多拉幾倍 v2.48", hint: "（多米 11-16：拉一拉就破圖，要從源頭解決）身體網格的每條邊最長拉到原形的幾倍。拉滿了就輪到旁邊的拉，整條平均變長；0 關（v2.47）", range: 0...5, step: 0.25),
        TuneField(key: \.memCap, name: "記住的形狀最多拉幾倍 v2.48", hint: "記住的形狀每條邊最長是原形的幾倍（要比上一條小）；0 關", range: 0...4, step: 0.2),
        TuneField(key: \.capLo, name: "每一小塊最多壓到幾成 v2.48", hint: "每條邊最短壓到原形的幾成", range: 0.1...0.9, step: 0.05),
        TuneField(key: \.capIter, name: "上下限每小步做幾輪 v2.48", hint: "跟防翻面一起做幾輪；沒有超過的就提早停", range: 1...8, step: 1),
        TuneField(key: \.capSlip, name: "手指讓多少 v2.48", hint: "被抓的那塊被上下限、窗台、牆擋回來多少，手指的有效位置就退多少的幾倍；0 關", range: 0...8, step: 0.5),
        TuneField(key: \.capVel, name: "上下限的修正留多少速度 v2.48", hint: "0：修正不留速度；1：留著（會來回彈）", range: 0...1, step: 0.25),
        TuneField(key: \.capGrabW, name: "拉滿時被抓的那塊讓多少 v2.48", hint: "邊拉到上限時，被手指抓著的那顆動多少（另一顆是 1）", range: 0...1, step: 0.05),
        TuneField(key: \.capPushW, name: "擠滿時被抓的那塊讓多少 v2.48", hint: "邊壓到下限、三角形快翻面時，被手指抓著的那顆動多少", range: 0...1, step: 0.05),
        TuneField(key: \.tremble, name: "被扯會發抖 v2.48", hint: "0：被扯、被戳時輪廓不再發抖（多米 11-16：拉太長莫名抽動，像壞掉）；1 回 v2.47", range: 0...1, step: 1),
        TuneField(key: \.struggle, name: "被扯會扒 v2.48", hint: "0：被扯時不再往反方向伸兩條偽足扒；1 回 v2.47", range: 0...1, step: 1),
        TuneField(key: \.inertiaDrag, name: "拖動的慣性", hint: "抓著拖時整團加速度反過來推參考形狀，離手指越遠推越多；0 關", range: 0...6, step: 0.1),
        TuneField(key: \.dragSpring, name: "拖到停會衝過頭", hint: "整團跟手指用帶慣性的彈簧（阻尼比，0.5 衝過頭約一成六，越小衝越多）；0 回 v2.24", range: 0...1, step: 0.05),
        TuneField(key: \.dragHz, name: "整團跟上的快慢", hint: "上面那條彈簧每秒幾下", range: 0.5...4, step: 0.1),
        TuneField(key: \.strokeV, name: "摸的速度門檻（點／秒）", hint: "手指落下這麼快就在移動、方向不是往外，算摸（手指滑過去，不釘粒子）；0 回 v2.25（一碰就抓）", range: 0...600, step: 10),
        TuneField(key: \.strokeT, name: "摸的判斷時間（秒）", hint: "手指落下多久內要走到上面那個速度；越短越不容易判成摸", range: 0.03...0.2, step: 0.01),
        TuneField(key: \.strokeStop, name: "摸到一半變抓（點／秒）", hint: "摸的時候慢過這個速度 0.12 秒，手指底下那塊就被抓住", range: 10...200, step: 5),
        TuneField(key: \.strokeCarry, name: "摸時整團被帶多遠（×半徑）", hint: "手指劃過去整團最多被帶多遠，之後自己回來", range: 0...0.6, step: 0.02),
        TuneField(key: \.strokePush, name: "摸時皮膚被推開", hint: "手指把旁邊的皮膚往外推多少", range: 0...100, step: 1),
        TuneField(key: \.strokeFric, name: "摸時皮膚被帶著走", hint: "手指帶著旁邊的皮膚走多少；0 像滑過冰", range: 0...60, step: 1),
        TuneField(key: \.dentTrail, name: "手指走過的痕跡（秒）", hint: "揉、摸的時候留下的痕跡多久淡掉；0 沒有痕跡", range: 0...1.5, step: 0.05),
        TuneField(key: \.hiStretch, name: "亮光跟著拉伸", hint: "1：身體被拉長、壓扁，白色亮光跟著變形；0 亮光只會轉", range: 0...1, step: 1),
        TuneField(key: \.camGrip, name: "手指底下不滑", hint: "1：抓著時畫面不在手指底下滑（只在拉很長時以手指為中心拉遠，放手才把形狀挪回畫面）；0：v2.23（拉開 0.5R 就對準形狀中心）", range: 0...1, step: 1, section: "按壓與記形"),
        TuneField(key: \.camPad, name: "鏡頭框形狀的邊（×半徑）", hint: "框形狀時四周多留多少；v2.24 0.2，v2.23 0.35", range: 0.05...0.5, step: 0.01, section: "按壓與記形"),
        TuneField(key: \.pressLocal, name: "只按時手指附近才記形", hint: "1：手指還沒拖開時只有手指附近記形（按久了對面的邊不會折）；0：整團都記（v2.23）", range: 0...1, step: 1, section: "按壓與記形"),
        TuneField(key: \.reachV, name: "揉的時候不補抓", hint: "1：直直往外拉才把外圈帶出去，揉的時候不會；0：手指動 0.12R 就補抓（v2.23，揉的時候外框會折）", range: 0...1, step: 1, section: "按壓與記形"),
        TuneField(key: \.camFill, name: "鏡頭留邊", hint: "抓著時形狀最多佔畫面幾成就開始退；1 貼邊（v2.12），越小留越多邊給手指繼續拉；沒碰時都貼邊；v2.24 0.85，v2.23 0.7", range: 0.3...1, step: 0.05, section: "按壓與記形"),
        TuneField(key: \.camCenter, name: "鏡頭對準形狀", hint: "1：形狀大到要縮鏡頭、或抓著拉開時，鏡頭對準形狀中心，兩邊都留邊，再抓那一端還有地方拉（v2.15 預設）；0 對準家", range: 0...1, step: 1, section: "按壓與記形"),
        TuneField(key: \.dens, name: "點的密度", hint: "每個半徑幾個點；12（v2.13），以前 9：拉到 8R 時外圈太疏、尾端交叉。越密越吃效能，改了會重建身體", range: 6...14, step: 1, section: "按壓與記形"),
        TuneField(key: \.flatMin, name: "最扁", hint: "壓到最扁是原本高度的幾成", range: 0.15...0.8, step: 0.05, section: "按壓與記形"),
        TuneField(key: \.ringGuard, name: "邊不能穿邊", hint: "1：邊界的點不能穿過另一段邊界（多米：交叉時像快壞掉）；0 關", range: 0...1, step: 1),
        TuneField(key: \.noFlip, name: "防打結（三角形不翻面）", hint: "身體裡每個小三角形的面積不能小於靜止的這麼多倍，記住的形狀也一樣（v2.29，多米：拉扯常常打結）；0 關（v2.28）", range: 0...0.5, step: 0.01),
        TuneField(key: \.gripUp, name: "抓著時回正的上限", hint: "抓著時每小步最多轉回頭朝上多少；太大的話身體轉不動，被拉過去的那條只能纏在身上（v2.29 0.004；以前 0.2）", range: 0...0.2, step: 0.001),
        TuneField(key: \.homeCap, name: "整團跟手指的速度上限（×格距／小步）", hint: "整團被拖著走時，每小步最多移這麼多；太快的話手指附近那圈會一下被剪開、整片翻面（v2.29 0.5；0 不限）", range: 0...3, step: 0.1),
        TuneField(key: \.softWall, name: "畫面邊是軟的", hint: "1：窗台上身體碰到畫面左右上緣可以超出去一點，慢慢被推回來；被壓在牆上不會擠成一條線、摺出結（v2.29）；0 硬牆", range: 0...1, step: 1),
        TuneField(key: \.shake, name: "搖晃沉澱 v2.31", hint: "1：搖手機牠在碗裡彈一下、肚子裡的亮粉揚起來變霧；放著不動約 30 秒沉澱，清透、發光、睜眼、叮一聲；捏牠也會攪起一點（多米 11-07：像雪花球，動了會濁、靜了會清）；0 關", range: 0...1, step: 1, section: "活物感"),
        TuneField(key: \.shakeN, name: "幾下搖滿", hint: "搖這麼多下亮粉就全揚起來，再用力甩也不會更多", range: 1...6, step: 1, section: "活物感"),
        TuneField(key: \.settleT, name: "沉澱秒數", hint: "完全不動的話，從全濁到全清大約幾秒", range: 10...60, step: 1, section: "活物感"),
        TuneField(key: \.calmBreathT, name: "沉澱時的呼吸週期（秒）", hint: "亮粉在沉的時候牠一次呼吸幾秒（10 秒＝每分鐘 6 次），帶著你慢下來", range: 4...15, step: 0.5, section: "活物感"),
        TuneField(key: \.stirRate, name: "捏著時攪起的速度", hint: "抓著、揉著時每秒攪起多少亮粉（0.12：揉 5 秒約六成濁）；0 只有搖才會濁", range: 0...0.5, step: 0.01, section: "活物感"),
        TuneField(key: \.shakeKick, name: "搖時牠在碗裡彈的力道", hint: "每搖一下給牠的速度倍數，有上限，躺著用力甩也不會飛出碗；0 只有亮粉動", range: 0...2, step: 0.1, section: "活物感"),
        TuneField(key: \.cling, name: "黏牆（v2.36）", hint: "1（多米 11-07：像章魚黏在牆上，捏下來會抵抗）：把牠慢慢放在窗框旁邊會黏住，貼牆那圈像吸盤，8 到 15 秒後自己爬下來；拉離牆超過門檻（熟 1 個半徑、戒 1.5 個）吸盤一顆一顆剝開，剩四分之一時整個揣下來；剝一半放手會黏回去；0 回 v2.30 的 1.6 秒", range: 0...1, step: 1, section: "活物感"),
        TuneField(key: \.deco, name: "擺飾（v2.37）", hint: "多米 11-08 生的那組：1 窗台中間布墊、左端蠟燭（夜晚點著）、窗框右上風鈴（搖手機會晃）；2 再加右端書堆、窗框左上晴天娃娃；3 書堆換成玻璃罐；0 全部拿掉", range: 0...3, step: 1, section: "外形"),
        TuneField(key: \.excite, name: "興奮（v2.32）", hint: "-1 自動：今天走路帶回 0 或 1 件平常、2 件有精神、3 件很興奮；0 到 3 假裝帶回幾件。興奮時休息短、走得遠、多張望、多看你、多來找你、呼嚕來得快、眨眼快、回家落地小跳；抓著時一字不動", range: -1...3, step: 1, section: "活物感"),
        TuneField(key: \.one, name: "一隻為主（v2.33）", hint: "1（多米 11-07：陪伴寵物只養一隻，留芋圓）：底部那排四隻不顯示，一開始就是芋圓；0 四隻回來（重開 app 才換回上次選的那隻）", range: 0...1, step: 1, section: "活物感"),
        TuneField(key: \.trKeep, name: "熟留下來（v2.34）", hint: "1（多米 11-07：陪伴寵物要記得你）：熟每隻分開存在這支手機，關掉、隔天再開都在；戒照樣每次歸零，背景 10 分鐘只歸零戒；0 回 v2.33，背景 10 分鐘熟跟戒都歸零", range: 0...1, step: 1, section: "活物感"),
        TuneField(key: \.shakeG, name: "搖的門檻（公尺／秒²）", hint: "手機加速度超過這個算搖了一下；躺著輕輕晃也要搖得到，走路、拿起手機不會誤觸", range: 6...25, step: 0.5, section: "活物感"),
        TuneField(key: \.glitN, name: "亮粉顆數", hint: "肚子裡幾顆", range: 40...300, step: 10, section: "活物感"),
        TuneField(key: \.envRoam, name: "牠自己出門", hint: "窗台上牠自己爬出碗、在窗台上走、爬回碗的機率倍數（v2.30）；0 就一直待在原地", range: 0...2, step: 0.1, section: "活物感"),
        TuneField(key: \.round, name: "外框圓角 v2.47", hint: "果凍皮的外框用模糊過的遮罩切：尖角變圓頭、凹進去的地方像水一樣連起來。數字是圓角大小的倍數（1 約 0.07 個半徑）；0 關（v2.46，照粒子外框畫）", range: 0...2.5, step: 0.1, section: "外形"),
        TuneField(key: \.glit, name: "肚子裡的亮粉 v2.47", hint: "0（多米 11-16：身體裡的粉末去掉）：不畫亮粉，摸牠也不會變霧；搖手機牠照樣彈、照樣慢呼吸。1 回 v2.46", range: 0...1, step: 1, section: "外形"),
        TuneField(key: \.water, name: "看得出是水 v2.49", hint: "（多米 11-16：要看得出來是由水份組成的）1：身體後面的窗框、窗台透過牠看得到而且被彎曲，薄的地方幾乎沒顏色；0 回 v2.48 的皮。要「水潤」開著才有", range: 0...1, step: 0.1),
        TuneField(key: \.refr, name: "水把後面的東西彎多少 v2.49", hint: "透過身體看到的背景偏移多少（×半徑），邊緣彎最多", range: 0...0.6, step: 0.02),
        TuneField(key: \.absorb, name: "厚的地方多有顏色 v2.49", hint: "0 整隻像清水；1 中間很濃", range: 0...1, step: 0.05),
        TuneField(key: \.caustic, name: "底下的聚光 v2.49", hint: "坐著時底下一塊聚起來的亮光和一圈淡影；0 關", range: 0...1.5, step: 0.1),
        TuneField(key: \.shine, name: "身體上的亮點 v2.51", hint: "（多米 11-22：身體內不要有反光）0 沒有：主亮點、小亮點、左上白弧、柔光全關；1 回 v2.50。v2.60 預設回到不透明（多米 11-24）：這條回到 0。外觀切到亮面透明時這條不作用", range: 0...1, step: 0.1),
        TuneField(key: \.opaque, name: "身體多不透明 v2.51", hint: "（多米 11-22：下方有一條線或底座）厚的地方蓋掉多少後面的東西。0 回 v2.50：窗台邊和布墊透過身體看得到；0.9 只剩邊緣薄的地方透。v2.60 預設回到不透明（多米 11-24）：這條回到 0.9。外觀切到亮面透明時這條不作用", range: 0...1, step: 0.05),
        TuneField(key: \.lump, name: "不規則外形 v2.51", hint: "（多米 11-22：預設形狀要不規則）1：下盤重、上面一個歪向一邊的鼓包；0 回 v2.50 接近圓的團塊", range: 0...1, step: 0.1),
        TuneField(key: \.strand, name: "黏條 v2.51", hint: "（多米 11-22：不能破皮；手指拉到哪就延長到哪）1：身體只拉到穩定的長度，再遠用一條黏條接到手指，不會斷；0 回 v2.50", range: 0...1, step: 1),
        TuneField(key: \.tugEdge, name: "捏邊緣算拉、捏中間算拿 v2.51", hint: "手指按下的地方離外框這麼近（×半徑）以內，就只把那塊拉出去；更靠中間照舊整隻被拖著走。0 一律整隻拖走", range: 0...1, step: 0.02),
        TuneField(key: \.split, name: "扯斷成兩隻 v2.62", hint: "（多米 11-26）1：抓著拉開超過「分裂距離」、手指又快（「扯斷速度」），就斷成兩隻，兩隻都能捏；碰到播合併動畫變回一隻。一次最多兩隻。0 關（黏條開著時照 v2.51 收腰斷開）", range: 0...1, step: 1),
        TuneField(key: \.splitV, name: "扯斷速度（半徑／秒）v2.62", hint: "手指在螢幕上每秒快過幾個半徑才算太激烈（v2.61 的快扯是 6）", range: 4...30, step: 0.5),
        TuneField(key: \.splitFrac, name: "斷下來那隻多大 v2.62", hint: "第二隻拿走幾成面積，原本那隻縮成剩下的；合回去兩邊加起來回到原本", range: 0.2...0.6, step: 0.05),
        TuneField(key: \.splitAgain, name: "合回去之後還能再斷 v2.62", hint: "1：合回一隻之後重新算，可以再斷一次（多米 11-26 定）；0：這次打開只斷一次", range: 0...1, step: 1),
        TuneField(key: \.mergeFx, name: "合併動畫 v2.62", hint: "0 黏絲搭橋、1 擠扁彈回、2 水滴加波紋、3 吞下去。預設 1（多米 11-26 選擠扁彈回），其他三版留著對照", range: 0...3, step: 1),
        TuneField(key: \.mergeGap, name: "碰到的距離（×半徑）v2.62", hint: "兩隻外框靠到這麼近就算碰到，開始合", range: 0...0.4, step: 0.02),
        TuneField(key: \.mergeWait, name: "貼著多久才合 v2.62", hint: "兩隻碰到之後要一直貼著這麼久才開始合；中間分開就重算。0 回到一碰就合", range: 0...5, step: 0.1),
        TuneField(key: \.splitAt, name: "分裂距離（×半徑）v2.51", hint: "v2.62 扯斷：手指從抓下去的地方拉開多遠（預設 1.8）。黏條開著時收腰斷開不看這條，照 v2.51 固定 3.4（從中心量）", range: 2...8, step: 0.2),
        TuneField(key: \.rejoin, name: "幾秒沒碰就黏回去 v2.51", hint: "第二隻沒人碰這麼久，自己一縮一衝爬回去；碰到就播合併動畫", range: 1...30, step: 1),
        TuneField(key: \.endless, name: "無限拉 v2.54", hint: "（多米 11-22：拉五公分只長三公分，要能無限擴張、跟手）1：手指不讓、拉伸上限不作用，邊拉滿了上限自己放寬，整條一起變長；0 回 v2.53", range: 0...1, step: 1),
        TuneField(key: \.pullCreep, name: "無限拉：拉長時定型速度", hint: "往外拉開 0.6R 起慢慢換成這個速度（1.8R 全換）：記形追得上手指，放手才不會縮回一截。揉、刷、兩指擠照舊用「定型速度」", range: 0...60, step: 1),
        TuneField(key: \.homeFloor, name: "抓著時家不壓進窗台 v2.55", hint: "（11-23：抓頭頂往上拉 2.5 到 3.5R 按住一秒多，身體下半被壓進窗台、扁成一條、翻面上百個）1：抓著時家最低只到身體底部剛好碰到地面；0 回 v2.54b", range: 0...1, step: 0.05),
        TuneField(key: \.pullNearR, name: "無限拉：拉長時記形範圍", hint: "往外拉長時整條都用整身座標記形（×半徑）", range: 0.5...12, step: 0.1),
        TuneField(key: \.growK, name: "無限拉：上限放寬多快", hint: "被抓的那塊跟不上手指時，每條邊的上限每秒放寬幾倍（e 的幾次方）", range: 0.2...6, step: 0.1),
        TuneField(key: \.remeshCalm, name: "補點後站穩幾秒 v2.56", hint: "（11-23）補點之後新的網格要重新站穩，這段時間每一幀把身體各處相對整團的速度留兩成，彈不起來、慢慢落定。量過拉 2.5 到 4.5R 按住：每幀跳動平均 3 到 9.5 → 1.8 到 2.7。0 回 v2.55", range: 0...1, step: 0.05),
        TuneField(key: \.remeshCalmK, name: "站穩時速度留幾成 v2.56", hint: "每 1/60 秒身體各處相對整團的速度留多少；1 等於不作用", range: 0...1, step: 0.05),
        TuneField(key: \.remeshHome, name: "放手就換回原本的網格 v2.58", hint: "（QC-0007 #46：拉一下放手就一直抽搐）1：拉著時照樣補點，手一離開就換回建身體時的網格，形狀照樣帶回去；0 回 v2.57", range: 0...1, step: 1),
        TuneField(key: \.pullGive, name: "往外拉時手指最多讓多少 v2.58", hint: "（11-24）往外拉開時，防翻面每次推一下手指就往旁邊讓一點，一路累積到 2 個半徑，那塊就不跟手（斜拉 5.5R 差 1.6R，最差 3.3R）。往外拉開 0.6R 起、1.8R 全算，手指讓的上限縮到這麼多個半徑；揉、壓、兩指擠照舊。0 回以前", range: 0...2, step: 0.05),
        TuneField(key: \.memUntie, name: "打結多久就解開（秒）v2.58", hint: "（QC-0007 #46）放手後記住的形狀外框交叉超過這麼久，暫時關掉記憶的上下限和防翻面、快退到不交叉為止（不關的話保險會把結卡住，一直抖）；黏在螢幕側邊、身體打結超過 0.6 秒就提早掉下來。0 關", range: 0...3, step: 0.1),
        TuneField(key: \.walkShow, name: "走路帶東西回來 v2.58", hint: "（QC-0007 #47：石頭和花瓣去掉；走路回來那段一起關）0：不出門、不帶東西回來，窗台上不畫、不放送的石頭，存的東西和步數都還在；1 回 v2.57", range: 0...1, step: 1),
        TuneField(key: \.remesh, name: "拉長時自動補點 v2.54", hint: "（多米 11-22）記住的形狀外框點距超過 2.6 個點距、或身體裡有邊拉到原形 2.8 倍，就照現在的形狀重新撒點（點距不變，最多原本 3 倍）；退回去點太密時再撒一次變少。0：只放寬上限不補點", range: 0...1, step: 1),
        TuneField(key: \.rateK, name: "快扯變硬、慢拉變軟 v2.54", hint: "（多米 11-22）手指每秒移動不到 rateLo 個半徑最軟（硬度少三成五×這個值），超過 rateHi 最硬（硬度多兩倍×這個值、記形少九成五×這個值）：猛扯拉不太長、會彈回去，慢拉一路變長。0 關掉", range: 0...1, step: 0.05),
        TuneField(key: \.rateLo, name: "快扯變硬：多慢算慢拉（半徑／秒）", hint: "一般慢慢拉大約每秒 3 到 6 個半徑；量過設 1 的話一般的拉也會變硬、跟不上手", range: 0.2...10, step: 0.1),
        TuneField(key: \.rateHi, name: "快扯變硬：多快算猛扯（半徑／秒）", hint: "", range: 2...20, step: 0.5),
        TuneField(key: \.hapPull, name: "震動跟著拉力走 v2.54", hint: "（多米 11-22）抓著拉時持續震動，拉越長越強越銳利（3R 約一半、8R 約八成），猛扯被身體頂住時馬上變強。這是最強時的強度，0 關掉", range: 0...1, step: 0.05),
        TuneField(key: \.frameCling, name: "黏窗框 v2.54", hint: "（多米 11-22：只要能爬手機四邊，窗沿的取消）0：放在窗框旁邊不再黏上窗框，只有螢幕左、右、上邊會黏；1 回 v2.53", range: 0...1, step: 1),
        TuneField(key: \.edgeCling, name: "黏在螢幕四周 v2.51", hint: "（多米 11-22）1：慢慢放在螢幕左邊、右邊、上邊旁邊會黏住；0 只有窗框", range: 0...1, step: 1),
        TuneField(key: \.flow, name: "流：放著會慢慢往下塌 v2.52", hint: "（多米 11-22：補「流」）沒有手指碰、坐在窗台上時，記住的形狀每秒往下塌掉高度的幾成、往兩邊攤開；手指一碰就停。0.05 大約 14 秒塌一半；回原形會同時把它拉回去。0 關（現在的行為）。三種材料的起點等主參照的錄影", range: 0...0.5, step: 0.01),
        TuneField(key: \.strandAt, name: "黏條開著時身體拉到多長 v2.52", hint: "黏條開著，窗台上身體本身最多拉到幾個半徑，再遠的部分是黏條。v2.53 預設回到 2.4（多米 11-22：1.6 拉起來不像整隻被拉、形狀留不住）。1.6（v2.52 試過）：v2.51 的 2.4 捏著邊緣往外拉時，那一塊被拉到外框折起來（16 種拉法裡 7 種折超過 120 度；1.6 是 0 種）。2.4 回 v2.51。黏條關掉時這條不作用，身體照「拉伸上限」拉（黏土 7）", range: 1...8, step: 0.1),
        TuneField(key: \.sillCap, name: "窗台上的拉伸上限（對照）v2.52", hint: "0：窗台不蓋掉拉伸上限（多米 11-22：黏土在窗台上也拉到 7）；3.2 回 v2.50（窗台上最多 3.2R、記形最多 2.6R）。只在黏條關著時作用，黏條開著看上面那條", range: 0...8, step: 0.1),
        TuneField(key: \.thin, name: "細絲：快到上限時圓角變小 v2.52", hint: "（多米 11-22：中間做法）1：拉到拉伸上限的六成起，外框的圓角慢慢變小，到上限時剩三成，拉細的那條看得到；0 關（v2.51，圓角固定）", range: 0...1, step: 1),
        TuneField(key: \.wbreath, name: "水的呼吸 v2.52", hint: "1：牠靜止時，透過身體看到的背景跟著呼吸輕輕變（彎的量 ±12%）；0 關（v2.51，靜止時折射是靜的）", range: 0...1, step: 1),
        TuneField(key: \.decoThru, name: "會動的擺飾透過身體看得到 v2.52", hint: "（多米 11-22：做）1：風鈴、晴天娃娃、走路帶回來的東西隔著身體也看得到；0 只有固定的背景（v2.49 的做法，用來量成本：開和關各看一次「算」的毫秒）", range: 0...1, step: 1),
        TuneField(key: \.bubbles, name: "身體裡的氣泡幾顆 v2.49", hint: "黏在身體裡、跟著被擠開；0 沒有", range: 0...12, step: 1),
        TuneField(key: \.wet, name: "水潤 v2.47", hint: "1（多米 11-16：要很有水份的感覺）：更透、亮點更大更銳、多一顆小亮點、邊緣一圈反光；0 回 v2.46 的皮", range: 0...1, step: 1, section: "外形"),
        TuneField(key: \.skin, name: "皮", hint: "1 果凍 A 清透（多米 11-07 定）：看得到肚子裡的亮粉在沉；亮粉揚起來時往奶凍混。0 平塗（舊畫法，沒有 Metal 的手機也用這個）", range: 0...1, step: 1, section: "外形"),
        TuneField(key: \.scene, name: "背景", hint: "0 藍：懸空（舊行為一條都不變）；1 白天、2 夜晚：窗台上有重力，牠坐在正中間的碗裡，石頭盤和盆栽只是圖（v2.28 窗台，v2.31 碗回中間）", range: 0...2, step: 1, section: "外形"),
        TuneField(key: \.fingerSolid, name: "手指是實心的（×半徑）", hint: "抓著拖過身體時，沒被抓到的部分被手指推開，不會被穿過去（v2.29 0.2；0 關）", range: 0...0.5, step: 0.01),
        TuneField(key: \.grabHold, name: "抓住跟手", hint: "被抓那塊不聽彈性、跟手指走的程度；黏土 0.85，0 是以前（落後手指約 1 個半徑）", range: 0...1, step: 0.05, section: "按壓與記形"),
        TuneField(key: \.nearMem, name: "手指附近記形", hint: "手指附近用整身座標記形，拉出一塊就留一塊；0 只用局部區塊", range: 0...1, step: 0.05, section: "按壓與記形"),
        TuneField(key: \.memMax, name: "記形上限（×半徑）", hint: "記住的形狀最多離原形多遠；黏土 5（v2.15，超過約 8.5R 會抖），v2.13 是 12，v2.12 是 4，以前 1.1", range: 0.5...20, step: 0.1, section: "按壓與記形"),
        TuneField(key: \.tentMem, name: "觸手記形", hint: "1：觸手跟身體一樣留形、一樣慢慢回；0：v2.7 尖端一秒多彈回", range: 0...1, step: 0.05, section: "按壓與記形"),

        TuneField(key: \.life, name: "活物感", hint: "沒碰時自己動的幅度", range: 0...1.5, step: 0.05, section: "活物感"),
        TuneField(key: \.drift, name: "觸手飄動", hint: "沒碰時觸手擺動的幅度（×半徑）", range: 0...0.4, step: 0.01, section: "活物感"),
        TuneField(key: \.wriggle, name: "蠕動", hint: "沒碰時整個身體輪廓慢慢變形的幅度（×半徑）", range: 0...0.3, step: 0.01, section: "活物感"),
        TuneField(key: \.idlePace, name: "自己動的速度", hint: "偽足伸縮與蠕動的快慢；1 是 v2.9 網頁版（多米：太快）", range: 0.1...1.5, step: 0.05, section: "活物感"),
        TuneField(key: \.pods, name: "偽足數量", hint: "沒碰時同一時間最多幾條在伸縮，隨機方向、上方也會長；0 關", range: 0...3, step: 1, section: "活物感"),
        TuneField(key: \.podLen, name: "偽足長度（×半徑）", hint: "伸到最長多長（每條再隨機 0.7 到 1.2 倍）", range: 0...1.4, step: 0.05, section: "活物感"),
        TuneField(key: \.jelly, name: "水母呼吸", hint: "1：規律一縮一放，收縮快放鬆慢、收縮時上浮；0：原本的呼吸", range: 0...1, step: 1, section: "活物感"),
        TuneField(key: \.jellyT, name: "水母呼吸週期（秒）", hint: "一縮一放幾秒", range: 1.5...6, step: 0.1, section: "活物感"),
        TuneField(key: \.jellyAmp, name: "水母收縮幅度", hint: "收縮時變窄幾成（同時變高八成五）", range: 0...0.25, step: 0.01, section: "活物感"),
        TuneField(key: \.jellyLift, name: "水母上浮（×半徑）", hint: "每次收縮往上浮多少，放鬆時慢慢沉回", range: 0...0.3, step: 0.01, section: "活物感"),
        TuneField(key: \.morph, name: "蠕動不重複", hint: "1：輪廓與觸手跟著平滑亂數變，形狀一直在換；0：v2.7 固定行進波", range: 0...1, step: 1, section: "活物感"),
        TuneField(key: \.wander, name: "遊走", hint: "沒碰時在畫面裡移動的速度（×半徑／秒）", range: 0...1, step: 0.05, section: "活物感"),
        TuneField(key: \.tail, name: "遊走拖尾（×半徑）", hint: "遊走時觸手往移動反方向拖的量，照速度自己淡入淡出；0 關（第 20 條）", range: 0...0.4, step: 0.02, section: "活物感"),
        TuneField(key: \.floppy, name: "觸手軟度", hint: "越大觸手末端越軟、越會甩", range: 0...0.9, step: 0.05, section: "活物感"),
        TuneField(key: \.idleFreeze, name: "碰到時凍住", hint: "1：活物感時鐘停住不歸零（候選 19）", range: 0...1, step: 1, section: "活物感"),
        TuneField(key: \.specialEvery, name: "特別回彈", hint: "每幾次放手來一次特別 Q 的回彈，0 關（候選 2 是 8）", range: 0...12, step: 1, section: "活物感"),
        TuneField(key: \.breathT, name: "呼吸週期（秒）", hint: "一次呼吸幾秒；原本 3.8，候選 23a 是 6", range: 2...8, step: 0.1, section: "活物感"),
        TuneField(key: \.breathShape, name: "呼吸不對稱", hint: "1：吸 40%、吐 55%、停 5%；0 正弦（候選 23b）", range: 0...1, step: 1, section: "活物感"),
        TuneField(key: \.breathDeep, name: "被摸久呼吸變深", hint: "1：連續抓超過 10 秒，放手後 20 秒內振幅 ×1.5、週期 ×1.2 再衰減（候選 23c）", range: 0...1, step: 1, section: "活物感"),

        TuneField(key: \.hapMax, name: "連續觸覺上限", hint: "捏的時候最多震多強", range: 0...1, step: 0.05, section: "觸覺"),
        TuneField(key: \.hapStatic, name: "連續觸覺：變形量比重", hint: "拉著不動也震的那部分", range: 0...1, step: 0.05, section: "觸覺"),
        TuneField(key: \.hapRate, name: "連續觸覺：變化率比重", hint: "正在變才震的那部分（候選 12：0.75，變形量 0.25）", range: 0...1, step: 0.05, section: "觸覺"),
        TuneField(key: \.hapRateNorm, name: "變化率多少算滿", hint: "每秒變形量變化多少算 1", range: 0.5...6, step: 0.1, section: "觸覺"),
        TuneField(key: \.hapSharp, name: "連續觸覺銳利度", hint: "偏悶還是偏脆", range: 0...1, step: 0.05, section: "觸覺"),
        TuneField(key: \.hapSharpStretch, name: "拉伸銳利度加成", hint: "拉長時銳利度多加多少（第三批 15）", range: 0...0.5, step: 0.05, section: "觸覺"),
        TuneField(key: \.popMin, name: "啵最輕", hint: "輕輕放手那一下", range: 0...1, step: 0.05, section: "觸覺"),
        TuneField(key: \.popMax, name: "啵最重", hint: "用力甩或拉到底放手那一下", range: 0...1, step: 0.05, section: "觸覺"),
        TuneField(key: \.popSharp, name: "啵銳利度", hint: "候選 14：黏土 0.3", range: 0...1, step: 0.05, section: "觸覺"),
        TuneField(key: \.popCount, name: "啵幾下", hint: "用力放手時幾下（輕輕放手少下）；v2.25 黏土 2、麻糬 3、果凍 4，開慣性時間隔跟晃動同步", range: 1...6, step: 1, section: "觸覺"),
        TuneField(key: \.popGap, name: "啵的間隔", hint: "幾下之間隔幾秒", range: 0.03...0.3, step: 0.01, section: "觸覺"),
        TuneField(key: \.popDecay, name: "啵的衰減", hint: "每下是前一下的幾成", range: 0.1...1, step: 0.05, section: "觸覺"),
        TuneField(key: \.tickSpacing, name: "質地微震間距", hint: "手指每走幾點一下；v2.25 是 12；0 關", range: 0...30, step: 1, section: "觸覺"),
        TuneField(key: \.tickRate, name: "顆粒每秒最多幾下", hint: "一秒幾十下會手麻", range: 5...40, step: 1, section: "觸覺"),
        TuneField(key: \.tickTense, name: "拉長時顆粒變密", hint: "拉到 2R 時間距縮幾成", range: 0...0.9, step: 0.05, section: "觸覺"),
        TuneField(key: \.pressGrain, name: "按下去的漸弱顆粒", hint: "1：第一下之後 0.3 秒內四下漸弱，接觸面積變了再一下（手機沒有力道，用時間和接觸面積代替）；0 回 v2.24", range: 0...1, step: 1, section: "觸覺"),
        TuneField(key: \.grainMin, name: "漸弱顆粒最輕", hint: "最後一下多輕", range: 0...0.5, step: 0.01, section: "觸覺"),
        TuneField(key: \.grainMax, name: "漸弱顆粒最重", hint: "第一下多重", range: 0...0.8, step: 0.01, section: "觸覺"),
        TuneField(key: \.grainSharp, name: "漸弱顆粒銳利度", hint: "偏鈍才像往下陷", range: 0...1, step: 0.01, section: "觸覺"),
        TuneField(key: \.purrRoll, name: "呼嚕用連續低頻", hint: "1：一陣一陣的低頻震動（一秒三陣）；0 回 v2.24（每 0.5 秒兩下輕敲）", range: 0...1, step: 1, section: "觸覺"),
        TuneField(key: \.tickMin, name: "微震最輕", hint: "手慢時", range: 0...0.6, step: 0.02, section: "觸覺"),
        TuneField(key: \.tickMax, name: "微震最重", hint: "手快時（每秒 3 個半徑）", range: 0...0.8, step: 0.02, section: "觸覺"),
        TuneField(key: \.tickSharp, name: "微震銳利度", hint: "顆粒偏鈍還是偏脆", range: 0...1, step: 0.05, section: "觸覺"),
        TuneField(key: \.pressSharp, name: "按下銳利度", hint: "手指碰到那一下的銳利度（第 15 條）", range: 0...1, step: 0.05, section: "觸覺"),
        TuneField(key: \.hapSharpSquash, name: "壓扁銳利度減少", hint: "按壓攤開時銳利度減多少（候選 15 是 0.05）", range: 0...0.3, step: 0.01, section: "觸覺"),
        TuneField(key: \.popViaHaptics, name: "啵走觸覺管線", hint: "1：放手音由 Core Haptics 播，跟震動同一個 pattern；要有錄音檔，第一次套了要重開 app（候選 17）", range: 0...1, step: 1, section: "觸覺"),

        TuneField(key: \.volMaster, name: "主音量", hint: "所有聲音一起", range: 0...1, step: 0.05, section: "聲音"),
        TuneField(key: \.rubMax, name: "揉的音量上限", hint: "揉最快時多大聲", range: 0...1, step: 0.05, section: "聲音"),
        TuneField(key: \.pitchJitter, name: "音高抖動", hint: "每次隨機差多少", range: 0...0.3, step: 0.01, section: "聲音"),
        TuneField(key: \.sndPullMax, name: "拉絲音量上限", hint: "拉的時候連續黏絲聲最大多大聲；拉越快越大聲、停住幾乎沒聲", range: 0...1, step: 0.05, section: "聲音"),
        TuneField(key: \.volMusic, name: "背景音樂音量", hint: "v2.21 lofi 的音量（喇叭按鈕在「音樂和音效」時才有）；手指抓著時降到六成", range: 0...1, step: 0.05, section: "聲音"),
        TuneField(key: \.sndSettle, name: "放手餘韻", hint: "拉過放手冒小氣泡、按久放手一聲小嘶的音量；0 關", range: 0...2, step: 0.1, section: "聲音"),
        TuneField(key: \.sndPressSize, name: "按的音量跟接觸面積", hint: "指尖輕、指腹重的差多少；0 關", range: 0...1, step: 0.05, section: "聲音"),

        TuneField(key: \.seed, name: "外形亂數種子", hint: "換一個數字就換一個形狀（會重置）", range: 1...30, step: 1, section: "外形"),
        TuneField(key: \.bodySize, name: "身體大小", hint: "半徑是畫面寬的幾成（會重置）；0.30 是 v2.24（寬約 4 公分），0.22 是 v2.10 到 v2.23，0.26 是 v2.9 以前", range: 0.15...0.4, step: 0.01, section: "外形"),
        TuneField(key: \.limbs, name: "固定觸手數", hint: "預設 0：沒有固定觸手的一團（多米 11-06）；8：v2.27 環繞身體、每條抓得住；5：以前的海星外形（會重置）", range: 0...12, step: 1, section: "外形"),
        TuneField(key: \.tentSlip, name: "觸手滑開", hint: "把觸手往自己的根推，推到剩靜止長度的幾倍就從手指滑開，不對折；越大越早滑開；0 關（會纏住抖）", range: 0...1, step: 0.05, section: "外形"),
        TuneField(key: \.tentBump, name: "觸手互撞", hint: "一條觸手撞到別條，對方被彈開的力道；手指抓著的那條不受影響；0 關，互相穿過去", range: 0...2, step: 0.05, section: "外形"),
        TuneField(key: \.moodColor, name: "心情變色", hint: "舒服偏粉橘、被扯偏紅、害怕或戒備偏藍灰、睡著偏深藍；數字是最多染幾成；0 不變色", range: 0...1, step: 0.05, section: "外形"),
        TuneField(key: \.homeFrac, name: "家的高度", hint: "身體的家在畫面高度的幾成；原本 0.40，候選 33 是 0.46", range: 0.3...0.55, step: 0.01, section: "外形"),
        TuneField(key: \.inkVar, name: "描邊粗細隨壓縮", hint: "1：被壓的邊描邊加粗到 1.3 倍、被拉的減到 0.8 倍；0 固定（候選 34）", range: 0...1, step: 0.1, section: "外形"),

        // v2.61 第一批 (the same words as the web). bumpSoft is not here: the phone does not read it (greetLook and brJit are read since v2.63)
        TuneField(key: \.skinU, name: "皮：不會斷的畫法 v2.61", hint: "1：先畫滿身體裡每一個小三角形，細的地方補一條保底線，拉遠、打結時皮比較不會斷開。0 回 v2.60（照外框畫）。只在果凍皮有作用", range: 0...1, step: 1, section: "這一批 v2.61"),
        TuneField(key: \.pullHold, name: "拉的 A3：拉長停住就定住 v2.61", hint: "1：拉開 0.6R 以上，手指停下來 0.25 秒，身體就不再自己變長。0 回 v2.60", range: 0...1, step: 1, section: "這一批 v2.61"),
        TuneField(key: \.pullWhole, name: "拉的 A4：往裡拉，整隻先走 v2.61", hint: "1：往身體裡面拉的那一段，整隻先跟著走，再拉長。0 回 v2.60", range: 0...1, step: 1, section: "這一批 v2.61"),
        TuneField(key: \.pullSoft, name: "拉的 A5：拉很長放手，收回去 v2.61", hint: "1：身體拉得很長時放手，先不逃、轉正有限速、放手後 0.8 秒內每一點有限速；按住不動時上限不會自己變大。0 回 v2.60", range: 0...1, step: 1, section: "這一批 v2.61"),
        TuneField(key: \.rough, name: "只有快扯算欺負 v2.61", hint: "1：慢慢拉很長不算欺負；快扯不會變熟，也不會變得怕你。0 回 v2.60（拉開 1.5R 撐半秒就算）", range: 0...1, step: 1, section: "這一批 v2.61"),
        TuneField(key: \.tapSoft, name: "慢慢點不算攻擊 v2.61", hint: "1：慢慢點牠不會嚇到，還是會縮一下，越點縮越小。0 回 v2.60", range: 0...1, step: 1, section: "這一批 v2.61"),
        TuneField(key: \.petSlow, name: "慢慢摸也算摸 v2.61", hint: "1：摸得很慢也會呼嚕、變熟。0 回 v2.60（太慢會被當成抓）", range: 0...1, step: 1, section: "這一批 v2.61"),
        TuneField(key: \.wakeSoft, name: "輕碰慢慢醒 v2.61", hint: "1：睡著時輕輕碰，慢慢醒；剛打開 40 秒才會睡。0 回 v2.60（一碰就嚇醒、30 秒就睡）", range: 0...1, step: 1, section: "這一批 v2.61"),
        TuneField(key: \.greetLook, name: "打開先看你 v2.61", hint: "1：打開、切回來，先看你一眼。0 回 v2.60", range: 0...1, step: 1, section: "這一批 v2.61"),
        TuneField(key: \.nearFast, name: "聽節奏時也會靠過來 v2.61", hint: "1：在聽你打節奏時，手指放旁邊照樣靠過來。0 回 v2.60", range: 0...1, step: 1, section: "這一批 v2.61"),
        TuneField(key: \.eyeTrue, name: "眼睛看真的手指 v2.61", hint: "1：眼睛跟著手指現在的位置。0 回 v2.60（慢四分之一秒）", range: 0...1, step: 1, section: "這一批 v2.61"),
        TuneField(key: \.snd61, name: "新的揉聲 v2.61", hint: "1：揉的聲音換新的循環，抓著時雨聲變小。0 回 v2.60", range: 0...1, step: 1, section: "這一批 v2.61"),
        TuneField(key: \.brJit, name: "作息每次不一樣 v2.61", hint: "1：醒多久、睡多久每次有點不同。0 回 v2.60（手機要大腦開著才有作用）", range: 0...1, step: 1, section: "這一批 v2.61"),

        // v2.63 (the web's words for brain, brPre, brAwakeT, brSleepT; the phone has the brain from v2.63)
        TuneField(key: \.brain, name: "大腦 v2.63", hint: "1：五個需求（睏、好奇、想被摸、怕、想動）一直在漲落，牠每做完一件事就做最強那個需求的事；跑完比較快睡、睡飽自己醒、想被摸了才來找你。0 回改之前（擲骰子決定、40 秒沒人碰就睡、睡了不會自己醒）", range: 0...1, step: 1, section: "這一批 v2.63"),
        TuneField(key: \.brPre, name: "換事情前的前兆", hint: "1：要睡之前先瞇眼、嘆一口氣，約 2 秒後才睡；要來找你之前先看你一眼。0 決定了馬上做", range: 0...1, step: 1, section: "這一批 v2.63"),
        TuneField(key: \.brAwakeT, name: "醒著多久會睏（秒）", hint: "沒人碰、沒跑的情況下，睏從 0 漲到滿要幾秒；20 秒沒人碰以後漲兩倍快，夜晚背景 1.5 倍", range: 60...900, step: 10, section: "這一批 v2.63"),
        TuneField(key: \.brSleepT, name: "睡多久睡飽（秒）", hint: "睏從滿退到 0 要睡幾秒；睡飽牠自己醒", range: 20...300, step: 5, section: "這一批 v2.63"),
        TuneField(key: \.mood, name: "心情 v2.63", hint: "1：牠有一個幾分鐘才慢慢變的心情。被揉到呼嚕、探到東西、你照牠的節奏回牠會變好；被扯、被嚇、睡著被吵醒會變差。心情好：好奇和想動漲得快、身體挺一點、看你的時候眼睛笑、步子大、被戳會朝你傾過來搖偽足。心情差：容易怕、身體扁一點、眼睛睜大、少走動、被戳會退開縮得更大。只活在這一次打開。0 回改之前（手機要大腦開著才有作用）", range: 0...1, step: 1, section: "這一批 v2.63"),
        TuneField(key: \.moodHalf, name: "心情多久退一半（秒）", hint: "沒事的時候心情慢慢回到普通偏好，這是退一半要的秒數", range: 30...900, step: 10, section: "這一批 v2.63"),
        // v2.63 C9 (the web's words for nap, napPurr, napWait)
        TuneField(key: \.nap, name: "揉夠了在你手邊睡著 v2.63", hint: "1（C9）：這次打開累計呼嚕滿「揉多久」秒，手指離開「放手幾秒」，牠就在你最後摸的地方睡著，不走回布墊；輕碰照「輕碰慢慢醒」。睡了這一覺累計歸零。0 回改之前（40 秒沒人碰才睡，大腦開著先走回布墊）", range: 0...1, step: 1, section: "這一批 v2.63"),
        TuneField(key: \.napPurr, name: "揉多久會睡在手邊（秒）", hint: "這次打開累計呼嚕幾秒才會在你手邊睡著。60 是我取的，數字待測", range: 10...300, step: 5, section: "這一批 v2.63"),
        TuneField(key: \.napWait, name: "放手幾秒睡著（秒）", hint: "累計夠了以後，手指離開幾秒睡著。6 是我取的，數字待測", range: 2...20, step: 0.5, section: "這一批 v2.63"),
    ]
}

extension UIColor {
    convenience init(hex: UInt32, alpha: CGFloat = 1) {
        self.init(red: CGFloat((hex >> 16) & 0xFF) / 255,
                  green: CGFloat((hex >> 8) & 0xFF) / 255,
                  blue: CGFloat(hex & 0xFF) / 255,
                  alpha: alpha)
    }
}
