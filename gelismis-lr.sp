#pragma semicolon 1

#define PLUGIN_AUTHOR "Vortéx!"
#define PLUGIN_VERSION "1.00"

#include <sourcemod>
#include <sdktools>
#include <multicolors>
#include <cstrike>
#include <smlib>
#include <sdkhooks>
#include <store>
#include <warden>
#define LoopClients(%1) for (int %1 = 1; %1 <= MaxClients; %1++) if (IsClientInGame(%1))

bool vortex_lr = false;
int vortex_bodysayi[MAXPLAYERS + 1];
int vortex_ct = -1;
int vortex_t = -1;
int vortex_sayimdeger;
bool vortex_CanFire[MAXPLAYERS + 1];
bool vortex_InLR[MAXPLAYERS + 1];
bool vortex_NoscopeLR;
bool vortex_KnifeLR;
bool vortex_DeagleLR;
ConVar kredi;
ConVar kredi2;

ConVar tagi;
char taggo[64];

new const String:FULL_SOUND_PATH[] = "sound/vortex/lrsarki.mp3";
new const String:RELATIVE_SOUND_PATH[] = "*/vortex/lrsarki.mp3";

public Plugin myinfo = 
{
	name = "Gelişmiş LR Eklentisi",
	author = PLUGIN_AUTHOR,
	version = PLUGIN_VERSION,
	url = "csgoplugin.center"
};

public void OnPluginStart()
{
	tagi = CreateConVar("sourceturk_eklenti_taglari", "SOURCETURK.NET", "Eklenti taglarını giriniz.");
	GetConVarString(tagi, taggo, sizeof(taggo));
	kredi = CreateConVar("sourceturk_lr_noscope_kredi", "300", "NoScope LR'de yenen oyuncuya kaç kredi verilsin?");
	kredi2 = CreateConVar("sourceturk_lr_knife_kredi", "300", "Bıçak LR'de yenen oyuncuya kaç kredi verilsin?");
	RegConsoleCmd("sm_lr", lastrequest);
	RegConsoleCmd("sm_lriptal", iptal);
	HookEvent("weapon_fire", weaponfire);
	HookEvent("player_hurt", hurt);
	HookEvent("player_death", playerdeath);
}

public void OnMapStart()
{
    AddFileToDownloadsTable( FULL_SOUND_PATH );
    FakePrecacheSound( RELATIVE_SOUND_PATH );
    
	decl String:mapName[64];
	GetCurrentMap(mapName, sizeof(mapName));
	
	if(!((StrContains(mapName, "jb_", false) != -1) || (StrContains(mapName, "jail_", false)!= -1) || (StrContains(mapName, "ba_jail_", false)!= -1)))
	{
		SetFailState("Bu eklenti yalnizca jail modunda calismaktadir!");
	}
}

public Action iptal(int client, int args)
{
	if(vortex_lr)
	{
		char name[64];
		GetClientName(client, name, sizeof(name));
		vortex_lr = false;
		ResetLR();
		CPrintToChatAll("{darkred}[%s] {orange}%s {default}tarafından {green}LR {lightred}iptal edildi.", taggo, name);
	}
	else CPrintToChat(client, "{darkred}[%s] {lime}Oynanan bir {green}LR {lightred}yok.", taggo);
}


public Action lastrequest(int client, int args)
{
	if(vortex_lr)
	{
		CPrintToChat(client, "{darkred}[%s] {green}Şuan zaten bir {lime}LR {green}oynanıyor!", taggo);
		return Plugin_Handled;
	}
	
	int takim = GetClientTeam(client);
	if(IsClientInGame(client))
	{
		if(GetClientTeam(client) == CS_TEAM_T)
		{
			if (GetAliveTeamCount(takim) == 1)
			{
				RespawnCTS();
				lrmenu(client);
			}
			else CPrintToChat(client, "{darkred}[%s] {green}LR {lime}atabilmek için {darkblue}sona kalmalısınız.", taggo);
		}
		else CPrintToChat(client, "{darkred}[%s] {green}LR {lime}atabilmek için \x01\x0B\x09T takımında {lightred}olmalısınız.", taggo);
	}
	return Plugin_Handled;
}

public void OnClientPutInServer(int client)
{
	SDKHook(client, SDKHook_WeaponCanUse, OnWeaponDecideUse);
}

