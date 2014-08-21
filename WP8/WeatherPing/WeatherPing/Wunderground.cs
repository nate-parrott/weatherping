using Newtonsoft.Json.Linq;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Net;
using System.Text;
using System.Threading.Tasks;

namespace WeatherPing
{
    class Wunderground
    {
        public class LocalInfo
        {
            public String weatherUrl, locationName;
        }
        public static async Task<LocalInfo> GetLocalInfoForUrl(String zipOrLatLon)
        {
            String apiRoot = "http://api.wunderground.com/api/71170515284b31ae";
            JObject result = await GetJson(apiRoot + "/geolookup/q/" + zipOrLatLon + ".json");
            JObject location = result.GetValue("location") as JObject;
            LocalInfo info = new LocalInfo();
            info.weatherUrl = location.GetValue("requesturl").ToString();
            info.locationName = location.GetValue("city").ToString();
            if (info.weatherUrl != null && info.locationName != null)
            {
                return info;
            }
            else
            {
                return null;
            }

        }
        public static async Task<JObject> GetJson(String url)
        {
            var tcs = new TaskCompletionSource<string>();
            var client = new WebClient();
            client.DownloadStringCompleted += (s, e) =>
            {
                if (e.Error == null)
                {
                    tcs.SetResult(e.Result);
                }
                else
                {
                    tcs.SetResult(null);
                }
            };

            client.DownloadStringAsync(new Uri(url));

            return await tcs.Task.ContinueWith<JObject>((task) =>
                {
                    if (task.Result != null)
                    {
                        return JObject.Parse(task.Result);
                    }
                    else
                    {
                        return null;
                    }
                });
        }
    }
}
