using System;
using System.Collections.Generic;
using System.Linq;
using System.Net;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Navigation;
using Microsoft.Phone.Controls;
using Microsoft.Phone.Shell;
using WeatherPing.Resources;

namespace WeatherPing
{
    public partial class MainPage : PhoneApplicationPage
    {
        // Constructor
        public MainPage()
        {
            InitializeComponent();

            // Sample code to localize the ApplicationBar
            //BuildLocalizedApplicationBar();
        }

        protected override void OnNavigatedTo(NavigationEventArgs e)
        {
            base.OnNavigatedTo(e);
            refresh();
        }

        private void refresh()
        {
            String weatherURL, locationName;
            int alertTimeSeconds;
            Parse.ParseInstallation install = App.installation;
            if (install.TryGetValue<String>("weatherURL", out weatherURL) && 
                install.TryGetValue<String>("locationName", out locationName) &&
                install.TryGetValue<int>("deliveryTime", out alertTimeSeconds)) {
                int hours = alertTimeSeconds / 3600;
                int minutes = (alertTimeSeconds - hours * 3600) / 60;
                bool PM = hours >= 12;
                if (PM) hours -= 12;
                if (hours == 0) hours = 12;
                AlertTimeLabel.Text = String.Format("{0}:{1} {2}", hours, minutes.ToString("D2"), PM ? "PM" : "AM");
                AlertLocationLabel.Text = locationName.ToLower();
                var urlString = String.Format("http://weatherping.parseapp.com/weather?url={0}&style=windows", Uri.EscapeDataString(weatherURL));
                loading = true;
                Browser.Source = new Uri(urlString);
            } else {
                NavigationService.Navigate(new Uri("/Hello.xaml", UriKind.Relative));
            }
        }

        private void WeatherLoaded(object sender, NavigationEventArgs e)
        {
            loading = false;
        }

        private bool m_loading = false;
        private bool loading
        {
            get
            {
                return m_loading;
            }
            set
            {
                if (m_loading != value)
                {
                    m_loading = value;
                    if (m_loading)
                    {
                        LoadingStart.Begin();
                    }
                    else
                    {
                        LoadingEnd.Begin();
                    }
                }
            }
        }

        private void Launch_Setup(object sender, System.Windows.Input.GestureEventArgs e)
        {
            NavigationService.Navigate(new Uri("/Location.xaml", UriKind.Relative));
        }
    }
}