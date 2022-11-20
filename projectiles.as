/* Baseclass + custom entities for various projectile entities (WIP)
Testing, tweaks, improvements and pull requests welcome
- Outerbeast

TO-DO:-
- feature to shoot smg/ar/shotgun
- consts for projectile speed/dmg
*/
CProjectileFuncs g_ProjectileFuncs;

enum projectiletypes
{
    Bullet = 0, //Doing this last
    //Spore_rocket,// NOPE
    ///Spore_grenade,// NOPE
	ShockBeam,
	DisplacerBall,
    HandGrenade,
    ARGrenade,
    ClusterGrenade,
    Crossbow_bolt,
    Rpg_rocket,
    Apache_rocket,
    Garg_stomp,
    Squid_spit,
    Gonarch_spit,
    //Pitdrone_sting,// NOPE
    Voltigore_shock, // Maybe?
    Hornet,
    Kingpin_plasma,
    Controller_headball,
    Controller_energyball,
    Nihilanth_energyball
};

enum FireType
{
	Toggle = 1,
	FireOnTrigger,
};
// TO-DO: Implement kv behaviour
enum TargetType
{
    Random = 0,
    Sequential,
    All
}
// TO-DO: Implement flag behaviour
enum projectile_spawnflags
{
    SF_STARTON              = 1 << 0,
    SF_SHOOT_FROM_ORIGIN    = 1 << 2
};
// Default projectile speeds
const float
    flSpeed_ShockBeam    = 2000.0f,
    flSpeed_CrossbowBolt = 200.0f,
    flSpeed_Hornet       = 300.0f,
    flSpeed_HornetFast   = flSpeed_Hornet * 4,
    flSpeed_GargStomp    = 500.0f,
    flSpeed_ControllerEnergyBall = g_EngineFuncs.CVarGetFloat( "sk_controller_speedball" ),
    flSpeed_NihilanthEnergyBall = 600.0f,
// Default damages for each projectile
    flDamage_ShockBeam = g_EngineFuncs.CVarGetFloat( "sk_plr_shockrifle" ),
    flDamage_Displacer = g_EngineFuncs.CVarGetFloat( "sk_plr_displacer_other" ),
    flDamage_SquidSpit = g_EngineFuncs.CVarGetFloat( "sk_bullsquid_dmg_spit" );

const array<string> STR_PROJECTILE_ENTS =
{
    "sporegrenade",
    "shock_beam",
    "displacer_portal", // displacer_ball in opfor
    "bmortar", // gonarch spit
    "crossbow_bolt",
    "garg_stomp",
    //"streak_spiral", // garg_stomp alias
    "gonomespit",
    "grenade",
    "hornet",
    "playerhornet", // ???
    "pitdronespike",
    "rpg_rocket",
    "hvr_rocket", // apache rockets
    "squidspit",
    "voltigoreshock",
    "kingpin_plasma_ball",
    "controller_head_ball",
    "controller_energy_ball",
    "nihilanth_energy_ball"
},
STR_PROJECTILE_MDLS =
{
    "sprites/bigspit.spr",
    "sprites/blueflare2.spr",
    "sprites/gargeye1.spr",
    "sprites/mommaspit.spr",
    "sprites/mommaspout.spr",
    "sprites/mommablob.spr",
    "models/pit_drone_spike.mdl"
};

final class CProjectileFuncs : MXNProjectiles
{
    bool IsEntityRegistered()
    {
        return( g_CustomEntityFuncs.IsCustomEntity( "env_projectile" ) );
    }

    void EntityRegister()
    {
        if( IsEntityRegistered() )
            return;

        g_CustomEntityFuncs.RegisterCustomEntity( "env_projectile", "env_projectile" );
        g_CustomEntityFuncs.RegisterCustomEntity( "env_projectile", "env_blowercannon" ); // Compatibility for Opposing Force entity
    }
}

