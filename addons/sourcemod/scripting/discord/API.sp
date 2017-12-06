/**
 * =============================================================================
 * [Discord] Core
 * Simpliest library for sending message on Discord Server with Discord WebHook.
 *
 * File: discord/API.sp
 * Role: Natives storage.
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

Handle g_hMessage;

// Helper
void API_ValidateMsg() {
    DebugMessage("API_ValidateMsg(): Started.")
    if (g_hMessage != null)
        return;

    DebugMessage("API_ValidateMsg(): Message don't started.")
    ThrowNativeError(SP_ERROR_NATIVE, "No one message in prepare progress");
}

// Natives
public int API_CancelMessage(Handle hPlugin, int iNumParams) {
    DebugMessage("API_CancelMessage()")
    if (g_hMessage) {
        if (UTIL_StringMapKeyExists(g_hMessage, "fields")) {
            Handle hArray;
            GetTrieValue(g_hMessage, "fields", hArray);

            int iLength = GetArraySize(hArray);
            for (int i; i < iLength; i++) {
                CloseHandle(view_as<Handle>(GetArrayCell(hArray, i)));
            }
            CloseHandle(hArray);
        }

        CloseHandle(g_hMessage);
        g_hMessage = null;
    }
}

public int API_StartMessage(Handle hPlugin, int iNumParams) {
    DebugMessage("API_StartMessage()")

    if (g_hMessage != null) {
        ThrowNativeError(SP_ERROR_NATIVE, "Couldn't start another message: currently we processing another message.");
        return;
    }

    g_hMessage = CreateTrie();
    RequestFrame(OnNextTick);
}

public int API_EndMessage(Handle hPlugin, int iNumParams) {
    DebugMessage("API_EndMessage()")
    API_ValidateMsg();

    char szWebHookName[64];
    GetNativeString(1, SZF(szWebHookName));

    if (g_bFirstConfigLoad == false) {
        Discord_Reload();
    }

    UTIL_SendMessage(g_hMessage, szWebHookName, GetNativeCell(2));
    Discord_CancelMessage();
}

public int API_SetUsername(Handle hPlugin, int iNumParams) {
    DebugMessage("API_SetUsername()")
    API_ValidateMsg();

    char szUsername[33];
    GetNativeString(1, SZF(szUsername));

    if (strlen(szUsername) < 2) {
        ThrowNativeError(SP_ERROR_NATIVE, "Username must be between 2 and 32 in length.");
        return;
    }

    SetTrieString(g_hMessage, "username", szUsername);
}

public int API_SetAvatar(Handle hPlugin, int iNumParams) {
    DebugMessage("API_SetAvatar()")
    API_ValidateMsg();

    char szAvatar[512];
    GetNativeString(1, SZF(szAvatar));
    SetTrieString(g_hMessage, "avatar", szAvatar);
}

public int API_SetContent(Handle hPlugin, int iNumParams) {
    DebugMessage("API_SetContent()")
    API_ValidateMsg();

    char szMessage[1024];
    if (iNumParams == 1) {
        GetNativeString(1, SZF(szMessage));
    } else {
        int iWritten;
        FormatNativeString(0, 1, 2, sizeof(szMessage), iWritten, szMessage);
    }

    SetTrieString(g_hMessage, "content", szMessage);
}

public int API_SetColor(Handle hPlugin, int iNumParams) {
    DebugMessage("API_SetColor()")
    API_ValidateMsg();

    SetTrieValue(g_hMessage, "color", GetNativeCell(1));
}

public int API_SetTitle(Handle hPlugin, int iNumParams) {
    DebugMessage("API_SetTitle()")
    API_ValidateMsg();

    char szURL[256]; // max url length - 255 + null byte
    char szTitle[256];

    GetNativeString(1, SZF(szURL));
    if (szURL[0]) {
        SetTrieString(g_hMessage, "title_url", szURL);
    } else {
        RemoveFromTrie(g_hMessage, "title_url");
    }

    if (iNumParams == 2) {
        GetNativeString(2, SZF(szTitle));
    } else {
        int iWritten;
        FormatNativeString(0, 2, 3, sizeof(szTitle), iWritten, szTitle);
    }
    SetTrieString(g_hMessage, "title", szTitle);
}

public int API_AddField(Handle hPlugin, int iNumParams) {
    DebugMessage("API_AddField()")
    API_ValidateMsg();

    Handle hArray;
    if (!UTIL_StringMapKeyExists(g_hMessage, "fields")) {
        hArray = CreateArray(4);
        SetTrieValue(g_hMessage, "fields", hArray);
    } else {
        GetTrieValue(g_hMessage, "fields", hArray);
    }

    char szBuffer[512];
    Handle hMap = CreateTrie();

    GetNativeString(1, SZF(szBuffer));
    SetTrieString(hMap, "title", szBuffer);

    GetNativeString(2, SZF(szBuffer));
    SetTrieString(hMap, "text", szBuffer);

    SetTrieValue(hMap, "short", GetNativeCell(3));

    PushArrayCell(hArray, hMap);
}

public int API_WebHookExists(Handle hPlugin, int iNumParams) {
    DebugMessage("API_WebHookExists()")

    if (g_bFirstConfigLoad == false) {
        Discord_Reload();
    }

    char szBuffer[64];
    char szRes[4];

    GetNativeString(1, szBuffer, sizeof(szBuffer));
    return (GetTrieString(g_hWebHooks, szBuffer, szRes, sizeof(szRes))) ? 1 : 0;
}

public int API_ReloadConfig(Handle hPlugin, int iNumParams) {
    DebugMessage("API_ReloadConfig()")
    Discord_Reload();
}

public int API_BindWebHook(Handle hPlugin, int iNumParams) {
    DebugMessage("API_BindWebHook()")

    char szWebHookName[64];
    char szURL[256];

    GetNativeString(1, szWebHookName,   sizeof(szWebHookName));
    GetNativeString(2, szURL,           sizeof(szURL));

    return UTIL_AddWebHook(szWebHookName, szURL, false) ? 1 : 0;
}