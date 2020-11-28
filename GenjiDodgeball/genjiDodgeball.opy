settings
{
	lobby
	{
		Allow Players Who Are In Queue: Yes
		Match Voice Chat: Enabled
	}
	modes
	{
		Deathmatch
		{
			enabled maps
			{
				Workshop Island Night
			}
		}
		General
		{
			Allow Hero Switching: Off
			Game Mode Start: Immediately
			Hero Limit: Off
			Respawn As Random Hero: On
		}
	}
	heroes
	{
		General
		{
			Genji
			{
				Damage Dealt: 10%
				Damage Received: 10%
				Swift Strike Cooldown Time: 100%
				Deflect Cooldown Time: 0%
				Primary Fire: Off
				Quick Melee: Off
				Secondary Fire: Off
				Ultimate Ability Dragonblade: Off
			}
			enabled heroes
			{
				Genji
			}
		}
	}
}
variables {
    global:
        0: BallPosition
        1: TailJoints
        2: BallDirection
        3: TargetedPlayer
        4: LastTargetedPlayer
        5: BallActive
        6: BallSpeed
        7: BallBounceNormal
        8: i
        9: PlayerSettings
        10: BallSettings
        11: GameplaySettings
        12: BouncePadSettings
        13: VFXSettings
        14: DeathEffects
        15: DeathSphereRadius
        16: RoundCountdown
        17: BouncePads
        18: testDummy
    player:
        0: Deflects
        1: MaxDeflectedSpeed
        2: BouncePadCooldown
}
subroutines {
    0: PlayDeathEffects
}
rule ("Disable starting countdown") {
    event {
        Ongoing - Global;
    }
    conditions {
        Is In Setup == True;
    }
    actions {
        Set Match Time(0);
    }
}

rule ("Get workshop settings") {
    event {
        Ongoing - Global;
    }
    actions {
        Set Global Variable At Index(PlayerSettings, 0, Workshop Setting Real(Custom String("Player", Null, Null, Null), Custom String("Deflect Cooldown", Null, Null, Null), 0.5, 0, 10, 0));
        Set Global Variable At Index(PlayerSettings, 1, Workshop Setting Real(Custom String("Player", Null, Null, Null), Custom String("Dash Cooldown", Null, Null, Null), 2.7, 0, 10, 1));
        Set Global Variable At Index(PlayerSettings, 2, Workshop Setting Real(Custom String("Player", Null, Null, Null), Custom String("Deflect Duration", Null, Null, Null), 0.3, 0, 2, 2));
        Set Global Variable At Index(PlayerSettings, 3, Workshop Setting Real(Custom String("Player", Null, Null, Null), Custom String("Dash Stun Time", Null, Null, Null), 1, 0, 5, 3));
        Set Global Variable At Index(BallSettings, 1, Workshop Setting Real(Custom String("Ball", Null, Null, Null), Custom String("Maximum Ball Speed", Null, Null, Null), 1000, 10, 5000, 1));
        Set Global Variable At Index(BallSettings, 0, Min(Workshop Setting Real(Custom String("Ball", Null, Null, Null), Custom String("Starting Ball Speed", Null, Null, Null), 25, 10, 5000, 0), Value In Array(Global.BallSettings, 1)));
        Set Global Variable At Index(BallSettings, 2, Workshop Setting Real(Custom String("Ball", Null, Null, Null), Custom String("Ball Acceleration", Null, Null, Null), 0.5, 0, 25, 2));
        Set Global Variable At Index(BallSettings, 3, Add(1, Divide(Workshop Setting Real(Custom String("Ball", Null, Null, Null), Custom String("Deflected Ball Speed Increase %", Null, Null, Null), 5, 0, 500, 3), 100)));
        Set Global Variable At Index(GameplaySettings, 0, Workshop Setting Toggle(Custom String("Gameplay", Null, Null, Null), Custom String("Allow Interceptions", Null, Null, Null), False, 0));
        Set Global Variable At Index(BouncePadSettings, 0, Workshop Setting Real(Custom String("Bounce Pads", Null, Null, Null), Custom String("Bounce Pad Cooldown", Null, Null, Null), 3, 0, 15, 0));
        Set Global Variable At Index(BouncePadSettings, 1, Workshop Setting Integer(Custom String("Bounce Pads", Null, Null, Null), Custom String("Number of Bounce Pads", Null, Null, Null), 4, 0, 16, 1));
        Set Global Variable At Index(BouncePadSettings, 2, Workshop Setting Real(Custom String("Bounce Pads", Null, Null, Null), Custom String("Bounce Pad Strength", Null, Null, Null), 30, 0, 100, 2));
        Set Global Variable At Index(BouncePadSettings, 3, Workshop Setting Real(Custom String("Bounce Pads", Null, Null, Null), Custom String("Bounce Pad Size", Null, Null, Null), 2, 0, 25, 3));
        Set Global Variable At Index(BouncePadSettings, 4, Workshop Setting Real(Custom String("Bounce Pads", Null, Null, Null), Custom String("Bounce Pad Distance From Center", Null, Null, Null), 12, 0, 20, 4));
        Set Global Variable At Index(VFXSettings, 0, Workshop Setting Integer(Custom String("VFX", Null, Null, Null), Custom String("Number of Tail Segments", Null, Null, Null), 2, 0, 8, 0));
        Set Global Variable At Index(VFXSettings, 1, Workshop Setting Toggle(Custom String("VFX", Null, Null, Null), Custom String("Death Effects", Null, Null, Null), True, 1));
    }
}

