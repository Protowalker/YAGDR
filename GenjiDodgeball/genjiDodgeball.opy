settings {
    "lobby": {
        "allowPlayersInQueue": true,
        "enableMatchVoiceChat": true
    },
    "gamemodes": {
        "ffa": {
            "enabledMaps": [
                "workshopIslandNight"
            ]
        },
        "general": {
            "enableHeroSwitching": false,
            "gamemodeStartTrigger": "immediately",
            "heroLimit": "off",
            "enableRandomHeroes": true
        }
    },
    "heroes": {
        "allTeams": {
            "genji": {
                "damageDealt%": 10,
				"damageReceived%": 10,
				"ability1Cooldown%": 100,
                "ability2Cooldown%": 0,
                "enablePrimaryFire": false,
                "enableMelee": false,
                "enableSecondaryFire": false,
                "enableUlt": false
            },
            "enabledHeroes": [
                "genji"
            ]
        }
    }
}

# Global variables

globalvar i 8
globalvar BallPosition
globalvar TailJoints
globalvar BallDirection
globalvar TargetedPlayer
globalvar LastTargetedPlayer
globalvar BallActive
globalvar BallSpeed
globalvar BallBounceNormal

globalvar PlayerSettings
#!define DeflectCooldown  PlayerSettings[0]
#!define DashCooldown     PlayerSettings[1]
#!define DeflectDuration  PlayerSettings[2]
#!define DashStunDuration PlayerSettings[3]

globalvar BallSettings
#!define StartingBallSpeed        BallSettings[0]
#!define MaxBallSpeed             BallSettings[1]
#!define BallAcceleration         BallSettings[2]
#!define DeflectedBallSpeedScalar BallSettings[3]

globalvar GameplaySettings
#!define InterceptionsEnabled GameplaySettings[0]

globalvar BouncePadSettings
#!define BouncePadMaxCooldown BouncePadSettings[0]
#!define NumBouncePads        BouncePadSettings[1]
#!define BouncePadStrength    BouncePadSettings[2]
#!define BouncePadSize        BouncePadSettings[3]
#!define BouncePadDistance    BouncePadSettings[4]

globalvar VFXSettings
#!define NumTailSegments     VFXSettings[0]
#!define DeathEffectsEnabled VFXSettings[1]

globalvar DeathEffects
#!define DeathBeam DeathEffects[0]
#!define DeathSphere DeathEffects[1]
globalvar DeathSphereRadius

globalvar RoundCountdown
#!define maxRoundCountdown 5


#Player variables

playervar Deflects
playervar MaxDeflectedSpeed
playervar BouncePadCooldown

# Subroutines

subroutine PlayDeathEffects

#!define isBlocking(player) (player).isUsingAbility1() or (player).isUsingAbility2()

/*
rule "Setup":
*/

rule "Disable starting countdown":
    @Condition isInSetup() == true
    
    setMatchTime(0)


rule "Get workshop settings":
    DeflectCooldown          =     createWorkshopSetting(float<0:10>,        "Player",      "Deflect Cooldown",                  0.5,   0)
    DashCooldown             =     createWorkshopSetting(float<0:10>,        "Player",      "Dash Cooldown",                     2.7,   1)
    DeflectDuration          =     createWorkshopSetting(float<0:2>,         "Player",      "Deflect Duration",                  0.3,   2)
    DashStunDuration         =     createWorkshopSetting(float<0:5>,         "Player",      "Dash Stun Time",                    1,     3)
    
	MaxBallSpeed             =     createWorkshopSetting(float<10:5000>,     "Ball",        "Maximum Ball Speed",                1000,  1)
	StartingBallSpeed        = min(createWorkshopSetting(float<10:5000>,     "Ball",        "Starting Ball Speed",               25,    0), MaxBallSpeed)
    BallAcceleration         =     createWorkshopSetting(float<0:25>,        "Ball",        "Ball Acceleration",                 0.5,   2)
    DeflectedBallSpeedScalar = 1 + createWorkshopSetting(float<0:500>,       "Ball",        "Deflected Ball Speed Increase %",   5,     3) / 100

    InterceptionsEnabled     =     createWorkshopSetting( bool,              "Gameplay",    "Allow Interceptions",               false, 0)

    BouncePadMaxCooldown     =     createWorkshopSetting(float<0:15>,        "Bounce Pads", "Bounce Pad Cooldown",               3,     0)
    NumBouncePads            =     createWorkshopSetting(  int<0:16>,        "Bounce Pads", "Number of Bounce Pads",             4,     1)
    BouncePadStrength        =     createWorkshopSetting(float<0:100>,       "Bounce Pads", "Bounce Pad Strength",               30,    2)
    BouncePadSize            =     createWorkshopSetting(float<0:25>,        "Bounce Pads", "Bounce Pad Size",                   2,     3)
    BouncePadDistance        =     createWorkshopSetting(float<0:20>,        "Bounce Pads", "Bounce Pad Distance From Center",   12,    4)

    NumTailSegments          =     createWorkshopSetting(  int<0:8>,         "VFX",         "Number of Tail Segments",           2,     0)
    DeathEffectsEnabled      =     createWorkshopSetting( bool,              "VFX",         "Death Effects",                     true,  1)