public Action OnWeaponDecideUse(client, weapon)
{
	if (vortex_KnifeLR)
	{
		char weapon_name[32];
		GetEdictClassname(weapon, weapon_name, sizeof(weapon_name));
		
		if ((client == vortex_t || client == vortex_ct) && !StrEqual(weapon_name, "weapon_knife"))
		{
			return Plugin_Handled;
		}
	}
	else if (vortex_NoscopeLR)
	{
		char weapon_name[32];
		GetEdictClassname(weapon, weapon_name, sizeof(weapon_name));
	
		if ((client == vortex_t || client == vortex_ct) && StrEqual(weapon_name, "weapon_knife"))
		{
			return Plugin_Handled;
		}
	}
	return Plugin_Continue;
}

public void lrmenu(int client)
{
	if(IsClientInGame(client))
	{
		Menu menu = CreateMenu(MenuHandler1);
		menu.SetTitle("Atmak istediğiniz LR tipini seçiniz.");
		menu.AddItem("deagle", "Deagle LR\n Korumayı alırsanız koruma olursunuz!");
		menu.AddItem("noscope", "Noscope LR\n Kazanırsanız %i TL kazanırsınız!", GetConVarInt(kredi));
		menu.AddItem("knife", "Bıçak LR\n Kazanırsanız %i TL kazanırsınız!", GetConVarInt(kredi2));
		menu.Display(client, 10);
	}
}

public int MenuHandler1(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_Select)
	{
		char szInfo[32];
		GetMenuItem(menu, param2, szInfo, sizeof(szInfo));
		if (IsClientInGame(param1))
		{
			choosemenu(param1);
		}
		if (StrEqual(szInfo, "deagle", true))
		{
			vortex_DeagleLR = 1;
			vortex_NoscopeLR = 0;
			vortex_KnifeLR = 0;
		}
		else if (StrEqual(szInfo, "noscope", true))
		{
			vortex_NoscopeLR = 1;
			vortex_DeagleLR = 0;
			vortex_KnifeLR = 0;
		}
		else if (StrEqual(szInfo, "knife", true))
		{
			vortex_NoscopeLR = 0;
			vortex_DeagleLR = 0;
			vortex_KnifeLR = 1;
		}
	}
	return Plugin_Handled;
}

public void choosemenu(int client)
{
	Handle menu = CreateMenu(MenuCallBack);
	SetMenuTitle(menu, "Kiminle LR atmak istiyorsunuz?");
	char sName[MAX_NAME_LENGTH];
	char sUserId[10];
	for(int i=1;i<=MaxClients;i++)
	{
	    if(IsClientInGame(i) && GetClientTeam(i) == CS_TEAM_CT)
	    {
	        GetClientName(i, sName, sizeof(sName));
	        IntToString(GetClientUserId(i), sUserId, sizeof(sUserId));
	        AddMenuItem(menu, sUserId, sName);
	    }
	}  
   
	SetMenuExitBackButton(menu, false);
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
	return Plugin_Handled; 
}

public int MenuCallBack(Handle menu, MenuAction action, int client, int itemNum)
{
    if ( action == MenuAction_Select )
    {
		char info[32];
		GetMenuItem(menu, itemNum, info, sizeof(info));
		GetClientOfUserId(StringToInt(info));
		int target = GetClientOfUserId(StringToInt(info));
		vortex_lr = true;
		vortex_ct = target;
		vortex_t = client;
		CreateTimer(1.0, lrbaslat);
	}
}