rule ("Initialize Global") {
    event {
        Ongoing - Global;
    }
    actions {
        Set Global Variable(BallPosition, Vector(0, 1.5, 0));
        Set Global Variable(TailJoints, Array(Global.BallPosition));
        Set Global Variable(BallDirection, Vector(0, 0, 0));
        Set Global Variable(BallSpeed, First Of(Global.BallSettings));
        Chase Global Variable At Rate(BallDirection, Direction Towards(Global.BallPosition, Eye Position(Global.TargetedPlayer)), 1.75, Destination and Rate);
        Chase Global Variable At Rate(BallSpeed, Value In Array(Global.BallSettings, 1), If-Then-Else(Global.BallActive, Value In Array(Global.BallSettings, 2), 0), Destination and Rate);
        Disable Built-In Game Mode Announcer;
        Disable Built-In Game Mode Completion;
    }
}

rule ("Create global HUD elements") {
    event {
        Ongoing - Global;
    }
    actions {
        "white normal"
        Create HUD Text(Remove From Array(All Players(All Teams), Global.TargetedPlayer), Null, Null, Custom String("Current Player Targeted: {0}", Global.TargetedPlayer, Null, Null), Left, -2, Null, Null, Color(White), Visible To and String, Default Visibility);
        "red when you're targeted"
        Create HUD Text(Global.TargetedPlayer, Null, Null, Custom String("Current Player Targeted: {0}", Global.TargetedPlayer, Null, Null), Left, -2, Null, Null, Color(Red), Visible To and String, Default Visibility);
        Create HUD Text(All Dead Players(All Teams), Custom String("Waiting for next round", Null, Null, Null), Custom String("You have been eliminated or joined during a round", Null, Null, Null), Custom String("You will spawn once the next round starts", Null, Null, Null), Top, 2, Color(White), Color(White), Color(White), Visible To and String, Default Visibility);
        "gameplay tips text"
        Create HUD Text(All Players(All Teams), Null, Null, Custom String("Deflect or Dash will deflect the ball to an enemy", Null, Null, Null), Right, -10, Null, Null, Color(White), Visible To and String, Default Visibility);
        Create HUD Text(All Players(All Teams), Null, Null, Custom String("If you get hit, you die. Last {0} standing wins!", Hero Icon String(Hero(Genji)), Null, Null), Right, -9, Null, Null, Color(White), Visible To and String, Default Visibility);
        "ball speed text color change with speed"
        Create HUD Text(All Players(All Teams), Null, Null, Custom String("Current Ball Speed: {0}", Global.BallSpeed, Null, Null), Left, -3, Null, Null, If-Then-Else(Compare(Global.BallSpeed, <, 20), Color(Blue), If-Then-Else(Compare(Global.BallSpeed, <, 25), Color(Green), If-Then-Else(Compare(Global.BallSpeed, <, 30), Color(Yellow), If-Then-Else(Compare(Global.BallSpeed, <, 35), Color(Orange), If-Then-Else(Compare(Global.BallSpeed, <, 55), Color(Red), Color(Purple)))))), Visible To String and Color, Default Visibility);
    }
}

