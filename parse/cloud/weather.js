(function() {
	
	var debug = true;
	
	var getDisplayDate = function(response) {
		var today = response.forecast.simpleforecast.forecastday[0].date;
		return today.weekday + ", " + today.month + "/" + today.day;
	}
	
	var parse = function(response, significantOnly) {
		var f = true;
		
		var FToPreferred = function(fahrenheit) {
			return f ? fahrenheit : (fahrenheit - 32) * 5 / 9;
		}
		
		// fog, wind, snow, sleet, rain, cloudy, partly_cloudy_night
		// partly_cloudy_day, clear_night, clear_day
		var iconToSkycon = {
			chanceflurries: "SNOW",
			chancerain: "RAIN",
			chancesleet: "SLEET",
			chancesnow: "SNOW",
			chancetstorms: "RAIN",
			clear: "CLEAR_DAY",
			cloudy: "CLOUDY",
			flurries: "SNOW",
			fog: "FOG",
			hazy: "FOG",
			mostlycloudy: "PARTLY_CLOUDY_DAY",
			mostlysunny: "PARTLY_CLOUDY_DAY",
			partlycloudy: "PARTLY_CLOUDY_DAY",
			partlysunny: "PARTLY_CLOUDY_DAY",
			sleet: "SLEET",
			rain: "RAIN",
			snow: "SNOW",
			sunny: "CLEAR_DAY",
			tstorms: "RAIN"
		};
		
		var today = response.forecast.simpleforecast.forecastday[0];
		var tonight = response.forecast.simpleforecast.forecastday[1]
		var highForDay = function(day) {
			return parseFloat(f ? day.high.fahrenheit : day.high.celsius)
		}
		var lowForDay = function(day) {
			return parseFloat(f ? day.low.fahrenheit : day.low.celsius)
		}
		var fullDayHigh = Math.max(highForDay(today), highForDay(tonight));
		var fullDayLow = Math.min(lowForDay(today), lowForDay(tonight));
				
		var yesterday = response.history.dailysummary[0];
		var yesterdayHigh = parseFloat(f ? yesterday.maxtempi : yesterday.maxtempm);
		var yesterdayLow = parseFloat(f ? yesterday.mintempi : yesterday.mintempm);
		var todayMid = Math.round((fullDayHigh + fullDayLow) / 2);
		var yesterdayMid = Math.round((yesterdayHigh + yesterdayLow) / 2);
		
		var significantTempDiff = FToPreferred(5);
		
		var sentences = [];
		
		if (todayMid != yesterdayMid) {
			var diff = "(" + yesterdayMid + " → " + todayMid + ")";
			if (Math.abs(todayMid - yesterdayMid) >= significantTempDiff) {
				if (todayMid > yesterdayMid) {
					sentences.push("Hotter today. " + diff);
				} else {
					sentences.push("Colder today. " + diff);
				}
			} else if (!significantOnly) {
				if (todayMid > yesterdayMid) {
					sentences.push("A little hotter today. " + diff);
				} else {
					sentences.push("A little colder today. " + diff);
				}
			}
		} else if (!significantOnly) {
			sentences.push("Same temperature as yesterday. (" + todayMid + ")");
		}
		
		var importantConditionIcons = [
		"chanceflurries", "chancerain", "chancesleet",
		"chancesnow", "chancetstorms", "flurries",
		"sleet", "rain", "snow", "tstorms"
		];
		var dayConditionsText = today.conditions;
		var dayConditionsIcon = today.icon;
		var nightConditionsText = tonight.conditions;
		var nightConditionsIcon = tonight.icon;
		var include = function(x) {return !significantOnly || importantConditionIcons.indexOf(x) != -1}
		var conditionSentences = [];
		if (include(dayConditionsIcon) && dayConditionsIcon == nightConditionsIcon) {
			conditionSentences.push(sentenceCase(dayConditionsText) + " all day and night");
		} else {
			if (include(dayConditionsIcon)) {
				conditionSentences.push(dayConditionsText.toLowerCase() + " during the day");
			}
			if (include(nightConditionsIcon)) {
				conditionSentences.push(nightConditionsText.toLowerCase() + " tonight");
			}
		}
		if (conditionSentences.length > 0) {
			var sentence = conditionSentences.join(', and ')+'.';
			sentence = sentence.substring(0,1).toUpperCase() + sentence.substring(1);
			sentences.push(sentence);
		}
		
		/*
		var now = response.current_observation;
		var currentTemp = f ? now.temp_f : now.temp_c;
		var currentConditions = now.icon;
		*/
		var interestingIcon = dayConditionsIcon;
		if (importantConditionIcons.indexOf(dayConditionsIcon) == -1 &&
		importantConditionIcons.indexOf(nightConditionsIcon) != -1) {
			interestingIcon = nightConditionsIcon;
		}
		var skycon = iconToSkycon[interestingIcon];
		
		var text = sentences.join(" ");
		return {text: text, skycon: skycon};
	}
	
	var getSummaryForURL = function(url, callback) {
		var cityPath = url.split(".")[0];
		console.log("URL:"+ "http://api.wunderground.com/api/71170515284b31ae/forecast/yesterday/q/"+cityPath+".json")
		Parse.Cloud.httpRequest({
			method: 'GET',
			url: "http://api.wunderground.com/api/71170515284b31ae/forecast/yesterday/q/"+cityPath+".json",
			success: function(response) {
				console.log("RESPONSE: "+ response);
				var response = JSON.parse(response.text);
				var parsed = parse(response, false);
				var parsedSignificant = parse(response, true);
				var relevant = parsedSignificant.text.length > 0;
				if (debug) {
					if (!relevant) {
						parsed.text = "IRRELEVANT: " + parsed.text;
						relevant = true;
					}
				}
				callback({text: parsed.text, skycon: parsed.skycon, relevant: relevant, displayDate: getDisplayDate(response)});
			},
			error: function(response) {
				callback(null);
			}
		})
	}
	
	module.exports.parse = parse;
	module.exports.getWeatherSummaryForURL = getSummaryForURL;
})();