mixin class MXNProjectiles
{   
    void Precache()
	{
        for( uint i = 0; i < STR_PROJECTILE_ENTS.length(); i++ )
		    g_Game.PrecacheOther( STR_PROJECTILE_ENTS[i] );

        for( uint i = 0; i < STR_PROJECTILE_MDLS.length(); i++ )
            g_Game.PrecacheModel( STR_PROJECTILE_MDLS[i] );
	}
    //!-BUG-!: Being spawned z units above where its supposed to
    CBaseEntity@ ShootCrossbowBolt(Vector& in vecOrigin, Vector& in vecAngles, edict_t@ eOwner, float flSpeed = flSpeed_CrossbowBolt)
    {
        Math.MakeVectors( vecAngles );
        vecAngles.x	= -vecAngles.x;
        Vector vecAim = g_Engine.v_forward;

        CBaseEntity@ pCrossbowBolt = g_EntityFuncs.Create( "crossbow_bolt", vecOrigin, vecAngles, true, eOwner );
        pCrossbowBolt.pev.velocity = vecAim * flSpeed;
        pCrossbowBolt.pev.speed = flSpeed;

        g_EntityFuncs.DispatchSpawn( pCrossbowBolt.edict() );

        return pCrossbowBolt;
    }

    CBaseEntity@ ShootShockBeam(Vector& in vecOrigin, Vector& in vecAngles, edict_t@ eOwner, float flSpeed = flSpeed_ShockBeam, float flDamage = flDamage_ShockBeam)
    {
        CBaseEntity@ pShockBeam = g_EntityFuncs.Create( "shock_beam", vecOrigin, vecAngles, true, eOwner );

        Math.MakeVectors( vecAngles );

        pShockBeam.pev.velocity = g_Engine.v_forward * flSpeed;
        pShockBeam.pev.velocity.z = -pShockBeam.pev.velocity.z; // don't know what for but its in the sdk

        pShockBeam.pev.dmg = flDamage;

		g_EntityFuncs.DispatchSpawn( pShockBeam.edict() );

        return pShockBeam;
    }
    //!-LIMITATION-!: not enough exposed vars to configure this properly. Do not use.
    private CBaseEntity@ ShootSpore(Vector& in vecOrigin, Vector& in vecAngles, edict_t@ eOwner, int iType)
    {
        CBaseEntity@ pSpore = g_EntityFuncs.Create( "sporegrenade", vecOrigin, vecAngles, true, eOwner );

        if( iType == SporeRocket )
        {
            pSpore.pev.velocity = vecAngles;
            pSpore.pev.angles = Math.VecToAngles( vecAngles );
        }
        else
            pSpore.pev.angles = vecAngles;

        pSpore.pev.friction = 1;

		g_EntityFuncs.DispatchSpawn( pSpore.edict() );

        return pSpore;
    }

    CBaseEntity@ ShootHornet(Vector& in vecOrigin, Vector& in vecAngles, edict_t@ eOwner, float flSpeed = flSpeed_Hornet)
    {
        Math.MakeVectors( vecAngles );
        CBaseEntity@ pHornet = g_EntityFuncs.Create( eOwner.vars.ClassNameIs( "player" ) ? "playerhornet" : "hornet", vecOrigin, g_vecZero, true, eOwner );
        pHornet.pev.velocity = g_Engine.v_forward * flSpeed;
	    pHornet.pev.angles = Math.VecToAngles( pHornet.pev.velocity );

        g_EntityFuncs.DispatchSpawn( pHornet.edict() );

        return pHornet;
    }

    CBaseEntity@ ShootApacheRocket(Vector& in vecOrigin, Vector& in vecAngles, Vector& in vecVelocity, edict_t@ eOwner)
    {
        Math.MakeVectors( vecAngles );
        CBaseEntity@ pRocket = g_EntityFuncs.Create( "hvr_rocket", vecOrigin, vecAngles, false, eOwner );

        pRocket.pev.velocity = vecVelocity + g_Engine.v_forward * 100;

        return pRocket;
    }

    CBaseEntity@ GargStomp(Vector& in vecOrigin, Vector& in vecEnd, edict_t@ eOwner, float flSpeed = flSpeed_GargStomp)
    {
        CBaseEntity@ pStomp = g_EntityFuncs.Create( "garg_stomp", vecOrigin, g_vecZero, true, eOwner );
	
        Vector vecDir = vecEnd - vecOrigin;
        pStomp.pev.scale = vecDir.Length();
        pStomp.pev.movedir = vecDir.Normalize();
        pStomp.pev.speed = flSpeed;

        g_EntityFuncs.DispatchSpawn( pStomp.edict() );

        return pStomp;
    }

    CBaseEntity@ SquidSpit(Vector& in vecOrigin, Vector& in vecVelocity, edict_t@ eOwner, float flDamage = flDamage_SquidSpit)
    {
        CBaseEntity@ pSpit = g_EntityFuncs.Create( "squidspit", vecOrigin, vecVelocity, true, eOwner );
       
        pSpit.pev.velocity = vecVelocity;
        pSpit.pev.nextthink = g_Engine.time + 0.1f;
        g_EntityFuncs.DispatchSpawn( pSpit.edict() );

        return pSpit;
    }

    CBaseEntity@ GonarchSpit(Vector& in vecOrigin, Vector& in vecVelocity, edict_t@ eOwner)
    {
        g_EngineFuncs.ServerPrint( "MXNProjectiles::GonarchSpit: Ignore this error . " );
        CBaseEntity@ pSpit = g_EntityFuncs.Create( "bmortar", vecOrigin, vecVelocity, true, eOwner );
        pSpit.pev.scale = 2.5;
        pSpit.pev.velocity = vecVelocity;
        pSpit.pev.nextthink = g_Engine.time + 0.1f;
        g_EntityFuncs.DispatchSpawn( pSpit.edict() );

        return pSpit;
    }
    // !-BUG-!: projectile model orientation is broken, and can't be fixed (issue with global v_forward)
    CBaseEntity@ PitDroneSting(Vector& in vecOrigin, Vector& in vecVelocity, edict_t@ eOwner)
    {
        CBaseEntity@ pSpit = g_EntityFuncs.Create( "pitdronespike", vecOrigin, Math.VecToAngles( vecVelocity ), true, eOwner );
        pSpit.pev.velocity = vecVelocity;
        g_EntityFuncs.DispatchSpawn( pSpit.edict() );

        return pSpit;
    }
    // Some fx are missing
    CBaseEntity@ VoltigoreShock(Vector& in vecOrigin, Vector& in vecVelocity, edict_t@ eOwner)
    {
        CBaseEntity@ pShock = g_EntityFuncs.Create( "voltigoreshock", vecOrigin, Math.VecToAngles( vecVelocity ), true, eOwner );
        pShock.pev.velocity = vecVelocity;
        g_EntityFuncs.DispatchSpawn( pShock.edict() );

        return pShock;
    }
    // Doesn't obey direction!
    CBaseEntity@ PlasmaBall(Vector& in vecOrigin, Vector& in vecTarget, edict_t@ eOwner)
    {
        CBaseEntity@ pPlasmaBall = g_EntityFuncs.Create( "kingpin_plasma_ball", vecOrigin, g_vecZero, true, eOwner );

        if( eOwner !is null )
        {
            CBaseMonster@ pMonster = g_EntityFuncs.Instance( eOwner ).MyMonsterPointer();

            if( pMonster !is null && pMonster.m_hEnemy )
                pMonster.m_hEnemy = g_EntityFuncs.Create( "info_target", vecTarget, g_vecZero, false );
        }

        g_EntityFuncs.DispatchSpawn( pPlasmaBall.edict() );

        return pPlasmaBall;
    }

    CBaseEntity@ ControllerBall(Vector& in vecOrigin, Vector& in vecVelocity, edict_t@ eOwner float flSpeed = flSpeed_ControllerEnergyBall)
    {
        CBaseEntity@ pControllerBall = g_EntityFuncs.Create( "controller_energy_ball", vecOrigin, vecVelocity, eOwner );
        pControllerBall.pev.velocity = vecVelocity * flSpeed;

        return pControllerBall;
    }

    CBaseEntity@ NihilanthEnergyBall(Vector& in vecOrigin, Vector& in vecVelocity, edict_t@ eOwner float flSpeed = flSpeed_NihilanthEnergyBall)
    {
        CBaseEntity@ pNihilanthEnergyBall = g_EntityFuncs.Create( "nihilanth_energy_ball", vecOrigin, vecVelocity, eOwner );
        pNihilanthEnergyBall.pev.velocity = vecVelocity * flSpeed;

        return pNihilanthEnergyBall;
    }
}