rule ("Initialize Player") {
    event {
        Ongoing - Each Player;
        All;
        All;
    }
    conditions {
        Has Spawned(Event Player) == True;
    }
    actions {
        Disable Built-In Game Mode Respawning(Event Player);
        Disable Game Mode HUD(Event Player);
        Disable Scoreboard(Event Player);
        Chase Player Variable At Rate(Event Player, BouncePadCooldown, 0, 1, None);
    }
}

rule ("Create player HUD elements") {
    event {
        Ongoing - Each Player;
        All;
        All;
    }
    actions {
        Create HUD Text(Event Player, (Event Player).Deflects, Custom String("Deflects", Null, Null, Null), Null, Left, 1, Color(Yellow), Color(White), Color(Yellow), Visible To and String, Default Visibility);
        Create HUD Text(Event Player, Round To Integer(Player Stat(Event Player, Eliminations), Down), Custom String("Kills", Null, Null, Null), Null, Left, 2, Color(Orange), Color(White), Color(Orange), Visible To and String, Default Visibility);
        Create HUD Text(Event Player, Round To Integer(Player Stat(Event Player, Deaths), Down), Custom String("Deaths", Null, Null, Null), Null, Left, 3, Color(Sky Blue), Color(White), Color(Sky Blue), Visible To and String, Default Visibility);
        Create HUD Text(Event Player, (Event Player).MaxDeflectedSpeed, Custom String("Highest Deflected Speed", Null, Null, Null), Null, Left, 4, Color(Red), Color(White), Color(Turquoise), Visible To and String, Default Visibility);
        Create HUD Text(Event Player, Round To Integer((Event Player).BouncePadCooldown, Up), Custom String("BouncePad", Null, Null, Null), Custom String("Cooldown", Null, Null, Null), Right, -1, Color(Green), Color(White), Color(White), Visible To and String, Default Visibility);
    }
}

rule ("Create the ball and its tail") {
    event {
        Ongoing - Global;
    }
    actions {
        Create Effect(Global.TargetedPlayer, Orb, Color(Red), Update Every Frame(Global.BallPosition), 1.9, Visible To Position and Radius);
        Create Effect(Remove From Array(All Players(All Teams), Global.TargetedPlayer), Orb, Color(White), Update Every Frame(Global.BallPosition), 1.9, Visible To Position and Radius);
        Create Effect(If-Then-Else(Compare(Global.TargetedPlayer, !=, Null), All Players(All Teams), Empty Array), Good Aura, Color(Red), Global.TargetedPlayer, 1, Visible To Position and Radius);
        Create Effect(Global.TargetedPlayer, Good Aura, Color(Red), Global.BallPosition, 1, Visible To Position and Radius);
        If(Compare(First Of(Global.VFXSettings), >, 0));
            Create Beam Effect(All Players(All Teams), Bad Beam, Update Every Frame(Global.BallPosition), Value In Array(Global.TailJoints, 1), Color(Yellow), Visible To Position and Radius);
        End;
        For Global Variable(i, 0, Subtract(First Of(Global.VFXSettings), 1), 1);
            Create Beam Effect(All Players(All Teams), Bad Beam, Value In Array(Global.TailJoints, Evaluate Once(Add(Global.i, 1))), Value In Array(Global.TailJoints, Evaluate Once(Add(Global.i, 2))), Color(Yellow), Visible To Position and Radius);
        End;
    }
}

rule ("Create starter podium") {
    event {
        Ongoing - Global;
    }
    actions {
        Create In-World Text(If-Then-Else(Global.BallActive, Null, All Players(All Teams)), Global.RoundCountdown, Vector(0, 2, 0), 4, Do Not Clip, Visible To and String, Color(Sky Blue), Default Visibility);
        Create Effect(If-Then-Else(Global.BallActive, Null, All Players(All Teams)), Sphere, Color(Sky Blue), Vector(0, 0, 0), 3.5, Visible To);
    }
}

