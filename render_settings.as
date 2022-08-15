/* Utility class for entity rendering
by Outerbeast
Supports a RenderIndividal method to emulate env_render_individual features
For more information about rendering, visit Sven Manor https://sites.google.com/site/svenmanor/rendermodes

Global Functions:-
* RGBA VectorToRGBA(const Vector vecColor, const float flAlpha = 255.0f)                    | Converts a Vector to RGBA, flApha will be rgba alpha value passed in.
* Vector RGBAtoVector(RGBA rgbaColor, float& out flAlpha = 0.0f)                            | Converts an RGBA to Vector, alpha amount is passed out "flApha"

Methods:-
* RenderSettings()                                                                          | Default constructor
* RenderSettings(const RenderSettings@ rs)                                                  | Constructor
* RenderSettings(int iRenderMode, int iRenderFx, float flRenderAmount, Vector vecColor)     | Constructor
* Render(int iRenderMode, int iRenderFx, RGBA rgbaColor)                                    | Constructor
* RenderSettings(EHandle hRenderDonor)                                                      | Constructor, receives render settings from another entity
* void Render(EHandle hEntity, int iRenderFlags = 0)                                        | Applies rendering to a given entity. See renderflags enum to select flags to exclude what render settings are applied.
* CBaseEntity@ RenderIndividual(EHandle hTarget, EHandle hPlayer, int iRenderFlags = 0)     | Applies rendering to a given entity, only visible to a given player. See renderflags enum to select flags to exclude what render settings are applied.
* void ResetRendering(EHandle hEntity, int iRenderFlags = 0)                                | Reverts entity's original rendering. See renderflags enum to select flags to exclude what render settings are applied.

Properties:-
int rendermode      | Entity render mode. See standard RenderModes enum for choices.
int renderfx        | Entity rendering effects. See RenderFX enum for choices
float renderamt     | Entity render amount. 
Vector rendercolor; | Entity render color. Format is Vector( r, g, b );

Notes:
RenderIndividual method returns a CBaseEntity handle to the env_render_individual instance it creates. Removing this entity will result in the rendering settings applied to reset.
Calling this method many times can lead to edicts being used and may result in free edicts running out. Use sparingly.
*/
enum renderflags
{
    NO_RENDER_FX    = 1,
    NO_RENDER_AMT   = 2,
    NO_RENDER_MODE  = 4,
    NO_RENDER_COLOR = 8
};

Vector RGBAtoVector(RGBA rgbaColor, float& out flAlpha = 0.0f)
{
    flAlpha = rgbaColor.a;

    return Vector( rgbaColor.r, rgbaColor.g, rgbaColor.b );
}

RGBA VectorToRGBA(const Vector vecColor, const float flAlpha = 255.0f)
{
    return RGBA( uint8( vecColor.x ), uint8( vecColor.y ), uint8( vecColor.z ), uint8( flAlpha ) );
}

final class RenderSettings
{
    int rendermode;
    int renderfx;
    float renderamt;
    Vector rendercolor;

    RenderSettings(const RenderSettings@ rs)
    {
        if( rs !is null )
        {
            rendermode = rs.rendermode;
            renderfx = rs.renderfx;
            renderamt = rs.renderamt;
            rendercolor = rs.rendercolor;
        }
    }

    RenderSettings(int iRenderMode, int iRenderFx, float flRenderAmount, Vector vecColor)
    {
        rendermode = iRenderMode;
        renderfx = iRenderFx;
        renderamt = flRenderAmount;
        rendercolor = vecColor;
    }

    RenderSettings(int iRenderMode, int iRenderFx, RGBA rgbaColor)
    {
        rendermode = iRenderMode;
        renderfx = iRenderFx;
        renderamt = rgbaColor.a;
        rendercolor = Vector( rgbaColor.r, rgbaColor.g, rgbaColor.b );
    }

    RenderSettings(EHandle hRenderDonor)
    {
        if( hRenderDonor )
        {
            rendermode = hRenderDonor.GetEntity().pev.rendermode;
            renderfx = hRenderDonor.GetEntity().pev.renderfx;
            renderamt = hRenderDonor.GetEntity().pev.renderamt;
            rendercolor = hRenderDonor.GetEntity().pev.rendercolor;
        }
    }

    void Render(EHandle hEntity, int iRenderFlags = 0)
    {
        if( !hEntity )
            return;

        CBaseEntity@ pEntity = hEntity.GetEntity();

        if( iRenderFlags & NO_RENDER_MODE == 0 )
            pEntity.pev.rendermode = rendermode;

        if( iRenderFlags & NO_RENDER_FX == 0 )
            pEntity.pev.renderfx = renderfx;

        if( iRenderFlags & NO_RENDER_AMT == 0 )
            pEntity.pev.renderamt = renderamt;
        
        if( iRenderFlags & NO_RENDER_COLOR == 0 )
            pEntity.pev.rendercolor = rendercolor;
    }

    CBaseEntity@ RenderIndividual(EHandle hTarget, EHandle hPlayer, int iRenderFlags = 0)
    {
        if( !hPlayer || !hTarget )
            return null;

        dictionary dictRenderIndividual =
        {
            { "rendermode", "" + rendermode },
            { "renderfx", "" + renderfx },
            { "renderamt", "" + renderamt },
            { "rendercolor", "" + rendercolor.ToString() },
            { "spawnflags", "" + iRenderFlags }
        };

        dictRenderIndividual["target"] = hTarget.GetEntity().GetTargetname() == "" ? 
                                string( hTarget.GetEntity().pev.targetname = string_t( "render_individual_entity_" + hTarget.GetEntity().entindex() ) ) :
                                hTarget.GetEntity().GetTargetname();
        
        dictRenderIndividual["netname"] = hPlayer.GetEntity().GetTargetname() == "" ? 
                                string( hPlayer.GetEntity().pev.targetname = string_t( "render_individual_player_" + hPlayer.GetEntity().entindex() ) ) : 
                                hPlayer.GetEntity().GetTargetname();

        CBaseEntity@ pRenderIndividual = g_EntityFuncs.CreateEntity( "env_render_individual", dictRenderIndividual );

        if( pRenderIndividual is null )
            return null;

        pRenderIndividual.Use( hPlayer.GetEntity(), pRenderIndividual, USE_ON, 0.0f );

        if( hPlayer.GetEntity().GetTargetname().StartsWith( "render_individual_" ) )
            hPlayer.GetEntity().pev.targetname = "";

        if( hTarget.GetEntity().GetTargetname().StartsWith( "render_individual_" ) )
            hTarget.GetEntity().pev.targetname = "";

        return pRenderIndividual;
    }

    void ResetRendering(EHandle hEntity, int iRenderFlags = 0)
    {
        if( !hEntity )
            return;

        CBaseEntity@ pEntity = hEntity.GetEntity();

        if( iRenderFlags & NO_RENDER_MODE == 0 )
            pEntity.pev.rendermode = pEntity.m_iOriginalRenderMode;

        if( iRenderFlags & NO_RENDER_FX == 0 )
            pEntity.pev.renderfx = pEntity.m_iOriginalRenderFX;

        if( iRenderFlags & NO_RENDER_AMT == 0 )
            pEntity.pev.renderamt = pEntity.m_flOriginalRenderAmount;
        
        if( iRenderFlags & NO_RENDER_COLOR == 0 )
            pEntity.pev.rendercolor = pEntity.m_vecOriginalRenderColor;
    }
};
