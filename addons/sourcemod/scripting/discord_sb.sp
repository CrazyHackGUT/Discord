#include <sourcebans>
#include <sourcecomms>
#include <discord_extended>

#pragma newdecls required

public Plugin myinfo = {
    description = "SourceBans + SourceComms module for Discord Extended Library.",
    version     = "1.0",
    author      = "CrazyHackGUT aka Kruzya",
    name        = "[Discord] SourceBans + SourceComms",
    url         = "https://kruzefag.ru/"
};

char g_szSite[256];

/**
 * Events.
 */
public void OnPluginStart() {
    Handle hCvar = CreateConVar("sm_discord_sburl", "https://bans.myproject.ru/", "SourceBans Site URL");
    HookConVarChange(hCvar, OnCvarChanged);
}

public void OnConfigsExecuted() {
    OnCvarChanged(FindConVar("sm_discord_sburl"), NULL_STRING, NULL_STRING);
}

public void OnCvarChanged(Handle hCvar, const char[] szOld, const char[] szNew) {
    GetConVarString(hCvar, g_szSite, sizeof(g_szSite));
}

/**
 * SourceBans
 */
public int SourceBans_OnBanPlayer(int client, int target, int time, char[] reason) {
    char szBuffer[2][256];

    Discord_StartMessage();
    Discord_SetUsername("SourceBans");
    Discord_SetTitle(g_szSite, "Open SourceBans Site");

    // User information
    GetClientName(target, szBuffer[0], sizeof(szBuffer[]));
    GetClientAuthId(target, AuthId_SteamID64, szBuffer[1], sizeof(szBuffer[]));
    Format(szBuffer[0], sizeof(szBuffer[]), "**[%s](https://steamcommunity.com/profiles/%s)**", szBuffer[0], szBuffer[1]);
    Discord_AddField("Player", szBuffer[0], true);

    // Admin information
    if (client && IsClientInGame(client)) {
        GetClientName(client, szBuffer[0], sizeof(szBuffer[]));
        GetClientAuthId(client, AuthId_SteamID64, szBuffer[1], sizeof(szBuffer[]));
        Format(szBuffer[0], sizeof(szBuffer[]), "**[%s](https://steamcommunity.com/profiles/%s)**", szBuffer[0], szBuffer[1]);
    } else {
        strcopy(szBuffer[0], sizeof(szBuffer[]), "CONSOLE");
    }
    Discord_AddField("Administrator", szBuffer[0], true);

    if (time == 0) {
        strcopy(szBuffer[0], sizeof(szBuffer[]), "Permanent");
    } else {
        UTIL_FormatTime(time * 60, szBuffer[0], sizeof(szBuffer[]));
    }

    Discord_AddField("Length", szBuffer[0]);
    Discord_AddField("Reason", reason[0] ? reason : "*No reason present*");

    Discord_EndMessage("sourcebans", true);
}

/**
 * SourceComms
 */
public int SourceComms_OnBlockAdded(int iClient, int iTarget, int iTime, int iType, char[] szReason) {
    if (iType > 3) {
        return;
    }

    char szBuffer[2][256];

    Discord_StartMessage();

    Discord_SetUsername("SourceComms");
    Discord_SetTitle(g_szSite, "Open SourceComms Site");

    // User information
    GetClientName(iTarget, szBuffer[0], sizeof(szBuffer[]));
    GetClientAuthId(iTarget, AuthId_SteamID64, szBuffer[1], sizeof(szBuffer[]));
    Format(szBuffer[0], sizeof(szBuffer[]), "[**%s**](https://steamcommunity.com/profiles/%s)", szBuffer[0], szBuffer[1]);
    Discord_AddField("Player", szBuffer[0], true);

    // Admin information
    if (iClient > 0 && IsClientInGame(iClient)) {
        GetClientName(iClient, szBuffer[0], sizeof(szBuffer[]));
        GetClientAuthId(iClient, AuthId_SteamID64, szBuffer[1], sizeof(szBuffer[]));
        Format(szBuffer[0], sizeof(szBuffer[]), "[**%s**](https://steamcommunity.com/profiles/%s)", szBuffer[0], szBuffer[1]);
    } else {
        strcopy(szBuffer[0], sizeof(szBuffer[]), "CONSOLE");
    }
    Discord_AddField("Administrator", szBuffer[0], true);

    if (iTime == 0) {
        strcopy(szBuffer[0], sizeof(szBuffer[]), "Permanent");
    } else {
        UTIL_FormatTime(iTime * 60, szBuffer[0], sizeof(szBuffer[]));
    }

    Discord_AddField("Length", szBuffer[0], true);

    switch (iType) {
        case TYPE_SILENCE:  strcopy(szBuffer[0], sizeof(szBuffer[]), "Voice + Text Chat");
        case TYPE_MUTE:     strcopy(szBuffer[0], sizeof(szBuffer[]), "Voice Chat");
        case TYPE_GAG:      strcopy(szBuffer[0], sizeof(szBuffer[]), "Text Chat");
    }

    Discord_AddField("Punishment Type", szBuffer[0], true);
    Discord_AddField("Reason", szReason[0] ? szReason : "*No reason present*");
    Discord_EndMessage("sourcebans", true);
}

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
