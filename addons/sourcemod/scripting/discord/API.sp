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
NativeHandler(API_IsMessageProcessing) {
  DebugMessage("API_IsMessageProcessing()")

  return (g_hMessage != null) ? 1 : 0;
}

NativeHandler(API_CancelMessage) {
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

NativeHandler(API_StartMessage) {
  DebugMessage("API_StartMessage()")

  if (g_hMessage != null) {
    ThrowNativeError(SP_ERROR_NATIVE, "Couldn't start another message: currently we processing another message.");
    return;
  }

  g_hMessage = CreateTrie();
  RequestFrame(OnNextTick);
}

NativeHandler(API_EndMessage) {
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

NativeHandler(API_SetUsername) {
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

NativeHandler(API_SetAvatar) {
  DebugMessage("API_SetAvatar()")
  API_ValidateMsg();

  char szAvatar[512];
  GetNativeString(1, SZF(szAvatar));
  SetTrieString(g_hMessage, "avatar", szAvatar);
}

NativeHandler(API_SetContent) {
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

NativeHandler(API_SetColor) {
  DebugMessage("API_SetColor()")
  API_ValidateMsg();

  SetTrieValue(g_hMessage, "color", GetNativeCell(1));
}

NativeHandler(API_SetTitle) {
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

NativeHandler(API_AddField) {
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

NativeHandler(API_WebHookExists) {
  DebugMessage("API_WebHookExists()")

  if (g_bFirstConfigLoad == false) {
    Discord_Reload();
  }

  char szBuffer[64];
  char szRes[4];

  GetNativeString(1, szBuffer, sizeof(szBuffer));
  return (GetTrieString(g_hWebHooks, szBuffer, szRes, sizeof(szRes))) ? 1 : 0;
}

NativeHandler(API_ReloadConfig) {
  DebugMessage("API_ReloadConfig()")
  Discord_Reload();
}

NativeHandler(API_BindWebHook) {
  DebugMessage("API_BindWebHook()")

  char szWebHookName[64];
  char szURL[256];

  GetNativeString(1, szWebHookName,   sizeof(szWebHookName));
  GetNativeString(2, szURL,       sizeof(szURL));

  return UTIL_AddWebHook(szWebHookName, szURL, false) ? 1 : 0;
}

// v1.0.6
NativeHandler(API_SetTimestamp) {
  DebugMessage("API_SetTimestamp()")
  API_ValidateMsg();

  int iTime = GetNativeCell(1);
  if (iTime < 0) {
    RemoveFromTrie(g_hMessage, "timestamp");
    return;
  }

  SetTrieValue(g_hMessage, "timestamp", iTime, true);
}

NativeHandler(API_SetAuthorImage) {
  DebugMessage("API_SetAuthorImage()")
  API_ValidateMsg();

  char szURL[256];
  GetNativeString(1, szURL, sizeof(szURL));

  if (szURL[0] == 0) {
    RemoveFromTrie(g_hMessage, "author_avatar");
    return;
  }

  SetTrieString(g_hMessage, "author_avatar", szURL, true);
}

NativeHandler(API_SetAuthorName) {
  DebugMessage("API_SetAuthorName()")
  API_ValidateMsg();

  char szAuthorName[256];
  GetNativeString(1, szAuthorName, sizeof(szAuthorName));

  if (szAuthorName[0] == 0) {
    RemoveFromTrie(g_hMessage, "author_name");
    return;
  }

  SetTrieString(g_hMessage, "author_name", szAuthorName, true);
}

NativeHandler(API_SetAuthorURL) {
  DebugMessage("API_SetAuthorURL()")
  API_ValidateMsg();

  char szURL[256];
  GetNativeString(1, szURL, sizeof(szURL));

  if (szURL[0] == 0) {
    RemoveFromTrie(g_hMessage, "author_url");
    return;
  }

  SetTrieString(g_hMessage, "author_url", szURL, true);
}

NativeHandler(API_SetFooterImage) {
  DebugMessage("API_SetFooterImage()")
  API_ValidateMsg();

  char szURL[256];
  GetNativeString(1, szURL, sizeof(szURL));

  if (szURL[0] == 0) {
    RemoveFromTrie(g_hMessage, "footer_image");
    return;
  }

  SetTrieString(g_hMessage, "footer_image", szURL, true);
}

NativeHandler(API_SetFooterText) {
  DebugMessage("API_SetFooterText()")
  API_ValidateMsg();

  char szText[256];
  if (iNumParams == 1) {
    GetNativeString(1, szText, sizeof(szText));
  } else {
    int iWritten;
    FormatNativeString(0, 1, 2, sizeof(szText), iWritten, szText);
  }

  if (szText[0] == 0) {
    RemoveFromTrie(g_hMessage, "footer_text");
    return;
  }

  SetTrieString(g_hMessage, "footer_text", szText, true);
}

NativeHandler(API_SetImage) {
  DebugMessage("API_SetImage()")
  API_ValidateMsg();

  char szURL[256];
  GetNativeString(1, szURL, sizeof(szURL));

  if (szURL[0])
    SetTrieString(g_hMessage, "embed_image", szURL);
  else
    RemoveFromTrie(g_hMessage, "embed_image");
}

NativeHandler(API_SetThumbnail) {
  DebugMessage("API_SetThumbnail()")
  API_ValidateMsg();

  char szURL[256];
  GetNativeString(1, szURL, sizeof(szURL));

  if (szURL[0])
    SetTrieString(g_hMessage, "embed_thumb", szURL);
  else
    RemoveFromTrie(g_hMessage, "embed_thumb");
}

NativeHandler(API_SetDescription) {
  DebugMessage("API_SetDescription()")
  API_ValidateMsg();

  char szDescription[2048];
  if (iNumParams == 1) {
    GetNativeString(1, szDescription, sizeof(szDescription));
  } else {
    int iWritten;
    FormatNativeString(0, 1, 2, sizeof(szDescription), iWritten, szDescription);
  }

  if (szDescription[0])
    SetTrieString(g_hMessage, "embed_description", szDescription);
  else
    RemoveFromTrie(g_hMessage, "embed_description");
}
