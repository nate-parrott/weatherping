using System;
using System.Collections.Generic;
using System.Linq;
using System.Net;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Navigation;
using Microsoft.Phone.Controls;
using Microsoft.Phone.Shell;
using Windows.Devices.Geolocation;
using System.Threading.Tasks;
using System.Windows.Input;

namespace WeatherPing
{
    public partial class Location : PhoneApplicationPage
    {
        private enum WorkState
        {
            None,
            WaitingForConsent,
            GettingLocation,
            Geocoding,
            Error,
            Done
        }
        private WorkState m_state = WorkState.None;

        private void setState(WorkState s)
        {
            m_state = s;
            Error.Visibility = s == WorkState.Error ? Visibility.Visible : Visibility.Collapsed;
            Loader.Visibility = s == WorkState.GettingLocation || s == WorkState.Geocoding ? Visibility.Visible : Visibility.Collapsed;
            Done.IsEnabled = s == WorkState.Done;
            Consent.Visibility = s == WorkState.WaitingForConsent ? Visibility.Visible : Visibility.Collapsed;
            LocationLabel.Visibility = s == WorkState.Done ? Visibility.Visible : Visibility.Collapsed;
        }

        public Location()
        {
            InitializeComponent();
        }

        protected override void OnNavigatedTo(NavigationEventArgs e)
        {
            base.OnNavigatedTo(e);
            setState(WorkState.WaitingForConsent);
        }

        private void Error_Click(object sender, RoutedEventArgs e)
        {
            setState(WorkState.WaitingForConsent);
        }

        private void Done_Click(object sender, RoutedEventArgs e)
        {
            NavigationService.Navigate(new Uri("/Time.xaml", UriKind.Relative));
        }

        private void Use_Location(object sender, System.Windows.RoutedEventArgs e)
        {
            GeoLocate();
        }

        private void Use_Zip_Code(object sender, System.Windows.RoutedEventArgs e)
        {
            TextBox textBox = new TextBox();
            // restrict input to digits:
            InputScope inputScope = new InputScope();
            InputScopeName inputScopeName = new InputScopeName();
            inputScopeName.NameValue = InputScopeNameValue.Digits;
            inputScope.Names.Add(inputScopeName);
            textBox.InputScope = inputScope;

            CustomMessageBox messageBox = new CustomMessageBox()
            {
                Message = "Enter your US zip code:",
                LeftButtonContent = "okay",
                RightButtonContent = "cancel",
                Content = textBox
            };
            messageBox.Loaded += (a, b) =>
            {
                textBox.Focus();
            };
            messageBox.Show();
            messageBox.Dismissed += (s, args) =>
            {
                if (args.Result == CustomMessageBoxResult.LeftButton)
                {
                    if (textBox.Text.Length >= 5)
                    {
                        geocodeUsingString(textBox.Text);
                    }
                }
            };
        }

        private void geocodeUsingString(String geoString) // zip code or lat, lon pair
        {
            setState(WorkState.Geocoding);
            Task<Wunderground.LocalInfo> t = Wunderground.GetLocalInfoForUrl(geoString);
            t.ContinueWith((task) =>
            {
                Wunderground.LocalInfo info;
                if (!task.IsFaulted && (info = task.Result) != null)
                {
                    LocationLabel.Text = info.locationName;
                    App.installation["locationName"] = info.locationName;
                    App.installation["weatherURL"] = info.weatherUrl;
                    setState(WorkState.Done);
                }
                else
                {
                    showError(null);
                }
            }, TaskScheduler.FromCurrentSynchronizationContext());
        }

        private async void GeoLocate()
        {
            setState(WorkState.GettingLocation);
            Geolocator geolocator = new Geolocator();
            geolocator.DesiredAccuracyInMeters = 1000;

            try
            {
                Geoposition geoposition = await geolocator.GetGeopositionAsync(
                    maximumAge: TimeSpan.FromMinutes(30),
                    timeout: TimeSpan.FromSeconds(10)
                    );

                String queryString = String.Format("{0},{1}", geoposition.Coordinate.Latitude, geoposition.Coordinate.Longitude);
                geocodeUsingString(queryString);
            }
            catch (Exception ex)
            {
                if ((uint)ex.HResult == 0x80004004)
                {
                    showError("Location appears to be disabled in Phone Settings.");
                }
                else
                {
                    showError("We weren't able to find your location automatically.");
                }
            }
        }

        private void showError(String error)
        {
            if (error == null) error = "Sorry, we couldn't fetch a location.";
            setState(WorkState.WaitingForConsent);
            MessageBox.Show(error,
            "Error",
            MessageBoxButton.OK);
        }
    }
}