globalvar DirectionRate

rule "Initialize Global":
    BallPosition = vect(0, 1.5, 0)
	TailJoints = [BallPosition]
    BallDirection = vect(0, 0, 0)
    BallSpeed = StartingBallSpeed
    chase(BallDirection, updateEveryTick(directionTowards(BallPosition, TargetedPlayer.getEyePosition())), rate=DirectionRate, ChaseReeval.DESTINATION_AND_RATE)
    chase(BallSpeed, MaxBallSpeed, rate=BallAcceleration if BallActive else 0, ChaseReeval.DESTINATION_AND_RATE)
    disableAnnouncer()
	disableGamemodeCompletion()


rule "Create global HUD elements":
    # white normal
    hudSubtext(getAllPlayers().exclude(TargetedPlayer), "Current Player Targeted: {0}".format(TargetedPlayer), HudPosition.LEFT, -2, Color.WHITE, HudReeval.VISIBILITY_AND_STRING, SpecVisibility.DEFAULT)
    # red when you're targeted
    hudSubtext(TargetedPlayer, "Current Player Targeted: {0}".format(TargetedPlayer), HudPosition.LEFT, -2, Color.RED, HudReeval.VISIBILITY_AND_STRING, SpecVisibility.DEFAULT)
    hudText(getDeadPlayers(Team.ALL), "Waiting for next round", "You have been eliminated or joined during a round", "You will spawn once the next round starts", HudPosition.TOP, 2, Color.WHITE, Color.WHITE, Color.WHITE, HudReeval.VISIBILITY_AND_STRING, SpecVisibility.DEFAULT)
	# gameplay tips text
    hudSubtext(getAllPlayers(), "Deflect or Dash will deflect the ball to an enemy", HudPosition.RIGHT, -10, Color.WHITE, HudReeval.VISIBILITY_AND_STRING, SpecVisibility.DEFAULT)
    hudSubtext(getAllPlayers(), "If you get hit, you die. Last {0} standing wins!".format(heroIcon(Hero.GENJI)), HudPosition.RIGHT, -9, Color.WHITE, HudReeval.VISIBILITY_AND_STRING, SpecVisibility.DEFAULT)
	# ball speed text color change with speed
	hudSubtext(getAllPlayers(), "Current Ball Speed: {0}".format(BallSpeed), HudPosition.LEFT, -3, Color.BLUE if BallSpeed < 20 else Color.GREEN if BallSpeed < 25 else Color.YELLOW if BallSpeed < 30 else Color.ORANGE if BallSpeed < 35 else Color.RED if BallSpeed < 55 else Color.PURPLE, HudReeval.VISIBILITY_STRING_AND_COLOR)


rule "Initialize Player":
    @Event eachPlayer
    @Hero all
    @Condition eventPlayer.hasSpawned() == true
    
    eventPlayer.disableRespawn()
    eventPlayer.disableGamemodeHud()
    eventPlayer.disableScoreboard()
    chase(eventPlayer.BouncePadCooldown, 0, rate=1, ChaseReeval.NONE)


rule "Create player HUD elements":
    @Event eachPlayer
    @Hero all

    hudText(eventPlayer, eventPlayer.Deflects, 								 "Deflects", 				null, 		HudPosition.LEFT,  1,  Color.YELLOW,   Color.WHITE, Color.YELLOW, 	 HudReeval.VISIBILITY_AND_STRING, SpecVisibility.DEFAULT)
    hudText(eventPlayer, floor(eventPlayer.getStatistic(Stat.ELIMINATIONS)), "Kills", 					null, 		HudPosition.LEFT,  2,  Color.ORANGE,   Color.WHITE, Color.ORANGE, 	 HudReeval.VISIBILITY_AND_STRING, SpecVisibility.DEFAULT)
    hudText(eventPlayer, floor(eventPlayer.getStatistic(Stat.DEATHS)), 		 "Deaths", 					null, 		HudPosition.LEFT,  3,  Color.SKY_BLUE, Color.WHITE, Color.SKY_BLUE,  HudReeval.VISIBILITY_AND_STRING, SpecVisibility.DEFAULT)
    hudText(eventPlayer, eventPlayer.MaxDeflectedSpeed, 					 "Highest Deflected Speed", null,	    HudPosition.LEFT,  4,  Color.RED, 	   Color.WHITE, Color.TURQUOISE, HudReeval.VISIBILITY_AND_STRING, SpecVisibility.DEFAULT)
    hudText(eventPlayer, ceil(eventPlayer.BouncePadCooldown), 				 "BouncePad",			    "Cooldown", HudPosition.RIGHT, -1, Color.GREEN,    Color.WHITE, Color.WHITE,     HudReeval.VISIBILITY_AND_STRING, SpecVisibility.DEFAULT)


