/**
 * =============================================================================
 * [Discord] SourceBans
 * Relaying all bans/comm punishments in Discord Server.
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

#undef REQUIRE_PLUGIN
#tryinclude <sourcebans>
#tryinclude <sourcecomms>
#tryinclude <materialadmin>
#define REQUIRE_PLUGIN

#if !defined _sourcebans_included
#if !defined _sourcecomms_included
#if !defined _materialadmin_included
  #error "Couldn't attach SourceBans / SourceComms / MaterialAdmin include"
#endif
#endif
#endif

#pragma newdecls required

stock const char g_szSBUrlName[]    = "sm_discord_sburl";
stock const char g_szSBHostName[]   = "sm_discord_sbhost";
stock const char g_szSBBColorName[] = "sm_discord_sbbcolor";
stock const char g_szSBCColorName[] = "sm_discord_sbccolor";

public Plugin myinfo = {
    description = "SourceBans + SourceComms / MaterialAdmin module for Discord Extended Library.",
    version     = "1.2",
    author      = "CrazyHackGUT aka Kruzya",
    name        = "[Discord] SourceBans + SourceComms",
    url         = "https://kruzefag.ru/"
};

char    g_szSite[256];
int     g_iCommsColor;
int     g_iBansColor;
bool    g_bHostname;

/**
 * Events.
 */
public void OnPluginStart() {
    HookConVarChange(
        CreateConVar(
            g_szSBUrlName,
            "https://bans.myproject.ru/",
            "SourceBans Site URL"
        ),
        OnURLChanged
    );

    HookConVarChange(
        CreateConVar(
            g_szSBHostName, "1",
            "Adds Hostname to ban/mute info?",
            _, true, 0.0, true, 1.0
        ),
        OnHostChanged
    );

    HookConVarChange(
        CreateConVar(
            g_szSBBColorName, "BE0000",
            "Color for Bans Information"
        ),
        OnBansColorChanged
    );

    HookConVarChange(
        CreateConVar(
            g_szSBCColorName, "0094FF",
            "Color for Comms Information"
        ),
        OnCommsColorChanged
    );

    AutoExecConfig(true, "SourceBans", "Discord");
}

public void OnConfigsExecuted() {
    OnURLChanged(FindConVar(g_szSBUrlName), NULL_STRING, NULL_STRING);
    OnHostChanged(FindConVar(g_szSBHostName), NULL_STRING, NULL_STRING);
    OnBansColorChanged(FindConVar(g_szSBBColorName), NULL_STRING, NULL_STRING);
    OnCommsColorChanged(FindConVar(g_szSBCColorName), NULL_STRING, NULL_STRING);
}

/**
 * ConVars hooks.
 */
public void OnURLChanged(Handle hCvar, const char[] szOld, const char[] szNew) {
    GetConVarString(hCvar, g_szSite, sizeof(g_szSite));
}

public void OnHostChanged(Handle hCvar, const char[] szOld, const char[] szNew) {
    g_bHostname = GetConVarBool(hCvar);
}

public void OnBansColorChanged(Handle hCvar, const char[] szOld, const char[] szNew) {
    g_iBansColor = UTIL_GetColorFromHEX(hCvar);
}

public void OnCommsColorChanged(Handle hCvar, const char[] szOld, const char[] szNew) {
    g_iCommsColor = UTIL_GetColorFromHEX(hCvar);
}

#if defined _sourcebans_included
/**
 * SourceBans
 */
public int SourceBans_OnBanPlayer(int client, int target, int time, char[] reason) {
    OnBanAdded(client, target, time, reason);
}
#endif

#if defined _sourcecomms_included
/**
 * SourceComms
 */
public int SourceComms_OnBlockAdded(int iClient, int iTarget, int iTime, int iType, char[] szReason) {
    if (iType > 3) {
        return;
    }

    OnBlockAdded(iClient, iTarget, iTime, iType, szReason);
}
#endif

#if defined _materialadmin_included
/**
 * Material Admin
 */
public void MAOnClientMuted(int iClient, int iTarget, char[] sIp, char[] sSteamID, char[] sName, int iType, int iTime, char[] sReason) {
    OnBlockAdded(iClient, iTarget,  iTime, iType, sReason);
}

public void MAOnClientBanned(int iClient, int iTarget, char[] sIp, char[] sSteamID, char[] sName, int iTime, char[] sReason) {
    OnBanAdded(iClient, iTarget, iTime, sReason);
}
#endif

