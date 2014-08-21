using System;
using System.Collections.Generic;
using System.Linq;
using System.Net;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Navigation;
using Microsoft.Phone.Controls;
using Microsoft.Phone.Shell;

namespace WeatherPing
{
    public partial class Hello : PhoneApplicationPage
    {
        public Hello()
        {
            InitializeComponent();
        }

        private void GetStarted(object sender, RoutedEventArgs e)
        {
            NavigationService.Navigate(new Uri("/Location.xaml", UriKind.Relative));
        }
    }
}