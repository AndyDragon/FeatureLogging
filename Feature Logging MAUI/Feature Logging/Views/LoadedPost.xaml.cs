using FeatureLogging.Base;
using FeatureLogging.ViewModels;

namespace FeatureLogging.Views;

public partial class LoadedPost : IThemePage
{
	public LoadedPost()
	{
		InitializeComponent();
	}

	protected override void OnAppearing()
	{
		base.OnAppearing();
		if (BindingContext is LoadedPostViewModel vm)
		{
			_ = vm.TriggerLoad();
		}
	}

	public void UpdateTheme(AppTheme theme)
	{
	}
}