void UTIL_FormatTime(int iTime, char[] szBuffer, int iMaxLength) {
    int days = iTime / (60 * 60 * 24);
    int hours = (iTime - (days * (60 * 60 * 24))) / (60 * 60);
    int minutes = (iTime - (days * (60 * 60 * 24)) - (hours * (60 * 60))) / 60;
    int len;

    if (days) {
        len += Format(szBuffer[len], iMaxLength - len, "%d %s", days, "days");
    }

    if (hours) {
        len += Format(szBuffer[len], iMaxLength - len, "%s%d %s", days ? " " : "", hours, "hours");
    }

    if (minutes) {
        len += Format(szBuffer[len], iMaxLength - len, "%s%d %s", (days || hours) ? " " : "", minutes, "minutes");
    }
}

int UTIL_GetColorFromHEX(Handle hCvar) {
    char szBuffer[10];
    GetConVarString(hCvar, szBuffer, sizeof(szBuffer));
    return UTIL_HEX2DEC(szBuffer);
}

int UTIL_HEX2DEC(const char[] szHEX) {
    int iResult = 0;

    for (int i; i<strlen(szHEX); i++) {
        char c = szHEX[i];

        if (c >= 48 && c <= 57) {
            c -= 48;
        } else if (c >= 65 && c <= 70) {
            c = (c - 65) + 10;
        } else if (c >= 97 && c <= 102) {
            c = (c - 97) + 10;
        }

        iResult = (iResult << 4) + c;
    }

    return iResult;
}

void UTIL_AddHeader(int iAdmin, int iTarget, int iTime) {
    char szBuffer[2][256];

    // Server Hostname, if enabled
    if (g_bHostname) {
        GetConVarString(FindConVar("hostname"), szBuffer[0], sizeof(szBuffer[]));
        Discord_AddField("Server name", szBuffer[0]);
    }

    // Admin information
    GetClientName(iTarget, szBuffer[0], sizeof(szBuffer[]));
    GetClientAuthId(iTarget, AuthId_SteamID64, szBuffer[1], sizeof(szBuffer[]));
    Format(szBuffer[0], sizeof(szBuffer[]), "**[%s](https://steamcommunity.com/profiles/%s)**", szBuffer[0], szBuffer[1]);
    Discord_AddField("Player", szBuffer[0], true);

    // Admin information
    if (iAdmin > 0 && IsClientInGame(iAdmin)) {
        GetClientName(iAdmin, szBuffer[0], sizeof(szBuffer[]));
        GetClientAuthId(iAdmin, AuthId_SteamID64, szBuffer[1], sizeof(szBuffer[]));
        Format(szBuffer[0], sizeof(szBuffer[]), "**[%s](https://steamcommunity.com/profiles/%s)**", szBuffer[0], szBuffer[1]);
    } else {
        strcopy(szBuffer[0], sizeof(szBuffer[]), "CONSOLE");
    }
    Discord_AddField("Administrator", szBuffer[0], true);

    // Time
    if (iTime == 0) {
        strcopy(szBuffer[0], sizeof(szBuffer[]), "Permanent");
    } else {
        UTIL_FormatTime(iTime * 60, szBuffer[0], sizeof(szBuffer[]));
    }
    Discord_AddField("Length", szBuffer[0], true);
}

void OnBlockAdded(int iClient, int iTarget, int iTime, int iType, char[] szReason) {
    Discord_StartMessage();
    Discord_SetUsername("SourceComms");
    Discord_SetTitle(g_szSite, "Open SourceComms Site");
    Discord_SetColor(g_iCommsColor);
    UTIL_AddHeader(iClient, iTarget, iTime);

    char szBuffer[256];

    switch (iType) {
        case TYPE_SILENCE:  strcopy(szBuffer, sizeof(szBuffer), "Voice + Text Chat");
        case TYPE_MUTE:     strcopy(szBuffer, sizeof(szBuffer), "Voice Chat");
        case TYPE_GAG:      strcopy(szBuffer, sizeof(szBuffer), "Text Chat");
    }

    Discord_AddField("Punishment Type", szBuffer, true);
    Discord_AddField("Reason", szReason[0] ? szReason : "*No reason present*", true);
    Discord_EndMessage("sourcebans", true);
}

void OnBanAdded(int iClient, int iTarget, int iTime, const char[] szReason) {
    Discord_StartMessage();
    Discord_SetUsername("SourceBans");
    Discord_SetTitle(g_szSite, "Open SourceBans Site");
    Discord_SetColor(g_iBansColor);

    UTIL_AddHeader(iClient, iTarget, iTime);

    Discord_AddField("Reason", szReason[0] ? szReason : "*No reason present*", true);
    Discord_EndMessage("sourcebans", true);
}
