
namespace FeatureLogging.ViewModels
{
    public class Feature : NotifyPropertyChanged
    {
        private bool isPicked = false;
        public bool IsPicked
        {
            get => isPicked;
            set => Set(ref isPicked, value);
        }

        private string postLink = string.Empty;
        public string PostLink
        {
            get => postLink;
            set => Set(ref postLink, value);
        }

        private string userAlias = string.Empty;
        public string UserAlias
        {
            get => userAlias;
            set => Set(ref userAlias, value);
        }

        private string userName = string.Empty;
        public string UserName
        {
            get => userName;
            set => Set(ref userName, value);
        }

        public Command PastePostLinkCommand => new(PastePostLink, CanPastePostLink);
        private void PastePostLink(object parameter)
        {
            PostLink = Clipboard.GetTextAsync().Result ?? string.Empty;
            if (PostLink.StartsWith("https://vero.co/"))
            {
                UserAlias = PostLink["https://vero.co/".Length..].Split("/").FirstOrDefault() ?? string.Empty;
            }
        }
        private bool CanPastePostLink(object parameter) => Clipboard.HasText;

        // TODO : need to handle load post...

        public Command PasteUserAliasCommand => new(PasteUserAlias, CanPasteUserAlias);
        private void PasteUserAlias(object parameter)
        {
            UserAlias = Clipboard.GetTextAsync().Result ?? string.Empty;
        }
        private bool CanPasteUserAlias(object parameter) => Clipboard.HasText;

        public Command PasteUserNameCommand => new(PasteUserName, CanPasteUserName);
        private void PasteUserName(object parameter)
        {
            UserName = Clipboard.GetTextAsync().Result ?? string.Empty;
        }
        private bool CanPasteUserName(object parameter) => Clipboard.HasText;
    }
}