rule ("Round starting! Setup") {
    event {
        Ongoing - Global;
    }
    conditions {
        Global.BallActive == True;
    }
    actions {
        Chase Global Variable At Rate(BallPosition, Add(Update Every Frame(Global.BallPosition), Update Every Frame(Global.BallDirection)), Global.BallSpeed, Destination and Rate);
        "TargetedPlayer = random.choice(getLivingPlayers(Team.ALL))"
        Set Global Variable(BallDirection, Direction Towards(Global.BallPosition, Eye Position(Global.TargetedPlayer)));
    }
}

rule ("Shorten deflect") {
    event {
        Ongoing - Each Player;
        All;
        All;
    }
    conditions {
        Is Using Ability 2(Event Player) == True;
    }
    actions {
        Wait(Value In Array(Global.PlayerSettings, 2), Ignore Condition);
        Set Ability 1 Enabled(Event Player, False);
        Set Ability 2 Enabled(Event Player, False);
        Wait(First Of(Global.PlayerSettings), Ignore Condition);
        Set Ability 1 Enabled(Event Player, True);
        Set Ability 2 Enabled(Event Player, True);
    }
}

rule ("Update tail joints") {
    event {
        Ongoing - Global;
    }
    actions {
        While(True);
            Set Global Variable(TailJoints, Append To Array(Global.BallPosition, Array Slice(Global.TailJoints, 0, First Of(Global.VFXSettings))));
            Wait(Divide(0.128, First Of(Global.VFXSettings)), Ignore Condition);
        End;
    }
}

rule ("Dash Cooldown") {
    event {
        Ongoing - Each Player;
        All;
        All;
    }
    conditions {
        Update Every Frame(Is Using Ability 1(Event Player)) == False;
    }
    actions {
        "waitUntil(not eventPlayer.isUsingAbility1(), 1)
\n 30% of 8 seconds, genji's CD at time of entry"
        Set Ability Cooldown(Event Player, Button(Ability 1), Value In Array(Global.PlayerSettings, 1));
    }
}

rule ("Intercept") {
    event {
        Ongoing - Each Player;
        All;
        All;
    }
    conditions {
        First Of(Global.GameplaySettings) == True;
        Global.BallActive == True;
        Global.LastTargetedPlayer != Event Player;
        Update Every Frame(Distance Between(Global.BallPosition, Eye Position(Event Player))) <= 1.9;
        Or(Is Using Ability 1(Event Player), Is Using Ability 2(Event Player)) == True;
    }
    actions {
        Set Global Variable(TargetedPlayer, Event Player);
    }
}

rule ("Ball reaches player") {
    event {
        Ongoing - Global;
    }
    conditions {
        Update Every Frame(Distance Between(Global.BallPosition, Eye Position(Global.TargetedPlayer))) <= 1.9;
        Global.BallActive == True;
    }
    actions {
        If(Or(Is Using Ability 1(Global.TargetedPlayer), Is Using Ability 2(Global.TargetedPlayer)));
            "cancel dash if they used it to deflect"
            If(Is Using Ability 1(Global.TargetedPlayer));
                Set Status(Global.TargetedPlayer, Null, Knocked Down, 1);
                Teleport(Global.TargetedPlayer, Global.BallPosition);
            End;
            Modify Player Variable(Global.TargetedPlayer, Deflects, Add, 1);
            Modify Player Variable(Global.TargetedPlayer, MaxDeflectedSpeed, Max, Global.BallSpeed);
            Set Global Variable(BallSpeed, Min(Value In Array(Global.BallSettings, 1), Multiply(Global.BallSpeed, Value In Array(Global.BallSettings, 3))));
            Play Effect(All Players(All Teams), Explosion Sound, Color(White), Position Of(Global.TargetedPlayer), 200);
            Set Global Variable(BallDirection, Facing Direction Of(Global.TargetedPlayer));
            "get closest living player to reticle"
            Set Global Variable(LastTargetedPlayer, Global.TargetedPlayer);
            Set Global Variable(TargetedPlayer, First Of(Sorted Array(Remove From Array(All Living Players(All Teams), Global.TargetedPlayer), Angle Between Vectors(Facing Direction Of(Global.TargetedPlayer), Direction Towards(Eye Position(Global.TargetedPlayer), Eye Position(Current Array Element))))));
            Wait(0.016, Ignore Condition);
            Loop If Condition Is True;
        Else;
            Set Status(Global.TargetedPlayer, Global.LastTargetedPlayer, Stunned, 1);
            Kill(Global.TargetedPlayer, Global.LastTargetedPlayer);
            If(Value In Array(Global.VFXSettings, 1));
                Start Rule(PlayDeathEffects, Do Nothing);
    }
}

