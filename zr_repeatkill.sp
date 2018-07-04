#pragma semicolon 1

#include <sourcemod>
#include <zombiereloaded>

#define PLUGIN_NAME 	"ZR Repeat Kill Detector"
#define PLUGIN_VERSION 	"1.1.1"

new Handle:g_hRespawnDelay = INVALID_HANDLE;
new Float:g_fDeathTime[MAXPLAYERS+1];
new bool:g_bBlockRespawn = false;
 
public Plugin:myinfo =
{
	name = PLUGIN_NAME,
	author = "GoD-Tony, modified by Vauff",
	description = "Disables respawning on maps with repeat killers",
	version = PLUGIN_VERSION,
	url = "https://github.com/Vauff/ZR_RepeatKill"
};

public void OnPluginStart() 
{
	RegAdminCmd("sm_togglerepeatkill", ToggleRepeatKill, ADMFLAG_GENERIC, "Turns off the repeat killer detector if it is enabled");
	RegAdminCmd("sm_togglerk", ToggleRepeatKill, ADMFLAG_GENERIC, "Turns off the repeat killer detector if it is enabled");
	RegAdminCmd("sm_rk", ToggleRepeatKill, ADMFLAG_GENERIC, "Turns off the repeat killer detector if it is enabled");
}

public OnAllPluginsLoaded()
{
	if ((g_hRespawnDelay = FindConVar("zr_respawn_delay")) == INVALID_HANDLE)
	{
		SetFailState("Failed to find zr_respawn_delay cvar.");
	}

	CreateConVar("zr_repeatkill_version", PLUGIN_VERSION, PLUGIN_NAME, FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	HookEvent("round_start", Event_RoundStart, EventHookMode_PostNoCopy);
	HookEvent("player_death", Event_PlayerDeath, EventHookMode_Post);
}

public Action ToggleRepeatKill(int client, int args) 
{
	if (g_bBlockRespawn)
	{
		PrintToChatAll(" \x04[ZR]\x01 Repeat killer detector force toggled off. Re-enabling respawn for this round.");
		ServerCommand("zr_zspawn_force @all 1");
		g_bBlockRespawn = false;
	}
	else
	{
		PrintToChat(client, " \x06 Repeat killer is already turned off!");
	}

	return Plugin_Handled;
}

public OnClientDisconnect(client)
{
	g_fDeathTime[client] = 0.0;
}

public Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	g_bBlockRespawn = false;
}

public Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (g_bBlockRespawn)
	{
		return;
	}

	decl String:weapon[32];
	GetEventString(event, "weapon", weapon, sizeof(weapon));

	new victim = GetClientOfUserId(GetEventInt(event, "userid"));
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));

	if (victim && !attacker && StrEqual(weapon, "trigger_hurt"))
	{
		new Float:fGameTime = GetGameTime();

		if (fGameTime - g_fDeathTime[victim] - GetConVarFloat(g_hRespawnDelay) < 5.0)
		{
			PrintToChatAll(" \x04[ZR]\x01 Repeat killer detected. Disabling respawn for this round.");
			g_bBlockRespawn = true;
		}

		g_fDeathTime[victim] = fGameTime;
	}
}

public Action:ZR_OnClientRespawn(&client, &ZR_RespawnCondition:condition)
{
	if (g_bBlockRespawn)
	{
		return Plugin_Handled;
	}

	return Plugin_Continue;
}
