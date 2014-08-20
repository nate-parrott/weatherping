var weather = require('./weather');
var fs = require('fs');
var response = JSON.parse(fs.readFileSync("sample.json"))
console.log("SIGNIFICANT", weather.parse(response, true));
console.log("INSIGNIFICANT", weather.parse(response, false));
