{ ... }:

{
  flake.modules.homeManager.discord =
    { ... }:

    {
      programs.vesktop = {
        enable = true;
        vencord = {
          settings = {
            # https://vencord.dev/plugins
            plugins = {
              AlwaysTrust.enabled = true;
              BetterFolders.enabled = true;
              BetterRoleContext.enabled = true;
              BetterSessions.enabled = true;
              BetterSettings.enabled = true;
              BetterUploadButton.enabled = true;
              BiggerStreamPreview.enabled = true;
              CallTimer.enabled = true;
              CharacterCount.enabled = true;
              ClearURLs.enabled = true;
              ConsoleJanitor.enabled = true;
              CopyFileContents.enabled = true;
              CustomIdle.enabled = true;
              FixYoutubeEmbeds.enabled = true;
              FriendsSince.enabled = true;
              FullSearchContext.enabled = true;
              GameActivityToggle.enabled = true;
              ImageFilename.enabled = true;
              ImageZoom.enabled = true;
              MemberCount.enabled = true;
              MentionAvatars.enabled = true;
              MessageLatency.enabled = true;
              VolumeBooster.enabled = true;
            };
          };
        };
      };
    };
}
