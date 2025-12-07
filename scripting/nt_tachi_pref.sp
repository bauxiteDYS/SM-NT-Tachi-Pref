#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <clientprefs>
#include <sdktools>
#include <neotokyo>

#define DEBUG false

Cookie tachiCookie;

bool g_lateLoad;
bool g_autoTachi[NEO_MAXPLAYERS+1];

public Plugin myinfo = {
	name = "Tachi",
	author = "bauxite, credits: soft as HELL",
	description = "Changes the fire mode of the Tachi on spawn to preference",
	version	= "0.1.0",
	url	= ""
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	g_lateLoad = late;
	return APLRes_Success;
}

public void OnPluginStart()
{
	HookEvent("player_spawn", OnPlayerSpawnPost, EventHookMode_Post);
	
	tachiCookie = RegClientCookie("tachi_fire_mode", "Tachi fire mode preference", CookieAccess_Public);
	SetCookieMenuItem(TachiMenu, tachiCookie, "Tachi Spawn Fire Mode");
	
	if(g_lateLoad) // OnAllPluginsLoaded is called on late load
	{
		for(int client = 1; client <= MaxClients; client++)
		{
			if(IsClientInGame(client))
			{
				OnClientCookiesCached(client);
			}
		}
	}
}

public void OnClientCookiesCached(int client)
{
	int iAutoTachi;
	char buf[2];
	GetClientCookie(client, tachiCookie, buf, 2);
	iAutoTachi = StringToInt(buf);
	
	if(iAutoTachi == 1)
	{
		g_autoTachi[client] = true;
	}
	else
	{
		g_autoTachi[client] = false;
	}
}

public void TachiMenu(int client, CookieMenuAction action, any info, char[] buffer, int maxlen)
{
	if (action == CookieMenuAction_SelectOption) 
	{
		TachiCustomMenu(client);
	}
}

public Action TachiCustomMenu(int client)
{
	Menu menu = new Menu(TachiCustomMenu_Handler, MENU_ACTIONS_DEFAULT);
	menu.AddItem("on", "Auto");
	menu.AddItem("off", "Semi");
	menu.Display(client, MENU_TIME_FOREVER);
	return Plugin_Handled;
}

public int TachiCustomMenu_Handler(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_End) 
	{
		delete menu;
	}
	else if (action == MenuAction_Select) 
	{
		int client = param1;
		int selection = param2;

		char option[10];
		menu.GetItem(selection, option, sizeof(option));

		if (StrEqual(option, "on")) 
		{ 
			SetClientCookie(client, tachiCookie, "1");
			g_autoTachi[client] = true;
		} 
		else 
		{
			SetClientCookie(client, tachiCookie, "0");
			g_autoTachi[client] = false;
		}
	}
	
	return 0;
}

public void OnPlayerSpawnPost(Event event, const char[] name, bool dontBroadcast)
{
	int userid = event.GetInt("userid");
	int client = GetClientOfUserId(userid);
	
	// uhh cookies should have cached before player spawns since we are using client prefs local sqlite, if not, that might be a problem
	if(g_autoTachi[client] == true)
	{
		RequestFrame(SetupTachi, userid);
	}
}

void SetupTachi(int userid)
{
	int client = GetClientOfUserId(userid);
	
	if(client <= 0 || !IsClientInGame(client) || !IsPlayerAlive(client) || GetClientTeam(client) <= 1)
	{
		return;
	}
	
	int wep = GetEntPropEnt(client, Prop_Send, "m_hMyWeapons", 1);
	
	if (wep <= 0 || GetWeaponSlot(wep) != SLOT_SECONDARY)
	{
		return;
	}
	
	#if DEBUG
	PrintToServer("wep: %d", wep);
	#endif
	
	char classname[32];
	
	if(GetEntityClassname(wep, classname, sizeof(classname)) && StrEqual(classname, "weapon_tachi"))
	{
		SetEntProp(wep, Prop_Send, "m_iFireMode", 1);
	}
}
