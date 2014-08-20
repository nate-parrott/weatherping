require('cloud/app.js');
var moment = require('cloud/moment-timezone-with-data-2010-2020.js');
var weather = require('cloud/weather.js');

function roundMoment(m) {
	m.seconds(0);
	m.minutes(Math.round(m.minutes() / 30) * 30);
	return m;
}

Parse.Cloud.define("getWeather", function(request, response) {
	weather.getWeatherSummaryForURL(request.params.url, function(w) {
		response.success(w);
	})
})

Parse.Cloud.job("delivery", function(request, status) {
  Parse.Cloud.useMasterKey();
  var query = new Parse.Query("_Installation");
	var installsByWeatherURL = {};
  query.each(function(install) {
		var deliveryTimeLocal = install.get('deliveryTime'); // in seconds offset from midnight
		var weatherURL = install.get('weatherURL');
		var tz = install.get("timeZone");
		if (deliveryTimeLocal != undefined && weatherURL != undefined) {
			var deliveryUTC = roundMoment(moment().tz(tz).startOf("day").add(deliveryTimeLocal, "seconds")).unix();
			console.log("Delivery: " + deliveryUTC);
			var nowUTC = roundMoment(moment()).unix();
			console.log("Now: " + nowUTC);
			if (nowUTC == deliveryUTC) {
				if (installsByWeatherURL[weatherURL] == undefined) {
					installsByWeatherURL[weatherURL] = [];
				}
				installsByWeatherURL[weatherURL].push(install);
			}
		}
  }).then(function() {
		var waitingOn = 0;
		var more = true;
		for (var weatherURL in installsByWeatherURL) {
		  if (installsByWeatherURL.hasOwnProperty(weatherURL)) {
				var installs = installsByWeatherURL[weatherURL];
				waitingOn++;
		    weather.getWeatherSummaryForURL(weatherURL, function(w) {
		    	if (w.relevant) {
		    		var ids = installs.map(function(i) {return i.get('installationId')});
						var query = (new Parse.Query("_Installation")).containedIn("installationId", ids);
						Parse.Push.send({
							where: query,
							data: {
								alert: w.text
							}
						})
						waitingOn--;
						if (waitingOn == 0 && !more) {
					    status.success("Done");
						}
		    	}
		    })
		  }
		}
		more = false;
		if (waitingOn == 0) {
	    status.success("Done");
		}
  }, function(error) {
    // Set the job's error status
    status.error("Error");
  });
});