public Action lrbaslat(Handle timer)
{
	if (IsClientInGame(vortex_t))
	{
		vortex_bodysayi[vortex_t] = 0;
		vortex_bodysayi[vortex_ct] = 0;
		vortex_InLR[vortex_t] = 1;
		vortex_InLR[vortex_ct] = 1;
		vortex_CanFire[vortex_t] = 1;
		vortex_lr = true;
		if (vortex_DeagleLR)
		{
			CPrintToChatAll("{darkred}[%s] \x01\x0B\x09%N {lime}adlı oyuncu \x01\x0B\x0B%N {lime}ile {orchid}Deagle {green}LR atıyor!", taggo, vortex_t, vortex_ct);
			CPrintToChatAll("{darkred}[%s] {orange}İlk atış hakkı {darkblue}%N'de!", taggo, vortex_t);
			GiveDeagle(vortex_t);
			GiveDeagle(vortex_ct);
			EmitSoundToAll(RELATIVE_SOUND_PATH);
			for(int i=1;i<=MaxClients;i++)
			{
			    if(IsClientInGame(i))
			    {
					char sBuffer[64];	
					int color_r = GetRandomInt(0, 255);
					int color_g = GetRandomInt(0, 255);
					int color_b = GetRandomInt(0, 255);
					Format(sBuffer, sizeof(sBuffer), "%i %i %i", color_r, color_g, color_b);
					int ent = CreateEntityByName("game_text");
					DispatchKeyValue(ent, "channel", "1");
					DispatchKeyValue(ent, "color", "0 0 0");
					DispatchKeyValue(ent, "color2", sBuffer);
					DispatchKeyValue(ent, "effect", "2");
					DispatchKeyValue(ent, "fadein", "0.1");
					DispatchKeyValue(ent, "fadeout", "0.1");
					DispatchKeyValue(ent, "fxtime", "5.0"); 		
					DispatchKeyValue(ent, "holdtime", "7.0");
					DispatchKeyValue(ent, "message", "LR Kuralları:\n2 Body İnfaz\nYüz Yüze\nSilah Değiştirmek Yasak\nZıplamak Yasak\nİyi şanslar!");
					DispatchKeyValue(ent, "spawnflags", "0"); 	
					DispatchKeyValue(ent, "x", "-1.0");
					DispatchKeyValue(ent, "y", "0.1"); 		
					DispatchSpawn(ent);
					SetVariantString("!activator");
					AcceptEntityInput(ent,"display", i);
				}
			}
		}
		else if (vortex_NoscopeLR)
		{
			if (IsClientInGame(vortex_t))
			{
				vortex_sayimdeger = 5;
				CreateTimer(1.0, Repeader, _, TIMER_REPEAT);
				CPrintToChatAll("{darkred}[%s] \x01\x0B\x09%N {lime}adlı oyuncu \x01\x0B\x0B%N {lime}ile {orchid}Noscope {green}LR atıyor!", taggo, vortex_t, vortex_ct);
			}
		}
		else if (vortex_KnifeLR)
		{
			if (IsClientInGame(vortex_t))
			{
				CPrintToChatAll("{darkred}[%s] \x01\x0B\x09%N {lime}adlı oyuncu \x01\x0B\x0B%N {lime}ile {orchid}Bıçak {green}LR atıyor!", taggo, vortex_t, vortex_ct);
				Client_RemoveAllWeapons(vortex_t, "", false);
				GivePlayerItem(vortex_t, "weapon_knife");
				Client_RemoveAllWeapons(vortex_ct, "", false);
				GivePlayerItem(vortex_ct, "weapon_knife");	
			}
		}
		SetEntityHealth(vortex_ct, 100);
		SetEntityHealth(vortex_t, 100);
	}
}

public Action Repeader(Handle timer)
{
	if (vortex_sayimdeger <= 1)
	{
		if (IsClientInGame(vortex_t) && IsClientInGame(vortex_ct))
		{
			Client_RemoveAllWeapons(vortex_t);
			Client_RemoveAllWeapons(vortex_ct);
			GivePlayerItem(vortex_ct, "weapon_awp");
			GivePlayerItem(vortex_t, "weapon_awp");
			GivePlayerItem(vortex_ct, "weapon_knife");
			GivePlayerItem(vortex_t, "weapon_knife");
		}
		PrintCenterTextAll("<b><font size='25' color='#FF8100'>Noscope LR başladı!</font>");
		CPrintToChatAll("{darkred}[%s] {green}Noscope LR başladı!", taggo);
		vortex_sayimdeger = 0;
		return Plugin_Stop;
	}
	vortex_sayimdeger -= 1;
	PrintCenterTextAll("<b><font size='25' color='#FF8100'>Noscope LR'ye son:</font> <font size='25' color='#ffffff'>%i saniye!</font></b>", vortex_sayimdeger);
	return Plugin_Continue;
}


public void GiveDeagle(int client)
{
	if (IsClientInGame(client))
	{
		Client_RemoveAllWeapons(client, "", false);
		GivePlayerItem(client, "weapon_knife");
		Client_GiveWeaponAndAmmo(client, "weapon_deagle", _, 0, _, 1);
	}
}