final class env_projectile : ScriptBaseEntity, MXNProjectiles
{
    private bool blToggled;
	private float m_flShootInterval;
	private int m_iZOffset, m_iWeaponType, m_iFireType, m_iShootCountDefault = Math.INT32_MAX, m_iShootCountCurrent = Math.INT32_MAX;// lol
    private Vector vecPitDroneStingTrueAngle;
    private EHandle hShooter, hProjectile; // Will be the entity to have the projectile originate from + projectile entity owner

	bool KeyValue(string& in szKey, string& in szValue)
	{
		if( szKey == "weaptype" ) // compatibility for env_blowercannnon key, use "weapons" otherwise
			m_iWeaponType = atoi( szValue );
		else if( szKey == "firetype" ) //Firing type is dependant on delay value
			m_iFireType = atoi( szValue );
		else if( szKey == "zoffset" )
			m_iZOffset = atoi( szValue );
        else if( szKey == "count" )
			m_iShootCountDefault = m_iShootCountCurrent = atoi( szValue );
        else if( szKey == "delay" ) // 0 delay meants fire per trigger, otherwise shoot continuously per delay
			m_flShootInterval = atof( szValue );
		else
			return BaseClass.KeyValue( szKey, szValue );

        return true;
	}

	void Spawn()
	{
        Precache();

        self.pev.movetype 	= MOVETYPE_NONE;
		self.pev.solid 		= SOLID_NOT;
		self.pev.effects	|= EF_NODRAW;
		
		g_EntityFuncs.SetOrigin( self, self.pev.origin );
		// op4 entity, needs special configuration
		if( self.GetClassname() == "env_blowercannon" )
		{
            switch( m_iWeaponType )
            {
                case 3: self.pev.weapons = ShockBeam; break;
                case 4: self.pev.weapons = DisplacerBall; break;
                default: self.pev.weapons = 0; break;
            }
		}

        BaseClass.Spawn();
	}
    // TO-DO: make this less ugly
    void GetShooter()
    {
        if( !hShooter && self.pev.netname != "" )
        {
            CBaseEntity@ pEntity;

            while( ( @pEntity = g_EntityFuncs.FindEntityByTargetname( null, self.pev.netname ) ) !is null )
            {
                if( pEntity is null )
                    continue;

                hShooter = pEntity;

                if( hShooter )
                    break;
            }
        }
    }

