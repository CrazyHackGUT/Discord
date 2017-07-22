/**
 * =============================================================================
 * [Discord] Core
 * Simpliest library for sending message on Discord Server with Discord WebHook.
 *
 * File: discord/Events.sp
 * Role: Handling all SourceMod standart events.
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

public APLRes AskPluginLoad2(Handle hMySelf, bool bLate, char[] szError, int iErrMax) {
    DebugMessage("AskPluginLoad2(): Called.")

    // Starting and ending for messages.
    CreateNative("Discord_CancelMessage",   API_CancelMessage);
    CreateNative("Discord_StartMessage",    API_StartMessage);
    CreateNative("Discord_EndMessage",      API_EndMessage);

    // Setting parameters for message.
    CreateNative("Discord_SetUsername",     API_SetUsername);
    CreateNative("Discord_SetAvatar",       API_SetAvatar); 

    // Content.
    CreateNative("Discord_SetContent",      API_SetContent);    // formatnativestring
    CreateNative("Discord_SetColor",        API_SetColor);      // only HEX (strlen(szColor) == 7)
    CreateNative("Discord_SetTitle",        API_SetTitle);
    CreateNative("Discord_AddField",        API_AddField);

    RegPluginLibrary("discord_extended");
}

public void OnPluginStart() {
    DebugMessage("OnPluginStart(): Called.")

    RegServerCmd("sm_reloaddiscord", Cmd_ReloadDiscord);
    g_hWebHooks = CreateTrie();

    char szUserAgent[64];
    FormatEx(SZF(szUserAgent), "SourcePawn (DiscordExtended v%s)", PLUGIN_VERSION);
    DebugMessage("OnPluginStart(): Generated User-Agent: %s", szUserAgent)

    g_hHTTPClient = new HTTPClient("https://discordapp.com");
    g_hHTTPClient.SetHeader("Content-Type", "application/json");
    g_hHTTPClient.SetHeader("User-Agent",   szUserAgent);
    DebugMessage("OnPluginStart(): Created HTTP Client with defined Content-Type and User-Agent.")

    DebugMessage("Discord Extended Library initialized (version %s, build date %s %s)", PLUGIN_VERSION, __DATE__, __TIME__)
}

public void OnMapStart() {
    DebugMessage("OnMapStart()")
    Discord_Reload();
}

public Action Cmd_ReloadDiscord(int iArgs) {
    DebugMessage("Cmd_ReloadDiscord()")
    Discord_Reload();
    return Plugin_Handled;
}

public void OnNextTick(any data) {
    DebugMessage("OnNextTick()")
    Discord_CancelMessage();
}

public void OnRequestComplete(HTTPResponse Response, any value) {
    DebugMessage("OnRequestComplete(): Status %d", Response.Status)

    JSON hJSON = Response.Data;
    if (hJSON) {
        UTIL_JSONDUMP(hJSON);
        CloseHandle(hJSON);
    }
}