public Action weaponfire(Handle event, char[] name, bool db)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (vortex_lr)
	{
		if (IsClientInGame(client))
		{
			if (vortex_InLR[client])
			{
				int weapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
				char weaponname[256];
				if (IsValidEntity(weapon))
				{
					GetEdictClassname(weapon, weaponname, sizeof(weaponname));
				}
				if (vortex_DeagleLR)
				{
					if (vortex_CanFire[client])
					{
						if (StrEqual(weaponname, "weapon_deagle", true))
						{
							if (vortex_t == client)
							{
								CreateTimer(0.1, DelayedGiveDeagle, vortex_ct);
								vortex_CanFire[vortex_ct] = 1;
								vortex_CanFire[vortex_t] = 0;
								char sBuffer[64];	
								int color_r = GetRandomInt(0, 255);
								int color_g = GetRandomInt(0, 255);
								int color_b = GetRandomInt(0, 255);
								Format(sBuffer, sizeof(sBuffer), "%i %i %i", color_r, color_g, color_b);
								int ent = CreateEntityByName("game_text");
								DispatchKeyValue(ent, "channel", "1");
								DispatchKeyValue(ent, "color", "0 0 0");
								DispatchKeyValue(ent, "color2", sBuffer);
								DispatchKeyValue(ent, "effect", "2");
								DispatchKeyValue(ent, "fadein", "0.1");
								DispatchKeyValue(ent, "fadeout", "0.1");
								DispatchKeyValue(ent, "fxtime", "2.0"); 		
								DispatchKeyValue(ent, "holdtime", "3.0");
								DispatchKeyValue(ent, "message", "Atış hakkı sizde!");
								DispatchKeyValue(ent, "spawnflags", "0"); 	
								DispatchKeyValue(ent, "x", "-1.0");
								DispatchKeyValue(ent, "y", "1.0"); 		
								DispatchSpawn(ent);
								SetVariantString("!activator");
								AcceptEntityInput(ent,"display", vortex_ct);	
							}
							else if (vortex_ct == client)
							{
								CreateTimer(0.1, DelayedGiveDeagle, vortex_t);
								vortex_CanFire[vortex_t] = 1;
								vortex_CanFire[vortex_ct] = 0;
								char sBuffer2[64];	
								int color_r = GetRandomInt(0, 255);
								int color_g = GetRandomInt(0, 255);
								int color_b = GetRandomInt(0, 255);
								Format(sBuffer2, sizeof(sBuffer2), "%i %i %i", color_r, color_g, color_b);
								int ent = CreateEntityByName("game_text");
								DispatchKeyValue(ent, "channel", "1");
								DispatchKeyValue(ent, "color", "0 0 0");
								DispatchKeyValue(ent, "color2", sBuffer2);
								DispatchKeyValue(ent, "effect", "2");
								DispatchKeyValue(ent, "fadein", "0.1");
								DispatchKeyValue(ent, "fadeout", "0.1");
								DispatchKeyValue(ent, "fxtime", "2.0"); 		
								DispatchKeyValue(ent, "holdtime", "3.0");
								DispatchKeyValue(ent, "message", "Atış hakkı sizde!");
								DispatchKeyValue(ent, "spawnflags", "0"); 	
								DispatchKeyValue(ent, "x", "-1.0");
								DispatchKeyValue(ent, "y", "1.0"); 		
								DispatchSpawn(ent);
								SetVariantString("!activator");
								AcceptEntityInput(ent,"display", vortex_t);	
							}
							CPrintToChatAll("{darkred}[%s] {orange}%N {lime}atış hakkını kullandı.", taggo, client);
						}
					}
					else
					{
						if (StrEqual(weaponname, "weapon_deagle", true))
						{
							ForcePlayerSuicide(client);
							CPrintToChatAll("{darkred}[%s] {orange}%N {lime}adlı oyuncu {green}sırası gelmeden sıktığı için {lightred}öldürüldü.", taggo, client);
							ResetLR();
						}
					}
				}
			}
		}
	}
	return Plugin_Handled;
}

public Action DelayedGiveDeagle(Handle timer, any client)
{
	if(IsClientInGame(client))
	{
		GiveDeagle(client);
	}
}

public void ResetLR()
{
	vortex_lr = false;
	for(int i=1;i<=MaxClients;i++)
	{
	    if(IsClientInGame(i))
	    {
			vortex_InLR[i] = 0;
			vortex_bodysayi[i] = 0;
			vortex_CanFire[i] = 0;	
			StopSound(i, SNDCHAN_AUTO, RELATIVE_SOUND_PATH);			
	    }
	}  
	vortex_ct = -1;
	vortex_t = -1;
	vortex_DeagleLR = 0;
	vortex_NoscopeLR = 0;
	vortex_KnifeLR = 0;
}