    EHandle ShootProjectile(CBaseEntity@ pShooter)
    {   // TO-DO: allow for a different entity as the source
        if( self.pev.netname != "!activator" )
            GetShooter();

        edict_t@ eShooter = hShooter ? hShooter.GetEntity().edict() : ( self.pev.netname == "!activator" ? pShooter.edict() : self.edict() );
        Vector vecStart = hShooter ? hShooter.GetEntity().pev.origin : ( self.pev.netname == "!activator" ? pShooter.pev.origin : self.pev.origin );
        //Vector vecTarget = self.GetNextTarget() is null ? g_vecZero: self.GetNextTarget().pev.origin;
        Vector vecTarget = g_EntityFuncs.FindEntityByTargetname( null, self.pev.target ).pev.origin;
        // TO-DO: use entities own angles as direction, if no target exists
        if( vecTarget == g_vecZero )
            return EHandle();

		Vector vecDistance = vecTarget - vecStart;
		vecDistance.z += m_iZOffset;

		Vector vecAim = Math.VecToAngles( vecDistance );
		vecAim.z = -vecAim.z;
        // TO-DO: test all this shite. I bet none of this shoots in the right direction
        CBaseEntity@ pProjectile;

		switch( self.pev.weapons )
		{
            case ShockBeam:
                @pProjectile = ShootShockBeam( vecStart, vecAim, eShooter, self.pev.speed != 0.0f ? self.pev.speed : 2000.0f, self.pev.dmg );
                break;

            case DisplacerBall:
            {
                vecAim.x = -vecAim.x;
                Math.MakeVectors( vecAim );

                float flDisplacerDmg = self.pev.dmg == 0.0f ? g_EngineFuncs.CVarGetFloat( "sk_plr_displacer_other" ) : self.pev.dmg;

                @pProjectile = g_EntityFuncs.CreateDisplacerPortal( vecStart, g_Engine.v_forward * 500, eShooter, flDisplacerDmg, g_EngineFuncs.CVarGetFloat( "sk_plr_displacer_radius" ) );

                break;
            }
            // To-DO: offset position z by -30 units or so
            case Crossbow_bolt:
                @pProjectile = ShootCrossbowBolt( vecStart, vecAim, eShooter, self.pev.speed <= 0.0f ? 2000.0f : self.pev.speed );
                break;

            case HandGrenade:
                @pProjectile = g_EntityFuncs.ShootTimed( eShooter.vars, vecStart, vecDistance, 5.0f );
                break;

            case ARGrenade:
                @pProjectile = g_EntityFuncs.ShootContact( eShooter.vars, vecStart, vecDistance );
                break;

            case ClusterGrenade:
                @pProjectile = g_EntityFuncs.ShootBananaCluster( eShooter.vars, vecStart, vecDistance );
                break;

            case Rpg_rocket:
                @pProjectile = g_EntityFuncs.CreateRPGRocket( vecStart, vecAim, eShooter );
                break;

            case Apache_rocket:
                @pProjectile = ShootApacheRocket( vecStart, vecAim, vecDistance, eShooter );
                break;

            case Garg_stomp:
                @pProjectile = GargStomp( vecStart, vecTarget, eShooter, self.pev.speed <= 0.0f ? 500.0f : self.pev.speed );
                break;
            // "No Model 0!" even when precached correctly
            case Squid_spit:
                @pProjectile = SquidSpit( vecStart, vecDistance, eShooter );
                break;
             
            case Gonarch_spit:
                @pProjectile = GonarchSpit( vecStart, vecDistance, eShooter );
                break;
            // !-BUG-!: angles follow player's, shooting z units above origin
/*             case Pitdrone_sting:
            {
                //const float flStingSpeed = self.pev.speed == 0 ? 900 : 1;
                vecPitDroneStingTrueAngle = Math.VecToAngles( vecDistance );
                @pProjectile = PitDroneSting( vecStart, vecDistance, eShooter );

                break;
            } */
            // Needs speed scalar
            case Hornet:
                @pProjectile = ShootHornet( vecStart, vecAim, eShooter );
                break;

            case Voltigore_shock:
                @pProjectile = VoltigoreShock( vecStart, vecDistance, eShooter );
                break;
            // !-BUG-!: only goes straight.
            case Kingpin_plasma:
                @pProjectile = PlasmaBall( vecStart, vecTarget, eShooter );
                break;

            case Controller_energyball:
                @pProjectile = ControllerBall( vecStart, vecAim, eShooter );
                break;
        }
        
        if( pProjectile !is null )
        {
            if( pProjectile.pev.model != "" )
            {
                pProjectile.pev.rendermode = self.pev.rendermode;
                pProjectile.pev.rendercolor = self.pev.rendercolor;
                pProjectile.pev.renderamt = self.pev.renderamt;
            }
            
            g_EntityFuncs.FireTargets( "" + self.pev.message, g_EntityFuncs.Instance( eShooter ), pProjectile, USE_ON, 0.0f, 0.0f );
            //g_EngineFuncs.ServerPrint( " !    " + self.GetClassname() + "   ! - " + self.GetTargetname() + " shot " + pProjectile.GetClassname() + ".\n" ); // debug info

            return EHandle( pProjectile );
        }
        else
            return EHandle();
    }

