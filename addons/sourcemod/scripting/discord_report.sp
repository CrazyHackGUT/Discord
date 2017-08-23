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

#define nullstr NULL_STRING
#define nullvec NULL_VECTOR
#define nullptr null

static const char g_szConVar[] = "sm_discord_report_cooldown";

Handle  g_hReasons;
bool    g_bReasonChat[MAXPLAYERS+1];
int     g_iApprReport[MAXPLAYERS+1];
int     g_iVictim[MAXPLAYERS+1];

public Plugin myinfo = {
    description = "Simple Report system. All reports sends into Discord server.",
    version     = "1.2",
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
    g_hReasons = CreateArray(ByteCountToCells(256));
}

public void OnMapStart() {
    LoadReasons();
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

            g_iVictim[iParam1] = GetClientUserId(iUID);
            if (GetArraySize(g_hReasons) == 0) {
                UTIL_HookChatMessage(iParam1);
            } else {
                UTIL_DrawReasonsMenu(iParam1);
            }
        }
    }
}

public int ReasonsMenuHandler(Handle hMenu, MenuAction eAction, int iParam1, int iParam2) {
    switch (eAction) {
        case MenuAction_End:    CloseHandle(hMenu);
        case MenuAction_Select: {
            char szReason[128];
            GetMenuItem(hMenu, iParam2, szReason, sizeof(szReason));

            if (!GetClientOfUserId(g_iVictim[iParam1])) {
                PrintToChat(iParam1, "[SM] %t", "Player no longer available");
                g_iVictim[iParam1] = -1;
                return;
            }

            if (strcmp(szReason, "###MY_OWN_REASON###", true) == 0) {
                UTIL_HookChatMessage(iParam1);
                return;
            }

            UTIL_ProcessReport(iParam1, GetClientOfUserId(g_iVictim[iParam1]), szReason);
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

    // Notify client.
    PrintToChat(iClient, "[SM] %t", "Send");
    g_iApprReport[iClient] = GetTime() + GetConVarInt(FindConVar(g_szConVar));

    g_bReasonChat[iClient] = false;
    g_iVictim[iClient] = -1;
}

/**
 * @section Reasons
 */
void LoadReasons() {
    static char szReasonsPath[PLATFORM_MAX_PATH];
    if (GetArraySize(g_hReasons) != 0) {
        ClearArray(g_hReasons);
    }

    if (szReasonsPath[0] == 0) {
        BuildPath(Path_SM, szReasonsPath, sizeof(szReasonsPath), "configs/Discord_ReportReasons.ini");
    }

    Handle hFile;
    if (!FileExists(szReasonsPath) || (hFile = OpenFile(szReasonsPath, "rt")) == nullptr) {
        LogError("[Discord: Simple Report System] Couldn't load reasons from %s", szReasonsPath);
        return;
    }

    char szBuffer[128];
    while (!IsEndOfFile(hFile)) {
        ReadFileLine(hFile, szBuffer, sizeof(szBuffer));

        if (szBuffer[0] == '/' && szBuffer[1] == '/') {
            continue;
        }

        PushArrayString(g_hReasons, szBuffer);
    }
    
    CloseHandle(hFile);
}

/**
 * @section UTILs.
 */
void UTIL_HookChatMessage(int iClient) {
    g_bReasonChat[iClient] = true;
    PrintToChat(iClient, "[SM] %t", "UseChatReason");
}

void UTIL_DrawReasonsMenu(int iClient) {
    Handle hMenu = CreateMenu(ReasonsMenuHandler);
    SetMenuExitBackButton(hMenu, true);
    SetMenuExitButton(hMenu, false);
    SetMenuTitle(hMenu, "%T:\n ", "SelectReason_Title", iClient);

    char szBuffer[128];
    int iLength = GetArraySize(g_hReasons);
    for (int i; i < iLength; i++) {
        GetArrayString(g_hReasons, i, szBuffer, sizeof(szBuffer));

        TrimString(szBuffer);
        if (szBuffer[0] == 0) {
            AddMenuItem(hMenu, nullstr, nullstr, ITEMDRAW_SPACER);
        } else {
            AddMenuItem(hMenu, szBuffer, szBuffer, ITEMDRAW_DEFAULT);
        }
    }

    AddMenuItem(hMenu, nullstr, nullstr, ITEMDRAW_SPACER);

    FormatEx(szBuffer, sizeof(szBuffer), "%T", "MyOwnReason", iClient);
    AddMenuItem(hMenu, "###MY_OWN_REASON###", szBuffer, ITEMDRAW_DEFAULT);

    DisplayMenu(hMenu, iClient, MENU_TIME_FOREVER);
}