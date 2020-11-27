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

#Global variables

globalvar BallPosition 
globalvar TailJoint1 
globalvar TailJoint2 
globalvar TailJoint3 
globalvar TailJoint4 
globalvar BallDirection 
globalvar TargetedPlayer 
globalvar LastTargetedPlayer 
globalvar BallActive 
globalvar BallSpeed 
globalvar BallBounceNormal


#Player variables

#!define isBlocking(player) ((player).isUsingAbility1() or (player).isUsingAbility2())


/*
rule "Setup":
*/

rule "Disable starting countdown":
    @Condition isInSetup() == true
    
    setMatchTime(0)


rule "Initialize Global":
    BallPosition = vect(0, 1.5, 0)
    TailJoint1 = vect(0, 0, 0)
    TailJoint2 = vect(0, 0, 0)
    BallDirection = vect(0, 0, 0)
    BallSpeed = 25
    chase(BallDirection, directionTowards(BallPosition, TargetedPlayer.getEyePosition()), rate=1.75, ChaseReeval.DESTINATION_AND_RATE)
    chase(BallSpeed, 9999, rate=0.5 if BallActive else 0, ChaseReeval.DESTINATION_AND_RATE)
    disableAnnouncer()
    disableGamemodeCompletion()


rule "Initialize Player":
    @Event eachPlayer
    @Hero all
    @Condition eventPlayer.hasSpawned() == true
    
    eventPlayer.disableRespawn()
    eventPlayer.disableGamemodeHud()
    eventPlayer.disableScoreboard()


#!define BALL_RADIUS 1.9

rule "Create the ball and its tail":
    createEffect(updateEveryTick(TargetedPlayer), Effect.ORB, Color.RED, updateEveryTick(BallPosition), BALL_RADIUS, EffectReeval.VISIBILITY_POSITION_AND_RADIUS)
    createEffect(updateEveryTick(getAllPlayers().exclude(TargetedPlayer)), Effect.ORB, Color.YELLOW, updateEveryTick(BallPosition), BALL_RADIUS, EffectReeval.VISIBILITY_POSITION_AND_RADIUS)
    createBeam(getAllPlayers(), Beam.BAD, updateEveryTick(BallPosition), updateEveryTick(TailJoint1), Color.YELLOW, EffectReeval.VISIBILITY_POSITION_AND_RADIUS)
    createBeam(getAllPlayers(), Beam.BAD, updateEveryTick(TailJoint1), updateEveryTick(TailJoint2), Color.YELLOW, EffectReeval.VISIBILITY_POSITION_AND_RADIUS)

/*
rule "Gameplay":
*/

rule "Round starting! Setup":
    @Condition BallActive == true
    
    chase(BallPosition, BallPosition +  updateEveryTick(BallDirection), rate=BallSpeed, ChaseReeval.DESTINATION_AND_RATE)
    TargetedPlayer = random.choice(getLivingPlayers(Team.ALL))
    BallDirection = directionTowards(BallPosition, TargetedPlayer.getEyePosition())


rule "Shorten deflect":
    @Event eachPlayer
    @Hero all
    @Condition eventPlayer.isUsingAbility2() == true
    
    wait(0.3)
    eventPlayer.setAbility1Enabled(false)
    eventPlayer.setAbility2Enabled(false)
    wait(0.5)
    eventPlayer.setAbility1Enabled(true)
    eventPlayer.setAbility2Enabled(true)

rule "Update tail joints":
    while true:
        TailJoint4 = TailJoint3
        TailJoint3 = TailJoint2
        TailJoint2 = TailJoint1
        TailJoint1 = BallPosition        
        wait(0.064)

rule "Dash Cooldown = 2.7":
    @Event eachPlayer
    @Hero all
    @Condition updateEveryTick(eventPlayer.isUsingAbility1()) == true
    
    waitUntil(not eventPlayer.isUsingAbility1(), 1)
    #30% of 8 seconds, genji's CD at time of entry
    eventPlayer.setAbilityCooldown(Button.ABILITY_1, 2.7)


rule "Ball reaches player, they miss":
    @Condition updateEveryTick(distance(BallPosition, TargetedPlayer.getEyePosition())) <= BALL_RADIUS
    @Condition isBlocking(TargetedPlayer) == false
    @Condition BallActive == true
    
    kill(TargetedPlayer, LastTargetedPlayer)


rule "Player lands block - bounce":
    @Condition updateEveryTick(distance(BallPosition, TargetedPlayer.getEyePosition())) <= BALL_RADIUS
    @Condition isBlocking(TargetedPlayer) == true
    @Condition BallActive == true
    
    #cancel dash if they used it
    if TargetedPlayer.isUsingAbility1():
        TargetedPlayer.setStatusEffect(null, Status.KNOCKED_DOWN, 1)
    BallDirection = TargetedPlayer.getFacingDirection()
    #get closest living player to reticle
    LastTargetedPlayer = TargetedPlayer
    TargetedPlayer = sorted(getLivingPlayers(Team.ALL).exclude(TargetedPlayer), lambda i: angleBetweenVectors(TargetedPlayer.getFacingDirection(), directionTowards(TargetedPlayer.getEyePosition(), i.getEyePosition())))[0]


rule "Ball bounces off wall or ground":
    @Condition updateEveryTick(raycast(BallPosition, BallPosition + BallDirection, null, getAllPlayers(), false).getHitPosition()) != BallPosition + BallDirection
    
    BallBounceNormal = raycast(BallPosition, BallPosition + BallDirection, null, getAllPlayers(), false).getNormal()
    BallDirection = BallDirection - (2 * BallBounceNormal * dotProduct(BallDirection, BallBounceNormal))


rule "Ball not active - restart":
    @Condition BallActive == false
    
    stopChasingVariable(BallPosition)
    BallPosition = vect(0, 1.5, 0)
    LastTargetedPlayer = null
    TargetedPlayer = null
    TailJoint1 = BallPosition
    TailJoint2 = BallPosition


/*
rule "Debug":
*/

rule "(Debug) toggle ballActive":
    @Condition hostPlayer.isHoldingButton(Button.INTERACT) == true
    
    BallActive = not BallActive
    getDeadPlayers(Team.ALL).respawn()
    BallSpeed = 25


rule "Debug HUDs":
    hudHeader(hostPlayer, "isBlocking: {0}".format(updateEveryTick(isBlocking(hostPlayer))), HudPosition.LEFT, 0, Color.WHITE, HudReeval.VISIBILITY_AND_STRING, SpecVisibility.DEFAULT)