#!define BALL_RADIUS 1.9

rule "Create the ball and its tail":
    createEffect(TargetedPlayer,						  Effect.ORB, Color.RED,   updateEveryTick(BallPosition), BALL_RADIUS, EffectReeval.VISIBILITY_POSITION_AND_RADIUS)
	createEffect(getAllPlayers().exclude(TargetedPlayer), Effect.ORB, Color.WHITE, updateEveryTick(BallPosition), BALL_RADIUS, EffectReeval.VISIBILITY_POSITION_AND_RADIUS)
	createEffect(getAllPlayers() if TargetedPlayer != null else [], Effect.GOOD_AURA, Color.RED, TargetedPlayer, 1, EffectReeval.VISIBILITY_POSITION_AND_RADIUS)
	createEffect(TargetedPlayer,  Effect.GOOD_AURA, Color.RED, BallPosition, 1, EffectReeval.VISIBILITY_POSITION_AND_RADIUS)
	if NumTailSegments > 0:
		createBeam(getAllPlayers(), Beam.BAD, updateEveryTick(BallPosition), TailJoints[1], Color.YELLOW, EffectReeval.VISIBILITY_POSITION_AND_RADIUS)		
	for i in range(NumTailSegments-1):
		createBeam(getAllPlayers(), Beam.BAD, TailJoints[evalOnce(i+1)], TailJoints[evalOnce(i+2)], Color.YELLOW, EffectReeval.VISIBILITY_POSITION_AND_RADIUS)

rule "Create starter podium":
    createInWorldText(null if BallActive else getAllPlayers(), RoundCountdown, vect(0, 2, 0), 4, Clip.NONE, WorldTextReeval.VISIBILITY_AND_STRING, Color.SKY_BLUE, SpecVisibility.DEFAULT)
    createEffect(null if BallActive else getAllPlayers(), Effect.SPHERE, Color.SKY_BLUE, vect(0,0,0), 3.5, EffectReeval.VISIBILITY)

/*
rule "Gameplay":
*/


rule "Round starting! Setup":
    @Condition BallActive == true
    DirectionRate = 1.75    
    chase(BallPosition, updateEveryTick(BallPosition) + updateEveryTick(normalize(BallDirection)), rate=BallSpeed, ChaseReeval.DESTINATION_AND_RATE)
    BallDirection = directionTowards(BallPosition, TargetedPlayer.getEyePosition())


rule "Shorten deflect":
    @Event eachPlayer
    @Hero all
    @Condition eventPlayer.isUsingAbility2() == true
    
    wait(DeflectDuration)
    eventPlayer.setAbility1Enabled(false)
    eventPlayer.setAbility2Enabled(false)
    wait(DeflectCooldown)
    eventPlayer.setAbility1Enabled(true)
    eventPlayer.setAbility2Enabled(true)


rule "Update tail joints":
	while true:
		TailJoints = BallPosition.concat(TailJoints.slice(0, NumTailSegments))   
        wait(0.128 / NumTailSegments)


rule "Dash Cooldown":
    @Event eachPlayer
    @Hero all
    @Condition updateEveryTick(eventPlayer.isUsingAbility1()) == false
    
    #waitUntil(not eventPlayer.isUsingAbility1(), 1)
    # 30% of 8 seconds, genji's CD at time of entry
    eventPlayer.setAbilityCooldown(Button.ABILITY_1, DashCooldown)


rule "Intercept":
    @Event eachPlayer
    @Condition InterceptionsEnabled == true
    @Condition BallActive == true
    @Condition LastTargetedPlayer != eventPlayer
    @Condition updateEveryTick(distance(BallPosition, eventPlayer.getEyePosition())) <= BALL_RADIUS
    @Condition isBlocking(eventPlayer)

    TargetedPlayer = eventPlayer
    