rule ("Ball bounces off wall or ground") {
    event {
        Ongoing - Global;
    }
    conditions {
        Update Every Frame(Ray Cast Hit Position(Global.BallPosition, Add(Global.BallPosition, Global.BallDirection), Null, All Players(All Teams), False)) != Add(Global.BallPosition, Global.BallDirection);
    }
    actions {
        Set Global Variable(BallBounceNormal, Ray Cast Hit Normal(Global.BallPosition, Add(Global.BallPosition, Global.BallDirection), Null, All Players(All Teams), False));
        Wait(0.016, Ignore Condition);
        Modify Global Variable(BallDirection, Subtract, Multiply(Multiply(2, Global.BallBounceNormal), Dot Product(Global.BallDirection, Global.BallBounceNormal)));
        Wait(0.016, Ignore Condition);
        Loop If Condition Is True;
    }
}

rule ("Ball not active - restart") {
    event {
        Ongoing - Global;
    }
    conditions {
        Global.BallActive == False;
    }
    actions {
        Stop Chasing Global Variable(BallPosition);
        Set Global Variable(BallPosition, Vector(0, 1.5, 0));
        Set Global Variable(LastTargetedPlayer, Null);
        Set Global Variable(TargetedPlayer, Random Value In Array(All Players(All Teams)));
        Set Global Variable(TailJoints, Mapped Array(Global.TailJoints, Global.BallPosition));
        Set Global Variable(RoundCountdown, 5);
        While(Compare(Global.RoundCountdown, >, 0));
            Wait(1, Ignore Condition);
            Modify Global Variable(RoundCountdown, Subtract, 1);
        End;
        Set Global Variable(BallActive, True);
    }
}

rule ("Player presses primary fire - use dash") {
    event {
        Ongoing - Each Player;
        All;
        All;
    }
    conditions {
        Is Button Held(Event Player, Button(Primary Fire)) == True;
    }
    actions {
        Press Button(Event Player, Button(Ability 1));
    }
}

rule ("Player presses secondary fire - use deflect") {
    event {
        Ongoing - Each Player;
        All;
        All;
    }
    conditions {
        Is Button Held(Event Player, Button(Secondary Fire)) == True;
    }
    actions {
        Press Button(Event Player, Button(Ability 2));
    }
}

rule ("Create BouncePads") {
    event {
        Ongoing - Global;
    }
    actions {
        Set Global Variable(BouncePads, Empty Array);
        For Global Variable(i, 0, Value In Array(Global.BouncePadSettings, 1), 1);
            Modify Global Variable(BouncePads, Append To Array, Add(Vector(0, 0, 0), Multiply(Direction From Angles(Multiply(360, Divide(Add(Global.i, 1), Value In Array(Global.BouncePadSettings, 1))), 0), Value In Array(Global.BouncePadSettings, 4))));
            Create Effect(Filtered Array(All Players(All Teams), Compare((Current Array Element).BouncePadCooldown, ==, 0)), Ring, Color(Green), Evaluate Once(Last Of(Global.BouncePads)), Value In Array(Global.BouncePadSettings, 3), Visible To);
            Create Effect(Filtered Array(All Players(All Teams), Compare((Current Array Element).BouncePadCooldown, !=, 0)), Ring, Color(Red), Evaluate Once(Last Of(Global.BouncePads)), Value In Array(Global.BouncePadSettings, 3), Visible To);
        End;
    }
}

rule ("Player Bounces") {
    event {
        Ongoing - Each Player;
        All;
        All;
    }
    conditions {
        Has Spawned(Event Player) == True;
        (Event Player).BouncePadCooldown == 0;
        Is True For Any(Global.BouncePads, Compare(Distance Between(Position Of(Event Player), Current Array Element), <=, Add(Value In Array(Global.BouncePadSettings, 3), 0.75))) == True;
        Is Button Held(Event Player, Button(Jump)) == True;
    }
    actions {
        Apply Impulse(Event Player, Up, Value In Array(Global.BouncePadSettings, 2), To World, Cancel Contrary Motion);
        Set Player Variable(Event Player, BouncePadCooldown, First Of(Global.BouncePadSettings));
    }
}

