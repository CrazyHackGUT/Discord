/**
 * =============================================================================
 * [Discord] Simple Report System
 * Simpliest Report System. Very simple.
 *
 * File: discord_report.sp
 * Role: -
 * =============================================================================
 *
 * This program is free software; you can redistribute it and/or modify it under
 * the terms of the GNU General Public License, version 3.0, as published by the
 * Free Software Foundation.
 * 
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
 * details.
 *
 * You should have received a copy of the GNU General Public License along with
 * this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * As a special exception, AlliedModders LLC gives you permission to link the
 * code of this program (as well as its derivative works) to "Half-Life 2," the
 * "Source Engine," the "SourcePawn JIT," and any Game MODs that run on software
 * by the Valve Corporation.  You must obey the GNU General Public License in
 * all respects for all other code used.  Additionally, AlliedModders LLC grants
 * this exception to all derivative works.  AlliedModders LLC defines further
 * exceptions, found in LICENSE.txt (as of this writing, version JULY-31-2007),
 * or <http://www.sourcemod.net/license.php>.
 *
 * Version: $Id$
 */

#include <discord_extended>
#include <sourcemod>

#pragma semicolon 1
#pragma newdecls required

static const char g_szConVar[] = "sm_discord_report_cooldown";

bool    g_bReasonChat[MAXPLAYERS+1];
int     g_iApprReport[MAXPLAYERS+1];
int     g_iVictim[MAXPLAYERS+1];

public Plugin myinfo = {
    description = "Simple Report system. All reports sends into Discord server.",
    version     = "1.1",
    author      = "CrazyHackGUT aka Kruzya",
    name        = "[Discord] Simple Report System",
    url         = "https://kruzefag.ru/"
};

/**
 * @section Events
 */
public void OnPluginStart() {
    LoadTranslations("discord_report.phrases");
    LoadTranslations("common.phrases");

    // Reg Report commands
    RegConsoleCmd("sm_report",  ReportCmd);
    RegConsoleCmd("report",     ReportCmd);

    // Hook chat
    RegConsoleCmd("say_team",   OnSayHook);
    RegConsoleCmd("say",        OnSayHook);

    for (int i; ++i <= MaxClients;) {
        if (!IsClientInGame(i))
            continue;

        OnClientPutInServer(i);
    }
    
    CreateConVar(g_szConVar, "60", "Cooldown after sending a report (in seconds)", _, true, 0.0);
}

public void OnClientPutInServer(int iClient) {
    if (IsFakeClient(iClient))
        return;

    g_iVictim[iClient]      = -1;
    g_iApprReport[iClient]  = -1;
    g_bReasonChat[iClient]  = false;
}

/**
 * @section Commands
 */
public Action ReportCmd(int iClient, int iArgs) {
    if (iClient == 0) {
        return Plugin_Handled;
    }

    if (g_iApprReport[iClient] > GetTime()) {
        PrintToChat(iClient, "[SM] %t", "Cooldown", g_iApprReport[iClient] - GetTime());
        return Plugin_Handled;
    }

    Handle hMenu = CreateMenu(SelectPlayerHandler);

    for (int i; ++i <= MaxClients;) {
        if (i == iClient || !IsClientInGame(i) || IsFakeClient(i))
            continue;

        char szUID[13];
        char szUsername[MAX_TARGET_LENGTH];

        GetClientName(i, szUsername, sizeof(szUsername));
        IntToString(GetClientUserId(i), szUID, sizeof(szUID));

        AddMenuItem(hMenu, szUID, szUsername);
    }

    if (GetMenuItemCount(hMenu) > 0) {
        SetMenuExitBackButton(hMenu, false);
        SetMenuExitButton(hMenu, true);
        SetMenuTitle(hMenu, "%T", "ReportPlayer", iClient);

        DisplayMenu(hMenu, iClient, MENU_TIME_FOREVER);
        return Plugin_Handled;
    }

    CloseHandle(hMenu);
    PrintToChat(iClient, "[SM] %t", "No Available Players");
    return Plugin_Handled;
}

public Action OnSayHook(int iClient, int iArgs) {
    if (!iClient || !g_bReasonChat[iClient]) {
        return Plugin_Continue;
    }

    if (!(g_iVictim[iClient] = GetClientOfUserId(g_iVictim[iClient]))) {
        PrintToChat(iClient, "[SM] %t", "Player no longer available");

        g_bReasonChat[iClient] = false;
        g_iVictim[iClient] = -1;
        return Plugin_Handled;
    }

    char szReason[256];

    // костыль для TF2, который всё сообщение заключает в кавычки, из-за чего выходит один аргумент.
    if (iArgs == 1) {
        GetCmdArg(1, szReason, sizeof(szReason));
    } else {
        GetCmdArgString(szReason, sizeof(szReason));
    }

    if (!strcmp(szReason, "!cancel")) {
        PrintToChat(iClient, "[SM] %t", "ReportCancelled");
        g_bReasonChat[iClient] = false;
        g_iVictim[iClient] = -1;
        return Plugin_Handled;
    }

    UTIL_ProcessReport(iClient, g_iVictim[iClient], szReason);
    PrintToChat(iClient, "[SM] %t", "Send");
    g_iApprReport[iClient] = GetTime() + GetConVarInt(FindConVar(g_szConVar));

    g_bReasonChat[iClient] = false;
    g_iVictim[iClient] = -1;

    return Plugin_Handled;
}

/**
 * @section MenuCallback
 */
public int SelectPlayerHandler(Handle hMenu, MenuAction eAction, int iParam1, int iParam2) {
    switch (eAction) {
        case MenuAction_End:    CloseHandle(hMenu);
        case MenuAction_Select: {
            char szUID[13];
            GetMenuItem(hMenu, iParam2, szUID, sizeof(szUID));

            int iUID = GetClientOfUserId(StringToInt(szUID));
            if (!iUID) {
                PrintToChat(iParam1, "[SM] %t", "Player no longer available");
                return;
            }

            g_bReasonChat[iParam1] = true;
            g_iVictim[iParam1] = GetClientUserId(iUID);
            PrintToChat(iParam1, "[SM] %t", "UseChatReason");
        }
    }
}

/**
 * @section Sender
 */
void UTIL_ProcessReport(int iClient, int iVictim, const char[] szReason) {
    char szBuffer[256];    

    Discord_StartMessage();
    Discord_SetUsername("Report System");
    Discord_SetColor(0xAA0000);

    // Server
    GetConVarString(FindConVar("hostname"), szBuffer, sizeof(szBuffer));
    Discord_AddField("Server", szBuffer);

    // Dispatcher Name
    GetClientName(iClient, szBuffer, sizeof(szBuffer));
    Discord_AddField("Dispatcher Name", szBuffer, true);

    // Dispatcher SteamID
    GetClientAuthId(iClient, AuthId_Steam2, szBuffer, sizeof(szBuffer));
    Discord_AddField("Dispatcher SteamID", szBuffer, true);

    // Victim Name
    GetClientName(iVictim, szBuffer, sizeof(szBuffer));
    Discord_AddField("Victim Name", szBuffer, true);

    // Victim SteamID
    GetClientAuthId(iVictim, AuthId_Steam2, szBuffer, sizeof(szBuffer));
    Discord_AddField("Victim SteamID", szBuffer, true);

    // Reason
    Discord_AddField("Reason", szReason, true);

    Discord_EndMessage("report", true);
}