rule "Ball reaches player":
    @Condition updateEveryTick(distance(BallPosition, TargetedPlayer.getEyePosition())) <= BALL_RADIUS
    @Condition BallActive == true
	
	if isBlocking(TargetedPlayer):
		# cancel dash if they used it to deflect
		if TargetedPlayer.isUsingAbility1():
			TargetedPlayer.setStatusEffect(null, Status.KNOCKED_DOWN, 1)
			TargetedPlayer.teleport(BallPosition)
		TargetedPlayer.Deflects += 1
		TargetedPlayer.MaxDeflectedSpeed = max(TargetedPlayer.MaxDeflectedSpeed, BallSpeed)
		BallSpeed = min(MaxBallSpeed, BallSpeed * DeflectedBallSpeedScalar)
		playEffect(getAllPlayers(), DynamicEffect.EXPLOSION_SOUND, Color.WHITE, TargetedPlayer.getPosition(), 200)
		BallDirection = TargetedPlayer.getFacingDirection()
		# get closest living player to reticle
		LastTargetedPlayer = TargetedPlayer
		TargetedPlayer = sorted(getLivingPlayers(Team.ALL).exclude(TargetedPlayer), lambda i: angleBetweenVectors(TargetedPlayer.getFacingDirection(), directionTowards(TargetedPlayer.getEyePosition(), i.getEyePosition())))[0]
		wait()
		if RULE_CONDITION: goto RULE_START
	else:
		TargetedPlayer.setStatusEffect(LastTargetedPlayer, Status.STUNNED, 1)
		kill(TargetedPlayer, LastTargetedPlayer)
        if DeathEffectsEnabled:	async(PlayDeathEffects(), AsyncBehavior.NOOP)

rule "Someone died - restart":
        @Condition TargetedPlayer.isAlive() == false
        if len(getLivingPlayers(Team.ALL)) == 1:
            bigMessage(getAllPlayers(), "{0} wins the round!".format(getLivingPlayers(Team.ALL)[0]))
            getAllPlayers().respawn()
            BallActive = false
            return
        wait(0.016)
        BallActive = false
        wait(0.032)
        RoundCountdown = 3
        BallSpeed = StartingBallSpeed

#!define ModifiedBallDirection (BallDirection*BALL_RADIUS*BallSpeed)

rule "Ball bounces off wall or ground":
    @Condition updateEveryTick(raycast(BallPosition, BallPosition + ModifiedBallDirection*0.016, null, getAllPlayers(), false).getHitPosition()) != BallPosition + ModifiedBallDirection*0.016
    
    BallBounceNormal = raycast(BallPosition, BallPosition + ModifiedBallDirection*0.016, null, getAllPlayers(), false).getNormal()
	wait()
	BallDirection = BallDirection - (2 * BallBounceNormal * dotProduct(BallDirection, BallBounceNormal))
    wait()
    DirectionRate = 0
    wait(0.1)
    DirectionRate=1.75
	if RULE_CONDITION: goto RULE_START


rule "Ball not active - restart":
    @Condition BallActive == false
    
    stopChasingVariable(BallPosition)
    BallPosition = vect(0, 1.5, 0)
    LastTargetedPlayer = null
    TargetedPlayer = random.choice(getLivingPlayers(Team.ALL))
	TailJoints = [BallPosition for jointPos in TailJoints]
    RoundCountdown = maxRoundCountdown
    while RoundCountdown > 0:
        wait(1)
        RoundCountdown -= 1

    BallActive = true


rule "Player presses primary fire - use dash":
    @Event eachPlayer
    @Condition eventPlayer.isHoldingButton(Button.PRIMARY_FIRE) == true
    eventPlayer.forceButtonPress(Button.ABILITY_1)

rule "Player presses secondary fire - use deflect":
    @Event eachPlayer
    @Condition eventPlayer.isHoldingButton(Button.SECONDARY_FIRE) == true
    eventPlayer.forceButtonPress(Button.ABILITY_2)


/*
BouncePads
*/

globalvar BouncePads

rule "Create BouncePads":
    BouncePads = []
    for i in range(NumBouncePads):
        BouncePads.append(vect(0, 0, 0) + angleToDirection(360 * ((i+1) / NumBouncePads), 0) * BouncePadDistance)
        createEffect([player for player in getAllPlayers() if player.BouncePadCooldown == 0], Effect.RING, Color.GREEN, evalOnce(BouncePads.last()), BouncePadSize, EffectReeval.VISIBILITY)
        createEffect([player for player in getAllPlayers() if player.BouncePadCooldown != 0], Effect.RING, Color.RED,   evalOnce(BouncePads.last()), BouncePadSize, EffectReeval.VISIBILITY)


