#if defined _discord_extended_included
 #endinput
#endif
#define _discord_extended_included

/**
 * Checks a existing started message.
 *
 * @return  bool
 */
native bool Discord_IsMessageProcessing();

/**
 * Starts a new message for webhook.
 * WARNING! If you don't call EndMessage() in one tick with StartMessage(), message automatically has been cancelled!
 *
 * @return  void
 */
native void Discord_StartMessage();

/**
 * Ends a message, sending into Discord WebHook.
 *
 * @param   szWebHook   WebHook name from configuration file.
 * @param   bAllowDef   If true, core send message into default webhook, if need webhook has been not found.
 *
 * @return  void
 * @throws  Error, if message don't has been started.
 */
native void Discord_EndMessage(const char[] szWebHook, bool bAllowDef = true);

/**
 * Cancels a current Discord Message.
 *
 * @return  void
 * @throws  Error, if message don't has been started.
 */
native void Discord_CancelMessage();

/**
 * Setup Username for sender.
 *
 * @param   szUserName  Username
 *
 * @return  void
 * @throws  Error, if message don't has been started.
 */
native void Discord_SetUsername(const char[] szUserName);

/**
 * Setup avatar for sender.
 *
 * @param   szURL       Sender avatar URL.
 *
 * @return  void
 * @throws  Error, if message don't has been started.
 */
native void Discord_SetAvatar(const char[] szURL);

/**
 * Setup a message text.
 *
 * @param   szText      Text
 * @param   ...         Any format parameters.
 *
 * @return  void
 * @throws  Error, if message don't has been started.
 */
native void Discord_SetContent(const char[] szText, any ...);

/**
 * Setup a color for attachment.
 *
 * @param   iColor      Color in HEX-representation (example 0xFFFFFF)
 *
 * @return  void
 * @throws  Error, if message don't has been started, or color in unknown format.
 */
native void Discord_SetColor(int iColor = 0xFFFFFF);

/**
 * Setup a title for attachment.
 *
 * @param   szURL       URL. Leave empty (NULL_STRING, ""), if you don't need make title clickable item.
 * @param   szText      Text
 * @param   ...         Any format parameters for text.
 *
 * @return  void
 * @throws  Error, if message don't has been started.
 */
native void Discord_SetTitle(const char[] szURL, const char[] szText, any ...);

/**
 * Add a field for attachment.
 *
 * @param   szTitle     Title
 * @param   szText      Text
 * @param   bInline     Is short? True, if yes, or false, if not.
 *
 * @return  void
 * @throws  Error, if message don't has been started.
 */
native void Discord_AddField(const char[] szTitle, const char[] szValue, bool bInline = false);

/**
 * Setup a author name.
 *
 * @param   szName      Name
 *
 * @return  void
 * @throws  Error, if message don't has been started.
 */
native void Discord_SetAuthorName(const char[] szName);

/**
 * Setup a author image (avatar, photo).
 *
 * @param   szURL       URL to photo.
 *
 * @return  void
 * @throws  Error, if message don't has been started.
 */
native void Discord_SetAuthorImage(const char[] szURL);

/**
 * Setup a author URL.
 *
 * @param   szURL       URL-address.
 *
 * @return  void
 * @throws  Error, if message don't has been started.
 */
native void Discord_SetAuthorURL(const char[] szURL);

/**
 * Setup a message timestamp (see https://github.com/CrazyHackGUT/Discord/tree/master/.github/TimestampDescribe.png for more details)
 *
 * @param   iTime       Timestamp with start from UNIX epoch.
 *                      Push any value less 0 (like -1) to delete timestamp.
 *
 * @return  void
 * @throws  Error, if message don't has been started.
 */
native void Discord_SetTimestamp(int iTimestamp = -1);

/**
 * Setup a footer text.
 *
 * @param   szText      Text.
 * @param   ...         Any format parameters for text.
 *
 * @return  void
 * @throws  Error, if message don't has been started.
 */
native void Discord_SetFooterText(const char[] szText, any ...);

/**
 * Setup a footer image.
 *
 * @param   szURL       URL to image.
 *
 * @return  void
 * @throws  Error, if message don't has been started.
 */
native void Discord_SetFooterImage(const char[] szURL);

/**
 * Setup a thumbnail for embed object.
 *
 * @param   szURL       URL to image.
 *
 * @return  void
 * @throws  Error, if message don't has been started.
 */
native void Discord_SetThumbnail(const char[] szURL);

/**
 * Setup a image for embed object.
 *
 * @param   szURL       URL to image.
 *
 * @return  void
 * @throws  Error, if message don't has been started.
 */
native void Discord_SetImage(const char[] szURL);

/**
 * Checks for webhook availability.
 *
 * @param   szWebHook   WebHook name.
 *
 * @return  bool
 */
native bool Discord_WebHookExists(const char[] szWebHook);

/**
 * Reloads a core configuration.
 *
 * @noreturn
 */
native void Discord_ReloadConfig();

/**
 * Manually setups a webhook URL.
 * This is can be helpful for a plugin-specific webhooks.
 *
 * This function protects already created webhooks.
 * You can't replace existing webhook.
 * 
 * @param   szName      WebHook name.
 * @param   szURL       WebHook URL.
 *
 * @return  bool
 */
native bool Discord_BindWebHook(const char[] szName, const char[] szURL);

public SharedPlugin __pl_discord_extended = {
  name = "discord_extended",
  file = "discord/Core.smx",
#if defined REQUIRE_PLUGIN
  required = 1,
#else
  required = 0,
#endif
};

#if !defined REQUIRE_PLUGIN
public __pl_discord_extended_SetNTVOptional() {
  MarkNativeAsOptional("Discord_CancelMessage");
  MarkNativeAsOptional("Discord_StartMessage");
  MarkNativeAsOptional("Discord_SetUsername");
  MarkNativeAsOptional("Discord_EndMessage");
  MarkNativeAsOptional("Discord_SetContent");
  MarkNativeAsOptional("Discord_SetAvatar");
  MarkNativeAsOptional("Discord_SetColor");
  MarkNativeAsOptional("Discord_SetTitle");
  MarkNativeAsOptional("Discord_AddField");

  // v1.0.2
  MarkNativeAsOptional("Discord_WebHookExists");
  MarkNativeAsOptional("Discord_ReloadConfig");
  MarkNativeAsOptional("Discord_BindWebHook");

  // v1.0.4
  MarkNativeAsOptional("Discord_IsMessageProcessing");

  // v1.0.6
  MarkNativeAsOptional("Discord_SetAuthorImage");
  MarkNativeAsOptional("Discord_SetFooterImage");
  MarkNativeAsOptional("Discord_SetAuthorName");
  MarkNativeAsOptional("Discord_SetFooterText");
  MarkNativeAsOptional("Discord_SetAuthorURL");
  MarkNativeAsOptional("Discord_SetTimestamp");

  // v1.0.7
  MarkNativeAsOptional("Discord_SetThumbnail");
  MarkNativeAsOptional("Discord_SetImage");
}
#endif
