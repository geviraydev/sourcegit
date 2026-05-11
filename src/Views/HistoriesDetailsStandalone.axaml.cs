using System;

namespace SourceGit.Views
{
    public partial class HistoriesDetailsStandalone : ChromelessWindow
    {
        public HistoriesDetailsStandalone()
        {
            InitializeComponent();
        }

        protected override void OnDataContextChanged(EventArgs e)
        {
            base.OnDataContextChanged(e);

            Title = DataContext switch
            {
                ViewModels.RevisionCompare => App.Text("HistoriesDetailsStandalone.RevisionCompare"),
                _ => App.Text("HistoriesDetailsStandalone.CommitDetail")
            };
        }
    }
}