public void RespawnCTS()
{
	for(int i=1;i<=MaxClients;i++)
	{
	    if(IsClientInGame(i) && GetClientTeam(i) == CS_TEAM_CT)
	    {
   			CS_RespawnPlayer(i);
	    }
	} 
}



public Action hurt(Handle event, char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	int attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	int hitgroup = GetEventInt(event, "hitgroup");
	
	if(vortex_lr)
	{
			int weapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
			char weaponname[256];
			if (IsValidEntity(weapon))
			{
				GetEdictClassname(weapon, weaponname, sizeof(weaponname));
			}
			
			if (vortex_DeagleLR)
			{
				if (vortex_InLR[client] && vortex_InLR[attacker])
				{
					if (StrEqual(weaponname, "weapon_deagle"))
					{
						if (hitgroup == 1)
						{
								CPrintToChatAll("{darkred}[%s] {orange}%N {lime}adlı oyuncu {green}LR'yi kazandı!", taggo, attacker);
						}
						else
						{
							vortex_bodysayi[attacker]++;
							if (vortex_bodysayi[attacker] > 1)
							{
								ForcePlayerSuicide(attacker);
								CPrintToChatAll("{darkred}[%s] {orange}%N {green}2 body attığı için {lightred}öldürüldü.", taggo, attacker);
								ResetLR();
							}
						}
					}
				}
			}
	}
}

public Action playerdeath(Handle event, char[] name, bool db)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	int attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	if (vortex_lr)
	{
		if (IsClientInGame(client))
		{
			if (vortex_DeagleLR)
			{
				if (GetClientTeam(client) == 3)
				{
					if (vortex_InLR[client] && vortex_InLR[attacker])
					{
							ChangeClientTeam(client, 2);
							ChangeClientTeam(attacker, 3);
					}
				}
			}
			else if (vortex_NoscopeLR)
			{
				if (vortex_InLR[client] && vortex_InLR[attacker])
				{
					CPrintToChat(attacker, "{darkred}[%s] {orange}Tebrikler, {orchid}%i TL {green}kazandınız.", taggo, GetConVarInt(kredi));
					Store_SetClientCredits(attacker, GetConVarInt(kredi) + Store_GetClientCredits(attacker));
					CPrintToChatAll("{darkred}[%s] {orange}%N {lime}adlı oyuncu {green}LR'yi {orchid}kazandı!", taggo, attacker);
				}
			}
			else if (vortex_KnifeLR)
			{
				if (vortex_InLR[client] && vortex_InLR[attacker])
				{
					CPrintToChat(attacker, "{darkred}[%s] {orange}Tebrikler, {orchid}%i TL {green}kazandınız.", taggo, GetConVarInt(kredi2));
					Store_SetClientCredits(attacker, GetConVarInt(kredi2) + Store_GetClientCredits(attacker));
					CPrintToChatAll("{darkred}[%s] {orange}%N {lime}adlı oyuncu {green}LR'yi {orchid}kazandı!", taggo, attacker);
				}
			}
		}
		ResetLR();
	}
	else
	{	
		if(GetAliveTeamCount(CS_TEAM_T) == 1)
		{
			for(int i=1;i<=MaxClients;i++)
			{
				if(IsClientInGame(i) && GetClientTeam(i) == CS_TEAM_T && IsPlayerAlive(i))
				{
					CPrintToChat(i, "{darkred}[%s] {green}Tebrikler! {lime}Sona kaldınız. {orange}!lr yazabilirsiniz.", taggo);
				}
			}
		}
	}
}



public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon)
{
	if (IsClientInGame(client) && vortex_NoscopeLR && vortex_InLR[client])
	{
		buttons &= ~IN_ATTACK2;
	}
	return Plugin_Continue;
}

stock int GetRandomPlayer(int team)  
{  
    int[] clients = new int[MaxClients];  
    int clientCount;  
    for (int i = 1; i <= MaxClients; i++)  
    {  
        if (IsClientInGame(i) && GetClientTeam(i) == team) 
        {  
            clients[clientCount++] = i;  
        }  
    }  
    return (clientCount == 0) ? -1 : clients[GetRandomInt(0, clientCount - 1)];  
}  

stock int GetAliveTeamCount(int team)
{
	int number = 0;
	LoopClients(i) if (IsPlayerAlive(i) && GetClientTeam(i) == team) number++;
	return number;
}

stock FakePrecacheSound( const String:szPath[] )
{
	AddToStringTable( FindStringTable( "soundprecache" ), szPath );
}