rule ("(Debug) toggle ballActive") {
    event {
        Ongoing - Global;
    }
    conditions {
        Is Button Held(Host Player, Button(Interact)) == True;
    }
    actions {
        Set Global Variable(BallActive, Not(Global.BallActive));
        Respawn(All Dead Players(All Teams));
        Set Global Variable(BallSpeed, First Of(Global.BallSettings));
        Wait(0.25, Ignore Condition);
    }
}

rule ("Debug HUDs") {
    event {
        Ongoing - Global;
    }
    actions {
        Create HUD Text(Host Player, Custom String("Server Load: {0}\nServer Load Peak: {1}\nServer Load Average: {2}", Update Every Frame(Server Load), Update Every Frame(Server Load Peak), Update Every Frame(Server Load Average)), Null, Null, Left, 0, Color(White), Null, Null, Visible To and String, Default Visibility);
        Create HUD Text(Host Player, Ray Cast Hit Position(Eye Position(Host Player), Add(Eye Position(Host Player), Multiply(Facing Direction Of(Host Player), 10)), Null, Null, False), Null, Null, Right, 5, Color(White), Null, Null, Visible To and String, Default Visibility);
    }
}

disabled rule ("lerp balldirection") {
    event {
        Ongoing - Global;
    }
    actions {
        Modify Global Variable(BallDirection, Add, Multiply(Subtract(Direction Towards(Global.BallPosition, Eye Position(Global.TargetedPlayer)), Global.BallDirection), 0.056));
        Wait(0.016, Ignore Condition);
        Loop;
    }
}

rule ("debug dummy") {
    event {
        Ongoing - Global;
    }
    actions {
        "@Disabled"
        Wait(3, Ignore Condition);
        Create Dummy Bot(Hero(Genji), All Teams, -1, Null, Null);
        Set Global Variable(testDummy, Last Created Entity);
        Start Facing(Global.testDummy, Direction From Angles(1, 0), 25, To Player, Direction and Turn Rate);
    }
}

rule ("ball close to dummy") {
    event {
        Ongoing - Global;
    }
    conditions {
        Distance Between(Eye Position(Global.testDummy), Global.BallPosition) <= 3;
        Is Button Held(Host Player, Button(Ultimate)) == False;
    }
    actions {
        Press Button(Global.testDummy, Button(Ability 2));
    }
}

rule ("sub_PlayDeathEffects") {
    event {
        Subroutine;
        PlayDeathEffects;
    }
    actions {
        Set Global Variable(DeathSphereRadius, 30);
        Chase Global Variable Over Time(DeathSphereRadius, 0, 0.25, Destination and Duration);
        Create Beam Effect(All Players(All Teams), Bad Beam, Global.LastTargetedPlayer, Global.TargetedPlayer, Color(Red), Visible To Position and Radius);
        Set Global Variable At Index(DeathEffects, 0, Last Created Entity);
        Create Effect(All Players(All Teams), Sphere, Color(Red), Global.TargetedPlayer, Global.DeathSphereRadius, Visible To Position and Radius);
        Set Global Variable At Index(DeathEffects, 1, Last Created Entity);
        Play Effect(All Players(All Teams), Ring Explosion Sound, Color(White), Evaluate Once(Position Of(Global.TargetedPlayer)), 40);
        Play Effect(All Players(All Teams), Good Explosion, Color(White), Evaluate Once(Position Of(Global.TargetedPlayer)), 5);
        Wait(0.256, Ignore Condition);
        Play Effect(All Players(All Teams), Ring Explosion, Color(Red), Evaluate Once(Position Of(Global.TargetedPlayer)), 30);
        Play Effect(All Players(All Teams), Explosion Sound, Color(White), Evaluate Once(Position Of(Global.TargetedPlayer)), 40);
        Destroy Effect(Value In Array(Global.DeathEffects, 1));
        Destroy Effect(First Of(Global.DeathEffects));
        Stop Chasing Global Variable(DeathSphereRadius);
    }
}