rule "Player Bounces":
    @Event eachPlayer        
    @Condition eventPlayer.hasSpawned()
    @Condition eventPlayer.BouncePadCooldown == 0
    @Condition any([distance(eventPlayer.getPosition(), pad) <= BouncePadSize + 0.75 for pad in BouncePads])
    @Condition eventPlayer.isHoldingButton(Button.JUMP)

    eventPlayer.applyImpulse(Vector.UP, BouncePadStrength, Relativity.TO_WORLD, Impulse.CANCEL_CONTRARY_MOTION)
    eventPlayer.BouncePadCooldown = BouncePadMaxCooldown 


/*
rule "Debug":
*/

rule "(Debug) toggle ballActive":
    @Condition hostPlayer.isHoldingButton(Button.INTERACT) == true
    
    BallActive = not BallActive
    getDeadPlayers(Team.ALL).respawn()
	BallSpeed = StartingBallSpeed
	wait(0.25)


rule "Debug HUDs":
    hudHeader(hostPlayer, "Server Load: {0}\nServer Load Peak: {1}\nServer Load Average: {2}".format(updateEveryTick(getServerLoad()), updateEveryTick(getPeakServerLoad()), updateEveryTick(getAverageServerLoad())), HudPosition.LEFT, 0, Color.WHITE, HudReeval.VISIBILITY_AND_STRING, SpecVisibility.DEFAULT)
    hudHeader(hostPlayer, raycast(hostPlayer.getEyePosition(), hostPlayer.getEyePosition() + hostPlayer.getFacingDirection() * 10, null, null, false).getHitPosition(), HudPosition.RIGHT, 5, Color.WHITE, HudReeval.VISIBILITY_AND_STRING)


rule "lerp balldirection":
    @Disabled
    BallDirection = BallDirection + (directionTowards(BallPosition, TargetedPlayer.getEyePosition()) - BallDirection)*(1.75/31.25)
    wait(0.016)
    goto RULE_START


globalvar testDummy
rule "debug dummy":
    #@Disabled
	wait(3)
	createDummy(Hero.GENJI, Team.ALL, -1, null, null)
    testDummy = getLastCreatedEntity()
    testDummy.startFacing(angleToDirection(1, 0), 25, Relativity.TO_PLAYER, FacingReeval.DIRECTION_AND_TURN_RATE)


rule "ball close to dummy":
    @Condition distance(testDummy.getEyePosition(), BallPosition) <= 3
    @Condition hostPlayer.isHoldingButton(Button.ULTIMATE) == false
    
    testDummy.forceButtonPress(Button.ABILITY_2)


def PlayDeathEffects():
    @Name "sub_PlayDeathEffects"
    
    DeathSphereRadius = 30
    chase(DeathSphereRadius, 0, duration=0.25, ChaseReeval.DESTINATION_AND_DURATION)
    createBeam(getAllPlayers(), Beam.BAD, LastTargetedPlayer, TargetedPlayer, Color.RED, EffectReeval.VISIBILITY_POSITION_AND_RADIUS)
    DeathBeam = getLastCreatedEntity()
    /*createEffect(getAllPlayers(), Effect.SPHERE, Color.RED, TargetedPlayer, updateEveryTick(30 + (getTotalTimeElapsed() - evalOnce(getTotalTimeElapsed())) * -120), EffectReeval.VISIBILITY_POSITION_AND_RADIUS)*/
    createEffect(getAllPlayers(), Effect.SPHERE, Color.RED, TargetedPlayer, DeathSphereRadius, EffectReeval.VISIBILITY_POSITION_AND_RADIUS)
    DeathSphere = getLastCreatedEntity()
    playEffect(getAllPlayers(), DynamicEffect.RING_EXPLOSION_SOUND, Color.WHITE, evalOnce(TargetedPlayer.getPosition()), 40)
    playEffect(getAllPlayers(), DynamicEffect.GOOD_EXPLOSION, Color.WHITE, evalOnce(TargetedPlayer.getPosition()), 5)
    wait(0.256)
    playEffect(getAllPlayers(), DynamicEffect.RING_EXPLOSION, Color.RED, evalOnce(TargetedPlayer.getPosition()), 30)
    playEffect(getAllPlayers(), DynamicEffect.EXPLOSION_SOUND, Color.WHITE, evalOnce(TargetedPlayer.getPosition()), 40)
    destroyEffect(DeathSphere)
    destroyEffect(DeathBeam)
    stopChasingVariable(DeathSphereRadius)
