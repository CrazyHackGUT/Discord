/**
 * =============================================================================
 * [Discord] Core
 * Simpliest library for sending message on Discord Server with Discord WebHook.
 *
 * File: discord/Debugger.sp
 * Role: Optional Core module for debugging.
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

#if defined DEBUG_MODE
stock void DebugMsg(const char[] sMsg, any ...) {
  static char szDebugLogFile[PLATFORM_MAX_PATH];
  if (!szDebugLogFile[0])
    BuildPath(Path_SM, SZF(szDebugLogFile), "logs/Discord_Debug.log");

  static char sBuffer[4096];
  VFormat(sBuffer, sizeof(sBuffer), sMsg, 2);
  LogToFile(szDebugLogFile, sBuffer);
}
#define DebugMessage(%0) DebugMsg(%0);
#else
#define DebugMessage(%0)
#endif
