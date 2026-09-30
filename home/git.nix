{ gitName, gitEmail, ... }:

{
  programs.git = {
    enable = true;
    settings = {
      user.name = gitName;
      user.email = gitEmail;
      init.defaultBranch = "main";
    };
  };
}