    void Use(CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float value)
	{//TO-DO: add repeated shooting via ShootInterval
        g_EngineFuncs.ServerPrint( " !    env_projectile    ! - " + self.GetTargetname() + " triggered.\n" );

        switch( useType )
        {
            case USE_ON:
            {
                hProjectile = ShootProjectile( pActivator );

                if( m_flShootInterval > 0.0f )
                { // otherwise its one shot per trigger
                    self.pev.nextthink = g_Engine.time + m_flShootInterval;
                    g_EngineFuncs.ServerPrint( "env_projectile is now thinking.\n");
                }

                blToggled = true;

                break;
            }
    
            case USE_OFF:
            {
                if( m_flShootInterval > 0.0f )
                {
                    m_iShootCountCurrent = m_iShootCountDefault; // reset the current shooting count
                    self.pev.nextthink = 0.0f; // stop shooting automatically
                }

                blToggled = false;

                break;
            }

            case USE_TOGGLE:
                self.Use( hShooter, pCaller, blToggled ? USE_OFF : USE_ON, 0.0f );
                break;

            default: break;
        }
	}

    void Think()
    {
        g_EngineFuncs.ServerPrint( "env_projectile thinks.\n");
        --m_iShootCountCurrent;
        self.Use( hShooter.GetEntity(), self, m_iShootCountCurrent < 1 ? USE_OFF : USE_ON, 0.0f );
    }
}