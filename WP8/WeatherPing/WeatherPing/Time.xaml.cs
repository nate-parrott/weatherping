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
    public partial class Time : PhoneApplicationPage
    {
        public Time()
        {
            InitializeComponent();
        }

        private void Done_Click(object sender, RoutedEventArgs e)
        {

        }

        private void Time_Changed(object sender, DateTimeValueChangedEventArgs e)
        {
            System.DateTime? valueOpt = e.NewDateTime;
            if (valueOpt.HasValue && TimePicker != null)
            {
                var value = valueOpt.Value;
                int seconds = value.Second + value.Minute * 60 + value.Hour * 3600;
                double roundToInterval = 60 * 30;
                seconds = (int) (Math.Round(seconds / roundToInterval) * roundToInterval);
                var newValue = new System.DateTime();
                newValue = newValue.AddSeconds(-getSecondsFromStartOfDay(newValue));
                newValue = newValue.AddSeconds(seconds);
                TimePicker.Value = newValue;
            }
        }

        private double getSecondsFromStartOfDay(DateTime t)
        {
            return t.Second + 60 * (t.Minute + 60 * t.Hour);
        }
    }
}